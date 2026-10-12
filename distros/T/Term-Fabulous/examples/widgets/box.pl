#!/usr/bin/env perl

# Term::Fabulous::Widget::Box, the container every layout is built from:
# a card with a border, a background, padding and a gap between its
# children, and a row of boxes that size themselves in three ways.
# Ctrl+C quits.
#
#     perl examples/widgets/box.pl

use v5.32;
use warnings;
use strict;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use Term::Fabulous;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;

use Clay::XS qw(sizing_grow sizing_fit sizing_fixed CLAY_TOP_TO_BOTTOM);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

# A card: a column of children, one cell of padding left and right and a
# gap of one row between them, inside a rounded border.
my $card = Term::Fabulous::Widget::Box->new(
	id     => 'card',
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_fit() },
		padding          => { left  => 1,             right  => 1 },
		child_gap        => 1,
	},
	background_color => [ 30, 35, 50, 255 ],
	bordered         => 1,
	border_color     => [ 97, 175, 239, 255 ],
	border_style     => Term::Fabulous::Enum::BorderStyle->Round,
);
$card->add_child(
	Term::Fabulous::Widget::Text->new( text => 'Title',                                                   text_color => [ 255, 255, 255, 255 ] ),
	Term::Fabulous::Widget::Text->new( text => 'Body text: a Box holds other widgets and lays them out.', text_color => [ 200, 205, 215, 255 ] ),
);

# A row of boxes: one as wide as its content, one that takes the room
# left over, and one of a fixed width.
my $row = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow() }, child_gap => 2 } );
foreach my $sample ( [ 'fit', sizing_fit(), [ 152, 195, 121, 255 ] ], [ 'grow', sizing_grow(), [ 97, 175, 239, 255 ] ], [ 'fixed(14)', sizing_fixed(14), [ 229, 192, 123, 255 ] ] ) {
	my ( $caption, $width, $color ) = @$sample;
	my $box = Term::Fabulous::Widget::Box->new(
		background_color => [ map( { int( $_ * 0.35 ) } @{$color}[ 0 .. 2 ] ), 255 ],
		bordered         => 1,
		border_color     => $color,
		border_style     => Term::Fabulous::Enum::BorderStyle->Solid,
		layout           => { sizing => { width => $width }, padding => { left => 1, right => 1 } },
	);
	$box->add_child( Term::Fabulous::Widget::Text->new( text => $caption, text_color => [ 255, 255, 255, 255 ] ) );
	$row->add_child($box);
}

$root->add_child( $card, $row );

Term::Fabulous->new( width => 80, height => 24, root => $root )->run;
