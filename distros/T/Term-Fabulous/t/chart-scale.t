use v5.32;
use warnings;
use utf8;

use Test2::V0;
use POSIX qw(setlocale LC_TIME);
use Time::HiRes ();

use Term::Fabulous::Chart::Scale::Category;
use Term::Fabulous::Chart::Scale::Linear;
use Term::Fabulous::Chart::Scale::Log;
use Term::Fabulous::Chart::Scale::Time;

my $Linear   = 'Term::Fabulous::Chart::Scale::Linear';
my $Log      = 'Term::Fabulous::Chart::Scale::Log';
my $Time     = 'Term::Fabulous::Chart::Scale::Time';
my $Category = 'Term::Fabulous::Chart::Scale::Category';

use constant { JUNE_1 => 1780272000, HOUR => 3600, DAY => 86400 };

# The default labels of a time axis come from strftime, which spells
# month names in the language of the locale; the expected labels below
# are English.
setlocale( LC_TIME, 'C' ) or die "cannot set LC_TIME to C: $!";

sub labels {
	my ($scale) = @_;
	return [ map { $_->{label} } $scale->ticks ];
}

sub domain {
	my ($scale) = @_;
	return [ $scale->min, $scale->max, $scale->used ];
}

subtest 'linear: nice ticks on whole cells' => sub {
	my $scale = $Linear->fit( extent => [ 3, 97 ], cells => 17 );
	is domain($scale),                                                                     [ 0, 100, 17 ],             'the data rounded out to the ticks, a tick every 4 cells';
	is [ $scale->kind, $scale->step, $scale->cells, $scale->tick_count, $scale->is_band ], [ 'linear', 25, 17, 5, 0 ], 'kind, step, cells, tick count, no bands';
	is [ $scale->ticks ],                                                       [ map { { value => $_ * 25, label => $_ * 25, position => $_ / 4 } } 0 .. 4 ], 'ticks with value, label and position';
	is [ $scale->position(50), $scale->position(125), $scale->value_at(0.75) ], [ 0.5, 1.25, 75 ],                                                             'position and value_at';
	is [ map { $scale->contains($_) } 0, 100, -1, 101 ],                        [ 1, 1, 0, 0 ],                                                                'contains';

	$scale = $Linear->fit( extent => [ 20, 80 ], cells => 17 );
	is domain($scale),                                                                [ 20, 80, 16 ],                        'three intervals of 5 cells leave one cell unused';
	is labels($scale),                                                                [ 20, 40, 60, 80 ],                    'their ticks';
	is domain( $Linear->fit( extent => [ -0.3, 0.7 ], cells => 11 ) ),                [ -0.5, 0.75, 11 ],                    'negative values';
	is labels( $Linear->fit( extent => [ -0.3, 0.7 ], cells => 11 ) ),                [qw(-0.50 -0.25 0.00 0.25 0.50 0.75)], 'labels with the decimals of the step';
	is labels( $Linear->fit( extent => [ 0, 20000 ], cells => 9 ) ),                  [qw(0 10k 20k)],                       'large values with SI prefixes';
	is labels( $Linear->fit( extent => [ 0, 1 ], cells => 9, format => 'percent' ) ), [qw(0% 50% 100%)],                     'a format';
};

