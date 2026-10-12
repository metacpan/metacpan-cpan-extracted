use v5.32;
use warnings;
use utf8;

use Test2::V0;

use Term::Fabulous::Editor;
use Term::Fabulous::TextView;
use Term::Fabulous::Unicode qw(cluster_columns);

# A view of $text, $columns x $rows, with the cursor at the end.
sub view {
	my ( $text, $columns, $rows, %options ) = @_;
	my $editor = Term::Fabulous::Editor->new( text => $text );
	my $view   = Term::Fabulous::TextView->new( editor => $editor, %options );
	$view->set_size( $columns, $rows )->follow_cursor;
	return $view;
}

# The text each visual row shows.
sub shown_rows {
	my ( $view, @rows ) = @_;
	@rows = $view->visual_rows unless @rows;
	return [
		map {
			my ( $line, undef, $to, undef, $shown ) = @$_;
			join '', map { $_->[1] } $view->clusters( $line, $shown, $to )
		} @rows
	];
}

subtest 'wrapping' => sub {
	skip_all 'the locale has no double-width wcwidth for CJK' unless cluster_columns("\x{5B57}") == 2;

	my @cases = (
		[ 'the quick brown fox',  10, [ 'the quick ', 'brown fox' ],  'breaks after the last blank that fits; the blank stays' ],
		[ 'abcdefghijklmnop',     6,  [ 'abcdef', 'ghijkl', 'mnop' ], 'a word wider than the row breaks anywhere' ],
		[ 'aaaaaaaaaa bbbbbbbbb', 10, [ 'aaaaaaaaaa', 'bbbbbbbbb' ],  'a blank that does not fit hangs: no row starts with it' ],
		[ "abcdefghi\x{5B57}",    10, [ 'abcdefghi', "\x{5B57}" ],    'a wide character at the edge moves to the next row' ],
		[ "bbbbbbbbb\x{5B57}cd",  10, [ 'bbbbbbbbb', "\x{5B57}cd" ],  'and the rest of the word follows it' ],
		[ 'abcdefghij',           10, [ 'abcdefghij', '' ],           'a full last row gets an empty row for the cursor' ],
		[ "one\n\ntwo",           10, [ 'one', '', 'two' ],           'every line starts a row' ],
	);
	foreach my $case (@cases) {
		my ( $text, $width, $expected, $name ) = @$case;
		is shown_rows( view( $text, $width, 9, wrap => 1 ) ), $expected, $name;
	}
	is shown_rows( view( 'the quick brown fox', 10, 9 ) ), ['the quick brown fox'], 'without wrapping a line is one row';
	is shown_rows( view( 'a b c d e f', 8, 1, wrap => 1, scrollbar => 1 ) ), [ 'a b c d', 'e f' ], 'a scrollbar takes one column when the rows do not fit';
};

subtest 'the cursor' => sub {
	my $full = view( 'abcdefghij', 10, 3, wrap => 1 );
	is [ $full->cursor_cell ], [ 0, 1 ], 'at the end of a full row it shows at the start of the next one';
	$full->editor->move_to( 0, 9 );
	is [ $full->cursor_cell ], [ 9, 0 ], 'on the last cluster of the row it stays there';

	my $hanging = view( 'aaaaaaaaaa bbb', 10, 3, wrap => 1 );
	$hanging->editor->move_to( 0, 10 );
	is [ $hanging->cursor_cell ], [ 0, 1 ], 'on a hanging blank it shows at the start of the next row';

	my $tall = view( join( "\n", 1 .. 10 ), 4, 3 );
	is [ $tall->top_row, $tall->cursor_cell ], [ 7, 2, 2 ], 'the view follows it down';
	$tall->editor->move_document_start;
	$tall->follow_cursor;
	is [ $tall->top_row, $tall->cursor_cell ], [ 0, 0, 0 ], 'and back up';
	is $tall->scroll_rows(4),                  4,           'the wheel scrolls without moving it';
	is [ $tall->cursor_cell ],                 [],          'which is then out of view';
	$tall->follow_cursor;
	is $tall->top_row,                            4,        'and stays scrolled while nothing changes';
	is [ $tall->scroll_rows(9), $tall->top_row ], [ 3, 7 ], 'up to the last rows';
};

