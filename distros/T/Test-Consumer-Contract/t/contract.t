#!/usr/bin/env perl

# End-to-end tests for the three checks, run the way another distribution would
# run them: a throwaway workspace holding a producer, its value object, and a
# consumer, with a second distribution declaring the contract and running it in
# a subprocess.  Each subtest breaks one thing and names the failure that must
# come out of it, so the checks are proved to detect drift rather than merely to
# pass on well-behaved code.

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Data::Dumper ();
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::Most;
use Cwd qw(abs_path);

my $HELPER_LIB = abs_path("$Bin/../lib");

# The three checks, by the name each reports itself under.
my @CHECKS = (
	'the producers still set the keys the contract claims',
	'registered consumers read only what every backend sets',
	'every discovered consumer is registered',
);

# ---------------------------------------------------------------------------
# The fixture workspace
# ---------------------------------------------------------------------------

my $VALUE_OBJECT = <<'PERL';
package Widget;

sub new
{
	my ($class, %args) = @_;

	my $self = bless {}, $class;
	$self->{'x'}      = $args{'x'}      // $args{'latitude'};
	$self->{'y'}      = $args{'y'}      // $args{'longitude'};
	$self->{'colour'} = $args{'colour'};

	return $self;
}

sub x      { $_[0]->{'x'} }
sub y      { $_[0]->{'y'} }
sub colour { $_[0]->{'colour'} }

1;
PERL

# The producer: it sets x, y and colour, and hands back a Widget.
my $PRODUCER = <<'PERL';
package Widget::Maker;

use Widget;

sub new { bless {}, $_[0] }

sub geocode
{
	my ($self, %args) = @_;

	my %COLOURS = (London => 'red', Paris => 'blue');

	return Widget->new(
		x        => 51.5074,
		y        => -0.1278,
		colour   => $COLOURS{$args{'location'}},
		location => $args{'location'},
	);
}

1;
PERL

# The same producer after it quietly stopped stamping one key.
my $PRODUCER_WITHOUT_COLOUR = $PRODUCER;
$PRODUCER_WITHOUT_COLOUR =~ s/^\t\tcolour   => \$COLOURS\{\$args\{'location'\}\},\n//m;

# A producer inside the declaring distribution, so the dist-relative and the
# workspace-relative evidence tables are both exercised.
my $WRITER = <<'PERL';
package Widget::Writer;

sub write { return { colour => 'red' } }

1;
PERL

# The consumer: it reads only keys every producer sets.
my $CONSUMER = <<'PERL';
package Widget::User;

use Widget::Maker;

sub render
{
	my ($self, $maker, $name) = @_;

	my $widget = $maker->geocode(location => $name);
	return unless $widget;

	return $widget->{'x'} . ',' . $widget->{'y'};
}

1;
PERL

# The same value object after it gained an accessor, documented at =head2 and
# implemented, which is how a value object grows one.
my $VALUE_OBJECT_WITH_POSTCODE = $VALUE_OBJECT;
$VALUE_OBJECT_WITH_POSTCODE =~ s/^1;$/=head2 postcode

The postcode, when the lookup that made the widget returned one.

=cut

sub postcode { \$_[0]->{'postcode'} }

1;/m;

# And after it gained one that is documented only, implemented through AUTOLOAD
# the way Geo::Location::Point implements attr(): the contract has to account for
# what the value object documents, not only for what it compiles.
my $VALUE_OBJECT_WITH_DOCUMENTED_ONLY = $VALUE_OBJECT;
$VALUE_OBJECT_WITH_DOCUMENTED_ONLY =~ s/^1;$/=head2 url

The URL the widget was built from.

=cut

1;/m;

# The same consumer after it started reading a key only some paths set.
my $CONSUMER_READING_COLOUR = $CONSUMER;
$CONSUMER_READING_COLOUR =~ s/return \$widget->\{'x'\} \. ',' \. \$widget->\{'y'\};/return \$widget->{'x'} . \$widget->{'colour'};/;

# A consumer nobody registered.
my $STRAY_CONSUMER = <<'PERL';
package Widget::Stray;

use Widget::Maker;

sub show
{
	my ($self, $maker) = @_;

	my $widget = $maker->geocode(location => 'London');
	return unless $widget;

	return $widget->{'x'};
}

1;
PERL

# A platform whose paths use '\', emulated on any platform: File::Spec->abs2rel()
# answers the way File::Spec::Win32 does, and File::Spec->catfile() reads a '\'
# as a separator, as it does there.  Every path the declaration writes - and so
# every path the checks look a file up by, and report it under - is spelled with
# '/', so a path taken straight from abs2rel() matches no registry key and no
# ignored rule, and every consumer is reported as unregistered.  That is what
# Windows CI caught, and it is why these tests can assert it without Windows.
my $WINDOWS_SEPARATORS = <<'PERL';
package WinSep;

