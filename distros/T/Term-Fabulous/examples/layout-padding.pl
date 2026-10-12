#!/usr/bin/env perl

# Padding, the gap between children and the space a border takes: the
# same three children in boxes with different settings. The boxes have a
# background, so their padding and gaps are visible. Ctrl+C quits.
#
#     perl examples/layout-padding.pl

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

use Clay::XS qw(sizing_grow padding_all CLAY_TOP_TO_BOTTOM);

my @COLORS = ( [ 97, 175, 239, 255 ], [ 152, 195, 121, 255 ], [ 229, 192, 123, 255 ] );

# A caption above a box with the given parameters, holding three children.
sub demo ( $caption, $layout, %parameters ) {
	my $box = Term::Fabulous::Widget::Box->new(
		background_color => [ 60, 68, 92, 255 ],
		layout           => { layout_direction => CLAY_TOP_TO_BOTTOM, %$layout },
		%parameters,
	);
	foreach my $index ( 0 .. 2 ) {
		my $child = Term::Fabulous::Widget::Box->new( background_color => $COLORS[$index], layout => { padding => { left => 1, right => 1 } } );
		$box->add_child( $child->add_child( Term::Fabulous::Widget::Text->new( text => "child " . ( $index + 1 ), text_color => [ 20, 25, 35, 255 ] ) ) );
	}

	my $column = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow() } } );
	$column->add_child( map { Term::Fabulous::Widget::Text->new( text => $_, text_color => [ 220, 220, 220, 255 ] ) } @$caption );
	return $column->add_child($box);
}

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		sizing    => { width => sizing_grow(), height => sizing_grow() },
		padding   => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap => 2,
	},
);

$root->add_child(
	demo( [ 'no padding',            'child_gap 0' ],               {} ),
	demo( [ 'padding left/right 2,', 'top/bottom 1, child_gap 1' ], { padding => { left => 2, right => 2, top => 1, bottom => 1 }, child_gap => 1 } ),
	demo(
		[ 'bordered and', 'padding_all(1)' ],
		{ padding => padding_all(1) },
		bordered     => 1,
		border_color => [ 255, 255, 255, 255 ],
		border_style => Term::Fabulous::Enum::BorderStyle->Round,
	),
);

Term::Fabulous->new( width => 80, height => 24, root => $root )->run;
