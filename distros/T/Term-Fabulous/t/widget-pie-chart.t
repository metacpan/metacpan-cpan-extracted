use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use FindBin;
use lib "$FindBin::Bin/lib";

use ChartTest;
use Term::Fabulous::Widget::DonutChart;
use Term::Fabulous::Widget::PieChart;
use Term::Fabulous::Widget::PolarAreaChart;

my ( $RED, $GREEN ) = map { rgb($_) } '#ff0000', '#00ff00';
my @DATA = ( { label => 'A', value => 50, color => '#ff0000' }, { label => 'B', value => 30, color => '#00ff00' }, { label => 'C', value => 20, color => '#0000ff' } );

sub pie   (%args) { return sized( 'Term::Fabulous::Widget::PieChart',   40, 12, data => [@DATA], %args ) }
sub donut (%args) { return sized( 'Term::Fabulous::Widget::DonutChart', 40, 14, data => [@DATA], %args ) }

# The legend entries: the text right of each square.
sub legend (@lines) {
	return [ map { /\x{25A0} (.*)\z/ ? $1 : () } @lines ];
}

subtest 'slices' => sub {
	my $chart = Term::Fabulous::Widget::PieChart->new( data => [ 3, 2 ], labels => ['Rent'], colors => [ undef, '#00ff00' ] );
	is [ $chart->slices ], [ { label => 'Rent', value => 3 }, { label => 'Slice 2', value => 2, color => '#00ff00' } ], 'numbers named by labels, colors by position';
	$chart->set_data( [ [ Rent => 5 ], { label => 'Food', value => 1, color => '#ff0000' } ] );
	is [ $chart->slices ], [ { label => 'Rent', value => 5 }, { label => 'Food', value => 1, color => '#ff0000' } ], 'pairs and hashes';
	is [ $chart->value('Food'), $chart->value('Fun'), $chart->total ], [ 1, undef, 6 ], 'value and total';

	ref_is $chart->set_value( Rent => 4 ), $chart, 'set_value returns the chart';
	$chart->set_value( Fun => 2 );
	is [ map { [ $_->{label}, $_->{value} ] } $chart->slices ], [ [ Rent => 4 ], [ Food => 1 ], [ Fun => 2 ] ], 'set_value changes a slice or adds one';
	$chart->add_slice( 'Car', 3, '#0000ff' );
	$chart->set_slice_color( Food => undef );
	$chart->remove_slice( 'Rent', 'Fun' );
	is [ $chart->slices ], [ { label => 'Food', value => 1 }, { label => 'Car', value => 3, color => '#0000ff' } ], 'add_slice, set_slice_color and remove_slice';
	$chart->clear_slices;
	is [ [ $chart->slices ], $chart->total ], [ [], 0 ], 'clear_slices';
};

subtest 'slices go clockwise from 12 o\'clock' => sub {
	my $chart = pie();
	my @lines = draw($chart);
	is [ bg_at( $chart, 20, 6 ), bg_at( $chart, 8, 6 ) ], [ $RED, $GREEN ],                            'the first half on the right';
	is legend(@lines),                                    [ 'A  50%', 'B  30%', 'C  20%' ],            'a legend with the shares on the right';
	is [ grep { /\x{25A0}/ } @lines[ 4 .. 6 ] ],          [ map { match qr/\x{25A0} [ABC]/ } 1 .. 3 ], 'centered beside the pie';
	like join( '', @lines ), qr/50%.*30%/s, 'the shares on the slices';

	$chart->start_angle(180);
	draw($chart);
	is [ bg_at( $chart, 20, 6 ), bg_at( $chart, 8, 6 ) ], [ $GREEN, $RED ], 'start_angle turns the pie';
};

subtest 'slice labels, legend values and order' => sub {
	my $chart = pie( slice_labels => 'label', legend_values => 'both', sort => 'asc' );
	my @lines = draw($chart);
	is legend(@lines), [ 'C  20  20%', 'B  30  30%', 'A  50  50%' ], 'sort asc; values and shares';
	like join( '', map { substr $_, 0, 26 } @lines ), qr/A.*B/s, 'the labels on the slices';
	$chart->sort('desc');
	$chart->legend_values('value');
	$chart->slice_labels('value');
	@lines = draw($chart);
	is legend(@lines), [ 'A  50', 'B  30', 'C  20' ], 'sort desc; values only';
	like join( '', map { substr $_, 0, 26 } @lines ), qr/50/, 'values on the slices';
	$chart->legend_values('none');
	$chart->slice_labels('none');
	@lines = draw($chart);
	is legend(@lines), [ 'A', 'B', 'C' ], 'no values';
	unlike join( '', @lines ), qr/[0-9]/, 'nor labels on the slices';
};

