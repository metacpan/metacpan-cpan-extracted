#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use IO::Async::Loop;
use IO::Async::Timer::Periodic;
use Term::Fabulous;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Scrolling qw(scroll_by_columns scroll_by_rows scroll_to_end);
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

# follow_end keeps the newest line in view until the user scrolls up;
# back at the end, the box follows again.
my $log = Term::Fabulous::Widget::ScrollBox->new(
	id               => 'log',
	horizontal       => 1,    # vertical scrolling is on by default
	follow_end       => 1,
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

# The moves stop at the edges of the content. Moving up leaves the end,
# which stops the following; End goes back to it, which resumes it.
my %action_by_key = (
	Up    => sub { scroll_by_rows( $ui, $log, -1 ) },
	Down  => sub { scroll_by_rows( $ui, $log,  1 ) },
	Left  => sub { scroll_by_columns( $ui, $log, -4 ) },
	Right => sub { scroll_by_columns( $ui, $log,  4 ) },
	Home  => sub { $ui->scroll_to( $log, { x => 0, y => 0 } ) },
	End   => sub { scroll_to_end( $ui, $log ) },
);
$root->on(
	KeyPress => sub ($event) {
		my $action = $action_by_key{ $event->main_key_name // '' } or return;
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

$ui->run;
