#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::AreaChart;
use Term::Fabulous::Widget::Box;
use Clay::XS qw(sizing_grow);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		sizing    => { width => sizing_grow(), height => sizing_grow() },
		padding   => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap => 4,
	},
);

my @years  = 2016 .. 2026;
my @series = (
	{ name => 'Coal',  data => [ 41, 40, 38, 37, 35, 36, 35, 33, 31, 29, 27 ] },
	{ name => 'Gas',   data => [ 22, 23, 23, 24, 24, 23, 22, 22, 22, 21, 21 ] },
	{ name => 'Wind',  data => [ 7,  8,  9,  10, 12, 12, 14, 16, 17, 19, 21 ] },
	{ name => 'Solar', data => [ 2,  2,  3,  3,  4,  5,  6,  8,  10, 12, 14 ] },
);

# The parts add up to the total...
$root->add_child(
	Term::Fabulous::Widget::AreaChart->new(
		title   => 'Electricity (TWh)',
		labels  => \@years,
		stacked => 1,
		curve   => 'monotone',
		series  => \@series,
	)
);

# ... or to 100 %: each part's share of the total, year by year.
$root->add_child(
	Term::Fabulous::Widget::AreaChart->new(
		title   => 'Share of the mix',
		labels  => \@years,
		stacked => 'percent',
		curve   => 'monotone',
		legend  => 'none',
		series  => \@series,
	)
);

Term::Fabulous->new( root => $root, width => 100, height => 22 )->run;
