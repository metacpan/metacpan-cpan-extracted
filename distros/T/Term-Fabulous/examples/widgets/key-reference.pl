#!/usr/bin/env perl

# Term::Fabulous::Widget::KeyReference: a small notes editor whose keys
# are commands of one table. F1 opens the key reference: the keys of the
# commands, and the keys of the text area and of the key reference
# itself, in groups. Typing filters it; Escape or Close closes it.
# Ctrl+Q quits.
#
#     perl examples/widgets/key-reference.pl

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
use Term::Fabulous::Widget::KeyReference;
use Term::Fabulous::Widget::StatusBar;
use Term::Fabulous::Widget::TextArea;

use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my $area   = Term::Fabulous::Widget::TextArea->new( value => "Shopping\n\n- bread\n- apples\n- coffee\n", wrap => 1, layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
my $editor = $area->editor;
my $status = Term::Fabulous::Widget::StatusBar->new( message => 'F1 shows the keys, Ctrl+Q quits.', parts => [ [ 'notes.txt', 'dim' ] ], timeout => 5 );

my ( $ui, $commands );

# The keys no command runs, in groups of their own.
my @other_keys = (
	[ 'Text',          'Ctrl+Z, Ctrl+Y',         'Undo, redo' ],
	[ 'Text',          'Ctrl+C, Ctrl+X, Ctrl+V', 'Copy, cut, paste' ],
	[ 'Text',          'Shift+arrows',           'Select' ],
	[ 'Text',          'Ctrl+Left, Ctrl+Right',  'A word to the left, to the right' ],
	[ 'Key reference', 'Tab, Shift+Tab',         'Move between the search, the keys and Close' ],
	[ 'Key reference', 'Escape',                 'Close the key reference' ],
);

sub show_keys () {
	Term::Fabulous::Widget::KeyReference->new( title => 'Keys of the notes editor', commands => $commands, keys => \@other_keys, width => 64, height => 24 )->open($ui);
	return;
}

$commands = Term::Fabulous::Commands->new(
	commands => [
		{ id => 'keys',       label => 'Keys...',         keys => ['F1'],     run => \&show_keys },
		{ id => 'new',        label => 'New note',        keys => ['Ctrl+N'], run => sub { $area->value('') } },
		{ id => 'save',       label => 'Save',            keys => ['Ctrl+S'], run => sub { $status->message( 'Saved notes.txt.', 'success' ) } },
		{ id => 'select_all', label => 'Select all',      keys => ['Ctrl+A'], run => sub { $editor->select_all } },
		{ id => 'wrap',       label => 'Wrap long lines', keys => ['Alt+w'],  run => sub { $area->wrap( !$area->wrap ) } },
		{ id => 'quit',       label => 'Quit',            keys => ['Ctrl+Q'], run => sub { $ui->loop->stop } },
	],
);

my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
$root->add_child( $area, $status );

# Ctrl+C copies here, so it does not end the program: Ctrl+Q does.
$ui = Term::Fabulous->new( width => 80, height => 24, root => $root, stop_on_ctrl_c => 0 );
$commands->listen($root);
$ui->interaction->set_focused_widget($area);
$ui->run;
