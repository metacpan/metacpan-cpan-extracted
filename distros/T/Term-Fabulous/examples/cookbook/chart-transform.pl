#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::LineChart;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

# Noisy daily visits for 120 days, with a weekly rhythm.
srand 3;
my @visits = map { 300 + 2 * $_ + 60 * sin( $_ * 6.283 / 7 ) + ( rand() - 0.5 ) * 160 } 0 .. 119;

# The same data three times: as it is, and smoothed two ways. The data
# given stays as it is; only what is drawn is prepared.
$root->add_child(
	Term::Fabulous::Widget::LineChart->new(
		title  => 'Daily visits',
		series => [
			{ name => 'Raw',            data => \@visits, color     => '#3a4152' },
			{ name => '7-day average',  data => \@visits, transform => [ [ 'moving_average', 7 ] ] },
			{ name => 'Smoothed (0.1)', data => \@visits, transform => [ [ 'exponential',    0.1 ] ], line_style => 'dashed' },
		],
	)
);

# Two prices of very different size, both indexed to 100 at the start,
# so their growth compares on one axis.
my @shares = map { 1200 + 4 * $_ + 80 * sin( $_ / 9 ) } 0 .. 119;
my @bonds  = map { 96 + 0.05 * $_ + 2 * sin( $_ / 15 ) } 0 .. 119;
$root->add_child(
	Term::Fabulous::Widget::LineChart->new(
		title     => 'Growth since day 1 (day 1 = 100)',
		transform => [ [ 'index', 100 ] ],
		curve     => 'monotone',
		series    => [ { name => 'Shares', data => \@shares }, { name => 'Bonds', data => \@bonds } ],
	)
);

Term::Fabulous->new( root => $root, width => 90, height => 30 )->run;