subtest 'scrolling sideways' => sub {
	skip_all 'the locale has no double-width wcwidth for CJK' unless cluster_columns("\x{5B57}") == 2;

	my @cases = (
		[ 'abcdefghijkl',              8, 12, 5, 'the end of the text and the cell after it are in view' ],
		[ 'abcdefghijkl',              8, 0,  0, 'the start' ],
		[ "\x{5B57}\x{5B57}\x{5B57}x", 4, 7,  4, 'the view starts at a whole wide character, never inside one' ],
	);
	foreach my $case (@cases) {
		my ( $text, $width, $offset, $left, $name ) = @$case;
		my $view = view( $text, $width, 1 );
		$view->editor->move_to( 0, $offset );
		$view->follow_cursor;
		is $view->left_column, $left, $name;
	}

	my $shrinking = view( 'abcdefghijkl', 8, 1 );
	$shrinking->editor->set_text('abcdefghij');
	$shrinking->follow_cursor;
	is $shrinking->left_column, 3, 'no further than needed to fill the view';

	my $lines = view( "a very long first line\nshort", 8, 2 );
	$lines->editor->move_to( 0, 22 );
	$lines->follow_cursor;
	is $lines->left_column, 15, 'a text area scrolls by the same rule';
	$lines->editor->move_to( 1, 5 );
	$lines->follow_cursor;
	is $lines->left_column, 0, 'for the line of the cursor';
	ok !view( 'abcdefghijkl', 8, 1, wrap => 1 )->left_column, 'a wrapping view never scrolls sideways';
};

subtest 'positions under a cell' => sub {
	my $wrapped = view( 'the quick brown fox', 10, 3, wrap => 1 );
	is [ $wrapped->position_at( 1, 1 ) ], [ 0, 11 ], 'a cell of a wrapped row';
	is [ $wrapped->position_at( 9, 0 ) ], [ 0, 9 ],  'past the end of a wrapped part: before its last cluster';
	is [ $wrapped->position_at( 9, 1 ) ], [ 0, 19 ], 'past the end of the last part: the end of the line';
	is [ $wrapped->position_at( 0, 7 ) ], [ 0, 10 ], 'below the text: the last row';

	my $scrolled = view( 'abcdefghijkl', 8, 1 );
	is [ $scrolled->position_at( 0, 0 ) ], [ 0, 5 ], 'a scrolled view maps through the scroll';
	my $tall = view( join( "\n", 1 .. 10 ), 4, 3 );
	is [ $tall->position_at( 0, 1 ) ], [ 8, 0 ], 'also downwards';
};

subtest 'moving vertically' => sub {
	my $view   = view( "abcdef ghijkl mno\nxy", 7, 5, wrap => 1 );
	my $editor = $view->editor;
	is shown_rows($view), [ 'abcdef ', 'ghijkl ', 'mno', 'xy' ], 'four visual rows';

	$editor->move_to( 0, 4 );
	$view->move_vertically(1);
	is [ $editor->cursor ], [ 0, 11 ], 'Down moves to the next wrapped row at the same column';
	$view->move_vertically(1);
	is [ $editor->cursor ], [ 0, 17 ], 'a shorter row ends at its end';
	$view->move_vertically(1);
	is [ $editor->cursor ], [ 1, 2 ], 'the next line, still short';
	$view->move_vertically(-2);
	is [ $editor->cursor ], [ 0, 11 ], 'up again aims for the column it started at';
	$view->move_vertically( -1, 1 );
	is [ $editor->cursor, $editor->selected_text ], [ 0, 4, 'ef ghij' ], 'and extends the selection on request';
	$view->move_vertically(-1);
	is [ $editor->cursor ], [ 0, 0 ], 'beyond the first row: the start';
	$editor->move_to( 0, 2 );
	$view->move_vertically(1);
	is [ $editor->cursor ], [ 0, 9 ], 'a cursor moved by other means aims anew';
	$view->move_vertically(9);
	is [ $editor->cursor ], [ 1, 2 ], 'beyond the last row: the end';
};

subtest 'settings' => sub {
	my $view = view( 'secret', 10, 1 );
	is shown_rows($view), ['secret'], 'clusters are shown as they are';
	$view->set_display( sub { '*' } );
	is shown_rows($view), ['******'], 'until the display function says otherwise';
	like dies { Term::Fabulous::TextView->new( editor => 'text' ) }, qr/editor must be a Term::Fabulous::Editor/,    'the editor is checked';
	like dies { $view->set_size( -1, 2 ) },                          qr/set_size needs a non-negative integer size/, 'and the size';
	like dies { $view->set_display('*') },                           qr/display must be a code reference/,           'and the display';
};

done_testing;
