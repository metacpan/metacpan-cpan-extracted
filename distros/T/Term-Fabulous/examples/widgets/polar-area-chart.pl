#!/usr/bin/env perl

# Term::Fabulous::Widget::PolarAreaChart: commits per weekday as slices
# of equal angle that reach as far out as their value, with rings for
# the scale. Move the mouse over a slice to emphasize it; Ctrl+C quits.
#
#     perl examples/widgets/polar-area-chart.pl

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
use Term::Fabulous::Widget::PolarAreaChart;

use Clay::XS qw(sizing_grow);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		sizing  => { width => sizing_grow(), height => sizing_grow() },
		padding => { left  => 2, right => 2, top => 1, bottom => 1 },
	},
);

my $chart = Term::Fabulous::Widget::PolarAreaChart->new(
	title => 'Commits by weekday',
	data  => [ [ Monday => 34 ], [ Tuesday => 41 ], [ Wednesday => 38 ], [ Thursday => 45 ], [ Friday => 29 ], [ Saturday => 9 ], [ Sunday => 6 ] ],
);
$root->add_child($chart);

Term::Fabulous->new( width => 80, height => 24, root => $root )->run;
