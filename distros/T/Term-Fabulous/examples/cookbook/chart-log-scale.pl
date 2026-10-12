#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::LineChart;
use Clay::XS qw(sizing_grow);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		sizing    => { width => sizing_grow(), height => sizing_grow() },
		padding   => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap => 4,
	},
);

# Values from a few to many thousands: on a linear axis the small ones
# lie flat on the floor...
my @series = (
	{ name => 'Downloads', data => [ 12, 40, 150, 610, 2400, 9800, 31000, 88000 ] },
	{ name => 'Issues',    data => [ 2,  5,  14,  30,  71,   160,  390,   900 ] },
);
my @years = 2019 .. 2026;
$root->add_child( Term::Fabulous::Widget::LineChart->new( title => 'Linear axis', labels => \@years, points => 1, series => \@series ) );

# ... on a logarithmic one every factor of ten takes the same room, and
# steady growth is a straight line.
$root->add_child(
	Term::Fabulous::Widget::LineChart->new(
		title  => 'Logarithmic axis',
		labels => \@years,
		points => 1,
		y_axis => { type => 'log' },
		series => \@series,
	)
);

Term::Fabulous->new( root => $root, width => 100, height => 20 )->run;
