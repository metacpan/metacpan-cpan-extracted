#!/usr/bin/env perl

# Unit tests for the parts of the contract checker that read source: which
# variables hold a result, what a read of one looks like, how a producer's
# assignment is recognised, and which directories it walks past.  The three
# checks themselves are exercised end to end in t/contract.t.

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::Most;
use Test::Consumer::Contract;

# White-box: some subtests below call the scanner's private subs directly.
# Sub::Private allows that under a test harness; the bypass makes it hold when
# this file is run on its own with perl as well.
$Sub::Private::BYPASS = 1;

my $contract = Test::Consumer::Contract->new(
	source     => 'Widget::Maker',
	producers  => {},
	guaranteed => [],
	methods       => [qw(geocode reverse_geocode geocode_many)],
	batch_methods => ['geocode_many'],
);

subtest 'a key read through a bound result is a read' => sub {
	my @reads = $contract->reads_of_results(<<'SOURCE');
my $widget = $maker->geocode(location => 'London');
return $widget->{'colour'};
SOURCE

	is(scalar(@reads), 1, 'one read') or diag(explain(\@reads));
	is($reads[0][0], 'colour', 'the key is named');
	is($reads[0][1], 2, 'the line number is the real one');
	is($reads[0][2], 'key', 'it is a hash key, not an accessor');
	is($reads[0][3], '(file scope)', 'no sub encloses it');
};

subtest 'a result passed to a helper is followed into it' => sub {
	my @reads = $contract->reads_of_results(<<'SOURCE');
my $point = $geocoder->reverse_geocode(lat => 1, long => 2);
_place($point);

sub _place
{
	my $point = shift;

	return $point->{'county'};
}
SOURCE

	is(scalar(@reads), 1, 'one read, found inside the helper') or diag(explain(\@reads));
	is($reads[0][0], 'county', 'the key is named');
	is($reads[0][3], '_place', 'the enclosing sub is named');
};

subtest 'an accessor call is a read, and so is an inspection' => sub {
	my @reads = $contract->reads_of_results(<<'SOURCE');
my $point = $geocoder->geocode(location => 'London');
return $point->latitude() if($point->can('latitude'));
SOURCE

	my %by_key = map { $_->[0] => $_->[2] } @reads;
	is_deeply(\%by_key, { latitude => 'accessor', can => 'accessor' },
		'both are accessor calls') or diag(explain(\@reads));
};

subtest 'POD and comments are not reads of a result' => sub {
	my $text = $contract->strip(<<'SOURCE');
# $widget->{'comment'} is in a comment
=head1 NAME

Widget::User - the $widget->{'pod'} key in prose is not a read

=cut

my $widget = $maker->geocode(location => 'London');
return $widget->{'x'};
SOURCE

	my @reads = $contract->reads_of_results($text);
	is(scalar(@reads), 1, 'only the real read is found') or diag(explain(\@reads));
	is($reads[0][0], 'x', 'and it is the real key');
	is($reads[0][1], 9, 'the line number survives stripping');
};

subtest 'the spellings that count as a producer setting a key' => sub {
	ok($contract->sets_key("colour => 'red'", 'colour'), 'bare key');
	ok($contract->sets_key("'colour' => 'red'", 'colour'), 'quoted key');
	ok($contract->sets_key('$widget->{\'colour\'} = \'red\'', 'colour'), 'assignment through the object');
	ok($contract->sets_key('$widget->{\'colour\'} //= \'red\'', 'colour'), 'defaulted assignment');

	ok(!$contract->sets_key("my \$colour = 'red'", 'colour'), 'a lexical is not the key');
	ok(!$contract->sets_key("colourblind => 1", 'colour'), 'a longer key is not the key');
	ok(!$contract->sets_key('$widget->colour()', 'colour'), 'calling an accessor is not setting the key');
};

subtest 'a path is judged the same whatever separator it is written with' => sub {
	ok($contract->_skipped_dir('/ws/Widget-User/blib'), 'a POSIX path to a build product is walked past');
	ok($contract->_skipped_dir('C:\\ws\\Widget-User\\blib'), 'and the Windows path to one, which used to be walked into');
	ok($contract->_skipped_dir('C:\\ws\\Widget-User\\.git'), 'a nested version control tree is walked past');
	ok(!$contract->_skipped_dir('C:\\ws\\Widget-User\\lib'), 'an ordinary directory is not');

	is($contract->_ported('Widget-User\\lib\\Widget\\User.pm'), 'Widget-User/lib/Widget/User.pm',
		'a platform path is spelled the way the contract spells files');
	is($contract->_ported('Widget-User/lib/Widget/User.pm'), 'Widget-User/lib/Widget/User.pm',
		'and one already spelled that way is left alone');
};

