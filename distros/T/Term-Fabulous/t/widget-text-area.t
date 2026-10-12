use v5.32;
use warnings;
use utf8;

use Test2::V0;

use FindBin;
use lib "$FindBin::Bin/lib";

use InputTest;
use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_WHEEL_DOWN TB_KEY_MOUSE_WHEEL_UP);
use Term::Fabulous::Widget::TextArea;

sub text_area {
	my (%options) = @_;

	my $area = Term::Fabulous::Widget::TextArea->new( preferred_columns => 12, preferred_rows => 3, %options );
	my $ui   = layout_ui($area);
	return ( $area, $ui );
}

sub rows {
	my ($area) = @_;
	return [ map { row_text( $area, $_ ) } 0 .. $area->rows - 1 ];
}

subtest 'size, wrapping and the scrollbar' => sub {
	my ( $area, $ui ) = text_area( value => "The quick brown fox jumps\nend" );
	is [ $area->columns, $area->rows ], [ 12, 3 ], 'preferred size without a layout size';
	is rows($area), [ "brown fox  \x{2502}", "jumps      \x{2503}", "end        \x{2503}" ],
		'lines wrap at spaces; the scrollbar shows when the text is taller';

	$area->wrap(0);
	is rows($area), [ 'The quick br', 'end         ', '            ' ], 'without wrapping every line takes one row';

	$area->wrap(1);
	$area->value('abcdefghijklmnopqrstuvwxyz');
	is rows($area), [ 'abcdefghijkl', 'mnopqrstuvwx', 'yz          ' ], 'a word wider than the area breaks anywhere';
};

subtest 'Enter, vertical movement and the goal column' => sub {
	my ( $area, $ui ) = text_area();
	my @changes;
	$area->on( Change => sub { push @changes, $_[0]->value; return } );
	type_text( $area, 'abcdef' );
	press( $area, 'Enter' );
	type_text( $area, 'ab' );
	is $area->value,    "abcdef\nab", 'Enter starts a new line';
	is scalar @changes, 9,            'every edit fires Change';

	press( $area, 'Up' );
	is [ $area->editor->cursor ], [ 0, 2 ], 'Up keeps the column';
	press( $area, 'End' );
	press( $area, 'Down' );
	is [ $area->editor->cursor ], [ 1, 2 ], 'Down stops at the end of a shorter line';
	press( $area, 'Up' );
	is [ $area->editor->cursor ], [ 0, 6 ], 'and returns to the column it aimed for';
	press( $area, 'Up' );
	is [ $area->editor->cursor ], [ 0, 0 ], 'Up on the first row goes to the start';
	press( $area, 'Shift+Down' );
	is $area->editor->selected_text, "abcdef\n", 'Shift+Down selects';
};

subtest 'scrolling follows the cursor' => sub {
	my ( $area, $ui ) = text_area( value => join "\n", 1 .. 10 );
	is $area->top_row, 7, 'the end of a long text is in view';
	press( $area, 'Ctrl+Home' );
	is shown($area)->top_row, 0, 'moving to the start scrolls up when the frame shows it';
	press( $area, 'PageDown' );
	is [ $area->editor->cursor ], [ 2, 0 ], 'Page Down moves by the height less one row';

	my $notch = click( $area, 0, 0, key => TB_KEY_MOUSE_WHEEL_DOWN );
	is [ $area->top_row, $area->editor->cursor ], [ 3, 2, 0 ], 'the wheel scrolls without moving the cursor';
	ok $notch->wheel_used, 'and uses the notch';
	click( $area, 0, 1 );
	is [ $area->editor->cursor ], [ 4, 0 ], 'a click maps through the scrolled view';

	click( $area, 0, 0, key => TB_KEY_MOUSE_WHEEL_DOWN ) foreach 1 .. 3;
	is $area->top_row, 7, 'down to the last rows';
	ok !click( $area, 0, 0, key => TB_KEY_MOUSE_WHEEL_DOWN )->wheel_used, 'a notch past the end is left to a scroll box around it';
	ok click( $area,  0, 0, key => TB_KEY_MOUSE_WHEEL_UP )->wheel_used,   'one back is not';
};

subtest 'wrapping wide characters and blanks' => sub {
	my ( $area, $ui ) = text_area( preferred_columns => 10, preferred_rows => 4, scrollbar => 0, value => "aaaaaaaaaa bbbbbbbbb\x{5B57}cd" );
	is rows($area), [ 'aaaaaaaaaa', 'bbbbbbbbb ', "\x{5B57}cd      ", '          ' ],
		'a wide character that does not fit after the carried word gets a row of its own; the blank at a full row hangs';

	$ui->interaction->set_focused_widget($area);
	$area->editor->move_to( 0, 10 );
	$area->mark_changed;    # edits through the editor make no frame due by themselves
	is [ map { shown($area)->cell( 0, 1 )->[$_] } 0, 1 ], [ 'b', $area->reverse_attr( $area->foreground_attr ) ], 'a cursor on the hanging blank shows at the start of the next row';
	press( $area, 'Right' );
	is [ $area->editor->cursor ], [ 0, 11 ], 'and Right moves on past it';
	click( $area, 0, 1 );
	is [ $area->editor->cursor ], [ 0, 11 ], 'a click on that row lands after the blank';
};

subtest 'editing re-wraps the changed lines' => sub {
	my ( $area, $ui ) = text_area( value => "one two three\nfour" );
	is rows($area), [ 'one two     ', 'three       ', 'four        ' ], 'wrapped';
	$area->editor->move_to( 0, 3 );
	press( $area, 'Delete' );
	press( $area, 'Delete' );
	press( $area, 'Delete' );
	press( $area, 'Delete' );
	is rows($area), [ 'one three   ', 'four        ', '            ' ], 'the edited line is wrapped again, the others are kept';
	$area->value("four\none two three");
	is rows($area), [ 'four        ', 'one two     ', 'three       ' ], 'lines that moved keep their wrapping';
};

subtest 'selection across lines' => sub {
	my ( $area, $ui ) = text_area( value => "ab\ncd" );
	$ui->interaction->set_focused_widget($area);
	press( $area, 'Ctrl+A' );
	my $selected = $area->color_attr( $area->selection_color );
	is [ map { shown($area)->cell( $_, 0 )->[2] } 0 .. 2 ], [ ($selected) x 3 ], 'a selected line break shows as a selected cell';
	press( $area, 'Delete' );
	is $area->value, '', 'the selection is deleted';
};

done_testing;