use File::Spec;

my $abs2rel = File::Spec->can('abs2rel');
my $catfile = File::Spec->can('catfile');

no warnings 'redefine';

*File::Spec::abs2rel = sub {
	my $rel = $abs2rel->(@_);
	$rel =~ s{/}{\\}g;

	return $rel;
};

*File::Spec::catfile = sub {
	my @parts = map { my $part = $_; $part =~ s{\\}{/}g; $part } @_;

	return $catfile->(@parts);
};

1;
PERL

my %BASE_DECLARATION = (
	source              => 'Widget::Maker',
	include             => ['Widget-Maker/lib'],
	value_object        => {
		class   => 'Widget',
		from    => { latitude => 1, longitude => 2 },
		derives => { x => 1, y => 2 },
	},
	accessors           => [qw(x y)],
	not_accessors       => { new => 'the constructor, not a slot of one result' },
	inspection          => [qw(can isa DOES)],
	guaranteed          => [qw(x y)],
	conditional         => { colour => 'only the painted path sets it' },
	producers           => { 'lib/Widget/Writer.pm' => [qw(colour)] },
	workspace_producers => { 'Widget-Maker/lib/Widget/Maker.pm' => [qw(x y colour)] },
	consumers           => { 'Widget-User/lib/Widget/User.pm' => { may_rely_on => {} } },
	ignored             => [],
	require_workspace   => [qw(Widget-Maker Widget-User)],
);

sub _write
{
	my ($dir, $rel, $content) = @_;

	my $path = File::Spec->catfile($dir, split(m{/}, $rel));
	make_path(dirname($path));
	open(my $fh, '>', $path) or die "Cannot write $path: $!";
	print {$fh} $content;
	close($fh) or die "Cannot close $path: $!";

	return $path;
}

# A workspace with the dists above in it, and whatever the scenario changes.
sub _fixture
{
	my ($files) = @_;

	my $dir = tempdir(CLEANUP => 1);

	my %default = (
		'Widget-Maker/lib/Widget.pm'          => $VALUE_OBJECT,
		'Widget-Maker/lib/Widget/Maker.pm'    => $PRODUCER,
		'Widget-User/lib/Widget/User.pm'      => $CONSUMER,
		'Widget-Contract/lib/Widget/Writer.pm' => $WRITER,
	);
	# A scenario may pass undef for a file to take it out of the fixture.
	$default{$_} = $files->{$_} for keys %{$files};

	for my $rel (sort keys %default) {
		next unless defined($default{$rel});
		_write($dir, $rel, $default{$rel});
	}

	# The declaring distribution needs a lib/ for its own root to be recognised.
	make_path(File::Spec->catdir($dir, 'Widget-Contract', 'lib'));

	return $dir;
}

# The declaration, written out as the test a second distribution would have.
# windows_separators is not part of the declaration: it puts the shim above on
# the fixture's include path and loads it before the module under test.
sub _check
{
	my ($dir, %declaration) = @_;

	my $windows_separators = delete $declaration{'windows_separators'};

	my %spec = (%BASE_DECLARATION, %declaration);

	my $dumped = Data::Dumper->new([\%spec])->Terse(1)->Sortkeys(1)->Dump();

	my @include = ("-I$HELPER_LIB");
	my $preload = '';
	if($windows_separators) {
		# In a directory of its own rather than in the fixture: the fixture is the
		# workspace the checks scan, and a shim dropped in it would be a sibling
		# distribution that the scenarios below did not ask for.
		my $shim = tempdir(CLEANUP => 1);
		_write($shim, 'WinSep/lib/WinSep.pm', $WINDOWS_SEPARATORS);
		push @include, '-I' . File::Spec->catdir($shim, 'WinSep', 'lib');
		$preload = "use WinSep;\n";
	}

	my $script = <<"SCRIPT";
#!perl -w
use strict;
use warnings;

$preload
use Test::Most;

# Everything the runner has to read arrives on one stream.  The diagnostics the
# checks leave behind go through Test::Builder, which keeps a stream of its own
# for them unless it is told otherwise, and anything written straight to STDERR
# is merged into stdout as well.  The runner used to ask the shell for this with
# "2>&1"; the redirection is done here instead, because a shell is the one thing
# that is not portable - the shell on Windows does not know the quoting a POSIX
# shell would, which is what used to break this suite there.
Test::More->builder->output(\\*STDOUT);
Test::More->builder->failure_output(\\*STDOUT);
open(STDERR, '>&', \\*STDOUT) or die "cannot send stderr to stdout: \$!";

use Test::Consumer::Contract qw(run_consumer_contract);

my \$spec = $dumped;

run_consumer_contract(%{\$spec});

done_testing();
SCRIPT

	my $path = _write($dir, 'Widget-Contract/t/contract.t', $script);

	# perl, the include path and the fixture test as separate arguments: no shell,
	# so nothing here rests on quoting that differs between platforms.  A
	# single-string open is run by the platform's shell, and the shell on Windows
	# is cmd.exe, which does not know what a POSIX single quote is: the quote
	# marks became part of the file name and every subtest saw "The filename,
	# directory name, or volume label syntax is incorrect." rather than a check.
	# The fixture sends its own diagnostics to stdout (see the script above), so
	# one stream is still what comes back.
	open(my $fh, '-|', $^X, @include, $path) or die "Cannot run $^X: $!";
	local $/;
	my $output = <$fh> // '';
	close($fh);
	my $status = $? >> 8;

	return ($status, $output);
}

