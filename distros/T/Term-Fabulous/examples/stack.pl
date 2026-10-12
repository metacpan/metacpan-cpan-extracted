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
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Enum::BorderStyle;

use Clay::XS qw(:all);

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
		text       => 'Stacked children share one box  (Ctrl+C to quit)',
		text_color => [ 220, 220, 220, 255 ],
	)
);

# A card: a bordered panel with a badge drawn over its top right corner.
# The panel fills the stack, so the badge needs no position of its own.
sub card ( $title, $lines, $badge, $badge_color ) {
	my $stack = Term::Fabulous::Widget::Box->new(
		layout => {
			layout_direction => CLAY_BACK_TO_FRONT,
			sizing           => { width => sizing_grow(),      height => sizing_grow() },
			child_alignment  => { x     => CLAY_ALIGN_X_RIGHT, y      => CLAY_ALIGN_Y_TOP },
		},
	);
	my $panel = Term::Fabulous::Widget::Box->new(
		layout => {
			layout_direction => CLAY_TOP_TO_BOTTOM,
			sizing           => { width => sizing_grow(), height => sizing_grow() },
			padding          => { left  => 1,             right  => 1 },
		},
		background_color => [ 30, 35, 50, 255 ],
		bordered         => 1,
		border_color     => [ 120, 160, 220, 255 ],
		border_style     => Term::Fabulous::Enum::BorderStyle->Round,
	);
	$panel->add_child( Term::Fabulous::Widget::Text->new( text => $title, text_color => [ 255, 255, 255, 255 ] ) );
	$panel->add_child( Term::Fabulous::Widget::Text->new( text => $_,     text_color => [ 170, 180, 200, 255 ] ) ) for @$lines;

	my $tag = Term::Fabulous::Widget::Box->new(
		layout           => { padding => { left => 1, right => 1 } },
		background_color => $badge_color,
	);
	$tag->add_child( Term::Fabulous::Widget::Text->new( text => $badge, text_color => [ 20, 25, 35, 255 ] ) );

	return $stack->add_child( $panel, $tag );
}

my $cards = Term::Fabulous::Widget::Box->new(
	layout => { sizing => { width => sizing_grow() }, child_gap => 2 },
);
$cards->add_child(
	card( 'Inbox',  [ '12 unread',   '3 flagged' ], '12',  [ 224, 108, 117, 255 ] ),
	card( 'Builds', [ 'main: green', 'dev: red' ],  'new', [ 152, 195, 121, 255 ] ),
	card( 'Queue',  ['idle'], '0', [ 229, 192, 123, 255 ] ),
);
$root->add_child($cards);

# A message centered over a log: the log grows to fill the stack, and the
# stack's child_alignment centers the message on top of it.
my $overlay = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_BACK_TO_FRONT,
		sizing           => { width => sizing_grow(),       height => sizing_grow() },
		child_alignment  => { x     => CLAY_ALIGN_X_CENTER, y      => CLAY_ALIGN_Y_CENTER },
	},
);
my $log = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 1,             right  => 1 },
	},
	background_color => [ 30, 35, 50, 255 ],
);
$log->add_child(
	Term::Fabulous::Widget::Text->new(
		text       => sprintf( '09:41:%02d  worker %d finished job %d', $_ * 7 % 60, $_ % 3 + 1, 400 + $_ ),
		text_color => [ 110, 120, 140, 255 ],
	)
) for 1 .. 8;

my $message = Term::Fabulous::Widget::Box->new(
	layout => {
		padding         => { left => 2, right => 2, top => 1, bottom => 1 },
		child_alignment => { x    => CLAY_ALIGN_X_CENTER },
	},
	background_color => [ 40, 46, 64, 255 ],
	bordered         => 1,
	border_color     => [ 152, 195, 121, 255 ],
	border_style     => Term::Fabulous::Enum::BorderStyle->Round,
);
$message->add_child( Term::Fabulous::Widget::Text->new( text => 'All jobs done', text_color => [ 255, 255, 255, 255 ] ) );
$overlay->add_child( $log, $message );
$root->add_child($overlay);

Term::Fabulous->new( width => 80, height => 24, root => $root )->run;