subtest 'a result taken out of a batch is followed, and the batch itself is not' => sub {
	my @reads = $contract->reads_of_results(<<'SOURCE');
my $batch = $geocoder->geocode_many(['London']);
my $count = $batch->{'lookups'};
my $point = (ref($batch) eq 'HASH') ? $batch->{'London'} : undef;
_coordinates($point);

sub _coordinates
{
	my $point = shift;

	return $point->{'lat'};
}
SOURCE

	my @keys = map { $_->[0] } @reads;
	is_deeply(\@keys, ['lat'], 'only the read off the result is found')
		or diag(explain(\@reads));
	is($reads[0][3], '_coordinates', 'and it was followed into the helper it was passed to');
};

subtest 'a value put into a hash or handed back out of a sub is followed' => sub {
	# Neither read is off a variable bound from the batch: one is through an
	# element of a hash the values were mapped into, the other off a sub that
	# returned one.  The hash held in a field of $self is not the hash that holds
	# results, so the read through it is not a read of a result.
	my @reads = $contract->reads_of_results(<<'SOURCE');
my $batch = $geocoder->geocode_many(['London', 'Paris']);
my %points = map { $_ => $batch->{$_} } ('London', 'Paris');
$self->{'cache'}{'London'} = $batch->{'London'};

sub show
{
	my ($self, $name) = @_;

	my $county = $self->{'cache'}{'London'}->{'county'};

	return $points{$name}->{'lat'};
}

sub pick
{
	my ($self, $name) = @_;

	my $batch = $geocoder->geocode_many([$name]);

	return $batch->{$name};
}

sub describe
{
	my ($self, $name) = @_;

	return $self->pick($name)->{'county'};
}
SOURCE

	my @found = map { $_->[0] . ' in ' . $_->[3] } @reads;
	is_deeply(\@found, ['lat in show', 'county in describe'],
		'both reads are followed, and $self is not taken for the hash')
		or diag(explain(\@reads));
};

subtest 'the producing calls are the ones the contract names' => sub {
	my $warehouse = Test::Consumer::Contract->new(
		source     => 'Warehouse::Stock',
		guaranteed => ['grams'],
		methods    => [qw(fetch scan)],
	);

	my @reads = $warehouse->reads_of_results(<<'SOURCE');
my $item = $stock->fetch(sku => 'A1');
return $item->{'grams'};
SOURCE

	is_deeply([map { $_->[0] } @reads], ['grams'], 'fetch() hands a result here')
		or diag(explain(\@reads));

	# The same read under a contract for a value object whose producer is called
	# geocode(): that call is not one of this contract's producing calls, so the
	# variable it binds is not a result and the read is not reported.  Nothing
	# about geocoding is built into the checker.
	my @geocoded = $warehouse->reads_of_results(<<'SOURCE');
my $item = $geocoder->geocode(location => 'London');
return $item->{'grams'};
SOURCE

	is(scalar(@geocoded), 0, 'a geocode() call is not a producer in this contract')
		or diag(explain(\@geocoded));
};

subtest 'a contract with no producing calls finds no reads at all' => sub {
	my $none = Test::Consumer::Contract->new(
		source     => 'Widget::Maker',
		guaranteed => [],
		methods    => [],
	);

	# An empty alternation would match at every position, which would make every
	# '(' a producing call and every key after one a read of a result.
	my @reads = $none->reads_of_results(<<'SOURCE');
my $widget = $maker->geocode(location => 'London');
return $widget->{'x'};
SOURCE

	is(scalar(@reads), 0, 'nothing any call returns is a result') or diag(explain(\@reads));
};

subtest 'a program is recognised by its shebang, not by a bin directory' => sub {
	my $dir = tempdir(CLEANUP => 1);

	my $program = File::Spec->catfile($dir, 'map-events');
	open(my $out, '>', $program) or die "Cannot write $program: $!";
	print {$out} "#!/usr/bin/env perl\n\nprint \"hi\\n\";\n";
	close($out) or die "Cannot close $program: $!";

	my $document = File::Spec->catfile($dir, 'Changes');
	open(my $doc, '>', $document) or die "Cannot write $document: $!";
	print {$doc} "Revision history\n\n0.01  the first version\n";
	close($doc) or die "Cannot close $document: $!";

	ok($contract->_program($program), 'an extensionless file that starts with #! is a program');
	ok(!$contract->_program($document), 'an extensionless document is not');
	ok(!$contract->_program(__FILE__), 'and a file with an extension is not one of these');
};