sub _passed
{
	my $output = shift;

	return grep { $output =~ /^ok \d+ - \Q$_\E$/m } @CHECKS;
}

sub _failed
{
	my $output = shift;

	return grep { $output =~ /^not ok \d+ - \Q$_\E$/m } @CHECKS;
}

sub _no_other_failures
{
	my ($output, @expected) = @_;

	my @failed = _failed($output);
	is_deeply([sort @failed], [sort @expected], 'exactly the expected checks failed')
		or diag($output);

	return;
}

# ---------------------------------------------------------------------------
# The checks
# ---------------------------------------------------------------------------

subtest 'a contract that holds passes all three checks' => sub {
	my ($status, $output) = _check(_fixture({}));

	is($status, 0, 'the contract passed') or diag($output);
	is(scalar(_passed($output)), 3, 'all three checks ran and passed') or diag($output);
	unlike($output, qr/^not ok/m, 'nothing failed');
};

subtest 'a value object that gains a documented accessor is caught' => sub {
	my ($status, $output) = _check(_fixture({
		'Widget-Maker/lib/Widget.pm' => $VALUE_OBJECT_WITH_POSTCODE,
	}));

	isnt($status, 0, 'the contract failed');
	like($output, qr/Widget documents 'postcode', which this contract does not mention/,
		'the check names the accessor the declaration is missing') or diag($output);
	like($output, qr/The value object and the reader contract have drifted apart/,
		'and says what has happened') or diag($output);
	like($output, qr/'accessors'[\s\S]*'conditional'[\s\S]*'not_accessors'/,
		'and tells the reader where each kind of accessor belongs') or diag($output);
	like($output, qr/^not ok \d+ - the accessor list matches the value object$/m,
		'the accessor check is the one that failed') or diag($output);
	is(scalar(_passed($output)), 3, 'the three producer and consumer checks still passed') or diag($output);
};

subtest 'an accessor the value object documents but does not compile is caught too' => sub {
	my ($status, $output) = _check(_fixture({
		'Widget-Maker/lib/Widget.pm' => $VALUE_OBJECT_WITH_DOCUMENTED_ONLY,
	}));

	isnt($status, 0, 'the contract failed');
	like($output, qr/Widget documents 'url', which this contract does not mention/,
		'a documented accessor dispatched through AUTOLOAD is found by its heading')
		or diag($output);
};

subtest 'the new accessor passes once the contract accounts for it' => sub {
	my %fixture = ('Widget-Maker/lib/Widget.pm' => $VALUE_OBJECT_WITH_POSTCODE);

	# In 'not_accessors': documented, but not a slot of one result.
	my ($not_accessor_status, $not_accessor_output) = _check(_fixture(\%fixture),
		not_accessors => {
			new      => 'the constructor, not a slot of one result',
			postcode => 'the widget carries no postcode; the demo declares it only',
		});
	is($not_accessor_status, 0, 'listing it in not_accessors satisfies the check')
		or diag($not_accessor_output);

	# In 'conditional': documented, and only some results carry it.
	my ($conditional_status, $conditional_output) = _check(_fixture(\%fixture),
		conditional => {
			colour   => 'only the painted path sets it',
			postcode => 'only the address lookup sets it',
		});
	is($conditional_status, 0, 'or in conditional, for an accessor only some results carry')
		or diag($conditional_output);
};

subtest 'a name the value object no longer documents is caught' => sub {
	my ($status, $output) = _check(_fixture({}),
		not_accessors => {
			new   => 'the constructor, not a slot of one result',
			shave => 'left over from a value object that had one',
		});

	isnt($status, 0, 'the contract failed');
	like($output, qr/not ok \d+ - shave is a documented accessor of Widget/,
		# Inside the accessor subtest, so the TAP line is indented.
		'the stale entry is named, as a renamed or removed accessor would be') or diag($output);
};

