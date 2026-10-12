use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use FindBin;
use lib "$FindBin::Bin/lib";

use ChartTest;
use Term::Fabulous::Widget::RadarChart;

my @LABELS = qw(Speed Power Range Cost);
my $RED    = rgb('#ff0000');

sub radar (%args) { return sized( 'Term::Fabulous::Widget::RadarChart', 40, 14, labels => [@LABELS], %args ) }

sub filled ($chart) {
	return scalar cells_with( $chart, sub ( $c, $x, $y ) { defined bg_at( $c, $x, $y ) } );
}

subtest 'labels around the web, ring values up the first spoke' => sub {
	my $chart = radar( series => [ { name => 'X', data => [ 4, 3, 5, 2 ] } ] );
	my @lines = draw($chart);
	like $lines[0],  qr/\A +Speed\z/,        'the first axis points up';
	like $lines[7],  qr/\A +Cost\S+Power\z/, 'the others clockwise';
	like $lines[13], qr/\A +Range\z/,        'all around';
	is [ map { /([0-9]+)/ ? $1 : () } @lines[ 1 .. 6 ] ], [ 6, 4, 2 ], 'the values of the rings';

	$chart->max(10);
	$chart->ticks(2);
	@lines = draw($chart);
	is [ map { /([0-9]+)/ ? $1 : () } @lines[ 1 .. 6 ] ], [ 10, 5 ], 'max and ticks';

	$chart->start_angle(90);
	@lines = draw($chart);
	like $lines[0], qr/\A +Cost\z/, 'start_angle turns the axes';
	like $lines[7], qr/Speed\z/,    'the first axis points right';
	ok scalar( grep { /\b10\b/ } @lines[ 5 .. 6 ] ), 'the ring values sit above the flat spoke';
	@lines
		= draw( sized( 'Term::Fabulous::Widget::RadarChart', 24, 9, labels => [@LABELS], start_angle => 90, max => 1000, ticks => 5, series => [ { name => 'X', data => [ 400, 300, 500, 200 ] } ] ) );
	unlike join( "\n", @lines ), qr/[0-9]{5}/, 'ring values that would touch are left out';
	like join( "\n", @lines ),   qr/\b1000\b/, 'the outer ring keeps its value';
	my %eight = ( labels => [ map { "L$_" } 1 .. 8 ], max => 100, ticks => 2, series => [ { name => 'X', data => [ (50) x 8 ] } ] );
	like join( "\n", draw( sized( 'Term::Fabulous::Widget::RadarChart', 30, 10, %eight, format => '%.0f' ) ) ),   qr/\b100\b/, 'a ring value fits beside the label of the next axis';
	unlike join( "\n", draw( sized( 'Term::Fabulous::Widget::RadarChart', 30, 10, %eight, format => '%.2f' ) ) ), qr/100\.00/, 'a wider one that would touch the label is left out';
};

subtest 'series' => sub {
	my $chart = radar( series => [ { name => 'X', data => [ 4, 3, 5, 2 ], color => '#ff0000' } ] );
	my @lines = draw($chart);
	unlike $lines[0], qr/\x{25A0}/, 'one series needs no legend';
	ok filled($chart) > 20,                                                                                                'an area series is filled';
	ok !grep( { bg_at( $chart, @$_ ) == $RED } cells_with( $chart, sub ( $c, $x, $y ) { defined bg_at( $c, $x, $y ) } ) ), 'translucently';

	$chart->add_series( name => 'Y', type => 'line', data => [ [ Power => 5 ] ], points => 1 );
	@lines = draw($chart);
	like $lines[0], qr/\A\x{25A0} X +\x{2501}\x{2501} Y\z/, 'two series have a legend';
	$chart->remove_series('X');
	@lines = draw($chart);
	is filled($chart), 0, 'a line series is not filled';
	like $lines[7], qr/\x{2022}\S*Power\z/, 'a value given by label is on its axis';

	like dies { $chart->set_data( Y => [ [ Speed => 1 ], [ Weight => 2 ] ] ) }, qr/series 'Y' has a value for 'Weight', which is not one of the labels/, 'a label the chart does not have dies at once';
	is $chart->series('Y')->{data}, [ [ Power => 5 ] ], 'and the data is as it was';
	like dies { $chart->labels( [qw(Speed Range Cost)] ) }, qr/series 'Y' has a value for 'Power', which is not one of the labels/, 'labels that take the axis from a value die';
	is $chart->labels, \@LABELS, 'and the labels are as they were';
};

subtest 'grids' => sub {
	my $chart = radar( max => 4, series => [ { name => 'X', type => 'line', data => [ 1, 1, 1, 1 ] } ] );
	draw($chart);
	my $polygon = braille_dots($chart);
	$chart->grid('none');
	draw($chart);
	ok braille_dots($chart) < $polygon / 3, 'no web without a grid';
	$chart->grid('circle');
	draw($chart);
	ok braille_dots($chart) > $polygon, 'circles are longer than polygons';
};

subtest 'dot and square points' => sub {
	my %line = ( max => 10, grid => 'none', series => [ { name => 'X', type => 'line', line_style => 'dotted', data => [ 5, 5, 5, 5 ] } ] );
	my %dots = map {
		my $chart = radar( %line, $_ ? ( points => 1, point => $_ ) : () );
		draw($chart);
		( $_ || 'none' => braille_dots($chart) );
	} '', qw(dot square);
	ok $dots{dot} > $dots{none},   "point => 'dot' draws Braille dots at the corners";
	ok $dots{square} > $dots{dot}, "point => 'square' adds more";
};

subtest 'fewer than three labels draw no plot' => sub {
	my $chart = radar( labels => [qw(a b)], series => [ { name => 'X', data => [ 1, 2 ] } ] );
	is [ grep { length } draw($chart) ], [], 'nothing';
};

subtest 'invalid input dies' => sub {
	like dies { radar( series => [ { name => 'X', type => 'bar' } ] ) }, qr/draws series of the types area, line, not 'bar'/, 'a bar series';
	like dies { radar( series => [ { name => 'X', data => [ [ Weight => 1 ] ] } ] ) }, qr/series 'X' has a value for 'Weight', which is not one of the labels/,
		'a value for a label the chart does not have';
	like dies { radar( grid => 'square' ) },    qr/grid must be one of circle, none, polygon, got 'square'/, 'an unknown grid';
	like dies { radar( min  => 'low' ) },       qr/min must be a number or undef, got 'low'/,                'a min that is no number';
	like dies { radar( min  => 5, max => 1 ) }, qr/RadarChart: min \(5\) must be less than max \(1\)/,       'a min above the max';
	my $chart = radar( min => 1 );
	like dies { $chart->max(0) }, qr/min \(1\) must be less than max \(0\)/, 'also when the max is set later';
	is $chart->max, undef, 'which leaves the max as it was';
	like dies { radar( ticks       => 0 ) },       qr/ticks must be a positive integer or undef, got '0'/,   'zero ticks';
	like dies { radar( start_angle => 'north' ) }, qr/start_angle must be a number of degrees, got 'north'/, 'an angle that is no number';
	like dies { radar( labels      => 'Speed' ) }, qr/labels must be an array reference of strings/,         'labels that are no array';
	like dies { radar()->series_default( curve => 'linear' ) }, qr/unknown series default 'curve'/, 'a series option radar charts do not take';
};

done_testing;
