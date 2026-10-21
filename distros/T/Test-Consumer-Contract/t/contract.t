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
use Test::Consumer::Contract;
use Cwd qw(abs_path);
use Errno qw(ENOENT);

my $HELPER_LIB = abs_path("$Bin/../lib");

# The three checks, by the name each reports itself under.
my @CHECKS = (
	'the producers still set the keys the contract claims',
	'registered consumers read only what every producer sets',
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
# The producer can also answer a batch.  geocode_many() hands back one hashref
# holding the results under their values and counts about the batch beside
# them - the shape Geo::Coder::Free::geocode_many() has - so a reader of it is a
# reader of results even though the variable it binds is not itself a result.
my $BATCH_METHOD = <<'PERL';
# The batch spelling of geocode(): one hashref, the results under their values.
sub geocode_many
{
	my ($self, $values) = @_;

	my %batch = (lookups => 0, resolved => 0, unresolved => 0);
	for my $value (@{$values}) {
		my $widget = $self->geocode(location => $value);
		$batch{'lookups'}++;
		if ($widget) {
			$batch{$value} = $widget;
			$batch{'resolved'}++;
		} else {
			$batch{'unresolved'}++;
		}
	}

	return \%batch;
}

1;
PERL

my $PRODUCER_WITH_BATCH = $PRODUCER;
$PRODUCER_WITH_BATCH =~ s/^1;$/$BATCH_METHOD/m;

# A consumer of a batch: it reads the batch's own counts, then takes a result
# out of it and reads the result.
my $BATCH_CONSUMER = <<'PERL';
package Widget::Batch;

use Widget::Maker;

sub show
{
	my ($self, $maker, $name) = @_;

	my $batch = $maker->geocode_many([$name]);
	return 'none' unless $batch->{'lookups'};

	my $widget = (ref($batch) eq 'HASH') ? $batch->{$name} : undef;
	return unless $widget;

	return $widget->{'x'} . ',' . $widget->{'y'};
}

1;
PERL

# The same consumer after it started reading a key only some paths set.
my $BATCH_CONSUMER_READING_COLOUR = $BATCH_CONSUMER;
$BATCH_CONSUMER_READING_COLOUR =~ s/return \$widget->\{'x'\} \. ',' \. \$widget->\{'y'\};/return \$widget->{'x'} . \$widget->{'colour'};/;

# A consumer that never binds a value of its own to a result: the batch's values
# go straight into a hash of its own, and straight back out of a helper, and it
# reads the results through those.  Both are the same value being followed, and
# neither leaves a variable of the shape the scanner used to look for.
my $BATCH_CONSUMER_VIA_HASH_AND_RETURN = <<'PERL';
package Widget::Batch::Store;

use Widget::Maker;

sub show
{
	my ($self, $maker, @names) = @_;

	my $batch  = $maker->geocode_many(\@names);
	my %points = map { $_ => $batch->{$_} } @names;
	my ($first) = sort keys %points;

	return 'none' unless defined($first);

	return $points{$first}->{'x'} . ',' . $points{$first}->{'y'};
}

sub first_point
{
	my ($self, $maker, $name) = @_;

	my $batch = $maker->geocode_many([$name]);

	return $batch->{$name};
}

sub describe
{
	my ($self, $maker, $name) = @_;

	return $self->first_point($maker, $name)->{'y'};
}

1;
PERL

# The same consumer after it started reading a key only some paths set, once
# through the hash and once off the returned result.
my $BATCH_CONSUMER_VIA_HASH_READING_COLOUR = $BATCH_CONSUMER_VIA_HASH_AND_RETURN;
$BATCH_CONSUMER_VIA_HASH_READING_COLOUR =~ s/\{'y'\}/{'colour'}/g;

# An extensionless program, of the kind the scanner used to walk past: a script
# is not a module and does not need a .pm to hold the same reader.
my $PROGRAM = <<'PERL';
#!/usr/bin/env perl

use strict;
use warnings;

use Widget::Maker;

my $maker  = Widget::Maker->new();
my $widget = $maker->geocode(location => 'London');

print $widget->{'x'}, ',', $widget->{'y'}, "\n";
PERL

my $PROGRAM_READING_COLOUR = $PROGRAM;
$PROGRAM_READING_COLOUR =~ s/print \$widget->\{'x'\}, ',', \$widget->\{'y'\}, "\\n";/print \$widget->{'x'}, ',', \$widget->{'colour'}, "\\n";/;

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

# The two capabilities this version added, taken away again the way the checker
# had them before.  A mutation is run in the fixture subprocess after the
# checker is loaded, so a scenario that only fails because of the capability is
# shown to pass without it - the test's failure is not a coincidence of the
# fixture.  These are mutations of the checker, not of the code under test.
my $NO_SHEBANG_DISCOVERY = <<'PERL';
# Before 0.02 a file with no extension was never a candidate.
*Test::Consumer::Contract::_program = sub { return 0 };
PERL

# Two mutations of batch support, one for each half of it.  The batch is not
# itself a result, so with the exemption removed its own counts are read as
# fields of one.
my $BATCH_IS_A_RESULT = <<'PERL';
*Test::Consumer::Contract::_batch_methods_re = sub { qr/nothing_matches_this/ };
PERL

# Before 0.02 geocode_many() was neither a producing method nor a batch, so a
# variable bound from it was not a result, and neither was a value taken out of
# it.  With the name out of both lists nothing binds it - an empty list finds
# nothing rather than matching everything - which is the state before 0.02.
my $NO_BATCH_METHOD = <<'PERL';
my $new = \&Test::Consumer::Contract::new;
*Test::Consumer::Contract::new = sub {
	my ($class, %spec) = @_;

	$spec{'methods'}       = [ grep { $_ ne 'geocode_many' } @{$spec{'methods'}} ];
	$spec{'batch_methods'} = [];

	return $new->($class, %spec);
};
PERL

# The third half of batch support, taken away on its own: with no sinks, a value
# out of a batch is followed only into a variable of its own, so a hash it was
# put into and a sub that handed one back are both invisible again.
my $NO_BATCH_VALUE_SINKS = <<'PERL';
*Test::Consumer::Contract::_batch_value_sinks = sub { return { holds => {}, hands_back => {} } };
PERL

# ---------------------------------------------------------------------------
# A third value object: a ledger entry.  It is read three ways that a geocoder
# result is not: through accessors rather than hash keys, a list at a time out
# of a report rather than one at a time out of a producing call, and by a reader
# that ships in the distribution that makes it.  The value object is produced by
# the distribution that declares the contract, which is the case the
# 'own_consumers' option is for - the readers are here, not in a sibling.
# ---------------------------------------------------------------------------

my $ENTRY = <<'PERL';
package Ledger::Entry;

=head2 amount

The amount the entry records.

=cut

sub new
{
	my ($class, %args) = @_;

	return bless {
		amount => $args{'amount'},
		memo   => $args{'memo'},
		note   => $args{'note'},
	}, $class;
}

sub amount { $_[0]->{'amount'} }

=head2 memo

=head3 PURPOSE

The memo written against the entry.

=cut

sub memo { $_[0]->{'memo'} }

=head2 cents

The same amount in cents, derived rather than stored.

=cut

sub cents { return $_[0]->{'amount'} * 100 }

1;
PERL

# A report hands back a list of results rather than one result.
my $LEDGER_REPORT = <<'PERL';
package Ledger::Report;

sub new
{
	my ($class, %args) = @_;

	return bless { entries => $args{'entries'} || [] }, $class;
}

sub results { return $_[0]->{'entries'} }

1;
PERL

my $LEDGER_STORE = <<'PERL';
package Ledger::Store;

use Ledger::Entry;
use Ledger::Report;

sub new { return bless {}, $_[0] }

sub entry
{
	my ($self, $id) = @_;

	return Ledger::Entry->new(amount => $id * 10, memo => "entry $id");
}

sub report
{
	my ($self) = @_;

	return Ledger::Report->new(entries => [ $self->entry(1), $self->entry(2) ]);
}

1;
PERL

# The reader in a sibling distribution: it takes the entries one at a time out
# of the report's list and reads each through an accessor, inside a helper that
# is handed the entry as its second argument - after the invocant - under a name
# of its own, so the helper's reads are found only by following what is passed
# to it.
my $LEDGER_UI = <<'PERL';
package Ledger::UI;

use Ledger::Entry;
use Ledger::Report;
use Ledger::Store;
use Carp qw(croak);

sub render
{
	my ($self, $store) = @_;

	my $report = $store->report;

	my @lines;
	for my $entry (@{ $report->results }) {
		push @lines, $self->_line($entry);
	}

	return join("\n", @lines);
}

sub _line
{
	my ($self, $record) = @_;

	croak 'not an entry' unless $record->isa('Ledger::Entry');

	return (' ' x $self->{'indent'}) . $record->memo . ': ' . $record->amount;
}

# An object of another class is not a result, however it was made: nothing here
# reads one.
sub _blank
{
	my ($self, $store) = @_;

	my $report = Ledger::Report->new(entries => []);

	return scalar @{ $report->{'entries'} };
}

1;
PERL

# The same reader after it started reading an accessor only some entries carry.
my $LEDGER_UI_READING_NOTE = $LEDGER_UI;
$LEDGER_UI_READING_NOTE =~ s/\$record->memo \. ': ' \. \$record->amount/\$record->note/;

# A reader in the distribution that produces the value object: a badge summarises
# an entry without leaving the distribution.  This is the file 'own_consumers'
# exists to find, and it is named the way a producer is - relative to the
# distribution.
my $LEDGER_BADGE = <<'PERL';
package Ledger::Badge;

use Ledger::Entry;
use Carp qw(croak);

sub total
{
	my ($self, $store) = @_;

	my $entry = $store->entry(1);
	croak 'not an entry' unless $entry->isa('Ledger::Entry');

	return $entry->cents;
}

1;
PERL

my %LEDGER_FILES = (
	'Ledger-Store/lib/Ledger/Entry.pm'  => $ENTRY,
	'Ledger-Store/lib/Ledger/Report.pm' => $LEDGER_REPORT,
	'Ledger-Store/lib/Ledger/Store.pm'  => $LEDGER_STORE,
	'Ledger-UI/lib/Ledger/UI.pm'        => $LEDGER_UI,
);

my %LEDGER_DECLARATION = (
	source            => 'Ledger::Entry',
	include           => ['Ledger-Store/lib'],
	# The constructor is named with its class: 'new' on its own is every
	# constructor in every file the checks read, and Ledger::Report->new() would
	# be bound as a result and its keys held to this value object's.
	methods           => ['Ledger::Entry->new', 'entry'],
	# A report hands back a list of results rather than one.
	list_methods      => ['results'],
	value_object      => {
		class   => 'Ledger::Entry',
		from    => { amount => 7 },
		derives => { cents => 700 },
	},
	accessors         => [qw(amount memo cents)],
	not_accessors     => { new => 'the constructor, not a slot of one result' },
	inspection        => [qw(can isa DOES)],
	guaranteed        => [qw(amount memo cents)],
	conditional       => { note => 'only an entry that carries a note sets it' },
	# The producer is in the declaring distribution, so its evidence is
	# dist-relative; the store that stamps the fields of a new entry is named
	# workspace-relative.
	producers         => { 'lib/Ledger/Entry.pm' => [qw(amount memo)] },
	workspace_producers => { 'Ledger-Store/lib/Ledger/Store.pm' => [qw(amount memo)] },
	consumers         => { 'Ledger-UI/lib/Ledger/UI.pm' => { may_rely_on => {} } },
	ignored           => [],
	own_consumers     => 1,
	require_workspace => ['Ledger-UI'],
);

# The three capabilities this version added for a value object of that shape,
# taken away again the way the checker had them before, so that a scenario which
# only fails because of one of them is shown to pass without it.
my $NO_LIST_METHODS = <<'PERL';
# Before 0.04 a list of results was not a shape the scanner knew: nothing binds
# from a report's results(), so the variable a reader loops over is not a result.
*Test::Consumer::Contract::_list_methods_re = sub { qr/(?!)/ };
PERL

# And before 0.04 a helper's result was its first parameter whatever it was, so
# a method helper bound the invocant instead of the result it was passed.
my $NO_INVOCANT_RULE = <<'PERL';
my $ranges = \&Test::Consumer::Contract::_sub_ranges;
*Test::Consumer::Contract::_sub_ranges = sub {
	my $found = $ranges->(@_);

	# The result was the first parameter the helper declares, whatever that was:
	# declaring it twice makes it the one a method call passes to as well.
	$_->{'params'} = [ ($_->{'params'}[0]) x 2 ] for @{$found};

	return $found;
};
PERL

# And a reader in the producing distribution was not scanned at all.
my $NO_OWN_CONSUMERS = <<'PERL';
my $new = \&Test::Consumer::Contract::new;
*Test::Consumer::Contract::new = sub {
	my ($class, %spec) = @_;

	$spec{'own_consumers'} = 0;

	return $new->($class, %spec);
};
PERL

# A producer that still shows a key in its synopsis but no longer sets it.  The
# evidence used to be the file as written, so the example was enough.
my $PRODUCER_WITH_COLOUR_IN_POD = $PRODUCER;
$PRODUCER_WITH_COLOUR_IN_POD =~ s/^\t\tcolour   => \$COLOURS\{\$args\{'location'\}\},\n//m;
$PRODUCER_WITH_COLOUR_IN_POD =~ s/^1;$/=head1 SYNOPSIS\n\n    my \$widget = Widget->new(colour => 'red');\n\n=cut\n\n1;/m;

my $EVIDENCE_AS_WRITTEN = <<'PERL';
# Before 0.04 the producer evidence was the file as written, synopsis included.
*Test::Consumer::Contract::strip = sub { return $_[1] };
PERL

# And before 0.04 an accessor read had to be a call: $result->score was not one,
# so a reader that read a result through its accessors read nothing at all.
my $NO_PARENLESS_ACCESSORS = <<'PERL';
*Test::Consumer::Contract::_accessor_read = sub { return qr/\s*->\s*(\w+)\s*\(/ };
PERL

# And every heading from =head2 down named an accessor, so a value object that
# documents an accessor and then describes it in sections was read as documenting
# PURPOSE, INPUT and OUTPUT as well.
my $ACCESSORS_AT_ANY_DEPTH = <<'PERL';
*Test::Consumer::Contract::documented_accessors = sub {
	my (undef, $text) = @_;

	my %found;
	$found{$1} = 1 while $text =~ /^=head[2-9]\s+(?:B<)?(\w+)/gm;
	$found{$1} = 1 while $text =~ /^sub\s+([A-Za-z]\w*)/gm;

	# Shaped like the real one: a list, or an arrayref in scalar context.
	my @names = sort keys %found;
	return wantarray ? @names : \@names;
};
PERL

# And a producing call was matched by its name alone, whatever class was written
# in front of it: 'Ledger::Entry->new' meant 'new', and every constructor in the
# file that bound a variable was a constructor of the value object.
my $UNQUALIFIED_CONSTRUCTORS = <<'PERL';
*Test::Consumer::Contract::_alternation = sub {
	my ($self, $key, $names) = @_;

	return $self->{$key} //= do {
		my @names = map { my $name = $_; $name =~ s/.*(?:->|::)//; $name } @{$names};
		return qr/(?!)/ unless @names;

		qr/(?:@{[ join('|', map { '->\\s*' . quotemeta($_) }
			sort { length($b) <=> length($a) } @names) ]})/;
	};
};
PERL

# And a value taken out of a batch was bound by a key in braces only; a batch
# read any other way handed back nothing that held a result.
my $NO_BATCH_SELECTION = <<'PERL';
*Test::Consumer::Contract::_selection_re = sub { return qr/(?!)/ };
PERL

# ---------------------------------------------------------------------------
# A second value object: a warehouse item, produced by calls that are not
# geocoders, declared with the same three checks.  The checker knows nothing of
# geocode(); these fixtures are what say so.
# ---------------------------------------------------------------------------

my $ITEM = <<'PERL';
package Item;

sub new
{
	my ($class, %args) = @_;

	my $self = bless {}, $class;
	$self->{'grams'} = $args{'grams'};
	$self->{'kilos'} = $args{'grams'} / 1000 if defined($args{'grams'});
	$self->{'name'}  = $args{'name'};
	$self->{'bin'}   = $args{'bin'};

	return $self;
}

sub grams { $_[0]->{'grams'} }
sub kilos { $_[0]->{'kilos'} }
sub name  { $_[0]->{'name'} }

1;
PERL

# The producer: fetch() hands back one item, scan() is the path that knows which
# bin it is in.  Nothing here is geocoded, and nothing reads a field of a result.
my $STOCK = <<'PERL';
package Warehouse::Stock;

use Item;

my %SHELF = (A1 => [250, 'bolt'], A2 => [4000, 'beam']);

sub fetch
{
	my ($self, %args) = @_;

	my $shelf = $SHELF{$args{'sku'}};
	return unless $shelf;

	return Item->new(grams => $shelf->[0], name => $shelf->[1]);
}

sub scan
{
	my ($self, $sku) = @_;

	my $shelf = $SHELF{$sku};
	return unless $shelf;

	return Item->new(grams => $shelf->[0], name => $shelf->[1],
		bin => 'B' . substr($sku, 1));
}

1;
PERL

# The consumer: it takes an item from fetch() and reads two fields every path
# sets.
my $STOCK_CONSUMER = <<'PERL';
package Warehouse::UI;

use Warehouse::Stock;

sub label
{
	my ($self, $stock, $sku) = @_;

	my $item = $stock->fetch(sku => $sku);
	return unless $item;

	return $item->{'name'} . ' (' . $item->{'kilos'} . 'kg)';
}

1;
PERL

my $STOCK_AUDIT = <<'PERL';
package Warehouse::Audit;

use Warehouse::Stock;

sub weight
{
	my ($self, $stock, $sku) = @_;

	my $item = $stock->scan($sku);
	return unless $item;

	return $item->{'grams'};
}

1;
PERL

my %STOCK_FILES = (
	'Warehouse-Stock/lib/Item.pm'            => $ITEM,
	'Warehouse-Stock/lib/Warehouse/Stock.pm' => $STOCK,
	'Warehouse-UI/lib/Warehouse/UI.pm'       => $STOCK_CONSUMER,
);

my %STOCK_DECLARATION = (
	source            => 'Warehouse::Stock',
	include           => ['Warehouse-Stock/lib'],
	# The producing calls, as this producer spells them.  Not one of them is
	# geocode(), and the checker never assumes otherwise.
	methods           => [qw(fetch scan)],
	batch_methods     => [],
	value_object      => {
		class   => 'Item',
		from    => { grams => 1000 },
		derives => { kilos => 1 },
	},
	accessors         => [qw(grams kilos name)],
	not_accessors     => { new => 'the constructor, not a slot of one result' },
	inspection        => [qw(can isa DOES)],
	guaranteed        => [qw(grams kilos name)],
	conditional       => { bin => 'only scan() knows which bin the item is in' },
	producers         => {},
	workspace_producers => { 'Warehouse-Stock/lib/Warehouse/Stock.pm' => [qw(grams name bin)] },
	consumers         => { 'Warehouse-UI/lib/Warehouse/UI.pm' => { may_rely_on => {} } },
	ignored           => [],
	require_workspace => [qw(Warehouse-Stock Warehouse-UI)],
);

my %BASE_DECLARATION = (
	source              => 'Widget::Maker',
	include             => ['Widget-Maker/lib'],
	# Required, and named here rather than defaulted inside the checker: it is
	# not a geocoder checker, and a name it guessed would quietly find nothing.
	methods             => [qw(geocode geocode_many)],
	batch_methods       => ['geocode_many'],
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

sub _read_back
{
	my $path = shift;

	open(my $fh, '<', $path) or return '';
	local $/;
	my $text = <$fh>;
	close($fh);

	return $text;
}

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

# The distribution that holds the declaration, and so the root the checks are
# made against.  A scenario for a second value object names its own.
my $DECLARING = 'Widget-Contract';

# A workspace with the dists above in it, and whatever the scenario changes.
# The second argument replaces the whole set of files, so a workspace can be
# built for a value object that shares nothing with the widgets.
sub _fixture
{
	my ($files, $base, $declaring) = @_;

	$declaring //= $DECLARING;

	my $dir = tempdir(CLEANUP => 1);

	my %default = %{$base // {
		'Widget-Maker/lib/Widget.pm'          => $VALUE_OBJECT,
		'Widget-Maker/lib/Widget/Maker.pm'    => $PRODUCER,
		'Widget-User/lib/Widget/User.pm'      => $CONSUMER,
		'Widget-Contract/lib/Widget/Writer.pm' => $WRITER,
	}};
	# A scenario may pass undef for a file to take it out of the fixture.
	$default{$_} = $files->{$_} for keys %{$files};

	for my $rel (sort keys %default) {
		next unless defined($default{$rel});
		_write($dir, $rel, $default{$rel});
	}

	# The declaring distribution needs a lib/ for its own root to be recognised.
	make_path(File::Spec->catdir($dir, $declaring, 'lib'));

	return $dir;
}

# The rules this file has proved, filled in as the mutations run.  It is declared
# here because _check() writes it, and read by the guard at the end of the file.
my %PROVED;

# The declaration, written out as the test a second distribution would have.
# windows_separators is not part of the declaration: it puts the shim above on
# the fixture's include path and loads it before the module under test.
sub _check
{
	my ($dir, %declaration) = @_;

	my $windows_separators = delete $declaration{'windows_separators'};
	# A mutation of the checker itself; unlike the declaration, it is not part of
	# what is dumped for the fixture to run.  It arrives with the rule it proves,
	# so that a mutation cannot be run without the guard being told about it: a
	# scenario that reaches for _check() directly to patch the checker dies here
	# rather than passing unproved.
	my $mutation = delete $declaration{'mutation'};
	my $proving  = delete $declaration{'proving'};
	if(defined($mutation) && !defined($proving)) {
		die "a mutation subtest has to name the rule it proves: use _prove()\n";
	}
	$PROVED{$proving} = 1 if defined($proving);
	# The declaration a scenario starts from, and the distribution that holds it.
	my $base      = delete $declaration{'base'}      // \%BASE_DECLARATION;
	my $declaring = delete $declaration{'declaring'} // $DECLARING;

	my %spec = (%{$base}, %declaration);

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

	# A mutant that wraps one of the checker's private subs calls it from
	# package main, which Sub::Private refuses outside a test harness.  The
	# bypass is the white-box exemption, and it is only granted to mutants.
	my $mutant = defined($mutation)
		? "no warnings 'redefine';\n\$Sub::Private::BYPASS = 1;\n\$Sub::Protected::BYPASS = 1;\n$mutation\n"
		: '';

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

$mutant
my \$spec = $dumped;

run_consumer_contract(%{\$spec});

done_testing();
SCRIPT

	my $path = _write($dir, "$declaring/t/contract.t", $script);

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

# One scenario, with one of the scanner's rules put back the way it was before
# the rule was written, and a note that this rule's mutation has been run.  Every
# mutation subtest goes through here, so the guard at the end of the file can see
# which rules have been proved: the rule has to be one the module declares, or the
# subtest that names it is a mistake rather than a proof.
#
# %PROVED is what the guard reads.  A rule the module declares and this file
# never proves fails there, and so does a capability named here that the module
# does not declare.
sub _prove
{
	my ($capability, $dir, %declaration) = @_;

	my $declared = Test::Consumer::Contract->scanner_capabilities();

	# A mutation for a rule the module does not declare proves nothing, and the
	# rule it was meant to prove is left unproved.  The mistake is recorded and
	# named here as well as in the guard at the end, so that a scenario added
	# under a misspelt rule fails where it was written.
	ok(exists($declared->{$capability}), "'$capability' is a rule the module declares")
		or diag("\tThe module declares " . join(', ', sort keys %{$declared}) . "\n");

	return _check($dir, %declaration, proving => $capability);
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

# Before 0.04 a workspace producer was read whether or not its sibling was
# there, so a declaration that named one failed check 1 on every install
# outside a workspace while checks 2 and 3 skipped.
subtest 'a workspace producer whose sibling is not there is skipped, not failed' => sub {
	my ($status, $output) = _check(_fixture({}),
		require_workspace   => ['No-Such-Distribution'],
		workspace_producers => {
			'Widget-Maker/lib/Widget/Maker.pm' => [qw(x y colour)],
			'No-Such-Distribution/lib/Gone.pm' => [qw(x)],
		});

	is($status, 0, 'the contract passed') or diag($output);
	is(scalar(_passed($output)), 1, 'the producer check ran and passed') or diag($output);
	like($output, qr/^\s*ok \d+ # skip No-Such-Distribution\/lib\/Gone\.pm is not checked: No-Such-Distribution is not in the workspace$/m,
		'the absent producer is skipped, naming the file and the sibling') or diag($output);
	like($output, qr/^\s*ok \d+ - Widget-Maker\/lib\/Widget\/Maker\.pm sets 'colour'$/m,
		'and a producer whose sibling is there is still checked') or diag($output);
	unlike($output, qr/cannot read/, 'nothing was reported unreadable') or diag($output);
};

subtest 'a workspace producer missing from a sibling that is there still fails' => sub {
	my ($status, $output) = _check(_fixture({}),
		workspace_producers => { 'Widget-Maker/lib/Widget/Gone.pm' => [qw(x)] });

	isnt($status, 0, 'the contract failed') or diag($output);
	like($output, qr/cannot read Widget-Maker\/lib\/Widget\/Gone\.pm/,
		'the file that moved is named') or diag($output);
	_no_other_failures($output, $CHECKS[0]);
};

# ---------------------------------------------------------------------------
# The two readers the scanner used to walk past: a program with no extension,
# and a result taken out of a batch.
# ---------------------------------------------------------------------------

subtest 'an unregistered program in bin/ is discovered' => sub {
	# Nothing in this fixture registers the program, and nothing in it reads a
	# result except the program: without discovery by shebang the check would
	# find no consumer to complain about and pass.
	my ($status, $output) = _check(_fixture({
		'Widget-User/bin/widget-map' => $PROGRAM,
	}));

	isnt($status, 0, 'the contract failed');
	like($output, qr/unregistered consumers of Widget::Maker results:/,
		'the check says what it found') or diag($output);
	like($output, qr/Widget-User\/bin\/widget-map/, 'and names the program') or diag($output);
	_no_other_failures($output, $CHECKS[2]);
};

subtest 'a bad read in an extensionless program is caught' => sub {
	# A program at the distribution root, which is neither a module nor under
	# bin/: ged2map is one, and its geocoding loop is a copy of a module's.
	my ($status, $output) = _check(_fixture({
		'Widget-User/map-events' => $PROGRAM_READING_COLOUR,
	}), consumers => {
		'Widget-User/lib/Widget/User.pm' => { may_rely_on => {} },
		'Widget-User/map-events'      => { may_rely_on => {} },
	});

	isnt($status, 0, 'the contract failed');
	like($output, qr/Widget-User\/map-events line \d+ in .*reads 'colour' \(key\) - only the painted path sets it/,
		'the check names the program, line, sub, key and why') or diag($output);
	_no_other_failures($output, $CHECKS[1]);
};

subtest 'an unregistered geocode_many consumer is discovered' => sub {
	# The batch consumer's only reads are off a result taken out of the batch, so
	# a scanner that does not follow geocode_many() sees no consumer at all.
	my ($status, $output) = _check(_fixture({
		'Widget-Maker/lib/Widget/Maker.pm' => $PRODUCER_WITH_BATCH,
		'Widget-User/lib/Widget/Batch.pm'  => $BATCH_CONSUMER,
	}));

	isnt($status, 0, 'the contract failed');
	like($output, qr/unregistered consumers of Widget::Maker results:/,
		'the check says what it found') or diag($output);
	like($output, qr/Widget-User\/lib\/Widget\/Batch\.pm/, 'and names the file') or diag($output);
	_no_other_failures($output, $CHECKS[2]);
};

subtest 'a result taken out of a geocode_many batch is a result' => sub {
	my ($status, $output) = _check(_fixture({
		'Widget-Maker/lib/Widget/Maker.pm' => $PRODUCER_WITH_BATCH,
		'Widget-User/lib/Widget/Batch.pm'  => $BATCH_CONSUMER,
	}), consumers => {
		'Widget-User/lib/Widget/User.pm'  => { may_rely_on => {} },
		'Widget-User/lib/Widget/Batch.pm' => { may_rely_on => {} },
	});

	is($status, 0, 'the batch consumer passed') or diag($output);
	is(scalar(_passed($output)), 3, 'all three checks ran and passed') or diag($output);
};

subtest 'a bad read of a result from a batch is caught' => sub {
	my ($status, $output) = _check(_fixture({
		'Widget-Maker/lib/Widget/Maker.pm' => $PRODUCER_WITH_BATCH,
		'Widget-User/lib/Widget/Batch.pm'  => $BATCH_CONSUMER_READING_COLOUR,
	}), consumers => {
		'Widget-User/lib/Widget/User.pm'  => { may_rely_on => {} },
		'Widget-User/lib/Widget/Batch.pm' => { may_rely_on => {} },
	});

	isnt($status, 0, 'the contract failed');
	like($output, qr/Widget-User\/lib\/Widget\/Batch\.pm line \d+ in show\(\) reads 'colour' \(key\) - only the painted path sets it/,
		'the check names the file, line, sub, key and why') or diag($output);
	_no_other_failures($output, $CHECKS[1]);
};

subtest 'a result put into a hash or handed back out of a sub is followed' => sub {
	# Nothing here is bound from the batch into a variable of its own: the value
	# goes into %points and then into an element read, and back out of
	# first_point() and then into a read straight off the call.  A scanner that
	# does not follow either sees a file that reads no result at all.
	my ($status, $output) = _check(_fixture({
		'Widget-Maker/lib/Widget/Maker.pm' => $PRODUCER_WITH_BATCH,
		'Widget-User/lib/Widget/Store.pm'  => $BATCH_CONSUMER_VIA_HASH_AND_RETURN,
	}), consumers => {
		'Widget-User/lib/Widget/User.pm'  => { may_rely_on => {} },
		'Widget-User/lib/Widget/Store.pm' => { may_rely_on => {} },
	});

	is($status, 0, 'the consumer of a hash and of a returned result passed') or diag($output);
	is(scalar(_passed($output)), 3, 'all three checks ran and passed') or diag($output);
};

subtest 'a bad read through a hash or off a returned result is caught' => sub {
	my ($status, $output) = _check(_fixture({
		'Widget-Maker/lib/Widget/Maker.pm' => $PRODUCER_WITH_BATCH,
		'Widget-User/lib/Widget/Store.pm'  => $BATCH_CONSUMER_VIA_HASH_READING_COLOUR,
	}), consumers => {
		'Widget-User/lib/Widget/User.pm'  => { may_rely_on => {} },
		'Widget-User/lib/Widget/Store.pm' => { may_rely_on => {} },
	});

	isnt($status, 0, 'the contract failed');
	like($output, qr/Widget-User\/lib\/Widget\/Store\.pm line \d+ in show\(\) reads 'colour' \(key\) - only the painted path sets it/,
		'the read through the hash is named') or diag($output);
	like($output, qr/Widget-User\/lib\/Widget\/Store\.pm line \d+ in describe\(\) reads 'colour' \(key\) - only the painted path sets it/,
		'and so is the read off the returned result') or diag($output);
	_no_other_failures($output, $CHECKS[1]);
};

# ---------------------------------------------------------------------------
# A second value object, with no geocoding anywhere in it: the same three
# checks, over a declaration whose producing calls are fetch() and scan().  The
# checker is not told what a geocoder looks like, so there is nothing to undo
# here - the fixtures are the whole of the difference.
# ---------------------------------------------------------------------------

subtest 'a contract for a value object that is not a geocoder passes' => sub {
	my ($status, $output) = _check(
		_fixture({}, \%STOCK_FILES, 'Warehouse-Contract'),
		base => \%STOCK_DECLARATION, declaring => 'Warehouse-Contract');

	is($status, 0, 'the contract passed') or diag($output);
	is(scalar(_passed($output)), 3, 'all three checks ran and passed') or diag($output);
	unlike($output, qr/geocode/, 'nothing in the run was a geocoder') or diag($output);
};

subtest 'a store that stops setting a promised field is caught' => sub {
	my $without_bin = $STOCK;
	$without_bin =~ s/,\n\t\tbin => 'B' \. substr\(\$sku, 1\)//;

	my ($status, $output) = _check(
		_fixture({ 'Warehouse-Stock/lib/Warehouse/Stock.pm' => $without_bin },
			\%STOCK_FILES, 'Warehouse-Contract'),
		base => \%STOCK_DECLARATION, declaring => 'Warehouse-Contract');

	isnt($status, 0, 'the contract failed') or diag($output);
	like($output, qr/Warehouse-Stock\/lib\/Warehouse\/Stock\.pm sets 'bin'/,
		'the field it stopped setting is named') or diag($output);
	_no_other_failures($output, $CHECKS[0]);
};

subtest 'a consumer of a field only one path sets is caught' => sub {
	my $reading_bin = $STOCK_CONSUMER;
	$reading_bin =~ s/\$item->\{'name'\} \. ' \(\' \. \$item->\{'kilos'\} \. 'kg\)'/\$item->{'bin'}/;

	my ($status, $output) = _check(
		_fixture({ 'Warehouse-UI/lib/Warehouse/UI.pm' => $reading_bin },
			\%STOCK_FILES, 'Warehouse-Contract'),
		base => \%STOCK_DECLARATION, declaring => 'Warehouse-Contract');

	isnt($status, 0, 'the contract failed') or diag($output);
	like($output, qr/Warehouse-UI\/lib\/Warehouse\/UI\.pm line \d+ in label\(\) reads 'bin' \(key\) - only scan\(\) knows which bin the item is in/,
		'the read is named with the reason it is unsafe') or diag($output);
	_no_other_failures($output, $CHECKS[1]);
};

subtest 'an unregistered consumer of the store is caught' => sub {
	my ($status, $output) = _check(
		_fixture({ 'Warehouse-UI/lib/Warehouse/Audit.pm' => $STOCK_AUDIT },
			\%STOCK_FILES, 'Warehouse-Contract'),
		base => \%STOCK_DECLARATION, declaring => 'Warehouse-Contract');

	isnt($status, 0, 'the contract failed') or diag($output);
	like($output, qr/unregistered consumers of Warehouse::Stock results:/,
		'the check says what it found') or diag($output);
	like($output, qr/Warehouse-UI\/lib\/Warehouse\/Audit\.pm/, 'and names the file') or diag($output);
	_no_other_failures($output, $CHECKS[2]);
};

# ---------------------------------------------------------------------------
# The mutations that prove the two new failures above are caused by the two new
# capabilities, rather than by the fixtures happening to be broken.
# ---------------------------------------------------------------------------

subtest 'mutation: without shebang discovery an unregistered program is invisible' => sub {
	# Discovery is the whole of what finds an unregistered consumer: with the
	# pre-0.02 extension filter back, the program is a file the workspace walk
	# never asks about, and the register-it failure goes quiet.
	my ($status, $output) = _prove('shebang_programs', _fixture({
		'Widget-User/bin/widget-map' => $PROGRAM,
	}), mutation => $NO_SHEBANG_DISCOVERY);

	is($status, 0, 'an unregistered program is no longer seen') or diag($output);
	is(scalar(_passed($output)), 3, 'all three checks pass') or diag($output);
	unlike($output, qr/widget-map|unregistered consumers/,
		'the program is never named') or diag($output);
};

subtest 'mutation: without batch support neither geocode_many failure is found' => sub {
	my ($stray_status, $stray_output) = _prove('batch_methods', _fixture({
		'Widget-Maker/lib/Widget/Maker.pm' => $PRODUCER_WITH_BATCH,
		'Widget-User/lib/Widget/Batch.pm'  => $BATCH_CONSUMER,
	}), mutation => $NO_BATCH_METHOD);

	is($stray_status, 0, 'an unregistered batch consumer is no longer seen') or diag($stray_output);
	is(scalar(_passed($stray_output)), 3, 'all three checks pass') or diag($stray_output);
	unlike($stray_output, qr/Widget\/Batch\.pm|unregistered consumers/,
		'the batch consumer is never named') or diag($stray_output);

	my ($bad_status, $bad_output) = _prove('batch_methods', _fixture({
		'Widget-Maker/lib/Widget/Maker.pm' => $PRODUCER_WITH_BATCH,
		'Widget-User/lib/Widget/Batch.pm'  => $BATCH_CONSUMER_READING_COLOUR,
	}), consumers => {
		'Widget-User/lib/Widget/User.pm'  => { may_rely_on => {} },
		'Widget-User/lib/Widget/Batch.pm' => { may_rely_on => {} },
	}, mutation => $NO_BATCH_METHOD);

	is($bad_status, 0, 'a bad read from a batch is no longer seen') or diag($bad_output);
	is(scalar(_passed($bad_output)), 3, 'all three checks pass') or diag($bad_output);
	# The file is still registered, so it is read and passes; what has gone is
	# the read that made it fail.
	unlike($bad_output, qr/reads 'colour'/,
		'the batch consumer\'s read is never found') or diag($bad_output);
};

subtest 'mutation: without following a value into a hash or a return, both reads are missed' => sub {
	# The same bad fixture as above, with only the sink following removed: the
	# variable bound from geocode_many() is still a batch, a value taken out of it
	# into a variable of its own is still a result.  What has gone is the read
	# that made the file fail.
	my ($status, $output) = _prove('batch_value_sinks', _fixture({
		'Widget-Maker/lib/Widget/Maker.pm' => $PRODUCER_WITH_BATCH,
		'Widget-User/lib/Widget/Store.pm'  => $BATCH_CONSUMER_VIA_HASH_READING_COLOUR,
	}), consumers => {
		'Widget-User/lib/Widget/User.pm'  => { may_rely_on => {} },
		'Widget-User/lib/Widget/Store.pm' => { may_rely_on => {} },
	}, mutation => $NO_BATCH_VALUE_SINKS);

	is($status, 0, 'neither bad read is seen') or diag($output);
	is(scalar(_passed($output)), 3, 'all three checks pass') or diag($output);
	unlike($output, qr/reads 'colour'/, 'the reads through the hash and the return are never found')
		or diag($output);
};

# ---------------------------------------------------------------------------
# A third value object, read through accessors, a list at a time, and by the
# distribution that makes it.  None of the three shapes is a geocoder's, and the
# checker is told about each of them in the declaration.
# ---------------------------------------------------------------------------

subtest 'the scanner reaches accessors, a list of results and a method helper' => sub {
	# The declaration is run in a subprocess like every other scenario; this one
	# is read here as well, so that the reads the contract is built on are named
	# rather than inferred from a passing check.
	my $dir = _fixture({}, \%LEDGER_FILES, 'Ledger-Store');

	my $contract = Test::Consumer::Contract->new(%LEDGER_DECLARATION,
		dist_root => File::Spec->catdir($dir, 'Ledger-Store'),
		workspace => $dir,
	);

	my @reads = $contract->reads_of_results($contract->strip(
		_read_back(File::Spec->catfile($dir, 'Ledger-UI', 'lib', 'Ledger', 'UI.pm'))));

	my @found = map { $_->[0] . ' in ' . $_->[3] } @reads;
	is_deeply([sort @found], ['amount in _line', 'isa in _line', 'memo in _line'],
		'both accessor reads are found, in the helper the entry is passed to, and no more')
		or diag(explain(\@reads));
};

subtest 'a value object read through accessors and a list of results passes' => sub {
	my ($status, $output) = _check(
		_fixture({}, \%LEDGER_FILES, 'Ledger-Store'),
		base => \%LEDGER_DECLARATION, declaring => 'Ledger-Store');

	is($status, 0, 'the contract passed') or diag($output);
	is(scalar(_passed($output)), 3, 'all three checks ran and passed') or diag($output);
	unlike($output, qr/geocode/, 'nothing in the run was a geocoder') or diag($output);
};

subtest 'an accessor the value object does not promise is caught' => sub {
	# The read is in the helper the entry is passed to, through an accessor rather
	# than a hash key: the failure names it as an accessor and says why 'note' is
	# conditional.
	my ($status, $output) = _check(
		_fixture({ 'Ledger-UI/lib/Ledger/UI.pm' => $LEDGER_UI_READING_NOTE }, \%LEDGER_FILES, 'Ledger-Store'),
		base => \%LEDGER_DECLARATION, declaring => 'Ledger-Store');

	isnt($status, 0, 'the contract failed') or diag($output);
	like($output, qr/Ledger-UI\/lib\/Ledger\/UI\.pm line \d+ in _line\(\) reads 'note' \(accessor\) - only an entry that carries a note sets it/,
		'the accessor read is named with the reason it is unsafe') or diag($output);
	_no_other_failures($output, $CHECKS[1]);
};

subtest 'mutation: without following a list of results the reader is invisible' => sub {
	my ($status, $output) = _prove('list_methods',
		_fixture({ 'Ledger-UI/lib/Ledger/UI.pm' => $LEDGER_UI_READING_NOTE }, \%LEDGER_FILES, 'Ledger-Store'),
		base => \%LEDGER_DECLARATION, declaring => 'Ledger-Store',
		mutation => $NO_LIST_METHODS);

	# With nothing bound from the report's list, the reader is not a reader of
	# results at all: the check that would have reported the read passes.
	ok(grep { $_ eq $CHECKS[1] } _passed($output),
		'the consumer check passed, because no read of a result was found') or diag($output);
	unlike($output, qr/reads 'note'/, 'the accessor read is never found') or diag($output);
};

subtest 'mutation: a method helper takes the result after the invocant' => sub {
	# With the parameter its result is taken to be the first one, a method helper
	# binds $self: the entry's accessor reads are missed, and the reader's own
	# object is read as if it were the value object.
	my ($status, $output) = _prove('invocant_parameter',
		_fixture({ 'Ledger-UI/lib/Ledger/UI.pm' => $LEDGER_UI_READING_NOTE }, \%LEDGER_FILES, 'Ledger-Store'),
		base => \%LEDGER_DECLARATION, declaring => 'Ledger-Store',
		mutation => $NO_INVOCANT_RULE);

	# $record is bound by nothing else, so the read of it goes with the rule: what
	# is left is the reader's own object being read as if it were the entry.
	unlike($output, qr/reads 'note'/, 'the entry the helper was passed is not followed')
		or diag($output);
	like($output, qr/Ledger-UI\/lib\/Ledger\/UI\.pm line \d+ in _line\(\) reads 'indent' \(key\)/,
		'$self is taken for the result instead, and read off') or diag($output);
	ok(grep { $_ eq $CHECKS[1] } _failed($output), 'and the consumer check is what failed')
		or diag($output);
};

subtest 'a reader in the producing distribution is discovered' => sub {
	# Nothing registers the badge: without 'own_consumers' the checker treats the
	# declaring distribution as the producer and never reads it.
	my ($status, $output) = _check(
		_fixture({ 'Ledger-Store/lib/Ledger/Badge.pm' => $LEDGER_BADGE }, \%LEDGER_FILES, 'Ledger-Store'),
		base => \%LEDGER_DECLARATION, declaring => 'Ledger-Store');

	isnt($status, 0, 'the contract failed') or diag($output);
	like($output, qr/unregistered consumers of Ledger::Entry results:/,
		'the check says what it found') or diag($output);
	like($output, qr/\tlib\/Ledger\/Badge\.pm$/m,
		'and names it relative to the distribution that holds it') or diag($output);
	_no_other_failures($output, $CHECKS[2]);
};

subtest 'and passes once it is registered' => sub {
	my ($status, $output) = _check(
		_fixture({ 'Ledger-Store/lib/Ledger/Badge.pm' => $LEDGER_BADGE }, \%LEDGER_FILES, 'Ledger-Store'),
		base => \%LEDGER_DECLARATION, declaring => 'Ledger-Store',
		consumers => {
			'Ledger-UI/lib/Ledger/UI.pm' => { may_rely_on => {} },
			'lib/Ledger/Badge.pm'        => { may_rely_on => {} },
		});

	is($status, 0, 'the registered reader passed') or diag($output);
	is(scalar(_passed($output)), 3, 'all three checks ran and passed') or diag($output);
};

subtest 'mutation: without own_consumers the reader in the producing distribution is invisible' => sub {
	my ($status, $output) = _prove('own_consumers',
		_fixture({ 'Ledger-Store/lib/Ledger/Badge.pm' => $LEDGER_BADGE }, \%LEDGER_FILES, 'Ledger-Store'),
		base => \%LEDGER_DECLARATION, declaring => 'Ledger-Store',
		mutation => $NO_OWN_CONSUMERS);

	is($status, 0, 'the unregistered reader is no longer seen') or diag($output);
	is(scalar(_passed($output)), 3, 'all three checks pass') or diag($output);
	unlike($output, qr/Badge\.pm/, 'and is never named') or diag($output);
};

subtest 'mutation: an unqualified constructor binds every constructor in the file' => sub {
	# Ledger::Report is not the value object, and Ledger-Report->new() is not one
	# of the calls the declaration names - but 'new' on its own is.
	my ($status, $output) = _prove('qualified_calls',
		_fixture({}, \%LEDGER_FILES, 'Ledger-Store'),
		base => \%LEDGER_DECLARATION, declaring => 'Ledger-Store',
		mutation => $UNQUALIFIED_CONSTRUCTORS);

	isnt($status, 0, 'the contract failed') or diag($output);
	like($output, qr/Ledger-UI\/lib\/Ledger\/UI\.pm line \d+ in _blank\(\) reads 'entries' \(key\)/,
		'the other class\'s constructor was taken for a producing call') or diag($output);
};

subtest 'a key left in a producer\'s synopsis is not evidence it is still set' => sub {
	# The producer stopped setting 'colour' when it got a POD example that shows
	# one being set.  The evidence is the code, so the key is reported as gone.
	my ($status, $output) = _check(_fixture({
		'Widget-Maker/lib/Widget/Maker.pm' => $PRODUCER_WITH_COLOUR_IN_POD,
	}));

	isnt($status, 0, 'the contract failed') or diag($output);
	like($output, qr/Widget-Maker\/lib\/Widget\/Maker\.pm sets 'colour'/,
		'the key the synopsis mentions is still reported as unset') or diag($output);
	_no_other_failures($output, $CHECKS[0]);
};

subtest 'mutation: the evidence used to be the file as written, synopsis and all' => sub {
	my ($status, $output) = _prove('code_not_prose', _fixture({
		'Widget-Maker/lib/Widget/Maker.pm' => $PRODUCER_WITH_COLOUR_IN_POD,
	}), mutation => $EVIDENCE_AS_WRITTEN);

	is($status, 0, 'the POD example is taken for evidence again') or diag($output);
	is(scalar(_passed($output)), 3, 'all three checks pass') or diag($output);
};

subtest 'mutation: a read out of a batch is bound by a key in braces' => sub {
	# A value is taken out of a batch by naming its key - $batch->{$name} - and
	# with that rule gone nothing binding the value holds a result, so the read of
	# one is not reported at all.
	my ($status, $output) = _prove('batch_selection', _fixture({
		'Widget-Maker/lib/Widget/Maker.pm' => $PRODUCER_WITH_BATCH,
		'Widget-User/lib/Widget/Batch.pm'  => $BATCH_CONSUMER_READING_COLOUR,
	}), consumers => {
		'Widget-User/lib/Widget/User.pm'  => { may_rely_on => {} },
		'Widget-User/lib/Widget/Batch.pm' => { may_rely_on => {} },
	}, mutation => $NO_BATCH_SELECTION);

	ok(grep { $_ eq $CHECKS[1] } _passed($output),
		'the consumer check passed, because no read of a result was found') or diag($output);
	unlike($output, qr/reads 'colour'/, 'the read of the value out of the batch is missed')
		or diag($output);
};

subtest 'mutation: an accessor read has to be a call' => sub {
	# With the parentheses demanded again, a reader that reads a result through
	# its accessors - $entry->memo, with no () - reads nothing as far as the
	# checker is concerned, so the one read that should be reported is not.
	my ($status, $output) = _prove('accessor_reads',
		_fixture({ 'Ledger-UI/lib/Ledger/UI.pm' => $LEDGER_UI_READING_NOTE }, \%LEDGER_FILES, 'Ledger-Store'),
		base => \%LEDGER_DECLARATION, declaring => 'Ledger-Store',
		mutation => $NO_PARENLESS_ACCESSORS);

	ok(grep { $_ eq $CHECKS[1] } _passed($output),
		'the consumer check passed, because the accessor reads were not found') or diag($output);
	unlike($output, qr/reads 'note'/, "the reader's accessor read is never found") or diag($output);
};

subtest 'mutation: every heading down from =head2 names an accessor' => sub {
	# The entry documents its accessors at =head2 and describes each one in a
	# =head3 section of its own.  Read every heading as a name and the sections
	# are accessors the contract has never heard of.
	my ($status, $output) = _prove('accessor_headings',
		_fixture({}, \%LEDGER_FILES, 'Ledger-Store'),
		base => \%LEDGER_DECLARATION, declaring => 'Ledger-Store',
		mutation => $ACCESSORS_AT_ANY_DEPTH);

	isnt($status, 0, 'the contract failed') or diag($output);
	like($output, qr/Ledger::Entry documents 'PURPOSE', which this contract does not mention/,
		'a section heading is reported as an accessor the contract is missing')
		or diag($output);
};

subtest 'mutation: a batch read as a result is caught' => sub {
	my ($status, $output) = _prove('batch_methods', _fixture({
		'Widget-Maker/lib/Widget/Maker.pm' => $PRODUCER_WITH_BATCH,
		'Widget-User/lib/Widget/Batch.pm'  => $BATCH_CONSUMER_READING_COLOUR,
	}), consumers => {
		'Widget-User/lib/Widget/User.pm'  => { may_rely_on => {} },
		'Widget-User/lib/Widget/Batch.pm' => { may_rely_on => {} },
	}, mutation => $BATCH_IS_A_RESULT);

	isnt($status, 0, 'the contract failed');
	# The variable bound from geocode_many() is a batch, so its counts are not
	# fields of a result; treat it as one and the count is read as a key.
	like($output, qr/Widget-User\/lib\/Widget\/Batch\.pm line \d+ in show\(\) reads 'lookups' \(key\) - no producer in this workspace ever sets it/,
		'the batch count is named as a read of a result') or diag($output);
	_no_other_failures($output, $CHECKS[1]);
};

# ---------------------------------------------------------------------------
# A value object that is there but broken, and a producer that is not there:
# both used to be quieter than they should.
# ---------------------------------------------------------------------------

subtest 'a value object that does not compile fails rather than skips' => sub {
	# Skipping a class that is in @INC but does not load hid the breakage: the
	# checks that needed the value object passed exactly when it was broken.
	my $broken = $VALUE_OBJECT;
	$broken =~ s/^sub x /sub x { /m;

	my ($status, $output) = _check(_fixture({ 'Widget-Maker/lib/Widget.pm' => $broken }));

	isnt($status, 0, 'the contract failed') or diag($output);
	like($output, qr/not ok \d+ - Widget compiles/, 'the class is named as not compiling') or diag($output);
	unlike($output, qr/Widget is not available in this checkout/, 'and it is not skipped as absent')
		or diag($output);
};

subtest 'a value object that is absent is still skipped' => sub {
	my ($status, $output) = _check(_fixture({ 'Widget-Maker/lib/Widget.pm' => undef }));

	like($output, qr/skip Widget is not available in this checkout/, 'the skip names the class')
		or diag($output);
};

subtest 'a constructor that dies fails the derivation without ending the run' => sub {
	my $dying = $VALUE_OBJECT;
	$dying =~ s/^\tmy \$self = bless \{\}, \$class;$/\tdie "no widgets today\\n";/m;

	my ($status, $output) = _check(_fixture({ 'Widget-Maker/lib/Widget.pm' => $dying }));

	isnt($status, 0, 'the contract failed') or diag($output);
	like($output, qr/not ok \d+ - a widget can still be made from latitude\/longitude/,
		'the construction is what failed') or diag($output);
	like($output, qr/no widgets today/, 'and the reason is shown') or diag($output);
	is(scalar(_passed($output)), 3, 'the checks after it still ran and passed') or diag($output);
};

subtest 'a producer that cannot be read says why' => sub {
	my $expected = do { local $! = ENOENT; "$!" };

	my ($status, $output) = _check(_fixture({}), producers => { 'lib/Widget/Gone.pm' => ['colour'] });

	isnt($status, 0, 'the contract failed') or diag($output);
	like($output, qr/cannot read lib\/Widget\/Gone\.pm: \Q$expected\E/,
		'the file and the operating system\'s reason are named') or diag($output);
	_no_other_failures($output, $CHECKS[0]);
};

# ---------------------------------------------------------------------------
# The guard: a rule the scanner applies, with no mutation to show it matters, is
# a rule nobody has proved does anything.
# ---------------------------------------------------------------------------

subtest 'a mutation that does not name its rule is refused rather than run' => sub {
	# The guard can only see the mutations it is told about, so a scenario that
	# patches the checker by another route is stopped: its pass would be a proof
	# nobody recorded, which is the failure the guard exists to prevent.
	throws_ok { _check(_fixture({}), mutation => $NO_BATCH_METHOD) }
		qr/a mutation subtest has to name the rule it proves/,
		'patching the checker without saying which rule is proved is an error';
};

subtest 'every scanner rule is proved by a mutation subtest' => sub {
	my $declared = Test::Consumer::Contract->scanner_capabilities();

	# One direction: a rule the module declares and this file never proves.  The
	# list is in the module, next to the code, so a rule added there - which is
	# what adding a behaviour to the scanner means - is caught here until it has a
	# mutation of its own and a scenario showing what the rule catches.
	my @unproved = grep { !$PROVED{$_} } sort keys %{$declared};
	is_deeply(\@unproved, [], 'no rule the module declares goes without a mutation')
		or diag("\n\tThe scanner's rules with no mutation subtest:\n\t"
			. join("\n\t", @unproved)
			. "\n\tEach is a behaviour of the scanner, not a spelling of the code that\n"
			. "\tbuys it: put the rule back the way it was before it was written, in\n"
			. "\tthe subprocess the scenario runs in, and show the failure it catches.\n");

	# The other direction, so that the list cannot quietly fall behind either.  A
	# mutation subtest for a rule that is not declared proves nothing, and _prove()
	# refuses to run it at all.
	my @unknown = grep { !exists($declared->{$_}) } sort keys %PROVED;
	is_deeply(\@unknown, [], 'and no mutation names a rule the module does not declare')
		or diag("\n\tProved by a mutation subtest, but not a rule of the module:\n\t"
			. join("\n\t", @unknown) . "\n");

	# And a row naming a sub the module does not define is a rule that could not
	# be mutated at all, so no mutation subtest could ever prove it.
	for my $capability (sort keys %{$declared}) {
		ok(Test::Consumer::Contract->can($declared->{$capability}),
			"$capability is exercised through $declared->{$capability}()");
	}
};

done_testing();
