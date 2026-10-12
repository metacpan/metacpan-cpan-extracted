use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use FindBin;
use lib "$FindBin::Bin/lib";

use ChartTest;
use Term::Fabulous::Widget::Histogram;

my ( $RED, $BLUE ) = map { rgb($_) } '#ff0000', '#0000ff';
my @SAMPLE = ( 1, 2, 2, 3, 3, 3, 4, 4, 4, 4 );

sub histogram (%args) { return sized( 'Term::Fabulous::Widget::Histogram', 40, 10, %args ) }

# The values of the first series as the chart draws them.
sub bin_values ($chart) {
	my ( undef, undef, $prepared ) = $chart->prepare_series;
	return $prepared->[0]{ys};
}

subtest 'counts per bin, from edge to edge' => sub {
	my $chart = histogram( bins => 4, series => [ { name => 'h', data => [@SAMPLE], color => '#ff0000' } ] );
	my @lines = draw($chart);
	is [ map { bar_eighths( $chart, $_, $RED ) } 3, 13, 22, 32 ], [ 16, 32, 48, 64 ], 'each bin as high as its count';
	is [ map { bg_at( $chart, $_, 7 ) } 2, 10, 11, 12 ], [ $RED, $RED, undef, $RED ], 'a column free between wide bins';
	like $lines[-1], qr/\A 1 +2 +3 +4\z/, 'a numeric x axis';
	is bin_values($chart), [ 1, 2, 3, 4 ], 'the counts';
};

subtest 'bin edges' => sub {
	my $chart = Term::Fabulous::Widget::Histogram->new;
	is [ $chart->bin_edges( [ 0 .. 100 ] ) ],       [ 0, 20, 40, 60, 80, 100 ],  'automatic bins have a nice width';
	is [ $chart->bin_edges( [ 0.1, 0.35, 0.8 ] ) ], [ 0, 0.5, 1 ],               'that covers the values';
	is [ $chart->bin_edges ],                       [ map { $_ / 10 } 0 .. 10 ], 'from 0 to 1 without values';
	is [ $chart->bin_edges( [ 1, 1.5 ], [9] ) ],    [ 0, 5, 10 ],                'over the values of all series';
	$chart->bins(4);
	is [ $chart->bin_edges( [ 1, 2, 4 ] ) ], [ 1, 1.75, 2.5, 3.25, 4 ], 'a number of bins divides the values evenly';
	$chart->bin_width(25);
	is [ $chart->bin_edges( [ 3, 90 ] ) ], [ 0, 25, 50, 75, 100 ], 'bin_width wins over bins';
	$chart->range( [ 0, 60 ] );
	is [ $chart->bin_edges( [ 3, 90 ] ) ], [ 0, 25, 50, 60 ], 'a range ends the last bin';
	$chart->bin_width(undef);
	$chart->bins(3);
	is [ $chart->bin_edges( [ 3, 90 ] ) ], [ 0, 20, 40, 60 ], 'bins divide the range';
};

subtest 'at most 1000 bins' => sub {
	my $chart = Term::Fabulous::Widget::Histogram->new( bin_width => 0.01 );
	my @edges = $chart->bin_edges( [ 0, 10_000 ] );
	is [ scalar @edges, $edges[1] - $edges[0], $edges[-1] ], [ 1001, 10, 10_000 ], 'a bin width too small for the data widens to a round width';
	$chart->range( [ 0, 2 ] );
	is [ $chart->bin_edges( [1] ) ], [ map { $_ / 100 } 0 .. 200 ], 'and is kept where it makes few enough bins';
};

subtest 'a range drops values outside it' => sub {
	my $chart = histogram( bins => 2, range => [ 0, 2 ], series => [ { data => [ -1, 0, 0.5, 1, 2, 2.5, undef ] } ] );
	is bin_values($chart), [ 2, 2 ], 'the high end belongs to the last bin';
};

subtest 'measures and cumulative counts' => sub {
	my $chart = histogram( bins => 2, measure => 'percent', series => [ { data => [ 1, 1, 1, 2 ] } ] );
	is bin_values($chart), [ 0.75, 0.25 ], 'percent: shares of the count';
	like( ( draw($chart) )[0], qr/\A\d+% /, 'on a percent axis' );
	$chart->measure('density');
	is bin_values($chart), [ 1.5, 0.5 ], 'density: shares per unit of x';
	$chart->measure('count');
	$chart->cumulative(1);
	is bin_values($chart), [ 3, 4 ], 'cumulative counts';
};

subtest 'several series' => sub {
	my @series = ( { name => 'a', data => [ 1, 2, 2, 3 ], color => '#ff0000' }, { name => 'b', data => [ 2, 3, 3, 4 ], color => '#0000ff' } );
	my $chart  = histogram( bins => 4, series => [@series] );
	my @lines  = draw($chart);
	like $lines[0], qr/\A\x{25A0} a +\x{25A0} b/, 'have a legend';
	my @colored = cells_with( $chart, sub ( $c, $x, $y ) { defined bg_at( $c, $x, $y ) } );
	ok @colored && !grep( {
			my $bg = bg_at( $chart, @$_ );
			$bg == $RED || $bg == $BLUE
	} @colored ),
		'overlap and show through each other';

	$chart->stacked(1);
	draw($chart);
	is [ bar_eighths( $chart, 13, $RED ), bar_eighths( $chart, 13, $BLUE ) ], [ 32, 16 ], 'stacked: opaque, one on the other';
};

subtest 'invalid input dies' => sub {
	like dies { histogram( series => [ { name => 'xy', data => [ [ 1, 2 ] ] } ] ) }, qr/series 'xy' of a histogram takes plain numbers, not \[ x, y \] points/, 'points die when they are given';
	my $chart = histogram( series => [ { name => 'h', data => [ 1, 2 ] } ] );
	like dies { $chart->add_points( h => { x => 3, y => 4 } ) }, qr/series 'h' of a histogram takes plain numbers/, 'also when they are added';
	is $chart->series('h')->{data}, [ 1, 2 ], 'which leaves the data as it was';
	like dies { histogram( bins      => 1001 ) },                   qr/bins must be 'auto' or a positive integer up to 1000, got '1001'/,     'more than 1000 bins';
	like dies { histogram( series    => [ { type => 'line' } ] ) }, qr/draws series of the types bar, not 'line'/,                            'a line series';
	like dies { histogram( bins      =>  0 ) },                     qr/bins must be 'auto' or a positive integer up to 1000, got '0'/,        'zero bins';
	like dies { histogram( bin_width => -1 ) },                     qr/bin_width must be a positive number or undef, got '-1'/,               'a negative bin width';
	like dies { histogram( range     => [ 5, 1 ] ) },               qr/range must be an array reference \[ low, high \] with low below high/, 'a reversed range';
	like dies { histogram( range     => [1] ) },                    qr/range must be an array reference/,                                     'a range of one value';
	like dies { histogram( measure   => 'sum' ) },                  qr/measure must be one of count, density, percent, got 'sum'/,            'an unknown measure';
	like dies { $chart->cumulative( [] ) }, qr/cumulative/, 'cumulative as an array';
};

done_testing;
