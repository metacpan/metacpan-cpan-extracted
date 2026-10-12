#!/usr/bin/env perl

# Term::Fabulous::Widget::Menu as a context menu: a list of files with a
# cursor. A right click on a file, Shift+F10 or the Menu key opens a menu
# of what can be done with it; the same commands also run with their
# keys. Paste is disabled until a file was cut, and Show hidden files is
# a setting with a check mark. Up and Down move the cursor, Escape closes
# the menu. Ctrl+C quits.
#
#     perl examples/widgets/menu.pl

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
use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_RIGHT TB_MOD_MOTION);
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Menu;
use Term::Fabulous::Widget::Prompt;
use Term::Fabulous::Widget::StatusBar;
use Term::Fabulous::Widget::Text;

use Clay::UI::Enum::Result;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my @files       = qw(.profile notes.txt todo.txt budget.csv letter.md photos.zip);
my $show_hidden = 1;
my $cursor      = 0;
my $cut;    # the file that was cut, waiting to be pasted

use constant LIST_TOP => 1;    # the empty row above the files

my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
my $list = Term::Fabulous::Widget::Box->new(
	layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() }, padding => { left => 2, top => LIST_TOP } } );
my $status = Term::Fabulous::Widget::StatusBar->new(
	message => 'Right-click a file, or press Shift+F10, for its menu.',
	parts   => [ [ 'Ctrl+C quits', 'dim' ] ],
	timeout => 5,
);
$root->add_child( $list, $status );

my @rows;

sub shown_files () {
	return grep { $show_hidden || !/\A\./ } @files;
}

sub current_file () {
	return ( shown_files() )[$cursor];
}

sub show_files () {
	my @shown = shown_files();
	$cursor = $#shown if $cursor > $#shown;
	@rows   = map { Term::Fabulous::Widget::Text->new( text => ( $_ == $cursor ? '> ' : '  ' ) . $shown[$_] ) } 0 .. $#shown;
	$list->clear_children;
	$list->add_child(@rows);
	return;
}
show_files();

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );

# What can be done with a file. The menu shows these commands, and their
# keys run them without the menu.
my $menu;
my $commands = Term::Fabulous::Commands->new(
	commands => [
		{ id => 'open', label => 'Open', keys => ['Enter'], run => sub { $status->message( 'Opened ' . current_file() . '.' ) } },
		{
			id    => 'rename',
			label => 'Rename...',
			keys  => ['F2'],
			run   => sub {
				my $old = current_file();
				Term::Fabulous::Widget::Prompt->ask( $ui, title => "Rename $old", label => 'New name', value => $old, required => 1 )->on(
					Answer => sub ($event) {
						return if $event->button ne 'ok';
						my $new = $event->value('value');
						@files = map { $_ eq $old ? $new : $_ } @files;
						show_files();
						$status->message( "Renamed $old.", 'success' );
						return;
					}
				);
			},
		},
		{ id => 'cut',    label => 'Cut',               keys => ['Ctrl+X'], run => sub { $cut = current_file(); $status->message("Cut $cut.") } },
		{ id => 'paste',  label => 'Paste',             keys => ['Ctrl+V'], run => sub { $status->message( "Pasted $cut.", 'success' ); $cut = undef }, enabled => sub { defined $cut } },
		{ id => 'hidden', label => 'Show hidden files', keys => ['Alt+h'],  run => sub { $show_hidden = !$show_hidden; show_files() }, checked => sub { $show_hidden } },
		{ id => 'menu',   label => 'Menu',              keys => [ 'Shift+F10', 'Menu' ], run => sub { open_at_cursor() } },
	],
);
$menu = Term::Fabulous::Widget::Menu->new( commands => $commands, items => [qw(open rename - cut paste - hidden)] );

# From the keyboard, the menu opens just below the file under the cursor.
sub open_at_cursor () {
	my $box = $ui->bounding_box($list) // return;
	$menu->open( $ui, x => $box->{x} + 2, y => $box->{y} + LIST_TOP + $cursor + 1 );
	return;
}
$commands->listen($root);

# Up and Down move the cursor; a right click on a file puts the cursor
# on it and opens the menu where the pointer is.
$root->on(
	KeyPress => sub ($event) {
		my %step = ( Up => -1, Down => 1 );
		my $by   = $step{ $event->key_name // '' } // return Clay::UI::Enum::Result->CONTINUE;
		$cursor = ( $cursor + $by ) % shown_files();
		show_files();
		return;
	}
);
$root->on(
	Mouse => sub ($event) {
		return Clay::UI::Enum::Result->CONTINUE unless $event->key == TB_KEY_MOUSE_RIGHT && !( $event->modifiers & TB_MOD_MOTION );
		my $box = $ui->bounding_box($list) // return Clay::UI::Enum::Result->CONTINUE;
		my $row = $event->y - $box->{y} - LIST_TOP;
		return Clay::UI::Enum::Result->CONTINUE unless $row >= 0 && $row <= $#rows;
		$cursor = $row;
		show_files();
		$menu->open( $ui, x => $event->x, y => $event->y );
		return;
	}
);

$ui->run;
