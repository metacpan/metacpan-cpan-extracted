#!/usr/bin/env perl

# Term::Fabulous::Widget::PieChart: the browsers of a website's visitors,
# largest first, with the small ones folded into "Other". Move the mouse
# over a slice or a legend entry to emphasize it; Ctrl+C quits.
#
#     perl examples/widgets/pie-chart.pl

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
use Term::Fabulous::Widget::PieChart;

use Clay::XS qw(sizing_grow);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		sizing  => { width => sizing_grow(), height => sizing_grow() },
		padding => { left  => 2, right => 2, top => 1, bottom => 1 },
	},
);

my $chart = Term::Fabulous::Widget::PieChart->new(
	title => 'Visitors by browser',
	sort  => 'desc',
	other => 0.03,
	data  => [
		[ Chrome  => 6420 ],
		[ Safari  => 1830 ],
		[ Firefox => 1210 ],
		[ Edge    => 980 ],
		[ Opera   => 160 ],
		[ Vivaldi => 90 ],
		[ Lynx    => 12 ],
	],
);
$root->add_child($chart);

Term::Fabulous->new( width => 80, height => 24, root => $root )->run;