subtest 'linear: options' => sub {
	is domain( $Linear->fit( cells  => 17 ) ),                                 [ 0, 1,  17 ], 'no data: 0 to 1';
	is domain( $Linear->fit( extent => [ 20, 80 ], zero => 1, cells => 17 ) ), [ 0, 80, 17 ], 'zero includes 0';
	my $fixed = $Linear->fit( extent => [ 3, 97 ], min => 0, max => 90, cells => 17 );
	is [ $fixed->min, $fixed->max, labels($fixed) ],                            [ 0, 90, [ 0, 25, 50, 75 ] ],      'fixed ends are not rounded';
	is [ $Linear->fit( extent => [ 3, 97 ], min => 3, cells => 17 )->min ],     [3],                               'a fixed min alone';
	is domain( $Linear->fit( extent => [ 3, 97 ], nice => 0, cells => 17 ) ),   [ 3, 97, 17 ],                     'nice => 0 keeps the domain at the data';
	is labels( $Linear->fit( extent => [ 0, 10 ], step => 5, cells => 17 ) ),   [ 0, 5, 10 ],                      'a fixed step';
	is labels( $Linear->fit( extent => [ 0, 100 ], ticks => 3, cells => 17 ) ), [ 0, 50, 100 ],                    'a wanted number of ticks';
	is labels( $Linear->fit( extent => [ 0, 3 ], integer => 1, cells => 17 ) ), [ 0, 1, 2, 3 ],                    'integer data has no ticks between whole numbers';
	is labels( $Linear->fit( extent => [ 0, 3 ], integer => 1, cells => 40 ) ), [ 0, 1, 2, 3 ],                    'not even with room for them';
	is labels( $Linear->fit( extent => [ 0, 3 ], cells => 40 ) ),               [qw(0.0 0.5 1.0 1.5 2.0 2.5 3.0)], 'other data has';
	is domain( $Linear->fit( extent => [ 5, 5 ], cells => 17 ) ),               [ 4.5, 5.5, 17 ],                  'a single value is widened';
	is domain( $Linear->fit( extent => [ 0, 100 ], cells => 1 ) ),              [ 0, 100, 1 ],                     'no room for ticks: the two ends';

	like dies { $Linear->fit( extent => [ 0, 1 ] ) },              qr/fit needs cells/,                         'cells are required';
	like dies { $Linear->fit( cells  => 0 ) },                     qr/cells must be a positive integer, got 0/, 'cells must be positive';
	like dies { $Linear->fit( cells  => 5, min => 3, max => 3 ) }, qr/min \(3\) must be less than max \(3\)/,   'min must be less than max';
};

subtest 'linear: a fixed step too small for the cells' => sub {
	my $start = Time::HiRes::time();
	my $scale = $Linear->fit( extent => [ 0, 5e6 ], step => 1, cells => 17 );
	ok Time::HiRes::time() - $start < 0.5, 'is given up at once, without listing its five million multiples';
	is [ labels($scale), domain($scale) ],                                            [ [qw(0 5M)], [ 0, 5e6, 17 ] ], 'the axis shows its two ends';
	is labels( $Linear->fit( extent => [ 0, 20_000 ], step => 1, cells => 30_000 ) ), [qw(0 20k)],                    'more than 10 000 ticks are never listed, whatever the cells';
};

subtest 'linear: horizontal axes space ticks by their labels' => sub {
	my $scale = $Linear->fit( extent => [ 0, 1000 ], cells => 40, orientation => 'horizontal' );
	is [ labels($scale), $scale->used ], [ [ 0, 250, 500, 750, 1000 ], 40 ], 'ticks need not fall on whole cells';
	$scale = $Linear->fit( extent => [ 0, 1000 ], cells => 40, orientation => 'horizontal', measure => sub { 10 } );
	is labels($scale),                                                                                   [ 0, 500, 1000 ], 'wider labels, fewer ticks';
	is labels( $Linear->fit( extent => [ 0, 1000 ], cells => 20, orientation => 'horizontal' ) ),        [ 0, 500, 1000 ], 'fewer cells, fewer ticks';
	is $Linear->fit( extent => [ 20, 80 ], cells => 17, orientation => 'horizontal', align => 1 )->used, 16, 'align chooses whole cells on a horizontal axis too';
};

