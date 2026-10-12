#!/usr/bin/env perl

# Term::Fabulous::Widget::DonutChart: a monthly budget with the total in
# the middle and the amounts in the legend. Move the mouse over a slice
# or a legend entry: the middle shows its share; Ctrl+C quits.
#
#     perl examples/widgets/donut-chart.pl

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
use Term::Fabulous::Widget::DonutChart;

use Clay::XS qw(sizing_grow);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		sizing  => { width => sizing_grow(), height => sizing_grow() },
		padding => { left  => 2, right => 2, top => 1, bottom => 1 },
	},
);

my $chart = Term::Fabulous::Widget::DonutChart->new(
	title         => 'Monthly budget',
	legend_values => 'both',
	format        => '%d €',
	data          => [ [ Rent => 1200 ], [ Food => 450 ], [ Transport => 180 ], [ Leisure => 220 ], [ Savings => 400 ], [ Other => 90 ] ],
);
$root->add_child($chart);

Term::Fabulous->new( width => 80, height => 24, root => $root )->run;