subtest 'small slices fold into Other' => sub {
	my $chart = pie( other => 0.1, data => [ [ A => 90 ], [ B => 4 ], [ C => 3 ], [ D => 2.5 ], [ E => 0.5 ] ] );
	is legend( draw($chart) ), [ 'A      90%', 'Other  10%' ], 'the slices below the share';
	$chart->other_label('Rest');
	is legend( draw($chart) ), [ 'A     90%', 'Rest  10%' ], 'other_label';
	$chart->set_data( [ [ A => 95 ], [ B => 5 ] ] );
	is legend( draw($chart) ), [ 'A  95%', 'B   5%' ], 'a single small slice is kept';
	$chart->other(0);
	$chart->set_data( [ [ A => 99.5 ], [ B => 0.5 ], [ Z => 0 ] ] );
	is legend( draw($chart) ), [ 'A  100%', 'B   <1%' ], 'empty slices are left out, tiny shares shown as <1%';
};

subtest 'other_label undef is Other' => sub {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my $chart = pie( other => 0.2, other_label => undef, data => [ [ A => 80 ], [ B => 5 ], [ C => 5 ], [ D => 10 ] ] );
	is [ $chart->other_label, legend( draw($chart) )->@* ], [ 'Other', 'A      80%', 'Other  20%' ], 'as with the accessor';
	is \@warnings,                                          [],                                      'without warnings';
};

subtest 'donuts' => sub {
	my $chart = donut();
	is [ $chart->hole, Term::Fabulous::Widget::PieChart->new->hole ], [ 0.6, 0 ], 'a donut has a hole, a pie none';
	my @lines = draw($chart);
	like $lines[6], qr/\A \x{2590} +100 +\x{258C}/, 'the total in the hole';
	like $lines[7], qr/ Total /,                    'named';
	is bg_at( $chart, 14, 6 ), undef, 'the hole is empty';

	$chart->center_text("Budget\n2026");
	@lines = draw($chart);
	is [ $lines[6], $lines[7] ], [ match qr/ Budget /, match qr/ 2026 / ], 'center_text';
	$chart->center_text('');
	@lines = draw($chart);
	unlike join( '', @lines[ 5 .. 8 ] ), qr/Total|Budget/, 'an empty one shows nothing';
	$chart->hole(0);
	draw($chart);
	ok defined bg_at( $chart, 14, 6 ), 'hole 0 closes it';
};

subtest 'gaps between the slices' => sub {
	my $chart = sized( 'Term::Fabulous::Widget::PieChart', 30, 12, gap => 1, legend => 'none', slice_labels => 'none', data => [ [ A => 1 ], [ B => 1 ], [ C => 1 ], [ D => 1 ] ] );
	my @lines = draw($chart);
	like $lines[3], qr/\A +\x{2597} +\x{258C}\x{2590} +\x{2596}\z/,               'a column free between the left and the right slices';
	like $lines[5], qr/\A +\x{259D}\x{2580}+\x{2598}\x{259D}\x{2580}+\x{2598}\z/, 'half a row free between the upper and the lower slices';
	is scalar( grep { defined bg_at( $chart, 14, $_ ) || defined bg_at( $chart, 15, $_ ) } 0 .. 11 ), 0, 'the gap has no color';

	$chart = sized( 'Term::Fabulous::Widget::PieChart', 30, 12, gap => 1, hole => 0.9, legend => 'none', slice_labels => 'none', data => [ [ A => 1 ], [ B => 1 ], [ C => 1 ], [ D => 1 ] ] );
	@lines = draw($chart);
	like $lines[0], qr/\A +\x{2597}\x{2584}+\x{2596}\x{2597}\x{2584}+\x{2596}\z/, 'a thin ring keeps the gaps between its arcs';
	like $lines[5], qr/\A +\x{259D}\x{2580} +4 +\x{2580}\x{2598}\z/,              'and is a column thick at the sides, around the total';

	$chart = sized( 'Term::Fabulous::Widget::PieChart', 30, 5, data => [ map { [ "Slice $_" => $_ ] } 1 .. 6 ] );
	like( ( draw($chart) )[4], qr/\A.* \+2 more\z/, 'a legend beside the plot counts the entries it has no room for' );
};

subtest 'markers' => sub {
	my $chart = pie( marker => 'braille' );
	draw($chart);
	ok braille_dots($chart) > 100, 'the braille marker';
	is $chart->marker('half'), 'half', 'marker';
};

