#!/usr/bin/env perl

# Term::Fabulous::Widget::AreaChart: website traffic by source, stacked,
# with monotone curves. Move the mouse over an area or a legend entry to
# emphasize it; Ctrl+C quits.
#
#     perl examples/widgets/area-chart.pl

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
use Term::Fabulous::Widget::AreaChart;

use Clay::XS qw(sizing_grow);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		sizing  => { width => sizing_grow(), height => sizing_grow() },
		padding => { left  => 2, right => 2, top => 1, bottom => 1 },
	},
);

my $chart = Term::Fabulous::Widget::AreaChart->new(
	title   => 'Visits by source',
	labels  => [qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)],
	stacked => 1,
	curve   => 'monotone',
	series  => [
		{ name => 'Search', data => [ 30, 35, 40, 38, 45, 60, 70, 65, 50, 48, 44, 52 ] },
		{ name => 'Social', data => [ 20, 22, 30, 35, 40, 45, 52, 50, 46, 40, 38, 42 ] },
		{ name => 'Direct', data => [ 10, 12, 14, 18, 20, 22, 25, 27, 26, 25, 27, 30 ] },
	],
);
$root->add_child($chart);

Term::Fabulous->new( width => 80, height => 24, root => $root )->run;
