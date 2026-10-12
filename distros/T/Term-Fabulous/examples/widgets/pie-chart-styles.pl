#!/usr/bin/env perl

# Term::Fabulous::Widget::PieChart: one set of slices drawn four ways,
# with the characters each marker draws with, gaps between the slices,
# the labels or the values on the slices, sorting and a start angle.
# Ctrl+C quits.
#
#     perl examples/widgets/pie-chart-styles.pl

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
use Term::Fabulous::Widget::PieChart;

use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

my @data = ( [ Rent => 1200 ], [ Food => 450 ], [ Car => 300 ], [ Fun => 220 ] );

sub pie (%options) {
	return Term::Fabulous::Widget::PieChart->new( legend => 'none', data => [ map { [@$_] } @data ], %options );
}

sub chart_row (@charts) {
	my $row = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() }, child_gap => 4 } );
	$row->add_child(@charts);
	return $row;
}

$root->add_child(
	chart_row(
		pie( title => 'marker quadrant (default)' ),
		pie( title => 'marker sextant, gap', marker => 'sextant', gap => 1 ),
	),
	chart_row(
		pie( title => 'marker braille, slice_labels label', marker => 'braille', slice_labels => 'label' ),
		pie( title => 'marker half, value, start_angle 90, asc', marker => 'half', slice_labels => 'value', start_angle => 90, sort => 'asc' ),
	),
);

Term::Fabulous->new( width => 90, height => 32, root => $root )->run;
