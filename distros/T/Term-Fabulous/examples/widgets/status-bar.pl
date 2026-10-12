#!/usr/bin/env perl

# Term::Fabulous::Widget::StatusBar: a list of files with a status bar at
# the bottom, which shows what the keys do and, on the right, the file
# under the cursor. Up and Down move the cursor, s saves (a success
# message), w warns, e fails. Above the list, a status bar of each other
# kind. Messages go away after five seconds. Ctrl+C quits.
#
#     perl examples/widgets/status-bar.pl

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
use Term::Fabulous::Widget::StatusBar;
use Term::Fabulous::Widget::Text;

use Clay::UI::Enum::Result;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my @files  = qw(notes.txt todo.txt budget.csv letter.md recipes.md photos.zip);
my $cursor = 0;

my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );

# A status bar of each of the other kinds, as they look.
my $samples = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow() }, child_gap => 1 } );
$samples->add_child(
	Term::Fabulous::Widget::StatusBar->new( message => 'Saved notes.txt.',                               kind => 'success', parts => ['UTF-8'] ),
	Term::Fabulous::Widget::StatusBar->new( message => 'letter.md was changed by another program.',      kind => 'warning', parts => [ [ 'modified',  'accent' ] ] ),
	Term::Fabulous::Widget::StatusBar->new( message => 'Could not write photos.zip: Permission denied.', kind => 'danger',  parts => [ [ 'read-only', 'danger' ] ] ),
);
$root->add_child($samples);

# The list of files, with the cursor on one of them.
my $list = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() }, padding => { left => 2, top => 1 } } );
my @rows = map { Term::Fabulous::Widget::Text->new( text => $_ ) } @files;
$list->add_child(@rows);
$root->add_child($list);

sub show_cursor () {
	$rows[$_]->text( ( $_ == $cursor ? '> ' : '  ' ) . $files[$_] ) foreach 0 .. $#files;
	return;
}
show_cursor();

# The status bar of the program: a hint on the left, the position of the
# cursor on the right, read whenever a frame is drawn.
my $status = Term::Fabulous::Widget::StatusBar->new(
	message => 'Up and Down move the cursor, s saves, w warns, e fails.',
	parts   => sub { ( sprintf( 'file %d of %d', $cursor + 1, scalar @files ), [ 'Ctrl+C quits', 'dim' ] ) },
	timeout => 5,
);
$root->add_child($status);

my %action = (
	Up   => sub { $cursor = ( $cursor - 1 ) % @files; show_cursor() },
	Down => sub { $cursor = ( $cursor + 1 ) % @files; show_cursor() },
	s    => sub { $status->message( "Saved $files[$cursor].",                        'success' ) },
	w    => sub { $status->message( "$files[$cursor] is larger than 1 MB.",          'warning' ) },
	e    => sub { $status->message( "Could not open $files[$cursor]: No such file.", 'danger' ) },
);
$root->on(
	KeyPress => sub ($event) {
		my $run = $action{ $event->key_name // '' } // return Clay::UI::Enum::Result->CONTINUE;
		$run->();
		return;
	}
);

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );
$ui->run;
