#!/usr/bin/env perl

use v5.32;
use warnings;
use strict;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../lib/";

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::PixelCanvas;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_LEFT TB_KEY_MOUSE_RIGHT);

use Clay::XS qw(:all);

my @palette = ( 0xFFFFFF, 0xFF5050, 0xFFC832, 0x50DC64, 0x50A0FF, 0xC878FF );
my $brush   = 0;

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

$root->add_child(
	Term::Fabulous::Widget::Text->new(
		text       => 'Left button paints, right button erases, 1-6 pick a color, c clears  (Ctrl+C to quit)',
		text_color => [ 220, 220, 220, 255 ],
	)
);

my $image = Term::Fabulous::Widget::PixelCanvas->new(
	background_color => [ 8, 10, 16, 255 ],
	bordered         => 1,
	border_color     => [ 120, 160, 220, 255 ],
	border_style     => Term::Fabulous::Enum::BorderStyle->Round,
	layout           => { sizing => { width => sizing_grow(), height => sizing_grow() } },
);
$root->add_child($image);

sub draw_shapes () {
	my ( $width, $height ) = ( $image->pixel_width, $image->pixel_height );
	$image->clear;
	$image->draw_rect( 0, 0, $width, $height, 0x304060 );
	$image->draw_line( 0, $height - 1, $width - 1, 0, 0x50DC64 );
	$image->draw_circle( $width / 2, $height / 2, $height / 3, 0xFFC832 );
	$image->fill_rect( 4, 4, 10, 6, 0x50A0FF );
	return;
}

$image->on( CanvasResize => sub ($event) { draw_shapes(); return } );

# The terminal reports the pointer per cell, which holds two pixels: the
# brush paints both. Dragging repeats the button's key with a motion flag.
$image->on(
	Mouse => sub ($event) {
		my $key = $event->key;
		return unless $key == TB_KEY_MOUSE_LEFT || $key == TB_KEY_MOUSE_RIGHT;
		my ( $x, $y ) = $image->pixel_at($event) or return;
		my $color = $key == TB_KEY_MOUSE_LEFT ? $palette[$brush] : undef;
		$image->set_pixel( $x, $y, $color )->set_pixel( $x, $y + 1, $color );
		return;
	}
);

$root->on(
	KeyPress => sub ($event) {
		my $char = chr $event->char;
		$brush = $char - 1 if $char =~ /\A[1-6]\z/;
		draw_shapes() if $char eq 'c';
		return;
	}
);

Term::Fabulous->new( width => 80, height => 24, root => $root )->run;