subtest 'workspace_present answers before a check has needed the cache' => sub {
	my $dir = tempdir(CLEANUP => 1);
	make_path(File::Spec->catdir($dir, 'Widget-User'));

	my $present = Test::Consumer::Contract->new(
		source            => 'Widget::Maker',
		guaranteed        => [],
		methods           => [],
		workspace         => $dir,
		require_workspace => ['Widget-User'],
	);
	ok($present->workspace_present(), 'a checkout that is there');

	my $missing = Test::Consumer::Contract->new(
		source            => 'Widget::Maker',
		guaranteed        => [],
		methods           => [],
		workspace         => $dir,
		require_workspace => ['No-Such-Distribution'],
	);
	ok(!$missing->workspace_present(), 'and one that is not');
};

# ---------------------------------------------------------------------------
# A value object with a different shape: accessors instead of hash keys, handed
# back a list at a time, produced by a call that names its class, and read inside
# the distribution that makes it.  Each of these is a rule of the scanner, and
# t/contract.t proves each one is load-bearing by putting it back the way it was
# before it was written; these are the same rules read directly.
# ---------------------------------------------------------------------------

my $ledger = Test::Consumer::Contract->new(
	source        => 'Ledger::Entry',
	producers     => {},
	guaranteed    => [],
	methods       => ['Ledger::Entry->new', 'entry'],
	list_methods  => ['results'],
);

subtest 'an accessor read is the name, with its parentheses or without them' => sub {
	my @reads = $ledger->reads_of_results(<<'SOURCE');
my $entry = Ledger::Entry->new(amount => 7);
return $entry->memo . ' ' . $entry->amount();
SOURCE

	my @found = map { $_->[0] . '/' . $_->[2] } @reads;
	is_deeply(\@found, ['memo/accessor', 'amount/accessor'],
		'both spellings are the same read') or diag(explain(\@reads));
};

subtest 'a list of results is followed wherever a reader takes one out' => sub {
	my @reads = $ledger->reads_of_results(<<'SOURCE');
my $report = $store->report;
for my $entry (@{ $report->results }) {
	$entry->{'memo'};
}
my @entries = @{ $report->results };
for my $entry (@entries) {
	$entry->{'amount'};
}
my @memos = map { $_->{'cents'} } @{ $report->results };
SOURCE

	my @found = map { $_->[0] } @reads;
	is_deeply(\@found, ['memo', 'amount', 'cents'],
		'the loop variable of each shape holds a result')
		or diag(explain(\@reads));
	is($reads[2][3], '(file scope)', 'the map is at file scope, as it is written')
		or diag(explain(\@reads));
};

subtest 'the arrayref itself is not a result, and neither is the report' => sub {
	my @reads = $ledger->reads_of_results(<<'SOURCE');
my $report = $store->report;
my $all = $report->results;
return $report->{'name'} . scalar(@{$all});
SOURCE

	is(scalar(@reads), 0, 'nothing the report holds is read as a field of a result')
		or diag(explain(\@reads));
};

subtest 'a helper is handed the result after the invocant, or first' => sub {
	my @reads = $ledger->reads_of_results(<<'SOURCE');
my $entry = $store->entry(1);
$self->_line($entry);
label($entry);

sub _line
{
	my ($self, $record) = @_;

	return $record->{'memo'} . $self->{'indent'};
}

sub label
{
	my ($record) = @_;

	return $record->{'amount'};
}
SOURCE

	my @found = map { $_->[0] . ' in ' . $_->[3] } @reads;
	is_deeply(\@found, ['memo in _line', 'amount in label'],
		'the helper takes what it is passed, and $self is not the result')
		or diag(explain(\@reads));
};

subtest 'a producing call names its class, or leaves it out' => sub {
	my @reads = $ledger->reads_of_results(<<'SOURCE');
my $entry  = Ledger::Entry->new(amount => 7);
my $other  = Ledger::Entry::new(amount => 8);
my $widget = Widget->new(amount => 9);
return $entry->{'memo'} . $other->{'memo'} . $widget->{'memo'};
SOURCE

	my @found = map { $_->[0] . ' at line ' . $_->[1] } @reads;
	is_deeply(\@found, ['memo at line 4', 'memo at line 4'],
		'both spellings of the class\'s own constructor bind, and the other class\'s does not')
		or diag(explain(\@reads));
};

