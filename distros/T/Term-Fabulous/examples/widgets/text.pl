#!/usr/bin/env perl

# Term::Fabulous::Widget::Text: text in any 24-bit color, wrapped at
# spaces to the width of its box and aligned within it, and text in any
# script, with wide characters and emoji taking two columns. Ctrl+C
# quits.
#
#     perl examples/widgets/text.pl

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
use Term::Fabulous::Widget::Text;

use Clay::XS qw(sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM CLAY_TEXT_ALIGN_CENTER CLAY_TEXT_ALIGN_RIGHT);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

sub state_row ( $state, $widget ) {
	my $label = Term::Fabulous::Widget::Box->new( width_group => 1 );
	$label->add_child( Term::Fabulous::Widget::Text->new( text => $state, text_color => [ 150, 160, 180, 255 ] ) );
	my $row = Term::Fabulous::Widget::Box->new( layout => { child_gap => 2 } );
	$row->add_child( $label, $widget );
	$root->add_child($row);
	return $widget;
}

my $words = Term::Fabulous::Widget::Box->new( layout => { child_gap => 2 } );
$words->add_child(
	map { Term::Fabulous::Widget::Text->new( text => $_->[0], text_color => $_->[1] ) } [ 'Red', [ 224, 108, 117, 255 ] ], [ 'Orange', [ 209, 154, 102, 255 ] ], [ 'Yellow', [ 229, 192, 123, 255 ] ],
	[ 'Green', [ 152, 195, 121, 255 ] ], [ 'Cyan', [ 86, 182, 194, 255 ] ], [ 'Blue', [ 97, 175, 239, 255 ] ], [ 'Violet', [ 198, 120, 221, 255 ] ]
);
state_row( 'colors', $words );

my $sentence = 'Text wraps at spaces to the width of its box, and each line can be aligned.';
my $columns  = Term::Fabulous::Widget::Box->new( layout => { child_gap => 3 } );
foreach my $alignment ( undef, CLAY_TEXT_ALIGN_CENTER, CLAY_TEXT_ALIGN_RIGHT ) {
	my $column = Term::Fabulous::Widget::Box->new( background_color => [ 30, 35, 50, 255 ], layout => { sizing => { width => sizing_fixed(18) } } );
	$column->add_child( Term::Fabulous::Widget::Text->new( text => $sentence, text_color => [ 220, 220, 220, 255 ], defined $alignment ? ( text_alignment => $alignment ) : () ) );
	$columns->add_child($column);
}
state_row( 'wrapped', $columns );

state_row( 'any script', Term::Fabulous::Widget::Text->new( text => 'Grüße · Ελληνικά · こんにちは · 안녕하세요 · 🙂🎉', text_color => [ 255, 255, 255, 255 ] ) );

Term::Fabulous->new( width => 80, height => 24, root => $root )->run;
