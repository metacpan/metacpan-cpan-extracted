#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::PolarAreaChart;
use Term::Fabulous::Widget::RadarChart;
use Clay::XS qw(sizing_grow);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		sizing    => { width => sizing_grow(), height => sizing_grow() },
		padding   => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap => 2,
	},
);

# One axis per label; each series has a value per axis. A 'line' series
# is not filled.
$root->add_child(
	Term::Fabulous::Widget::RadarChart->new(
		title  => 'Player stats',
		labels => [qw(Pace Shooting Passing Dribbling Defense Physical)],
		min    => 0,
		max    => 100,
		grid   => 'circle',
		series => [
			{ name => 'Striker',  data => [ 89, 91, 72, 86, 38, 77 ] },
			{ name => 'Defender', data => [ 71, 45, 68, 62, 90, 86 ] },
			{ name => 'Average',  data => [ 70, 60, 65, 66, 60, 70 ], type => 'line', line_style => 'dashed', color => '#898781' },
		],
	)
);

# Slices of equal angle; their length shows the value.
$root->add_child(
	Term::Fabulous::Widget::PolarAreaChart->new(
		title       => 'Rain per season (mm)',
		data        => [ [ Spring => 170 ], [ Summer => 210 ], [ Autumn => 260 ], [ Winter => 190 ] ],
		start_angle => -45,
	)
);

Term::Fabulous->new( root => $root, width => 100, height => 26 )->run;