subtest 'a name without a class binds that call whatever the class' => sub {
	my @reads = $ledger->reads_of_results(<<'SOURCE');
my $entry = $store->entry(1);
return $entry->{'memo'};
SOURCE

	is_deeply([map { $_->[0] } @reads], ['memo'], 'entry() binds, wherever it is called')
		or diag(explain(\@reads));
};

subtest 'documented_accessors names the =head2 headings and the public subs' => sub {
	my @names = $ledger->documented_accessors(<<'POD');
=head2 amount

=head3 PURPOSE

The amount the entry records.

=cut

sub amount { $_[0]->{'amount'} }

sub memo { $_[0]->{'memo'} }
POD

	is_deeply(\@names, [qw(amount memo)],
		'the section beneath an accessor is not another accessor')
		or diag(explain(\@names));
};

# A file written into a fixture workspace, with its directories made first.
sub _write_file
{
	my ($path, $content) = @_;

	make_path(dirname($path));
	open(my $fh, '>', $path) or die "Cannot write $path: $!";
	print {$fh} $content;
	close($fh) or die "Cannot close $path: $!";

	return $path;
}

subtest 'own_consumers adds the distribution itself to the search' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $store = File::Spec->catdir($dir, 'Ledger-Store');

	_write_file(File::Spec->catfile($store, 'lib', 'Ledger', 'Entry.pm'), "package Ledger::Entry;\n\n1;\n");
	_write_file(File::Spec->catfile($store, 'bin', 'ledger'), "#!/usr/bin/env perl\n");
	_write_file(File::Spec->catfile($store, 'scripts', 'ledger-report'), "#!/usr/bin/env perl\n");
	_write_file(File::Spec->catfile($store, 't', 'own.t'), "my \$entry = Ledger::Entry->new();\n");
	_write_file(File::Spec->catfile($dir, 'Ledger-UI', 'lib', 'Ledger', 'UI.pm'), "package Ledger::UI;\n\n1;\n");

	my %declaration = (
		source     => 'Ledger::Entry',
		guaranteed => [],
		methods    => ['Ledger::Entry->new'],
		dist_root  => $store,
		workspace  => $dir,
	);

	my $own = Test::Consumer::Contract->new(%declaration, own_consumers => 1);
	my %found = map { $_ => 1 } @{$own->_workspace_sources()};

	ok($found{'lib/Ledger/Entry.pm'},
		"the distribution's own lib is searched, named relative to it") or diag(explain(\%found));
	ok($found{'bin/ledger'}, 'and its bin');
	ok($found{'scripts/ledger-report'}, 'and its scripts');
	ok($found{'Ledger-UI/lib/Ledger/UI.pm'},
		'and the sibling distributions, named relative to the workspace');
	ok(!$found{'t/own.t'},
		'but not its own tests, which are the proof of the value object rather than readers of it');

	# The names are resolved the same way when a registered consumer is read.
	is($own->consumer_path('lib/Ledger/Entry.pm'),
		File::Spec->catfile($store, 'lib', 'Ledger', 'Entry.pm'),
		'a consumer in the distribution is looked for in the distribution');
	is($own->consumer_path('Ledger-UI/lib/Ledger/UI.pm'),
		File::Spec->catfile($dir, 'Ledger-UI', 'lib', 'Ledger', 'UI.pm'),
		'and one in a sibling, in the workspace');

	my $siblings = Test::Consumer::Contract->new(%declaration, own_consumers => 0);
	my %elsewhere = map { $_ => 1 } @{$siblings->_workspace_sources()};

	ok(!$elsewhere{'lib/Ledger/Entry.pm'},
		'without the option the declaring distribution is the producer, and is not searched');
	ok($elsewhere{'Ledger-UI/lib/Ledger/UI.pm'}, 'while the siblings still are');
};

subtest 'a rule whose seam is a sub the module defines' => sub {
	my $declared = Test::Consumer::Contract->scanner_capabilities();

	# One shape, whatever context it is called in: a list of names where a hash
	# of names to seams was asked for would leave every seam undef, and the guard
	# that reads this list would pass without checking anything.
	is(ref($declared), 'HASH', 'the inventory is a hash of rule name to seam, in any context');
	ok(scalar(keys %{$declared}), 'the module declares the rules the scanner applies');
	for my $capability (sort keys %{$declared}) {
		ok(Test::Consumer::Contract->can($declared->{$capability}),
			"$capability is exercised through $declared->{$capability}()");
	}
};

