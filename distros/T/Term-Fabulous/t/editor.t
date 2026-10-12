use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use utf8;

use Test2::V0;

use Term::Fabulous::Editor;

sub editor {
	my (%options) = @_;
	return Term::Fabulous::Editor->new(%options);
}

sub text_after_insert ( $text, %options ) {
	my $editor = editor(%options);
	$editor->insert($text);
	return $editor->text;
}

subtest 'text and lines' => sub {
	my $editor = editor( text => "one\r\ntwo\rthree" );
	is [ $editor->lines ],                              [ 'one', 'two', 'three' ], 'line breaks are normalized';
	is [ $editor->cursor ],                             [ 2, 5 ],                  'the cursor starts at the end';
	is editor( text => "a\nb", multi_line => 0 )->text, 'a b',                     'a single-line editor turns line breaks into spaces';
	is editor()->line_count,                            1,                         'an empty text has one line';
	like dies { editor( text => [] ) }, qr/text must be a string/, 'a non-string dies';
};

subtest 'grapheme clusters' => sub {
	my $editor = editor( text => "e\x{301}x\x{1F1E9}\x{1F1EA}" );
	is [ $editor->boundaries(0) ], [ 0, 2, 3, 5 ], 'a combining accent and a flag are one cluster each';
	is $editor->character_count,   3,              'clusters are counted';

	$editor->move_left;
	is [ $editor->cursor ], [ 0, 3 ], 'the cursor moves over a whole flag';
	$editor->move_to( 0, 1 );
	is [ $editor->cursor ], [ 0, 0 ], 'a position inside a cluster moves to its start';
};

subtest 'movement' => sub {
	my $editor = editor( text => "one two\nthree" );
	$editor->move_to( 1, 0 )->move_left;
	is [ $editor->cursor ], [ 0, 7 ], 'left from the start of a line goes to the end of the previous one';
	$editor->move_right;
	is [ $editor->cursor ], [ 1, 0 ], 'right from the end of a line goes to the next one';

	$editor->move_to( 0, 6 )->move_word_left;
	is [ $editor->cursor ], [ 0, 4 ], 'word left goes to the start of the word';
	$editor->move_word_right;
	is [ $editor->cursor ], [ 0, 7 ], 'word right goes to the end of the word';
	$editor->move_document_start->move_line_end;
	is [ $editor->cursor ], [ 0, 7 ], 'line end';
};

subtest 'selection' => sub {
	my $editor = editor( text => "one two\nthree" );
	$editor->move_document_start->move_word_right(1)->move_right(1);
	is $editor->selected_text, 'one ', 'extending moves select from where they started';
	$editor->move_left;
	is [ $editor->cursor, $editor->has_selection ], [ 0, 0, 0 ], 'left without Shift collapses to the start';

	$editor->move_to( 0, 4 )->move_document_end(1);
	is $editor->selected_text, "two\nthree",   'a selection spans lines';
	is [ $editor->selection ], [ 0, 4, 1, 5 ], 'selection is ordered';
	$editor->select_word_at( 1, 2 );
	is $editor->selected_text, 'three', 'select_word_at';
	my $accents = editor( text => "x!\x{301}caf\x{e9}e\x{301} y" );
	$accents->select_word_at( 0, 5 );
	is $accents->selected_text, "caf\x{e9}e\x{301}", 'a word is made of whole clusters; a mark does not make punctuation a word';
	$accents->select_word_at( 0, 1 );
	is $accents->selected_text, "!\x{301}", 'between words, the single cluster';
	$editor->select_all;
	is $editor->selected_text, "one two\nthree", 'select_all';
};

subtest 'editing' => sub {
	my $editor = editor( text => "one two\nthree" );
	$editor->move_to( 0, 3 );
	ok $editor->insert('!'), 'insert reports a change';
	is $editor->text, "one! two\nthree", 'inserted at the cursor';

	$editor->move_to( 1, 0 );
	$editor->delete_backward;
	is $editor->text, "one! twothree", 'backspace at the start of a line joins the lines';
	$editor->delete_word_backward;
	is $editor->text, "one! three", 'delete_word_backward';
	$editor->move_to( 0, 1 )->delete_to_line_end;
	is $editor->text, 'o', 'delete_to_line_end';

	$editor->select_all;
	$editor->type('x');
	is $editor->text, 'x', 'typing replaces the selection';
	ok !$editor->delete_forward, 'deleting at the end changes nothing';
	$editor->select_all;
	ok $editor->type(''), 'typing an empty string with a selection is an edit';
	is $editor->text,     '',    'it deletes the selection';
	is $editor->line(-1), undef, 'a negative row has no line';
};

