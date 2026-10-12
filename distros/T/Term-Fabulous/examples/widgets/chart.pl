#!/usr/bin/env perl

# Term::Fabulous::Widget::Chart: what every chart has, shown on four bar
# charts of the same data: the title aligned left, center and right, the
# legend at the top, the bottom, the left and the right, two palettes, a
# series emphasized with highlight, and a chart on a light panel that
# picks light-theme colors by itself. Move the mouse over a series to
# emphasize it; Ctrl+C quits.
#
#     perl examples/widgets/chart.pl

use v5.32;
use warnings;
use strict;
use utf8;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use Term::Fabulous;
use Term::Fabulous::Widget::BarChart;
use Term::Fabulous::Widget::Box;

use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

my @series = (
	{ name => 'web',     data => [ 12, 15, 19, 23 ] },
	{ name => 'iOS',     data => [ 8,  11, 12, 16 ] },
	{ name => 'Android', data => [ 6,  9,  13, 17 ] },
);

sub chart (%options) {
	return Term::Fabulous::Widget::BarChart->new(
		labels => [qw(Q1 Q2 Q3 Q4)],
		series => [
			map {
				{ %$_ }
			} @series
		],
		%options
	);
}

sub chart_row (@children) {
	my $row = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() }, child_gap => 4 } );
	$row->add_child(@children);
	return $row;
}

# A chart on a light panel: no theme given, it reads the background.
my $light = Term::Fabulous::Widget::Box->new(
	background_color => [ 246, 246, 242, 255 ],
	layout           => { sizing => { width => sizing_grow(), height => sizing_grow() }, padding => { left => 2, right => 2, top => 1 } },
);
$light->add_child( chart( title => 'Light panel, legend left', title_align => 'right', legend => 'left', palette => 'classic' ) );

$root->add_child(
	chart_row(
		chart( title => 'Legend at the top (auto)' ),
		chart( title => 'Centered, legend at the bottom', title_align => 'center', legend => 'bottom', palette => 'vivid' ),
	),
	chart_row(
		chart( title => 'Legend right, highlight "iOS"', legend => 'right', highlight => 'iOS' ),
		$light,
	),
);

Term::Fabulous->new( width => 100, height => 32, root => $root )->run;