subtest 'log' => sub {
	my $scale = $Log->fit( extent => [ 3, 42_000 ], cells => 17 );
	is [ labels($scale), domain($scale) ],                                                            [ [qw(1 10 100 1k 10k 100k)], [ 1, 1e5, 16 ] ], 'decades from the power below to the power above';
	is [ $scale->kind, $scale->base ],                                                                [ 'log', 10 ],                                  'kind and base';
	is [ $scale->position(100), $scale->position(0), $scale->position(-5), $scale->position(undef) ], [ float(0.4), undef, undef, undef ],            'zero and below have no position';
	is [ $scale->value_at(0.4), $scale->contains(0), $scale->contains(1e5) ],                         [ float(100), 0, 1 ],                           'value_at and contains';

	is labels( $Log->fit( extent => [ 0.01, 1 ], cells => 17 ) ),                             [qw(0.01 0.1 1)],    'powers below 1 as decimals';
	is labels( $Log->fit( extent => [ 1, 8 ], base => 2, cells => 17 ) ),                     [qw(1 2 4 8)],       'another base';
	is labels( $Log->fit( extent => [ 1, 1000 ], format => '%d', cells => 17 ) ),             [qw(1 10 100 1000)], 'a format';
	is labels( $Log->fit( extent => [ 1, 1e6 ], cells => 4 ) ),                               [qw(1 10k)],         'crowded powers: every fourth labeled';
	is labels( $Log->fit( extent => [ 1, 1e6 ], cells => 20, orientation => 'horizontal' ) ), [qw(1 100 10k 1M)],  'a horizontal axis spaces them by their labels';
	my $fixed = $Log->fit( extent => [ 3, 500 ], min => 2, cells => 17 );
	is [ $fixed->min, $fixed->max, labels($fixed) ],               [ 2,   1000, [qw(10 100 1k)] ], 'a fixed min is not rounded';
	is domain( $Log->fit( extent => [ 100, 100 ], cells => 17 ) ), [ 100, 1000, 17 ],              'a single value spans a decade';

	like dies { $Log->fit( cells => 5, base => 1 ) }, qr/base must be a number greater than 1, got 1/,             'base 1 dies';
	like dies { $Log->fit( cells => 5, min  => 0 ) }, qr/min of a logarithmic axis must be greater than 0, got 0/, 'min 0 dies';
	like dies { $Log->fit( cells => 5, min => 10, max => 1 ) }, qr/min \(10\) must be less than max \(1\)/, 'min must be less than max';
};

subtest 'log: fixed ends beyond the data' => sub {
	my $below = $Log->fit( extent => [ 10, 1000 ], max => 5, cells => 10 );
	is [ $below->min, $below->max ], [ 0.1, float(5) ], 'a fixed max below the data is kept; the min moves a decade below it';
	my $above = $Log->fit( extent => [ 10, 1000 ], min => 5000, cells => 10 );
	is [ $above->min, $above->max ], [ 5000, 1e5 ], 'a fixed min above the data is kept; the max moves a decade above it';
};

subtest 'time' => sub {
	my $scale = $Time->fit( extent => [ JUNE_1, JUNE_1 + 2 * DAY ], cells => 60, utc => 1 );
	is labels($scale),                                                  [ 'Jun 1', '12:00', 'Jun 2', '12:00', 'Jun 3' ],                 'hours between days show the date at midnight';
	is [ $scale->interval, $scale->kind, $scale->utc, domain($scale) ], [ [ hour => 12 ], 'time', 1, [ JUNE_1, JUNE_1 + 2 * DAY, 60 ] ], 'the interval; the domain is the data';
	is [ map { $_->{position} } $scale->ticks ],                        [ 0, 0.25, 0.5, 0.75, 1 ],                                       'tick positions';
	is $scale->value_at(0.5),                                           JUNE_1 + DAY,                                                    'value_at';

	my %interval;
	foreach my $case (
		[ second => [ JUNE_1, JUNE_1 + 120 ],      60, [ second => 30 ], [qw(00:00:00 00:00:30 00:01:00 00:01:30 00:02:00)] ],
		[ minute => [ JUNE_1, JUNE_1 + HOUR ],     60, [ minute => 10 ], [ 'Jun 1', qw(00:10 00:20 00:30 00:40 00:50 01:00) ] ],
		[ week   => [ JUNE_1, JUNE_1 + 30 * DAY ], 60, [ week => 1 ],    [ 'Jun 1', 'Jun 8', 'Jun 15', 'Jun 22', 'Jun 29' ] ],
		[ month  => [ 1767225600, 1798761600 ],    80, [ month => 2 ],   [qw(2026 Mar May Jul Sep Nov 2027)] ],
		[ year   => [ 946684800, 1767225600 ],     60, [ year => 5 ],    [qw(2000 2005 2010 2015 2020 2025)] ],
		)
	{
		my ( $name, $extent, $cells, $interval, $labels ) = @$case;
		my $fitted = $Time->fit( extent => $extent, cells => $cells, utc => 1 );
		is [ $fitted->interval, labels($fitted) ], [ $interval, $labels ], "$name ticks and their labels";
	}

	is labels( $Time->fit( extent => [ JUNE_1, JUNE_1 + 2 * DAY ], cells => 20, utc => 1, orientation => 'vertical' ) ),
		[ 'Jun 1', '06:00', '12:00', '18:00', 'Jun 2', '06:00', '12:00', '18:00', 'Jun 3' ], 'a vertical axis needs less room';
	is labels( $Time->fit( extent => [ JUNE_1, JUNE_1 + 2 * DAY ], cells => 60, utc => 1, format => '%d.%m.' ) ), [qw(01.06. 01.06. 02.06. 02.06. 03.06.)], 'a format labels every tick the same way';
	is domain( $Time->fit( extent => [ JUNE_1, JUNE_1 ], cells => 60, utc => 1 ) ), [ JUNE_1 - HOUR / 2, JUNE_1 + HOUR / 2, 60 ], 'a single moment is widened to an hour';
	is domain( $Time->fit( extent => [ 0, 1 ], min => JUNE_1, max => JUNE_1 + DAY, cells => 60, utc => 1 ) ), [ JUNE_1, JUNE_1 + DAY, 60 ], 'fixed ends';

	like dies { $Time->fit( cells => 'many' ) },                  qr/cells must be a positive integer, got many/, 'invalid cells die';
	like dies { $Time->fit( cells => 5, min => 10, max => 10 ) }, qr/min \(10\) must be before max \(10\)/,       'min must be before max';
};

