package Term::Fabulous::Widget::TextArea;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::TextInput;

our $VERSION = '0.02';

class Term::Fabulous::Widget::TextArea
	:isa(Term::Fabulous::Widget::TextInput)
	:strict(params)
{
	use List::Util qw(max);
	use Term::Fabulous::Check qw(boolean positive_integer);
	use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_WHEEL_UP TB_KEY_MOUSE_WHEEL_DOWN);
	use Term::Fabulous::Viewport qw(scroll_thumb);
	use Term::Fabulous::Widget::Scrollbar;

	use constant WHEEL_ROWS => 3;

	# Vertical movement: key name => [ direction, unit, extend the selection ].
	my %VERTICAL_BY_KEY = (
		'Up'             => [ -1, 'row',  0 ],
		'Shift+Up'       => [ -1, 'row',  1 ],
		'Down'           => [  1, 'row',  0 ],
		'Shift+Down'     => [  1, 'row',  1 ],
		'PageUp'         => [ -1, 'page', 0 ],
		'Shift+PageUp'   => [ -1, 'page', 1 ],
		'PageDown'       => [  1, 'page', 0 ],
		'Shift+PageDown' => [  1, 'page', 1 ],
	);

	field $preferred_columns :param = 40;
	field $preferred_rows    :param = 5;
	field $wrap              :param = 1;
	field $scrollbar         :param = 1;

	ADJUST {
		$preferred_columns = positive_integer( $self, preferred_columns => $preferred_columns );
		$preferred_rows    = positive_integer( $self, preferred_rows    => $preferred_rows );
		$wrap              = boolean( $self, wrap      => $wrap );
		$scrollbar         = boolean( $self, scrollbar => $scrollbar );
		$self->view->set_wrap($wrap)->set_scrollbar($scrollbar);
	}

	method is_multi_line :common :override () {
		return 1;
	}

	method preferred_columns (@new) {
		return $preferred_columns unless @new;
		$preferred_columns = positive_integer( $self, preferred_columns => $new[0] );
		$self->mark_changed;
		return $preferred_columns;
	}

	method preferred_rows (@new) {
		return $preferred_rows unless @new;
		$preferred_rows = positive_integer( $self, preferred_rows => $new[0] );
		$self->mark_changed;
		return $preferred_rows;
	}

	method wrap (@new) {
		return $wrap unless @new;
		$wrap = boolean( $self, wrap => $new[0] );
		$self->view->set_wrap($wrap);
		$self->mark_changed;
		return $wrap;
	}

	method scrollbar (@new) {
		return $scrollbar unless @new;
		$scrollbar = boolean( $self, scrollbar => $new[0] );
		$self->view->set_scrollbar($scrollbar);
		$self->mark_changed;
		return $scrollbar;
	}

	method layout_properties :common () {
		return ( $class->SUPER::layout_properties, preferred_columns => 'scalar', preferred_rows => 'scalar', wrap => 'boolean', scrollbar => 'boolean' );
	}

	method natural_size () {
		return ( $preferred_columns, $preferred_rows );
	}

	method top_row () {
		return $self->view->top_row;
	}

	method scroll_rows ($rows) {
		$self->view->scroll_rows($rows);
		return $self->mark_changed;
	}

	# ---------------------------------------------------------------------
	# Input
	# ---------------------------------------------------------------------

	method handle_key :override ($event) {
		my $name = $event->main_key_name // '';
		if ( my $vertical = $VERTICAL_BY_KEY{$name} ) {
			my ( $direction, $unit, $extend ) = @$vertical;
			$self->view->move_vertically( $direction * ( $unit eq 'page' ? max( 1, $self->rows - 1 ) : 1 ), $extend );
			$self->mark_changed;
			return 1;
		}
		return $self->apply_edit( $self->editor->insert("\n") ) if $name eq 'Enter' && !$self->read_only;
		return $self->SUPER::handle_key($event);
	}

	# At its end the notch is left to a scroll box around the area.
	method handle_mouse :override ($event) {
		my $key = $event->key;
		return $self->SUPER::handle_mouse($event) unless $key == TB_KEY_MOUSE_WHEEL_UP || $key == TB_KEY_MOUSE_WHEEL_DOWN;
		return 0 unless $self->view->scroll_rows( $key == TB_KEY_MOUSE_WHEEL_UP ? -WHEEL_ROWS : WHEEL_ROWS );
		$self->mark_changed;
		$event->use_wheel;
		return 1;
	}

	method value :override (@new) {
		return $self->SUPER::value unless @new;
		$self->view->home;
		return $self->SUPER::value(@new);
	}

	# ---------------------------------------------------------------------
	# Painting
	# ---------------------------------------------------------------------

	method paint :override () {
		$self->SUPER::paint;
		$self->_paint_scrollbar if $self->view->has_scrollbar;
		return;
	}

	# In the last column, in the theme's scrollbar colors.
	method _paint_scrollbar () {
		my $view = $self->view;
		Term::Fabulous::Widget::Scrollbar->paint_track(
			$self,
			axis            => 'vertical',
			at              => $self->columns - 1,
			thumb           => scroll_thumb( $view->visual_row_count, $self->rows, $view->top_row, $self->rows ),
			track_attr      => $self->color_attr( $self->family_look( scrollbar => 'track' ) ),
			thumb_attr      => $self->color_attr( $self->family_look( scrollbar => 'thumb' ) ),
			background_attr => $self->focus_background_attr,
		);
		return;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::TextArea - Multi-line text input

=head1 SYNOPSIS

	use Clay::UI::Enum::Result;
	use Term::Fabulous::Widget::TextArea;
	use Clay::XS qw(sizing_grow sizing_fixed);

	my $notes = Term::Fabulous::Widget::TextArea->new(
		id          => 'notes',
		placeholder => 'Notes',
		layout      => { sizing => { width => sizing_grow(), height => sizing_fixed(8) } },
	);

	my $dirty = 0;
	$notes->on( Change => sub ($event) {
		$dirty = 1;
		return Clay::UI::Enum::Result->CONTINUE;
	} );

	my @lines = split /\n/, $notes->value, -1;

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.02/screenshots/widget-text-area.svg" alt="A text area with a shopping list, a wrapped long line and a scrollbar"></p>

=end html

=head1 DESCRIPTION

The picture shows a focused text area of six rows with the cursor at the
end of the text. The long line about the party wraps at a space, and
the scrollbar on the right shows that the text has more rows than the
area: the first line is scrolled out at the top. The program is
F<examples/widgets/text-area.pl>.

A text area holds text of several lines that the user can type, edit,
select and copy. By default, lines longer than the area are wrapped at
word boundaries; with C<< wrap => 0 >> every line takes one row and the
view scrolls sideways instead. The view scrolls up and down to keep the
cursor visible, and while the text is taller than the area, a scrollbar
is shown in its rightmost column.

The text (C<value>) is a Perl character string; lines are separated by
C<"\n">. C<"\r\n"> and C<"\r"> in assigned or pasted text are converted
to C<"\n">.

The editing keys, mouse selection, the placeholder, C<max_length>,
C<read_only> and the C<Change> event are shared with the text field and
described in L<Term::Fabulous::Widget::TextInput>. Disabling, colors and
sizing are described in L<Term::Fabulous::Widget::Input>.

=head1 CONSTRUCTOR

=head2 new

	my $area = Term::Fabulous::Widget::TextArea->new(%parameters);

Accepts the parameters of
L<Term::Fabulous::Widget::TextInput/CONSTRUCTOR> (C<value>,
C<placeholder>, C<max_length>, C<read_only>, C<placeholder_color>,
C<selection_color>, C<background_color>) and of
L<Term::Fabulous::Widget::Input/CONSTRUCTOR> (C<id>, C<layout>,
C<disabled>, C<can_focus>, C<text_color>, C<disabled_color>,
C<accent_color>, C<focus_background_color>, the border parameters, the
other Box parameters), plus the ones below. Unknown parameters die.

=over

=item C<preferred_columns>

A positive integer. Default: 40. The width of the text in columns when
the C<layout> gives the area no width. Dies if not a positive integer.

=item C<preferred_rows>

A positive integer. Default: 5. The height of the text in rows when the
C<layout> gives the area no height. Dies if not a positive integer.

=item C<wrap>

A boolean, stored as 1 or 0; a reference dies. Default: 1. When true, a line longer than
the area continues on the next row, broken after the last space that
fits, or inside a word that is wider than the area. A space at which a
full row breaks is not shown at the start of the next row; the cursor
before it shows there, on the same cell as the cursor after it, so
C<Right> over that space moves the cursor without visible change. A wide character that does not fit at the end of a
row starts the next one. When false, every line takes exactly one row
and the view scrolls sideways with the cursor, by the rule a text field
follows (see L<Term::Fabulous::TextView/Scrolling>): it shows the
cursor's cell, starts where a character of the cursor's line starts and
scrolls no further than needed to fill the area with that line.

=item C<scrollbar>

A boolean, stored as 1 or 0; a reference dies. Default: 1. When true, a scrollbar is
shown in the rightmost column while the text has more rows than the
area; it then takes one column from the text. The scrollbar only shows
the position; it cannot be dragged. It is drawn like every scrollbar
(L<Term::Fabulous::Widget::Scrollbar>), in the theme's C<scrollbar.track>
and C<scrollbar.thumb> colors.

=back

=head1 METHODS

The methods of L<Term::Fabulous::Widget::TextInput/METHODS> (C<value>,
C<max_length>, C<placeholder>, C<read_only>, C<placeholder_color>,
C<selection_color>, C<editor>) and of
L<Term::Fabulous::Widget::Input/METHODS> (C<disabled>, C<is_enabled>,
the color accessors, C<mark_changed>), plus:

=head2 value

	my $text = $area->value;
	$area->value("first line\nsecond line");

As described in L<Term::Fabulous::Widget::TextInput/value>. Writing
also scrolls the view back to the top-left before it moves to the
cursor at the end of the new text.

=head2 preferred_columns

	my $columns = $area->preferred_columns;
	$area->preferred_columns(60);

Accessor for the C<preferred_columns> parameter. Writing returns the new
value, which takes effect at the next frame. Dies if not a positive
integer; the old value then stays.

=head2 preferred_rows

	my $rows = $area->preferred_rows;
	$area->preferred_rows(10);

Accessor for the C<preferred_rows> parameter. Writing returns the new
value, which takes effect at the next frame. Dies if not a positive
integer; the old value then stays.

=head2 wrap

	$area->wrap(0);

Accessor for the C<wrap> parameter. Returns 1 or 0, also for a value
passed to C<new>. Writing re-wraps the text, marks the input changed
and returns the new value; the next frame scrolls to the cursor. Any
plain value is accepted as a boolean; a reference dies and leaves the
setting unchanged.

=head2 scrollbar

	$area->scrollbar(0);

Accessor for the C<scrollbar> parameter. Returns 1 or 0, also for a
value passed to C<new>. Writing marks the input changed and returns the
new value; the next frame scrolls to the cursor. Any plain value is
accepted as a boolean; a reference dies and leaves the setting
unchanged.

=head2 scroll_rows

	$area->scroll_rows(-3);    # three rows towards the top
	$area->scroll_rows(10);    # ten rows towards the end

Scrolls the view by visual rows (wrapped rows count separately) without
moving the cursor. Negative numbers scroll towards the top. The view
stops at the first and last row of the text. Returns the area. The view
jumps back to the cursor when a frame is drawn after the cursor, the
text or the size changed.

=head2 top_row

	my $row = $area->top_row;

The index of the first visual row shown, counted from 0. With wrapping,
a long line spans several visual rows. The view follows the cursor when
a frame is drawn, so after an edit or a cursor movement this is the row
the next frame shows at the top; the wheel scrolls it at once.

=head1 KEYS

All keys of L<Term::Fabulous::Widget::TextInput/KEYS>, plus:

=over

=item C<Enter>

Starts a new line (inserts C<"\n"> at the cursor, replacing the
selection). While C<read_only> is set, C<Enter> is not used and
bubbles. A text area fires no C<Submit> event.

=item C<Up>, C<Down>

Move the cursor one visual row up or down. While moving vertically, the
cursor aims for the column it had when vertical movement started. Above
the first row the cursor goes to the start of the text, below the last
row to its end.

=item C<PageUp>, C<PageDown>

Move the cursor by a page: the height of the area minus one row, but
at least one row.

=item C<Shift+Up>, C<Shift+Down>, C<Shift+PageUp>, C<Shift+PageDown>

The movements above, extending the selection.

=back

C<Home> and C<End> move to the start and end of the text line, not of
the wrapped row. C<Tab> is not inserted: it bubbles, and
L<Term::Fabulous> moves the focus to the next widget. C<Escape> and the
function keys bubble too.

=head1 MOUSE

As described in L<Term::Fabulous::Widget::TextInput/MOUSE>: click to
place the cursor, drag (while the pointer stays over the input) to
select, double-click to select a word. Each notch of the mouse wheel
scrolls the view by three rows without moving the cursor.

=head1 EVENTS

=over

=item C<Change>

L<Term::Fabulous::Event::Change> after every change the user makes to
the text (including C<Enter>); C<< $event->value >> is the whole new
text.

=back

=head1 KDL PROPERTIES

The properties of L<Term::Fabulous::Widget::TextInput/KDL PROPERTIES>,
plus C<preferred_columns>, C<preferred_rows>, C<wrap> and C<scrollbar>
(C<#true> / C<#false>):

=for highlighter language=kdl

	use Term::Fabulous::Widget::TextArea as TextArea

	TextArea "log" {
		preferred_rows 10
		wrap #false
		read_only #true
		sizing width=grow
	}

In KDL, C<value> is a single string; write line breaks as C<\n> inside
the string (C<value "first\nsecond">).

=head1 EXAMPLES

=head2 A read-only log that shows the newest line

=for highlighter language=perl

	my $log = Term::Fabulous::Widget::TextArea->new(
		read_only => 1,
		wrap      => 0,
		layout    => { sizing => { width => sizing_grow(), height => sizing_grow() } },
	);

	# Appends at the end through the editor: only the new line is wrapped
	# and kept for undo, however long the log grows.
	sub log_line ($line) {
		my $editor = $log->editor;
		$editor->move_document_end;
		$editor->insert( $editor->is_empty ? $line : "\n$line" );
		$log->mark_changed;    # the next frame scrolls to the new line
		return;
	}

=head2 Count the lines while the user types

	use Clay::UI::Enum::Result;

	$notes->on( Change => sub ($event) {
		my $lines = () = $event->value =~ /\n/g;
		$status->text( sprintf '%d lines', $lines + 1 );
		return Clay::UI::Enum::Result->CONTINUE;
	} );

=head1 CAVEATS

Inside a L<Term::Fabulous::Widget::ScrollBox>, a notch of the mouse
wheel over the text area scrolls the text area; once it shows its first
(last) rows, a notch up (down) scrolls the scroll box instead.

=head1 SEE ALSO

L<Term::Fabulous::Widget::TextInput>, L<Term::Fabulous::Widget::TextField>,
L<Term::Fabulous::Editor>,
L<the text area section of the forms guide|Term::Fabulous::Manual::Forms/Text areas>,
L<Term::Fabulous::Cookbook::Forms/Build a form from a KDL file (text fields, radio buttons, dropdown, slider, checkbox)>.

=cut