subtest 'polar area charts' => sub {
	my $chart = sized( 'Term::Fabulous::Widget::PolarAreaChart', 40, 14, data => [ { label => 'A', value => 4, color => '#ff0000' }, [ B => 2 ], [ C => 1 ] ] );
	my @lines = draw($chart);
	is legend(@lines), [ 'A  4', 'B  2', 'C  1' ], 'the values in the legend';
	unlike join( '', map { substr $_, 0, 30 } @lines[ 1 .. 12 ] ), qr/%/, 'no shares on the slices';
	like $lines[0],                                                qr/4/, 'the rings are labeled up the 12 o\'clock line';
	my $red = scalar cells_with( $chart, sub ( $c, $x, $y ) { ( bg_at( $c, $x, $y ) // -1 ) == $RED } );
	ok $red > 0 && !grep( { ( bg_at( $chart, $_, 12 ) // -1 ) == $RED } 0 .. 39 ), 'the first slice takes the first third from 12 o\'clock';

	$chart->max(8);
	@lines = draw($chart);
	ok scalar( cells_with( $chart, sub ( $c, $x, $y ) { ( bg_at( $c, $x, $y ) // -1 ) == $RED } ) ) < $red, 'max sets the value of the outer ring';
	like join( '', @lines ), qr/7\.5.*5\.0.*2\.5/s, 'and its labels';
	like dies { $chart->max(-1) },  qr/max must be a positive number or undef, got '-1'/,   'a negative max dies';
	like dies { $chart->ticks(0) }, qr/ticks must be a positive integer or undef, got '0'/, 'zero ticks die';
};

subtest 'invalid input dies' => sub {
	my $chart = pie();
	my @cases = (
		[ sub { pie( data => [ [ A => -1 ] ] ) },                             qr/the value of slice 'A' must be a number of at least 0, got '-1'/, 'a negative value' ],
		[ sub { pie( data => [ [ A => 1 ], [ A => 2 ] ] ) },                  qr/two slices are labeled 'A'/,                                      'a label twice' ],
		[ sub { pie( data => [ { label => 'A', value => 1, size => 2 } ] ) }, qr/slice 0 takes only label, value and color, got size/,             'an unknown key' ],
		[ sub { pie( data => [ ['A'] ] ) },                                   qr/slice 0 must be \[ label, value \], got an array of 1 values/,    'a pair of one' ],
		[ sub { pie( data => { A => 1 } ) },                                  qr/data must be an array reference, got a HASH reference/,           'data that is no array' ],
		[ sub { pie( data => [ [ '', 1 ] ] ) },                               qr/a slice label must be a non-empty string/,                        'an empty label' ],
		[ sub { $chart->add_slice( A => 1 ) },               qr/a slice labeled 'A' exists already/, 'add_slice of a known label' ],
		[ sub { $chart->remove_slice('Z') },                 qr/no slice labeled 'Z'/,               'remove_slice of an unknown label' ],
		[ sub { $chart->set_slice_color( Z => '#ff0000' ) }, qr/no slice labeled 'Z'/,               'set_slice_color of an unknown label' ],
		[ sub { pie( hole          => 0.95 ) },     qr/hole must be a number from 0 to 0\.9, got '0\.95'/,                  'a hole too large' ],
		[ sub { pie( marker        => 'block' ) },  qr/marker must be quadrant, half, sextant, braille, got 'block'/,       'an unknown marker' ],
		[ sub { pie( sort          => 'random' ) }, qr/sort must be one of asc, desc, none, got 'random'/,                  'an unknown sort' ],
		[ sub { pie( slice_labels  => 'all' ) },    qr/slice_labels must be one of label, none, percent, value, got 'all'/, 'unknown slice labels' ],
		[ sub { pie( legend_values => 'all' ) },    qr/legend_values must be one of both, none, percent, value, got 'all'/, 'unknown legend values' ],
		[ sub { pie( other         => 2 ) },        qr/other must be a number from 0 to 1, got '2'/,                        'an other share above 1' ],
		[ sub { pie( start_angle   => 'north' ) },  qr/start_angle must be a number of degrees, got 'north'/,               'an angle that is no number' ],
	);
	foreach my $case (@cases) {
		like dies { $case->[0]->() }, $case->[1], $case->[2];
	}
	my $unchanged = pie();
	ok dies { $unchanged->set_data( [ [ A => 5 ], [ B => -1 ] ] ) }, 'set_data with an invalid slice dies';
	is $unchanged->value('A'), 50, 'and leaves the slices as they were';
};

done_testing;
