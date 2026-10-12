#!/usr/bin/env perl

# Term::Fabulous::Widget::BarChart: revenue per quarter of two years as
# grouped bars with their values. Move the mouse over a bar to emphasize
# its year; Ctrl+C quits.
#
#     perl examples/widgets/bar-chart.pl

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
use Term::Fabulous::Widget::BarChart;

use Clay::XS qw(sizing_grow);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		sizing  => { width => sizing_grow(), height => sizing_grow() },
		padding => { left  => 2, right => 2, top => 1, bottom => 1 },
	},
);

my $chart = Term::Fabulous::Widget::BarChart->new(
	title        => 'Revenue by quarter',
	labels       => [qw(Q1 Q2 Q3 Q4)],
	value_labels => 1,
	y_axis       => { title => 'million EUR' },
	series       => [
		{ name => '2025', data => [ 42.5, 51.2, 48.0, 63.4 ] },
		{ name => '2026', data => [ 47.1, 58.3, 61.0, 72.2 ] },
	],
);
$root->add_child($chart);

Term::Fabulous->new( width => 80, height => 24, root => $root )->run;