subtest 'a bare statement is not mistaken for a bound result' => sub {
	my @reads = $contract->reads_of_results(<<'SOURCE');
$maker->geocode(location => 'London');
my $colour = 'red';
print $colour->{'not_a_read'};
SOURCE

	is(scalar(@reads), 0, 'nothing is read off a result') or diag(explain(\@reads));
};

# ---------------------------------------------------------------------------
# Fixes made in the critique: each subtest is a case the scanner used to get
# wrong.
# ---------------------------------------------------------------------------

subtest 'POD that is never closed is still POD' => sub {
	# After __END__ a module's POD often has no =cut, and the old pattern only
	# removed POD it saw closed: every example in it was read as code.
	my $text = $contract->strip(<<'SOURCE');
my $widget = $maker->geocode(location => 'London');
return $widget->{'x'};

=head1 SYNOPSIS

    $widget->{'pod'};
SOURCE

	my @reads = $contract->reads_of_results($text);
	is_deeply([map { $_->[0] } @reads], ['x'], 'the example in the open POD is not a read')
		or diag(explain(\@reads));
	is(($text =~ tr/\n//), 6, 'and the lines are kept');
};

subtest 'nothing after __END__ or __DATA__ is code' => sub {
	my $text = $contract->strip(<<'SOURCE');
my $widget = $maker->geocode(location => 'London');
return $widget->{'x'};
__DATA__
$widget->{'data'}
SOURCE

	my @reads = $contract->reads_of_results($text);
	is_deeply([map { $_->[0] } @reads], ['x'], 'the data section is not read') or diag(explain(\@reads));
};

subtest 'a comparison is not a producer setting a key' => sub {
	ok(!$contract->sets_key(q{$widget->{'colour'} =~ /red/}, 'colour'), 'a match against the key is not setting it');
	ok(!$contract->sets_key(q{$widget->{'colour'} == 1}, 'colour'), 'nor is a numeric comparison');
	ok($contract->sets_key(q{$widget->{'colour'} ||= 'red'}, 'colour'), 'an or-assignment is');
	ok(!$contract->sets_key(q{'colour" => 1}, 'colour'), 'mismatched quotes are not a key');
	ok($contract->sets_key(q{"colour" => 1}, 'colour'), 'double quotes are');
};

subtest 'a comparison with a producing call does not bind the variable compared' => sub {
	my @reads = $contract->reads_of_results(<<'SOURCE');
my $same = ($widget == $maker->geocode(location => 'London'));
return $widget->{'colour'};
SOURCE

	is(scalar(@reads), 0, '$widget was compared, not assigned') or diag(explain(\@reads));
};

subtest 'a one-line sub ends on its own line' => sub {
	# 'sub x { ... }' used to run on to the next sub's closing brace, so the
	# read in render() was reported under the one-liner's name.
	my @reads = $contract->reads_of_results(<<'SOURCE');
sub new { bless {}, shift }
sub declared;

sub render
{
	my $widget = $maker->geocode(location => 'London');

	return $widget->{'colour'};
}
SOURCE

	is_deeply([map { $_->[0] . ' in ' . $_->[3] } @reads], ['colour in render'],
		'the read is in the sub that holds it') or diag(explain(\@reads));
};

subtest 'a brace inside a string does not end a map block' => sub {
	my @reads = $ledger->reads_of_results(<<'SOURCE');
my @lines = map { '}' . $_->{'memo'} } @{ $report->results };
SOURCE

	is_deeply([map { $_->[0] } @reads], ['memo'], 'the topic of the map is still a result')
		or diag(explain(\@reads));
};

subtest 'the public lists are arrayrefs in scalar context' => sub {
	my $reads = $contract->reads_of_results("my \$w = \$m->geocode();\n\$w->{'x'};\n");
	is(ref($reads), 'ARRAY', 'reads_of_results') or diag(explain($reads));
	is($reads->[0][0], 'x', 'holding the read');

	my $names = $contract->documented_accessors("=head2 x\n\n=cut\n\nsub y { 1 }\n");
	is_deeply($names, [qw(x y)], 'documented_accessors');
};

subtest 'the public methods refuse a missing argument' => sub {
	throws_ok { $contract->strip(undef) } qr/strip\(\) needs a 'text'/, 'strip';
	throws_ok { $contract->sets_key('text') } qr/sets_key\(\) needs a 'key'/, 'sets_key';
	throws_ok { $contract->reads_of_results() } qr/reads_of_results\(\)/, 'reads_of_results';
	throws_ok { $contract->consumer_path('') } qr/consumer_path\(\)/, 'consumer_path';
};

done_testing();