subtest 'category' => sub {
	my $scale = $Category->fit( labels => [qw(Jan Feb Mar)], cells => 30 );
	is [ $scale->kind, $scale->is_band, [ $scale->labels ], $scale->count, $scale->min, $scale->max ], [ 'category', 1, [qw(Jan Feb Mar)], 3, 0, 2 ], 'labels and their numbers';
	is [ $scale->slot_cells, $scale->position(1), $scale->value_at(0.5) ],                             [ 10, 0.5, 1 ],                                'each category in the middle of its slot';
	is labels($scale),                                                                                 [qw(Jan Feb Mar)],                             'every category is a tick';
	is [ map { $scale->label_at($_) } 0, 2, 3 ],                                                       [ 'Jan', 'Mar', undef ],                       'label_at: the label of a category number';

	$scale = $Category->fit( labels => [qw(Jan Feb Mar)], cells => 32 );
	is [ $scale->slot_cells, $scale->position(0), $scale->value_at( $scale->position(2) ) ], [ 10, 0.1875, 2 ], 'slots of whole cells; the cells left over go to both ends';
	is $Category->fit( labels => [ 1 .. 10 ], cells => 19 )->slot_cells,                     1.9,               'unless too many are left over';

	$scale = $Category->fit( labels => [qw(a b c d e)], cells => 41, band => 0 );
	is [ $scale->is_band, $scale->slot_cells, $scale->position(0), $scale->position(4), $scale->value_at(0.5) ], [ 0, 10, 0, 1, 2 ], 'a point scale runs from end to end';
	is $Category->fit( labels => ['only'], cells => 9, band => 0 )->position(0),                                 0.5,                'a single point lies in the middle';

	my @months = qw(January February March April May June July August September October November December);
	is labels( $Category->fit( labels => \@months, cells => 24 ) ), [qw(January April July October)], 'labels too wide for their slots: every third labeled';
	is labels( $Category->fit( labels => \@months,    cells => 24, measure     => sub { 1 } ) ),  \@months,                      'measure decides the width';
	is labels( $Category->fit( labels => [ 1 .. 30 ], cells => 10, orientation => 'vertical' ) ), [ map { 1 + 3 * $_ } 0 .. 9 ], 'a vertical axis labels one category per cell';

	like dies { $Category->fit( labels => ['a'] ) }, qr/fit needs cells/, 'cells are required';
};

done_testing;
