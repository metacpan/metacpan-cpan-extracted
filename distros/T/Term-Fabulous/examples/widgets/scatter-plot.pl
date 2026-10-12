#!/usr/bin/env perl

# Term::Fabulous::Widget::ScatterPlot: the engine power and fuel use of
# two kinds of cars, each with its trend line. Move the mouse over a
# point to emphasize its kind; Ctrl+C quits.
#
#     perl examples/widgets/scatter-plot.pl

use v5.32;
use warnings;
use strict;
use utf8;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::ScatterPlot;

use Clay::XS qw(sizing_grow);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		sizing  => { width => sizing_grow(), height => sizing_grow() },
		padding => { left  => 2, right => 2, top => 1, bottom => 1 },
	},
);

# Made-up measurements: fuel use grows with the power, less for hybrids.
srand 42;

sub cars ( $count, $base, $per_kw, $spread ) {
	return map {
		my $power = 50 + rand 150;
		[ sprintf( '%.0f', $power ), sprintf( '%.1f', $base + $per_kw * $power + ( rand() - 0.5 ) * $spread ) ];
	} 1 .. $count;
}

my $chart = Term::Fabulous::Widget::ScatterPlot->new(
	title  => 'Power and fuel use',
	x_axis => { title => 'Engine power (kW)' },
	y_axis => { title => 'l/100 km' },
	series => [
		{ name => 'Petrol', data => [ cars( 40, 3.5, 0.030, 2.0 ) ], trend => 1 },
		{ name => 'Hybrid', data => [ cars( 30, 2.0, 0.022, 1.6 ) ], trend => 1 },
	],
);
$root->add_child($chart);

Term::Fabulous->new( width => 80, height => 24, root => $root )->run;
