#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::AreaChart;
use Term::Fabulous::Widget::BarChart;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::LineChart;
use Clay::XS qw(sizing_grow sizing_percent CLAY_LEFT_TO_RIGHT_WRAP);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_LEFT_TO_RIGHT_WRAP,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 3,
		line_gap         => 1,
	},
);

my @wave   = map { 5 + 2 * sin( $_ / 2 ) } 0 .. 12;
my @labels = qw(Mon Tue Wed Thu Fri);
my %small  = ( layout => { sizing => { width => sizing_percent(0.31), height => sizing_percent(0.48) } } );

# Three line styles.
$root->add_child(
	Term::Fabulous::Widget::LineChart->new(
		%small,
		title  => 'line_style',
		series => [
			{ name => 'solid',  data => [ map { $_ + 3 } @wave ] },
			{ name => 'dashed', data => \@wave,                   line_style => 'dashed' },
			{ name => 'dotted', data => [ map { $_ - 3 } @wave ], line_style => 'dotted' },
		],
	)
);

# Missing values: a gap, or a line across it.
my @holes = map { $_ >= 5 && $_ <= 7 ? undef : $wave[$_] } 0 .. $#wave;
$root->add_child(
	Term::Fabulous::Widget::LineChart->new(
		%small,
		title  => 'gaps and span_gaps',
		series => [
			{ name => 'gap', data => [ map { defined ? $_ + 2 : undef } @holes ] },
			{ name => 'span_gaps', data => [ map { defined ? $_ - 2 : undef } @holes ], span_gaps => 1 },
		],
	)
);

# An area with a line along its top and a mark on every point.
$root->add_child(
	Term::Fabulous::Widget::AreaChart->new(
		%small,
		title  => 'area: line and points',
		line   => 1,
		points => 1,
		series => [ { name => 'visits', data => [ 3, 6, 4, 8, 7, 9, 6 ] } ],
	)
);

# Narrow bars: together they take 0.4 of their slot.
$root->add_child(
	Term::Fabulous::Widget::BarChart->new(
		%small,
		title     => 'bar_width 0.4',
		bar_width => 0.4,
		labels    => \@labels,
		series    => [ { name => 'orders', data => [ 18, 24, 21, 30, 34 ] } ],
	)
);

# Two stack groups side by side in every slot.
$root->add_child(
	Term::Fabulous::Widget::BarChart->new(
		%small,
		title  => 'stack groups',
		labels => [qw(Q1 Q2 Q3)],
		series => [
			{ name => 'shop 2025', data => [ 12, 15, 11 ], stack => '2025' },
			{ name => 'app 2025',  data => [ 6,  8,  9 ],  stack => '2025' },
			{ name => 'shop 2026', data => [ 14, 16, 15 ], stack => '2026' },
			{ name => 'app 2026',  data => [ 9,  12, 14 ], stack => '2026' },
		],
	)
);

# Grid lines at the ticks of both axes.
$root->add_child(
	Term::Fabulous::Widget::LineChart->new(
		%small,
		title  => 'grid',
		x_axis => { grid => 'dashed' },
		y_axis => { grid => 'solid' },
		series => [ { name => 'wave', data => \@wave } ],
	)
);

Term::Fabulous->new( root => $root, width => 100, height => 30 )->run;
