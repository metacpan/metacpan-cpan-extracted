#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
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

# The same points, connected six ways.
my @data = ( 2, 6, 3, 9, 8, 4, 5 );
foreach my $curve (qw(linear step monotone catmull-rom ease-in-out-sine ease-out-bounce)) {
	$root->add_child(
		Term::Fabulous::Widget::LineChart->new(
			title  => $curve,
			curve  => $curve,
			points => 1,
			x_axis => { visible => 0 },
			y_axis => { visible => 0, min => 0, max => 10 },
			series => [ { name => $curve, data => \@data } ],
			layout => { sizing => { width => sizing_percent(0.31), height => sizing_percent(0.47) } },
		)
	);
}

Term::Fabulous->new( root => $root, width => 100, height => 26 )->run;
