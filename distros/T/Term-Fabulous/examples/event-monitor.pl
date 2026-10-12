#!/usr/bin/env perl

# Shows the events Term::Fabulous fires: a listener on the root widget
# logs every event that bubbles up to it, with the widget it was fired on
# (the target). Type into the field, press Tab, Enter, Space, function
# keys or Ctrl combinations, click the widgets: the log shows the key
# names, the clicks, the focus moving and the events of the widgets. The
# hover events do not bubble, so they are logged by listeners on the
# widgets themselves. The line at the bottom follows the pointer. Ctrl+C
# quits.
#
#     perl examples/event-monitor.pl

use v5.32;
use warnings;
use strict;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../lib/";

use Clay::UI::Enum::Result;
use Term::Fabulous;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Termbox qw(:keys TB_MOD_MOTION);
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Button;
use Term::Fabulous::Widget::Checkbox;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextField;

use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

use constant LOG_LINES => 20;

my %MOUSE_KEY_NAME = (
	TB_KEY_MOUSE_LEFT()        => 'left',
	TB_KEY_MOUSE_MIDDLE()      => 'middle',
	TB_KEY_MOUSE_RIGHT()       => 'right',
	TB_KEY_MOUSE_RELEASE()     => 'release',
	TB_KEY_MOUSE_WHEEL_UP()    => 'wheel up',
	TB_KEY_MOUSE_WHEEL_DOWN()  => 'wheel down',
	TF_KEY_MOUSE_WHEEL_LEFT()  => 'wheel left',
	TF_KEY_MOUSE_WHEEL_RIGHT() => 'wheel right',
);

sub text ( $string, $color = [ 220, 220, 220, 255 ] ) {
	return Term::Fabulous::Widget::Text->new( text => $string, text_color => $color );
}

my $root = Term::Fabulous::Widget::Box->new(
	id     => 'root',
	layout => {
		sizing    => { width => sizing_grow(), height => sizing_grow() },
		padding   => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap => 3,
	},
);

# The widgets to try out, on the left.
my $controls = Term::Fabulous::Widget::Box->new( id => 'controls', layout => { layout_direction => CLAY_TOP_TO_BOTTOM, child_gap => 1 } );
my $name     = Term::Fabulous::Widget::TextField->new( id => 'name', placeholder => 'Type here', preferred_columns => 16 );
my $agree    = Term::Fabulous::Widget::Checkbox->new( id => 'agree', label => 'Subscribe' );
my $ok       = Term::Fabulous::Widget::Button->new(
	id               => 'ok',
	background_color => [ 40, 60, 90, 255 ],
	bordered         => 1,
	border_color     => [ 90, 110, 140, 255 ],
	border_style     => Term::Fabulous::Enum::BorderStyle->Round,
	layout           => { padding => { left => 1, right => 1 } },
);
$ok->add_child( text( 'OK', [ 255, 255, 255, 255 ] ) );
$controls->add_child( text( 'Name:', [ 150, 160, 180, 255 ] ), $name, $agree, $ok );

# The log, on the right, and the pointer position below it.
my $log_box = Term::Fabulous::Widget::Box->new(
	id     => 'log',
	layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } },
);
my @log_lines = map { text( '', [ 200, 210, 225, 255 ] ) } 1 .. LOG_LINES;
my $pointer   = text( 'Pointer: not seen yet', [ 120, 130, 150, 255 ] );
$log_box->add_child( text( 'Event          Target     Details', [ 229, 192, 123, 255 ] ), @log_lines, text(''), $pointer );
$root->add_child( $controls, $log_box );

my @entries;

sub log_event ( $event, $details = '' ) {
	my $target = $event->target;
	push @entries, sprintf '%-14s %-10s %s', $event->name, ( $target && $target->can('id') ? $target->id : undef ) // ref $target, $details;
	shift @entries while @entries > LOG_LINES;
	$log_lines[$_]->text( $entries[$_] // '' ) foreach 0 .. LOG_LINES - 1;
	return;
}

sub key_details ($event) {
	my $text = $event->text;
	return sprintf '%s%s', $event->key_name // '(no name)', defined $text ? " types '$text'" : '';
}

sub mouse_details ($event) {
	my $what = $MOUSE_KEY_NAME{ $event->key } // 'key ' . $event->key;
	$what .= ' drag' if $event->modifiers & TB_MOD_MOTION;
	return sprintf '%s at %d,%d', $what, $event->x, $event->y;
}

# Every listener returns CONTINUE, so logging changes nothing about how
# the events travel; the root has no ancestors anyway.
my $continue   = Clay::UI::Enum::Result->CONTINUE;
my %details_of = (
	KeyPress  => \&key_details,
	Mouse     => \&mouse_details,
	OnPress   => sub ($event) { sprintf 'at %.1f,%.1f', $event->x, $event->y },
	OnRelease => sub ($event) { sprintf 'at %.1f,%.1f', $event->x, $event->y },
	Change    => sub ($event) { 'value ' . ( $event->value // 'undef' ) },
	Submit    => sub ($event) { "value '" . $event->value . "'" },
	Activate  => sub ($event) { '' },
	OnFocus   => sub ($event) { '' },
	OnBlur    => sub ($event) { '' },
);
foreach my $event_name ( sort keys %details_of ) {
	$root->on( $event_name => sub ($event) { log_event( $event, $details_of{$event_name}->($event) ); return $continue } );
}
foreach my $widget ( $name, $agree, $ok ) {
	$widget->on( $_ => sub ($event) { log_event($event); return $continue } ) foreach qw(OnHoverStart OnHoverStopped);
}
$root->on(
	MouseMove => sub ($event) {
		$pointer->text( sprintf 'Pointer: %d,%d over %s', $event->x, $event->y, $event->target->id // ref $event->target );
		return $continue;
	}
);

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );
$ui->run;
