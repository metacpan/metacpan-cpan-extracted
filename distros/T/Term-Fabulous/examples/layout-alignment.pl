#!/usr/bin/env perl

# child_alignment: nine boxes of the same size, each with one child,
# aligned with every combination of x (left, center, right) and y (top,
# center, bottom). Ctrl+C quits.
#
#     perl examples/layout-alignment.pl

use v5.32;
use warnings;
use strict;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../lib/";

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;

use Clay::XS qw(
	sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM
	CLAY_ALIGN_X_LEFT CLAY_ALIGN_X_CENTER CLAY_ALIGN_X_RIGHT
	CLAY_ALIGN_Y_TOP CLAY_ALIGN_Y_CENTER CLAY_ALIGN_Y_BOTTOM
);

my @X = ( [ left => CLAY_ALIGN_X_LEFT ], [ center => CLAY_ALIGN_X_CENTER ], [ right  => CLAY_ALIGN_X_RIGHT ] );
my @Y = ( [ top  => CLAY_ALIGN_Y_TOP ],  [ center => CLAY_ALIGN_Y_CENTER ], [ bottom => CLAY_ALIGN_Y_BOTTOM ] );

# A box of 24 by 5 cells whose child is aligned by $x and $y.
sub cell ( $x, $y ) {
	my ( $x_name, $x_value ) = @$x;
	my ( $y_name, $y_value ) = @$y;
	my $cell = Term::Fabulous::Widget::Box->new(
		background_color => [ 40, 46, 64, 255 ],
		layout           => {
			sizing          => { width => sizing_fixed(24), height => sizing_fixed(5) },
			child_alignment => { x     => $x_value,         y      => $y_value },
		},
	);
	my $child = Term::Fabulous::Widget::Box->new( background_color => [ 97, 175, 239, 255 ], layout => { padding => { left => 1, right => 1 } } );
	$child->add_child( Term::Fabulous::Widget::Text->new( text => "x=$x_name y=$y_name", text_color => [ 20, 25, 35, 255 ] ) );
	return $cell->add_child($child);
}

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

foreach my $y (@Y) {
	my $row = Term::Fabulous::Widget::Box->new( layout => { child_gap => 2 } );
	$row->add_child( map { cell( $_, $y ) } @X );
	$root->add_child($row);
}

Term::Fabulous->new( width => 80, height => 24, root => $root )->run;
