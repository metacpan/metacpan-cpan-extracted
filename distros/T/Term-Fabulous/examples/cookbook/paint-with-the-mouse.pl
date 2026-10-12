#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Canvas;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_LEFT TB_KEY_MOUSE_RIGHT TB_MOD_MOTION);
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);
my $help   = Term::Fabulous::Widget::Text->new( text => 'Left button draws, right button erases. Drag to draw lines.', text_color => [ 230, 230, 230, 255 ] );
my $canvas = Term::Fabulous::Widget::Canvas->new(
	background_color => [ 10, 12, 20, 255 ],
	bordered         => 1,
	border_style     => Term::Fabulous::Enum::BorderStyle->Round,
	border_color     => [ 120, 160, 220, 255 ],
	layout           => { sizing => { width => sizing_grow(), height => sizing_grow() } },
);
$root->add_child( $help, $canvas );

$canvas->on(
	Mouse => sub ($event) {
		my $key = $event->key;
		return unless $key == TB_KEY_MOUSE_LEFT || $key == TB_KEY_MOUSE_RIGHT;

		# cell_at turns the pointer position into a cell of the canvas, or
		# the empty list when the pointer is on the border.
		my ( $x, $y ) = $canvas->cell_at($event) or return;
		my $dragging = $event->modifiers & TB_MOD_MOTION;

		if ( $key == TB_KEY_MOUSE_RIGHT ) {
			$canvas->erase( $x, $y );
		}
		else {
			$canvas->put( $x, $y, $dragging ? '*' : 'o', $dragging ? 0xFFC832 : 0x50DC64 );
		}
		return;
	}
);

Term::Fabulous->new( root => $root, width => 80, height => 24 )->run;
