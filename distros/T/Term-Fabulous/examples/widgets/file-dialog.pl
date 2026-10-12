#!/usr/bin/env perl

# Term::Fabulous::Widget::FileDialog: a notes program that asks for
# files and folders. o opens a note (the dropdown switches between notes
# and all files), s saves the note under a name (a name without a dot
# gets .txt, and an existing file is replaced only after a question), f
# chooses a folder. The status bar shows the answer. The dialogs start
# in a folder of sample notes that the program makes in a temporary
# directory and deletes when it ends, so it never writes your files.
# Escape closes a dialog. Ctrl+C quits.
#
#     perl examples/widgets/file-dialog.pl

use v5.32;
use warnings;
use strict;
use utf8;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::FileDialog;
use Term::Fabulous::Widget::StatusBar;
use Term::Fabulous::Widget::Text;

use Clay::UI::Enum::Result;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);
use Encode qw(decode);
use File::Basename qw(basename);
use File::Path qw(make_path);
use File::Temp;
use Time::Local qw(timegm);

# The sample notes, each with its size in lines and the day it was last
# changed, so the list looks the same on every run. Their folder is deep
# enough that the dialog's folder line shows only the end of its path.
my $temporary = File::Temp->newdir;
my $notes     = "$temporary/home/ada/Documents/Projects/analytical-engine/notes";
my @samples   = (
	[ 'archive/',         0,   [ 2026, 2, 14 ] ],
	[ 'drafts/',          0,   [ 2026, 5, 28 ] ],
	[ 'ideas.md',         40,  [ 2026, 5, 30 ] ],
	[ 'reading-list.txt', 12,  [ 2026, 4, 2 ] ],
	[ 'shopping.txt',     3,   [ 2026, 5, 31 ] ],
	[ 'todo.txt',         25,  [ 2026, 6, 1 ] ],
	[ 'budget.csv',       300, [ 2026, 3, 9 ] ],
	[ '.backup',          90,  [ 2026, 1, 5 ] ],
);
make_path($notes);
foreach my $sample (@samples) {
	my ( $name, $lines, $day ) = @$sample;
	my $path = "$notes/$name";
	if ( $name =~ m{/\z} ) {
		make_path($path);
	}
	else {
		open my $file, '>', $path or die "Cannot write $path: $!\n";
		print {$file} "A line of the note $name.\n" x $lines;
		close $file;
	}
	my $time = timegm( 0, 30, 10, $day->[2], $day->[1] - 1, $day->[0] );
	utime $time, $time, $path;
}

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
	},
);
my $page = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1 },
		child_gap        => 1,
	}
);
my $current = Term::Fabulous::Widget::Text->new( text => 'No note is open.' );
$page->add_child( Term::Fabulous::Widget::Text->new( text => 'Notes', bold => 1 ), $current );
my $status = Term::Fabulous::Widget::StatusBar->new( message => 'o opens a note, s saves it as, f chooses a folder.', parts => [ [ 'Ctrl+C quits', 'dim' ] ] );
$root->add_child( $page, $status );

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );

my $open_note;    # the path of the note that is open

# The last part of a path, decoded for the screen: a path is bytes, as
# the file system and the dialog's answer have it, and a whole one would
# not fit on the line.
sub shown ($path) {
	return decode( 'UTF-8', basename($path), Encode::FB_PERLQQ | Encode::LEAVE_SRC );
}

# Every dialog answers the same way: the button says what was chosen,
# the path is in the values.
sub answered ($event) {
	if ( $event->button eq 'cancel' ) {
		$status->message( $event->dismissed ? 'Closed with Escape.' : 'Cancelled.', 'warning' );
		return;
	}
	my $path = $event->value('path');
	$open_note = $path if $event->button ne 'choose';
	$current->text( defined $open_note ? 'The open note is ' . shown($open_note) . '.' : 'No note is open.' );
	$status->message( ucfirst( $event->button ) . ': ' . shown($path), 'success' );
	return;
}

sub ask_for (%params) {
	my $dialog = Term::Fabulous::Widget::FileDialog->new( directory => $notes, width => 60, list_rows => 7, %params );
	$dialog->on( Answer => \&answered );
	$dialog->open($ui);
	return;
}

$root->on(
	KeyPress => sub ($event) {
		my $key = $event->key_name // '';
		return ask_for( mode => 'open', filters => [ [ 'Notes' => '*.txt *.md' ], [ 'All files' => '*' ] ] ) if $key eq 'o';
		return ask_for( mode => 'save', name    => 'new-note.txt', default_extension => 'txt', current_file => $open_note ) if $key eq 's';
		return ask_for( mode => 'folder' ) if $key eq 'f';
		return Clay::UI::Enum::Result->CONTINUE;
	}
);

$ui->run;