subtest 'a producer that stops setting a key is caught' => sub {
	my ($status, $output) = _check(_fixture({
		'Widget-Maker/lib/Widget/Maker.pm' => $PRODUCER_WITHOUT_COLOUR,
	}));

	isnt($status, 0, 'the contract failed');
	like($output, qr/not ok \d+ - Widget-Maker\/lib\/Widget\/Maker\.pm sets 'colour'/,
		'the check names the file and the key') or diag($output);
	_no_other_failures($output, $CHECKS[0]);
};

subtest 'a consumer reading a key its producer does not promise is caught' => sub {
	my ($status, $output) = _check(_fixture({
		'Widget-User/lib/Widget/User.pm' => $CONSUMER_READING_COLOUR,
	}));

	isnt($status, 0, 'the contract failed');
	like($output, qr/Widget-User\/lib\/Widget\/User\.pm line \d+ in render\(\) reads 'colour' \(key\) - only the painted path sets it/,
		'the check names the file, line, sub, key and why') or diag($output);
	_no_other_failures($output, $CHECKS[1]);
};

subtest 'a read the consumer registers is allowed' => sub {
	my ($status, $output) = _check(_fixture({
		'Widget-User/lib/Widget/User.pm' => $CONSUMER_READING_COLOUR,
	}), consumers => {
		'Widget-User/lib/Widget/User.pm' => {
			may_rely_on => {
				render => { colour => 'only reached on the painted path' },
			},
		},
	});

	is($status, 0, 'the registered read passed') or diag($output);
	unlike($output, qr/^not ok/m, 'nothing failed');
};

subtest 'a registry entry that is no longer read is reported as stale' => sub {
	my ($status, $output) = _check(_fixture({}), consumers => {
		'Widget-User/lib/Widget/User.pm' => {
			may_rely_on => {
				render => { colour => 'only reached on the painted path' },
			},
		},
	});

	isnt($status, 0, 'the contract failed');
	like($output, qr/Remove the stale entry, so the registry keeps describing the code/,
		'the stale entry is named') or diag($output);
	_no_other_failures($output, $CHECKS[1]);
};

subtest 'a consumer that is not registered is caught' => sub {
	my ($status, $output) = _check(_fixture({
		'Widget-User/lib/Widget/Stray.pm' => $STRAY_CONSUMER,
	}));

	isnt($status, 0, 'the contract failed');
	like($output, qr/unregistered consumers of Widget::Maker results:/,
		'the check says what it found') or diag($output);
	like($output, qr/Widget-User\/lib\/Widget\/Stray\.pm/, 'and names the file') or diag($output);
	_no_other_failures($output, $CHECKS[2]);
};

subtest 'an ignored file is not reported as an unregistered consumer' => sub {
	my ($status, $output) = _check(_fixture({
		'Widget-User/lib/Widget/Stray.pm' => $STRAY_CONSUMER,
	}), ignored => [
		['Widget-User/lib/Widget/Stray.pm', 'a demo that is not part of the contract'],
	]);

	is($status, 0, 'the ignored file was left alone') or diag($output);
	is(scalar(_passed($output)), 3, 'all three checks ran and passed') or diag($output);
};

subtest 'the checks hold on a platform whose paths use backslashes' => sub {
	my ($status, $output) = _check(_fixture({}), windows_separators => 1);

	is($status, 0, 'the contract passed') or diag($output);
	is(scalar(_passed($output)), 3, 'all three checks ran and passed') or diag($output);
	unlike($output, qr/\\/, 'and nothing they report carries a platform separator')
		or diag($output);
};

subtest 'and a consumer is named the way the contract names files' => sub {
	my ($status, $output) = _check(_fixture({
		'Widget-User/lib/Widget/Stray.pm' => $STRAY_CONSUMER,
	}), windows_separators => 1);

	isnt($status, 0, 'the contract failed');
	like($output, qr/Widget-User\/lib\/Widget\/Stray\.pm/, 'the unregistered file is named with /')
		or diag($output);
	_no_other_failures($output, $CHECKS[2]);
};

subtest 'and an ignored rule written with / still matches' => sub {
	my ($status, $output) = _check(_fixture({
		'Widget-User/lib/Widget/Stray.pm' => $STRAY_CONSUMER,
	}), ignored => [
		['Widget-User/lib/Widget/Stray.pm', 'a demo that is not part of the contract'],
	], windows_separators => 1);

	is($status, 0, 'the ignored file was left alone') or diag($output);
	is(scalar(_passed($output)), 3, 'all three checks ran and passed') or diag($output);
};

subtest 'the workspace checks skip when the siblings are not there' => sub {
	my ($status, $output) = _check(_fixture({}), require_workspace => ['No-Such-Distribution']);

	is($status, 0, 'only the checks that can run did run') or diag($output);
	is(scalar(_passed($output)), 1, 'the producer check ran') or diag($output);
	like($output, qr/sibling checkouts are not present \(No-Such-Distribution\)/,
		'and the skip says which checkout is missing') or diag($output);
};

done_testing();