subtest 'max_length' => sub {
	my $editor = editor( text => 'ab', max_length => 4 );
	$editor->insert('cdef');
	is $editor->text, 'abcd', 'inserted text is cut to fit';
	$editor->move_to( 0, 1 )->move_right(1);
	$editor->type('XYZ');
	is $editor->text, 'aXcd', 'a replaced selection makes room';
	like dies { $editor->set_text('abcde') }, qr/more than max_length 4/, 'a longer text dies';
	like dies { $editor->set_max_length(2) }, qr/more than max_length 2/, 'a limit below the length dies';
	like dies { editor( max_length => -1 ) }, qr/non-negative integer/,   'an invalid limit dies';
};

subtest 'accept' => sub {
	my $editor = editor( accept => '0-9' );
	$editor->type('a');
	is $editor->text, '', 'a rejected cluster is not typed';
	$editor->insert('+49 170 1234');
	is $editor->text, '491701234', 'rejected clusters are dropped from inserted text, the rest is kept';
	$editor->select_all;
	$editor->type('x');
	is $editor->text,   '491701234', 'typing only rejected clusters leaves the selection alone';
	is $editor->accept, '0-9',       'the spec is kept as given';

	is text_after_insert( "1\n2", accept => qr/\p{L}/, text => "ab\ncd" ),         "ab\ncd\n", 'a regular expression is matched per cluster, line breaks pass';
	is text_after_insert( 'xyzzy', accept => sub ($cluster) { $cluster eq 'z' } ), 'zz',       'a code reference is a predicate';
	is text_after_insert( 'a1b2c3', accept => '0-9', max_length => 2 ),            '12',       'max_length counts what is accepted';

	like dies { $editor->set_text('12a') }, qr/accept rejects: "a"/, 'set_text with a rejected cluster dies';
	like dies { editor( text   => 'abc12', accept => '0-9' ) }, qr/accept rejects: "abc"/,             'the constructor dies the same way';
	like dies { editor( text   => '42' )->set_accept('a-z') },  qr/accept rejects: "42"/,              'a spec that rejects the current text dies';
	like dies { editor( accept => 'z-a' ) },                    qr/not the body of a character class/, 'a bad character class dies';
	like dies { editor( accept => [] ) },                       qr/accept must be/,                    'a reference of another kind dies';
	my $lifted = editor( accept => '0-9' )->set_accept(undef);
	$lifted->insert('ok');
	is $lifted->text, 'ok', 'undef lifts the restriction';
};

subtest 'undo and redo' => sub {
	my $editor = editor();
	$editor->type($_) foreach split //, 'hello world';
	is $editor->text, 'hello world', 'typed';

	$editor->undo;
	is $editor->text, 'hello ', 'undo takes back the last word';
	$editor->undo;
	is $editor->text, 'hello', 'then the spaces';
	$editor->redo;
	is $editor->text, 'hello ', 'redo';

	$editor->move_to( 0, 0 );
	$editor->type('X');
	ok !$editor->can_redo, 'an edit clears the redo steps';
	$editor->undo;
	is [ $editor->text, $editor->cursor ], [ 'hello ', 0, 0 ], 'undo restores the cursor';
	ok !editor( text => 'set' )->can_undo, 'set_text starts a fresh history';
};

subtest 'undo and redo across lines' => sub {
	my $editor = editor( text => "one\ntwo\nthree" );
	my @texts  = ( $editor->text );
	my $record = sub { push @texts, $editor->text };

	$editor->move_to( 1, 1 )->move_to( 2, 2, 1 );
	$editor->insert("X\nY\nZ");
	$record->();
	$editor->move_document_start->move_line_end(1);
	$editor->cut;
	$record->();
	$editor->move_document_end;
	$editor->insert(" end\nmore");
	$record->();
	$editor->move_to( 1, 0 );
	$editor->delete_backward;
	$record->();
	$editor->paste;
	$record->();

	my @undone;
	unshift @undone, $editor->text while $editor->undo;
	is \@undone, [ @texts[ 0 .. $#texts - 1 ] ], 'undo walks back through every step';
	my @redone;
	push @redone, $editor->text while $editor->redo;
	is $redone[-1],         $texts[-1], 'redo walks forward to the last text';
	is [ $editor->cursor ], [ 0, 3 ],   'with the cursor after the last edit';
};

subtest 'clipboard' => sub {
	my $editor = editor( text => 'cut me' );
	$editor->move_document_start->move_word_right(1);
	ok $editor->cut, 'cut';
	is [ $editor->text, Term::Fabulous::Editor->clipboard ], [ ' me', 'cut' ], 'cut moves the selection to the clipboard';

	my $other = editor( text => 'x' );
	$other->paste;
	is $other->text, 'xcut', 'the clipboard is shared';
	ok !$other->copy, 'copy needs a selection';
	Term::Fabulous::Editor->clipboard('set');
	$other->paste;
	is $other->text,      'xcutset', 'the clipboard can be set';
	is $other->clipboard, 'set',     'the clipboard can be read through an editor';
};

done_testing;
