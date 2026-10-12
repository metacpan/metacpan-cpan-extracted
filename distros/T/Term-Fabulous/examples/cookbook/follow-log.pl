#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use IO::Async::Loop;
use IO::Async::Timer::Periodic;
use List::Util qw(min);
use Term::Fabulous;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::ScrollBox;
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 1,             right  => 1 },
	},
);
$root->add_child(
	Term::Fabulous::Widget::Text->new(
		text       => 'Wheel or Up/Down scroll, Left/Right scroll sideways, Home goes to the top, End follows the newest line.',
		text_color => [ 230, 230, 230, 255 ],
	)
);

my $log = Term::Fabulous::Widget::ScrollBox->new(
	id               => 'log',
	horizontal       => 1,    # vertical scrolling is on by default
	background_color => [ 30, 35, 50, 255 ],
	bordered         => 1,
	border_color     => [ 120, 160, 220, 255 ],
	border_style     => Term::Fabulous::Enum::BorderStyle->Round,
	layout           => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
	},
);
$root->add_child($log);

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );

# scroll_state describes the last frame: the scroll position, the visible
# size of the box (viewport) and the size of its content. The position is
# 0 at the top and left and negative when scrolled down or right; the
# lowest one shows the bottom of the content.
sub lowest_y ($state) { return min( 0, $state->{viewport}{height} - $state->{content}{height} ) }

# Moves the view; scroll_to keeps it within the content.
sub scroll_by ( $columns, $rows ) {
	my $state = $ui->scroll_state($log) or return;    # not laid out yet
	$ui->scroll_to( $log, { x => $state->{position}{x} - $columns, y => $state->{position}{y} - $rows } );
	return;
}

# Follow the newest line until the user scrolls up; End follows again.
my $follow = 1;
$log->on(
	OnScroll => sub ($event) {
		$follow = 0 if $event->delta_y > 0;    # positive: the view moved up
		return;
	}
);

my %action_by_key = (
	Up    => sub { $follow = 0; scroll_by( 0, -1 ) },
	Down  => sub { scroll_by( 0,  1 ) },
	Left  => sub { scroll_by( -4, 0 ) },
	Right => sub { scroll_by( 4,  0 ) },
	Home  => sub { $follow = 0; $ui->scroll_to( $log, { x => 0, y => 0 } ) },
	End   => sub { $follow = 1 },
);
$root->on(
	KeyPress => sub ($event) {
		my $action = $action_by_key{ $event->key_name // '' } or return;
		$action->();
		return;
	}
);

my $count = 0;
my $loop  = IO::Async::Loop->new;
$loop->add(
	IO::Async::Timer::Periodic->new(
		interval => 0.25,
		on_tick  => sub {
			$count++;
			my $text = sprintf 'Line %4d', $count;
			$text .= ' ' . ( '-' x 150 ) . ' a wide line' if $count % 5 == 0;    # wider than the box
			$log->add_child( Term::Fabulous::Widget::Text->new( text => $text, text_color => [ 200, 210, 230, 255 ] ) );
			return;
		},
	)->start
);

# The content height is known only after the frame that lays out a new
# line, so keep moving to the bottom as long as the view follows.
$loop->add(
	IO::Async::Timer::Periodic->new(
		interval => 1 / 30,
		on_tick  => sub {
			return unless $follow;
			my $state = $ui->scroll_state($log) or return;
			$ui->scroll_to( $log, { y => lowest_y($state) } ) if $state->{position}{y} != lowest_y($state);
			return;
		},
	)->start
);

$ui->run;
