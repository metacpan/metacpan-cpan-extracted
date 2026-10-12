#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_RIGHT TB_MOD_MOTION);
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Menu;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextArea;
use Clay::UI::Enum::Result;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);
my $notes = Term::Fabulous::Widget::TextArea->new(
	value  => "Select some words, then right-click,\nor press Shift+F10 or the Menu key.\n",
	layout => { sizing => { width => sizing_grow(), height => sizing_grow() } },
);
$root->add_child( Term::Fabulous::Widget::Text->new( text => 'Notes' ), $notes );

# The text area knows these keys already; the menu shows them, and
# offers Cut and Copy only while text is selected.
my $editor = $notes->editor;
my $menu   = Term::Fabulous::Widget::Menu->new(
	items => [
		{ label => 'Cut',   keys => ['Ctrl+X'], run => sub { $editor->cut },  enabled => sub { $editor->has_selection } },
		{ label => 'Copy',  keys => ['Ctrl+C'], run => sub { $editor->copy }, enabled => sub { $editor->has_selection } },
		{ label => 'Paste', keys => ['Ctrl+V'], run => sub { $editor->paste } },
		'-',
		{ label => 'Select all', keys => ['Ctrl+A'], run => sub { $editor->select_all } },
	],
);

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24, stop_on_ctrl_c => 0 );

# A right click opens the menu at the pointer...
$notes->on(
	Mouse => sub ($event) {
		return Clay::UI::Enum::Result->CONTINUE unless $event->key == TB_KEY_MOUSE_RIGHT && !( $event->modifiers & TB_MOD_MOTION );
		$menu->open( $ui, x => $event->x, y => $event->y );
		return;
	}
);

# ... and the keyboard opens it in the top left corner of the text area.
# Ctrl+Q quits.
$root->on(
	KeyPress => sub ($event) {
		my $key = $event->key_name // '';
		if ( $key eq 'Shift+F10' || $key eq 'Menu' ) {
			my $box = $ui->bounding_box($notes);
			$menu->open( $ui, x => $box->{x} + 1, y => $box->{y} + 1 );
			return;
		}
		if ( $key eq 'Ctrl+Q' ) {
			$ui->loop->stop;
			return;
		}
		return Clay::UI::Enum::Result->CONTINUE;
	}
);

$ui->interaction->set_focused_widget($notes);
$ui->run;
