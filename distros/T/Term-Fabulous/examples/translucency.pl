#!/usr/bin/env perl

# Translucent backgrounds. Three bordered boxes with half-transparent
# colors orbit the center of a screen full of text. Their backgrounds are
# blended with the text below them, and glyphs_show_through decides what
# becomes of that text: it shows through, tinted, or is covered.
#
# The demo also shows what cannot be blended: the bottom row has no
# background, so over the terminal's default color a box is drawn opaque;
# and a box edge that lands on the second cell of a wide glyph (CJK, emoji)
# cuts that glyph, like any paint over such a cell does.
#
#     perl examples/translucency.pl
#
# Space pauses the orbit, g toggles glyphs_show_through on every box, q
# or Ctrl+C quits.

use v5.32;
use warnings;
use strict;
use utf8;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../lib/";

use IO::Async::Loop;
use IO::Async::Timer::Periodic;
use List::Util qw(max);
use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::ScrollBox;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Enum::BorderStyle;
use Clay::XS qw(sizing_grow sizing_fit sizing_fixed CLAY_TOP_TO_BOTTOM CLAY_ATTACH_TO_PARENT CLAY_ATTACH_POINT_LEFT_TOP);

use constant PI                => 4 * atan2( 1, 1 );
use constant FRAMES_PER_SECOND => 30;
use constant SECONDS_PER_ORBIT => 20;
use constant WORDS_IN_THE_TEXT => 1500;
use constant BOX_WIDTH         => 30;
use constant BOX_HEIGHT        => 6;

# Random text with a few wide words (two columns each) mixed in.
my @words = qw(
	terminal cell glyph border layout widget frame color alpha blend
	shadow buffer render target scissor canvas pointer focus event timer
	漢字 東京 🙂 naïve Grüße
);
srand(7);
my $text = join ' ', map { $words[ rand @words ] } 1 .. WORDS_IN_THE_TEXT;

my $page = Term::Fabulous::Widget::ScrollBox->new(
	id     => 'page',
	layout => {
		sizing  => { width => sizing_grow(), height => sizing_grow() },
		padding => { left  => 2, right => 2, top => 1, bottom => 1 },
	},
);
$page->add_child( Term::Fabulous::Widget::Text->new( text => $text, text_color => [ 190, 200, 215, 255 ] ) );

# No background: over the terminal's default color nothing can be blended.
my $footer = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_fit() }, padding => { left => 2, right => 2 } } );
$footer->add_child(
	Term::Fabulous::Widget::Text->new(
		text       => 'Space pauses, g toggles glyphs_show_through, q quits. This row has no background, so over it the boxes are opaque.',
		text_color => [ 150, 150, 150, 255 ],
	)
);

my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
$root->add_child( $page, $footer );

# Each orbiting box: its color, whether the text below shows through, and
# a second line that says what to look for.
my @orbit = (
	{ color => [ 60,  140, 255, 128 ], shows_through => 1, note => 'text below shows through, tinted' },
	{ color => [ 255, 90,  90,  128 ], shows_through => 0, note => 'text below is covered' },
	{ color => [ 120, 230, 120, 64 ],  shows_through => 1, note => 'alpha 64: a lighter tint' },
);
foreach my $box (@orbit) {
	$box->{title}  = Term::Fabulous::Widget::Text->new( text_color => [ 255, 240, 160, 255 ] );
	$box->{widget} = Term::Fabulous::Widget::Box->new(
		background_color    => $box->{color},
		glyphs_show_through => $box->{shows_through},
		bordered            => 1,
		border_style        => Term::Fabulous::Enum::BorderStyle->Round,
		border_color        => [ @{ $box->{color} }[ 0 .. 2 ], 255 ],
		layout              => {
			layout_direction => CLAY_TOP_TO_BOTTOM,
			sizing           => { width => sizing_fixed(BOX_WIDTH), height => sizing_fixed(BOX_HEIGHT) },
			padding          => { left  => 1, right => 1, top => 1 },
		},
		floating => {
			attach_to     => CLAY_ATTACH_TO_PARENT,
			attach_points => { element => CLAY_ATTACH_POINT_LEFT_TOP, parent => CLAY_ATTACH_POINT_LEFT_TOP },
		},
	);
	$box->{widget}->add_child( $box->{title}, Term::Fabulous::Widget::Text->new( text => $box->{note}, text_color => [ 255, 255, 255, 255 ] ) );
	$root->add_child( $box->{widget} );
}

sub show_titles () {
	$_->{title}->text( 'glyphs_show_through => ' . $_->{widget}->glyphs_show_through ) foreach @orbit;
	return;
}

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );

# Moves every box along an ellipse around the center of the screen, each a
# third of a turn apart. The offset is the box's top-left cell.
my $angle = 0;

sub place_boxes () {
	my ( $center_x, $center_y ) = ( $ui->width / 2, $ui->height / 2 );
	my $radius_x = max( 0, $center_x - BOX_WIDTH / 2 - 1 );
	my $radius_y = max( 0, $center_y - BOX_HEIGHT / 2 );
	foreach my $index ( 0 .. $#orbit ) {
		my $box_angle = $angle + $index * 2 * PI / @orbit;
		my $widget    = $orbit[$index]{widget};
		$widget->floating(
			{
				%{ $widget->floating },
				offset => {
					x => int( $center_x + $radius_x * cos($box_angle) - BOX_WIDTH / 2 + 0.5 ),
					y => int( $center_y + $radius_y * sin($box_angle) - BOX_HEIGHT / 2 + 0.5 ),
				},
			}
		);
	}
	return;
}

my $paused        = 0;
my %action_by_key = (
	'Space'  => sub { $paused = !$paused },
	'g'      => sub { $_->{widget}->glyphs_show_through( !$_->{widget}->glyphs_show_through ) foreach @orbit; show_titles() },
	'q'      => sub { $ui->loop->stop },
	'Ctrl+Q' => sub { $ui->loop->stop },
);
$root->on(
	KeyPress => sub ($event) {
		my $action = $action_by_key{ $event->key_name // '' } or return;
		$action->();
		return;
	}
);

my $orbit_timer = IO::Async::Timer::Periodic->new(
	interval       => 1 / FRAMES_PER_SECOND,
	first_interval => 0,
	on_tick        => sub {
		$angle += 2 * PI / ( SECONDS_PER_ORBIT * FRAMES_PER_SECOND ) unless $paused;
		place_boxes();
		return;
	},
);
$orbit_timer->start;
IO::Async::Loop->new->add($orbit_timer);

show_titles();
$ui->run;
