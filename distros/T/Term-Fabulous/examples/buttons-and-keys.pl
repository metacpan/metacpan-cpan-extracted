#!/usr/bin/env perl

# Buttons that react to the mouse and the keyboard, application key
# bindings and a clock that a timer updates once per second.
#
#     perl examples/buttons-and-keys.pl

use v5.32;
use warnings;
use strict;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../lib/";

use IO::Async::Loop;
use IO::Async::Timer::Periodic;
use POSIX qw(strftime);
use Term::Fabulous;
use Term::Fabulous::Color;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Button;
use Term::Fabulous::Widget::Text;

use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my $button_color = Term::Fabulous::Color->new( color => '#2b3a55' );
my $hover_color  = $button_color->lighten(0.15);
my $border_color = Term::Fabulous::Color->new( color => '#5a6b8c' );

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

sub label ( $text, $color = [ 220, 220, 220, 255 ] ) {
	return Term::Fabulous::Widget::Text->new( text => $text, text_color => $color );
}

my $clock   = label( 'Time: --:--:--', [ 150, 160, 180, 255 ] );
my $counter = label('Counter: 0');
my $status  = label('Tab focuses a button, Enter or Space presses it, or click one. + - r change the counter, q, Escape or Ctrl+Q quits.');
$root->add_child( $clock, $counter );

my $count = 0;

sub set_count ($new) {
	$count = $new;
	$counter->text("Counter: $count");
	return;
}

# A Button shows its state by itself: its border takes the focus color
# while it has the focus, and its colors are swapped while the mouse
# button is held on it. The pointer is reported as it moves, so
# OnHoverStart and OnHoverStopped follow the mouse; here they lighten the
# background. Activate fires for a click and for Enter or Space while the
# button has the focus.
sub button ( $id, $caption, $action ) {
	my $button = Term::Fabulous::Widget::Button->new(
		id               => $id,
		background_color => $button_color,
		border_color     => $border_color,
		bordered         => 1,
		border_style     => Term::Fabulous::Enum::BorderStyle->Round,
		layout           => { padding => { left => 1, right => 1 } },
	);
	$button->add_child( label($caption) );

	$button->on( OnHoverStart   => sub ($event) { $button->background_color($hover_color);  return } );
	$button->on( OnHoverStopped => sub ($event) { $button->background_color($button_color); return } );
	$button->on( Activate       => sub ($event) { $action->();                              return } );
	return $button;
}

my $buttons = Term::Fabulous::Widget::Box->new( layout => { child_gap => 2 } );
$buttons->add_child(
	button( increase => 'Increase', sub { set_count( $count + 1 ) } ),
	button( decrease => 'Decrease', sub { set_count( $count - 1 ) } ),
	button( reset    => 'Reset',    sub { set_count(0) } ),
);
$root->add_child( $buttons, $status );

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );

# Application shortcuts. KeyPress reaches the root when nothing has the
# focus, or when the focused widget's listeners let it bubble; a Button
# keeps only Enter and Space for itself. Alt plus a letter arrives as one
# key (Alt+x), so binding Escape does not catch Alt combinations.
my %action_by_key = (
	'+'      => sub { set_count( $count + 1 ) },
	'-'      => sub { set_count( $count - 1 ) },
	'r'      => sub { set_count(0) },
	'q'      => sub { $ui->loop->stop },
	'Escape' => sub { $ui->loop->stop },
	'Ctrl+Q' => sub { $ui->loop->stop },
);
$root->on(
	KeyPress => sub ($event) {
		my $action = $action_by_key{ $event->key_name // '' } or return;
		$action->();
		return;
	}
);

# A frame is drawn whenever a widget changed, so changing the text is all
# the timer has to do.
my $timer = IO::Async::Timer::Periodic->new(
	interval       => 1,
	first_interval => 0,
	on_tick        => sub { $clock->text( strftime( 'Time: %H:%M:%S', localtime ) ); return },
);
$timer->start;
IO::Async::Loop->new->add($timer);

$ui->run;
