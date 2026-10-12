#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous::Static;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my $Style = 'Term::Fabulous::Enum::BorderStyle';

sub panel ( $title, %border ) {
	my $box = Term::Fabulous::Widget::Box->new(
		border_color => [ 120, 180, 240, 255 ],
		layout       => { sizing => { width => sizing_grow() }, padding => { left => 1, right => 1 } },
		%border,
	);
	$box->add_child( Term::Fabulous::Widget::Text->new( text => $title, text_color => [ 230, 230, 230, 255 ] ) );
	return $box;
}

my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow() }, child_gap => 1 } );

# Lines above and below only: no left and right border.
my $rules = panel(
	'Rules above and below',
	bordered            => { top => 1, bottom => 1 },
	border_style_top    => $Style->Double,
	border_style_bottom => $Style->Solid,
);

# A box with a heavy top edge. border_style sets the sides that have no
# style of their own.
my $header = panel( 'Heavy top edge', bordered => 1, border_style => $Style->Solid, border_style_top => $Style->Heavy );

# A tab-like look: thick left edge only.
my $marker = panel( 'Thick left edge', bordered => { left => 1 }, border_style_left => $Style->Thick );

$root->add_child( $rules, $header, $marker );
Term::Fabulous::Static->new( root => $root, width => 32 )->print( colors => 0 );
