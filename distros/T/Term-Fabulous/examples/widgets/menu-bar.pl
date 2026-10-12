#!/usr/bin/env perl

# Term::Fabulous::Widget::MenuBar: a small notes editor with a menu bar,
# a text area and a status bar. Every menu item is a command of one
# table, so the keys in the menus work without opening them, and an item
# that cannot run now (Save without changes, Undo with nothing to undo,
# Copy without a selection) is dimmed. F10 or Alt with the underlined
# letter opens a menu; the arrow keys, Enter and Escape work in it. A
# click on a title opens its menu too. Ctrl+Q quits, and asks first when
# there are unsaved changes.
#
#     perl examples/widgets/menu-bar.pl

use v5.32;
use warnings;
use strict;
use utf8;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use Term::Fabulous;
use Term::Fabulous::Commands;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::MenuBar;
use Term::Fabulous::Widget::Prompt;
use Term::Fabulous::Widget::StatusBar;
use Term::Fabulous::Widget::TextArea;

use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my $saved = "Shopping\n\n- bread\n- apples\n- coffee\n";

my $area   = Term::Fabulous::Widget::TextArea->new( value => $saved, wrap => 1, layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
my $editor = $area->editor;

sub is_modified () {
	return $area->value ne $saved ? 1 : 0;
}

my $status = Term::Fabulous::Widget::StatusBar->new(
	message => 'F10 opens the menus, Ctrl+Q quits.',
	timeout => 5,
	parts   => sub {
		my ( $row, $column ) = $editor->cursor;
		return ( ( is_modified() ? [ 'modified', 'accent' ] : () ), sprintf( 'Ln %d, Col %d', $row + 1, $column + 1 ) );
	},
);

my $ui;

# Quitting with unsaved changes asks first, starting on Cancel.
sub quit () {
	return $ui->loop->stop unless is_modified();
	Term::Fabulous::Widget::Prompt->confirm( $ui, title => 'Quit?', message => 'The notes have unsaved changes.', ok => 'Quit', focus => 'cancel' )
		->on( Answer => sub ($event) { $ui->loop->stop if $event->button eq 'ok'; return } );
	return;
}

my $commands = Term::Fabulous::Commands->new(
	commands => [
		{ id => 'save', label => 'Save', keys => ['Ctrl+S'], run => sub { $saved = $area->value; $status->message( 'Saved notes.txt.', 'success' ) }, enabled => \&is_modified },
		{ id => 'quit', label => 'Quit', keys => ['Ctrl+Q'], run => \&quit },

		{ id => 'undo',       label => 'Undo',       keys => ['Ctrl+Z'], run => sub { $editor->undo }, enabled => sub { $editor->can_undo } },
		{ id => 'redo',       label => 'Redo',       keys => ['Ctrl+Y'], run => sub { $editor->redo }, enabled => sub { $editor->can_redo } },
		{ id => 'cut',        label => 'Cut',        keys => ['Ctrl+X'], run => sub { $editor->cut },  enabled => sub { $editor->has_selection } },
		{ id => 'copy',       label => 'Copy',       keys => ['Ctrl+C'], run => sub { $editor->copy }, enabled => sub { $editor->has_selection } },
		{ id => 'paste',      label => 'Paste',      keys => ['Ctrl+V'], run => sub { $editor->paste } },
		{ id => 'select_all', label => 'Select all', keys => ['Ctrl+A'], run => sub { $editor->select_all } },

		{ id => 'wrap', label => 'Wrap long lines', keys => ['Alt+w'], run => sub { $area->wrap( !$area->wrap ) }, checked => sub { $area->wrap } },

		{ id => 'about', label => 'About', run => sub { Term::Fabulous::Widget::Prompt->alert( $ui, title => 'Notes', message => 'A small editor made with [bold]Term::Fabulous[/].' ) } },
	],
);

my $menu_bar = Term::Fabulous::Widget::MenuBar->new(
	commands => $commands,
	caption  => 'notes.txt',
	menus    => [
		{ title => 'File', items => [qw(save - quit)] },
		{ title => 'Edit', items => [qw(undo redo - cut copy paste - select_all)] },
		{ title => 'View', items => ['wrap'] },
		{ title => 'Help', items => ['about'] },
	],
);

my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
$root->add_child( $menu_bar, $area, $status );

# Ctrl+C copies here, so it does not end the program: Ctrl+Q does.
$ui = Term::Fabulous->new( width => 80, height => 24, root => $root, stop_on_ctrl_c => 0 );
$commands->listen($root);
$menu_bar->listen($root);
$ui->interaction->set_focused_widget($area);
$ui->run;
