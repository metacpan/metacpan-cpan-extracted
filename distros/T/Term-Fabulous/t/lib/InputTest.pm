package InputTest;

# Helpers for the input widget tests: lay widgets out on a memory
# terminal, send them keys and mouse events, and read back what they
# painted. Widgets paint when a frame is drawn: shown and row_text draw
# the frames that are due first. press and click fire their events at the widget itself, which
# tests the widget's own handling; screen_click goes through Term::Fabulous
# like a click on the terminal (hit-testing, focus, OnPress and OnRelease).

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Exporter 'import';
our @EXPORT = qw(layout_ui press type_text click screen_click shown row_text);    ## no critic (Modules::ProhibitAutomaticExportation) every test uses all helpers

use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);
use Term::Fabulous;
use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_LEFT);
use Term::Fabulous::Termbox::Event;
use Term::Fabulous::Terminal::Memory;
use Term::Fabulous::Event::KeyPress;
use Term::Fabulous::Event::Mouse;
use Term::Fabulous::Widget::Box;

# A Term::Fabulous on a 40x20 memory terminal with the widgets stacked in
# a root box, laid out and drawn once.
sub layout_ui (@widgets) {
	my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
	$root->add_child(@widgets);
	my $terminal = Term::Fabulous::Terminal::Memory->new( width => 40, height => 20 );
	my $ui       = Term::Fabulous->new( root => $root, width => 40, height => 20, terminal => $terminal );
	$ui->step;
	return $ui;
}

# Fires the KeyPress of the key named like
# Term::Fabulous::Event::KeyPress->key_name ('Ctrl+Shift+Left', 'Enter',
# 'Ctrl+W') or typing one character ('a') at the widget.
sub press ( $widget, $name ) {
	my $event = Term::Fabulous::Termbox::Event->new( Term::Fabulous::Event::KeyPress->fields_for_name($name) );
	$widget->fire_event( Term::Fabulous::Event::KeyPress->of($event) );
	return;
}

sub type_text ( $widget, $text ) {
	press( $widget, $_ ) foreach split //, $text;
	return;
}

# A mouse event at a cell of the widget's buffer, as the widget was laid
# out last. Returns the event.
sub click ( $widget, $x, $y, %options ) {
	my ( $origin_x, $origin_y ) = $widget->content_origin;
	my $event = Term::Fabulous::Event::Mouse->new(
		key       => $options{key} // TB_KEY_MOUSE_LEFT,
		x         => $origin_x + $x,
		y         => $origin_y + $y,
		modifiers => $options{modifiers} // 0,
	);
	$widget->fire_event($event);
	return $event;
}

# A click on the terminal at a cell of the widget's buffer, handled by the
# Term::Fabulous the widget belongs to.
sub screen_click ( $widget, $x, $y ) {
	my $ui = $widget->ui;
	my ( $origin_x, $origin_y ) = $widget->content_origin;
	$ui->terminal->click( $origin_x + $x, $origin_y + $y );
	$ui->step;
	return;
}

# Draws the frames due in the UI of a widget, so its cells show its
# current state; returns the widget.
sub shown ($widget) {
	my $ui = $widget->ui // die "InputTest: the widget is not part of a UI\n";
	$ui->can('step') ? $ui->step : $ui->draw;
	return $widget;
}

# The glyphs of one buffer row as the next frame shows them; unset cells
# read as spaces, and the cells a wide glyph covers are left out.
sub row_text ( $canvas, $y ) {
	shown($canvas);
	my ($glyphs) = $canvas->cell_row($y);
	return join '', map { my $glyph = $glyphs->[$_]; ref $glyph ? $glyph->[0] : defined $glyph ? '' : ' ' } 0 .. $canvas->columns - 1;
}

1;
