#!/usr/bin/env perl

# Term::Fabulous::Widget::RadarChart: the ratings of two laptops in six
# categories, as filled shapes on a web of axes. Move the mouse over a
# shape or a legend entry to emphasize it; Ctrl+C quits.
#
#     perl examples/widgets/radar-chart.pl

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
use Term::Fabulous::Widget::RadarChart;

use Clay::XS qw(sizing_grow);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		sizing  => { width => sizing_grow(), height => sizing_grow() },
		padding => { left  => 2, right => 2, top => 1, bottom => 1 },
	},
);

my $chart = Term::Fabulous::Widget::RadarChart->new(
	title  => 'Laptop ratings',
	labels => [ 'Speed', 'Battery', 'Screen', 'Keyboard', 'Weight', 'Price' ],
	max    => 10,
	points => 1,
	series => [
		{ name => 'Model A', data => [ 9, 6, 8, 7, 5, 4 ] },
		{ name => 'Model B', data => [ 6, 9, 6, 8, 9, 7 ] },
	],
);
$root->add_child($chart);

Term::Fabulous->new( width => 80, height => 24, root => $root )->run;
