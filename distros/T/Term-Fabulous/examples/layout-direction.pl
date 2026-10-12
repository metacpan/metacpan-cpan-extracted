#!/usr/bin/env perl

# The four layout directions side by side: the same numbered boxes
# placed left to right, top to bottom, left to right with wrapping, and
# on top of each other. Ctrl+C quits.
#
#     perl examples/layout-direction.pl

use v5.32;
use warnings;
use strict;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../lib/";

use Term::Fabulous;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;

use Clay::XS qw(
	sizing_grow sizing_fixed
	CLAY_LEFT_TO_RIGHT CLAY_TOP_TO_BOTTOM CLAY_LEFT_TO_RIGHT_WRAP CLAY_BACK_TO_FRONT
	CLAY_ALIGN_X_RIGHT CLAY_ALIGN_Y_BOTTOM
);

my @COLORS = ( [ 97, 175, 239, 255 ], [ 152, 195, 121, 255 ], [ 229, 192, 123, 255 ], [ 198, 120, 221, 255 ], [ 224, 108, 117, 255 ] );

# A colored box with a label, one cell of padding left and right.
sub item ( $label, $color, $sizing = {} ) {
	my $item = Term::Fabulous::Widget::Box->new(
		background_color => $color,
		layout           => { sizing => $sizing, padding => { left => 1, right => 1 } },
	);
	return $item->add_child( Term::Fabulous::Widget::Text->new( text => $label, text_color => [ 20, 25, 35, 255 ] ) );
}

# A framed panel with a caption, holding a box with the given layout keys.
sub panel ( $caption, $layout, @items ) {
	my $frame = Term::Fabulous::Widget::Box->new(
		layout => {
			layout_direction => CLAY_TOP_TO_BOTTOM,
			sizing           => { width => sizing_grow(), height => sizing_grow() },
			padding          => { left  => 1,             right  => 1 },
			child_gap        => 1,
		},
		background_color => [ 30, 35, 50, 255 ],
		bordered         => 1,
		border_color     => [ 120, 160, 220, 255 ],
		border_style     => Term::Fabulous::Enum::BorderStyle->Round,
	);
	my $content = Term::Fabulous::Widget::Box->new(
		layout => { sizing => { width => sizing_grow() }, child_gap => 1, %$layout },
	);
	$content->add_child(@items);
	return $frame->add_child( Term::Fabulous::Widget::Text->new( text => $caption, text_color => [ 255, 255, 255, 255 ] ), $content );
}

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 1,             right  => 1 },
		child_gap        => 1,
	},
);

my $top    = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() }, child_gap => 1 } );
my $bottom = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() }, child_gap => 1 } );

$top->add_child(
	panel( 'CLAY_LEFT_TO_RIGHT (right)', { layout_direction => CLAY_LEFT_TO_RIGHT }, map { item( $_, $COLORS[ $_ - 1 ] ) } 1 .. 3 ),
	panel( 'CLAY_TOP_TO_BOTTOM (down)',  { layout_direction => CLAY_TOP_TO_BOTTOM }, map { item( $_, $COLORS[ $_ - 1 ] ) } 1 .. 3 ),
);
$bottom->add_child(
	panel( 'CLAY_LEFT_TO_RIGHT_WRAP (wrap)', { layout_direction => CLAY_LEFT_TO_RIGHT_WRAP }, map { item( "item $_", $COLORS[ ( $_ - 1 ) % @COLORS ] ) } 1 .. 7 ),
	panel(
		'CLAY_BACK_TO_FRONT (stack)',

		# Aligned to the bottom right, so the label of every box stays visible.
		{ layout_direction => CLAY_BACK_TO_FRONT, child_alignment => { x => CLAY_ALIGN_X_RIGHT, y => CLAY_ALIGN_Y_BOTTOM } },
		item( '1', $COLORS[0], { width => sizing_fixed(24), height => sizing_fixed(4) } ),
		item( '2', $COLORS[1], { width => sizing_fixed(14), height => sizing_fixed(3) } ),
		item( '3', $COLORS[2], { width => sizing_fixed(6),  height => sizing_fixed(2) } ),
	),
);
$root->add_child( $top, $bottom );

Term::Fabulous->new( width => 80, height => 24, root => $root )->run;
