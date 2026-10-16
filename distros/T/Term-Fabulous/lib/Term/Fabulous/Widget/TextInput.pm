package Term::Fabulous::Widget::TextInput;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Editor;
use Term::Fabulous::TextView;
use Term::Fabulous::Widget::Input;

our $VERSION = '0.03';

class Term::Fabulous::Widget::TextInput
	:isa(Term::Fabulous::Widget::Input)
	:abstract
{
	use Feature::Compat::Try;
	use Scalar::Util qw(weaken);
	use Term::Fabulous::Check qw(boolean string);
	use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_LEFT TB_KEY_MOUSE_RELEASE TB_MOD_MOTION TB_MOD_SHIFT);
	use Time::HiRes qw(time);
	use Term::Fabulous::Unicode qw(sanitize_text grapheme_clusters);

	use constant DOUBLE_CLICK_SECONDS => 0.4;

	# Cursor movement: key name => [ editor method, extend the selection ].
	my %MOVEMENT_BY_KEY = (
		'Left'             => [ move_left           => 0 ],
		'Shift+Left'       => [ move_left           => 1 ],
		'Right'            => [ move_right          => 0 ],
		'Shift+Right'      => [ move_right          => 1 ],
		'Ctrl+Left'        => [ move_word_left      => 0 ],
		'Ctrl+Shift+Left'  => [ move_word_left      => 1 ],
		'Ctrl+Right'       => [ move_word_right     => 0 ],
		'Ctrl+Shift+Right' => [ move_word_right     => 1 ],
		'Home'             => [ move_line_start     => 0 ],
		'Shift+Home'       => [ move_line_start     => 1 ],
		'End'              => [ move_line_end       => 0 ],
		'Shift+End'        => [ move_line_end       => 1 ],
		'Ctrl+Home'        => [ move_document_start => 0 ],
		'Ctrl+Shift+Home'  => [ move_document_start => 1 ],
		'Ctrl+End'         => [ move_document_end   => 0 ],
		'Ctrl+Shift+End'   => [ move_document_end   => 1 ],
	);

	# Edits: key name => editor method.
	my %EDIT_BY_KEY = (
		'Backspace'    => 'delete_backward',
		'Delete'       => 'delete_forward',
		'Ctrl+W'       => 'delete_word_backward',
		'Ctrl+Delete'  => 'delete_word_forward',
		'Ctrl+U'       => 'delete_to_line_start',
		'Ctrl+K'       => 'delete_to_line_end',
		'Ctrl+X'       => 'cut',
		'Shift+Delete' => 'cut',
		'Ctrl+V'       => 'paste',
		'Shift+Insert' => 'paste',
		'Ctrl+Z'       => 'undo',
		'Ctrl+Y'       => 'redo',
	);

	# A text that must not show (a password) has no words to move or delete
	# by, which would tell where its spaces are: these keys act on the
	# whole text instead. It cannot be copied or cut either.
	my %WHOLE_TEXT_KEY_FOR = (
		'Ctrl+Left'        => 'Home',
		'Ctrl+Shift+Left'  => 'Shift+Home',
		'Ctrl+Right'       => 'End',
		'Ctrl+Shift+Right' => 'Shift+End',
		'Ctrl+W'           => 'Ctrl+U',
		'Ctrl+Delete'      => 'Ctrl+K',
	);
	my %COPIES = map { $_ => 1 } 'Ctrl+X', 'Shift+Delete', 'Ctrl+Insert';

	field $editor :reader = Term::Fabulous::Editor->new( multi_line => __CLASS__->is_multi_line );

	field $placeholder :param = '';
	field $read_only   :param = 0;

	# The explicit accept spec; undef takes the validator's suggestion.
	field $accept :param = undef;

	# How the text is laid out in the buffer: one row without wrapping
	# unless a subclass says otherwise.
	field $view :reader;

	# Mouse: whether a press in the widget started a drag, and the time and
	# position of the last press, for double clicks.
	field $dragging = 0;
	field @last_press;

	ADJUST :params ( :$value = undef, :$max_length = undef ) {
		weaken( my $weak_self = $self );
		$view = Term::Fabulous::TextView->new( editor => $editor, display => sub ($cluster) { $weak_self->display_cluster($cluster) } );

		$read_only   = boolean( $self, read_only => $read_only );
		$placeholder = string( $self, placeholder => $placeholder );
		$self->max_length($max_length) if defined $max_length;
		$self->_apply_accept;
		$self->value($value) if defined $value;
	}

	# Runs an editor call for a public method; the editor's errors are
	# reworded to name this widget, which is the class the caller used.
	method _in_editor ($code) {
		try {
			return $code->();
		}
		catch ($error) {
			$error =~ s/\ATerm::Fabulous::Editor:/ref($self) . ':'/e;
			die $error;
		}
	}

	method is_multi_line :common () {
		return 0;
	}

	# True when the text is not shown as it is (a masked password field).
	method hides_text () {
		return 0;
	}

	# ---------------------------------------------------------------------
	# Properties
	# ---------------------------------------------------------------------

	method value (@new) {
		return $editor->text unless @new;
		$self->_in_editor( sub { $editor->set_text( $new[0] ) } );
		$self->mark_changed;
		return $editor->text;
	}

	method max_length (@new) {
		return $editor->max_length unless @new;
		$self->_in_editor( sub { $editor->set_max_length( $new[0] ) } );
		return $editor->max_length;
	}

	method accept (@new) {
		return $accept unless @new;
		my $previous = $accept;
		$accept = $new[0];
		try {
			$self->_apply_accept;
		}
		catch ($error) {
			$accept = $previous;
			die $error;
		}
		return $accept;
	}

	# The editor takes the explicit accept spec, or the validator's
	# suggestion.
	method _apply_accept () {
		my $validator = $self->validator;
		my $spec      = $accept // ( defined $validator ? $validator->accept : undef );
		$self->_in_editor( sub { $editor->set_accept($spec) } );
		return;
	}

	method validator_changed :override () {
		$self->_apply_accept;
		return;
	}

	method placeholder (@new) {
		return $placeholder unless @new;
		$placeholder = string( $self, placeholder => $new[0] );
		$self->mark_changed;
		return $placeholder;
	}

	method read_only (@new) {
		return $read_only unless @new;
		$read_only = boolean( $self, read_only => $new[0] );
		return $read_only;
	}

	method theme_family :common () {
		return 'text_input';
	}

	method themed_params :common () {
		return ( $class->SUPER::themed_params, placeholder_color => [ 'placeholder', 'normal', 'cell_color' ], selection_color => [ 'selection', 'normal', 'cell_color' ] );
	}

	method placeholder_color (@new) {
		return @new ? $self->set_look( placeholder_color => $new[0] ) : $self->look_value('placeholder_color');
	}

	method selection_color (@new) {
		return @new ? $self->set_look( selection_color => $new[0] ) : $self->look_value('selection_color');
	}

	method layout_properties :common () {
		return (
			$class->SUPER::layout_properties,
			value       => 'scalar',
			placeholder => 'scalar',
			max_length  => 'scalar',
			accept      => 'scalar',
			read_only   => 'boolean',
		);
	}

	# The max_length, accept and validator of a layout come first, so they
	# limit the value wherever it stands.
	my %LIMITS_VALUE = map { $_ => 1 } qw(max_length accept validator);

	method apply_layout_settings :override (@settings) {
		return $self->SUPER::apply_layout_settings( ( grep { $LIMITS_VALUE{ $_->[0] } } @settings ), ( grep { !$LIMITS_VALUE{ $_->[0] } } @settings ) );
	}

	# ---------------------------------------------------------------------
	# Keys
	# ---------------------------------------------------------------------

	method handle_key ($event) {
		my $text = $event->text;
		return $self->apply_edit( $editor->type($text) ) if defined $text && !$read_only;

		my $name = $event->main_key_name // return 0;
		if ( $self->hides_text ) {
			return 0 if $COPIES{$name};
			$name = $WHOLE_TEXT_KEY_FOR{$name} // $name;
		}
		if ( my $movement = $MOVEMENT_BY_KEY{$name} ) {
			my ( $method, $extend ) = @$movement;
			$editor->$method($extend);
			return $self->_view_changed;
		}
		if ( my $edit = $EDIT_BY_KEY{$name} ) {
			return 0 if $read_only;
			return $self->apply_edit( $editor->$edit );
		}
		if ( $name eq 'Ctrl+A' ) {
			$editor->select_all;
			return $self->_view_changed;
		}
		if ( $name eq 'Ctrl+Insert' ) {
			$editor->copy;
			return 1;
		}
		return 0;
	}

	# The editor changed the cursor, the selection or the text: the next
	# frame shows it. Returns 1, for handlers that used their event.
	method _view_changed () {
		$self->mark_changed;
		return 1;
	}

	# After an editor edit: fires Change when the text changed. Returns 1,
	# the key was used either way.
	method apply_edit ($changed) {
		$self->_view_changed;
		$self->fire_change( $editor->text ) if $changed;
		return 1;
	}

	# ---------------------------------------------------------------------
	# Mouse: a press places the cursor, a Shift+click extends the
	# selection to it, a double click selects a word (the whole text when
	# it is hidden), dragging selects.
	# ---------------------------------------------------------------------

	method handle_mouse ($event) {
		my $key = $event->key;
		if ( $key == TB_KEY_MOUSE_RELEASE ) {
			$dragging = 0;
			return 1;
		}
		return 0 unless $key == TB_KEY_MOUSE_LEFT;

		my ( $column, $row ) = $self->cell_at($event);
		return 1 unless defined $column;
		my @position = $view->position_at( $column, $row );

		if ( $event->modifiers & TB_MOD_MOTION ) {
			$editor->move_to( @position, 1 ) if $dragging;
			return $self->_view_changed;
		}

		my $now = time;
		if ( $event->modifiers & TB_MOD_SHIFT ) {
			$editor->move_to( @position, 1 );
			@last_press = ();
		}
		elsif ( @last_press && $now - $last_press[0] <= DOUBLE_CLICK_SECONDS && "@last_press[1, 2]" eq "@position" ) {
			$self->hides_text ? $editor->select_all : $editor->select_word_at(@position);
			@last_press = ();
		}
		else {
			$editor->move_to( @position, 0 );
			@last_press = ( $now, @position );
		}
		$dragging = 1;
		return $self->_view_changed;
	}

	# ---------------------------------------------------------------------
	# Painting
	# ---------------------------------------------------------------------

	# Edits made through the editor, also by the program, show when the
	# frame is drawn: the view follows the cursor whenever the editor or
	# the size changed.
	method refresh :override () {
		$view->set_size( $self->columns, $self->rows )->follow_cursor;
		return $self->SUPER::refresh;
	}

	method paint_key :override () {
		return ( $self->SUPER::paint_key, $editor->revision, $view->top_row, $view->left_column );
	}

	method focus_changed :override ($is_focused) {
		$dragging = 0;
		return;
	}

	# How a cluster of the text is shown; a password field masks it.
	method display_cluster ($cluster) {
		return sanitize_text($cluster);
	}

	method paint () {
		$self->paint_focus_background;
		return $self->_paint_placeholder if $editor->is_empty && length $placeholder;

		my $width = $view->text_columns;
		my $y     = 0;
		foreach my $row ( $view->visible_rows ) {
			my ( $line, $from, $to, $is_last, $shown ) = @$row;
			my $end_x = $self->_paint_part( $y, $line, $shown, $to, $is_last, $from, $width );
			$self->_paint_selected_line_break( $y, $line, $end_x, $width ) if $is_last;
			$y++;
		}
		return;
	}

	sub _is_selected ( $selection, $row, $offset ) {
		my ( $row_0, $offset_0, $row_1, $offset_1 ) = @$selection;
		return 0 unless defined $row_0;
		return 0 if $row < $row_0 || ( $row == $row_0 && $offset < $offset_0 );
		return 0 if $row > $row_1 || ( $row == $row_1 && $offset >= $offset_1 );
		return 1;
	}

	# Paints the part [from, to) of a line on buffer row $y, scrolled as
	# the view is, with the selection and (when $cursor_at_end allows a
	# cursor at $to) the cursor. Text in [hidden_from, from) belongs to the
	# row unseen; a cursor on it is shown at $from. Returns the column after
	# the text.
	method _paint_part ( $y, $row, $from, $to, $cursor_at_end, $hidden_from, $width ) {
		my @selection = $editor->selection;
		my ( $cursor_row, $cursor_offset ) = $editor->cursor;
		my $has_cursor = $self->is_focused && $cursor_row == $row;
		$cursor_offset = $from if $cursor_offset >= $hidden_from && $cursor_offset < $from;
		my $fg       = $self->foreground_attr;
		my $bg       = $self->focus_background_attr;
		my $selected = $self->color_attr( $self->look_value('selection_color') );

		my $x = -$view->left_column;
		foreach my $cluster ( $view->clusters( $row, $from, $to ) ) {
			my ( $offset, $display, $columns ) = @$cluster;
			my $cell_bg = _is_selected( \@selection, $row, $offset ) ? $selected : $bg;
			my $cell_fg = $has_cursor && $offset == $cursor_offset ? $self->reverse_attr($fg) : $fg;
			$self->put_attrs( $x, $y, $display, $cell_fg, $cell_bg ) if $x >= 0 && $x + $columns <= $width;
			$x += $columns;
		}
		$self->put_attrs( $x, $y, ' ', $self->reverse_attr($fg), $bg )
			if $has_cursor && $cursor_at_end && $cursor_offset == $to && $x >= 0 && $x < $width;
		return $x;
	}

	# A selection reaching over the end of a line shows a selected cell
	# after it.
	method _paint_selected_line_break ( $y, $line, $x, $width ) {
		return if $line == $editor->line_count - 1 || $x < 0 || $x >= $width;
		my ( $row_0, $offset_0, $row_1 ) = $editor->selection;
		return unless defined $row_0 && $line < $row_1;
		return if $line < $row_0 || ( $line == $row_0 && $offset_0 > length $editor->line($line) );

		my ( $cursor_row, $cursor_offset ) = $editor->cursor;
		return if $self->is_focused && $cursor_row == $line && $cursor_offset == length $editor->line($line);
		$self->put_attrs( $x, $y, ' ', undef, $self->color_attr( $self->look_value('selection_color') ) );
		return;
	}

	method _paint_placeholder () {
		my $bg = $self->focus_background_attr;
		$self->paint_text( 0, 0, $placeholder, $self->color_attr( $self->look_value('placeholder_color') ), $bg );
		return unless $self->is_focused;

		my ($first) = grapheme_clusters($placeholder);
		$self->put_attrs( 0, 0, $first // ' ', $self->reverse_attr( $self->foreground_attr ), $bg );
		return;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::TextInput - Common base class of the text input widgets

=head1 SYNOPSIS

	use Clay::UI::Enum::Result;
	use Term::Fabulous::Widget::TextField;

	# The parameters and methods below work the same for both text inputs:
	my $field = Term::Fabulous::Widget::TextField->new(
		value             => 'initial text',
		placeholder       => 'Type here',
		max_length        => 40,
		accept            => 'a-zA-Z ',    # the characters the user may type
		read_only         => 0,
		placeholder_color => '#787e8a',
		selection_color   => [ 38, 79, 120 ],
	);

	my $text = $field->value;          # a character string
	$field->value('replaced');         # fires no Change event

	$field->on( Change => sub ($event) {
		say 'now: ', $event->value;
		return Clay::UI::Enum::Result->CONTINUE;
	} );

=head1 DESCRIPTION

C<Term::Fabulous::Widget::TextInput> is the abstract base class of
L<Term::Fabulous::Widget::TextField> (one line) and
L<Term::Fabulous::Widget::TextArea> (several lines). It holds what both
have in common: the text with its cursor, selection, undo history and
clipboard (kept in a L<Term::Fabulous::Editor>), the editing keys, mouse
selection, the placeholder and the C<read_only> mode. You do not create
a C<TextInput> directly; its C<new> dies.

The text is a Perl character string (decoded text), not UTF-8 encoded
bytes. The cursor moves by grapheme clusters, that is by what a reader
sees as one character (a letter with a combining accent, an emoji with
modifiers, a flag), and wide characters such as CJK take two columns.

While the input has the focus, its content is painted on
C<focus_background_color> and the cursor is shown as a block: the
character under it in reverse video. Selected text is painted on
C<selection_color>. While the text is empty, the C<placeholder> is
shown instead, in C<placeholder_color>.

Everything described for L<Term::Fabulous::Widget::Input> applies as
well: C<disabled>, the colors, focus, sizing and the C<Change> event.

=head1 CONSTRUCTOR

=head2 new

	my $field = Term::Fabulous::Widget::TextField->new(%parameters);
	my $area  = Term::Fabulous::Widget::TextArea->new(%parameters);

The text inputs accept the parameters of
L<Term::Fabulous::Widget::Input/CONSTRUCTOR> and these. Unknown
parameters die.

=over

=item C<value>

A character string. Default: C<''>. The initial text. The cursor starts
at its end. A text field turns line breaks into spaces; a text area
converts C<"\r\n"> and C<"\r"> to C<"\n">. Dies if the text is longer
than C<max_length>.

=item C<placeholder>

A character string. Default: C<''> (none). A hint shown in
C<placeholder_color> while the text is empty. It is never part of the
C<value>.

=item C<max_length>

A non-negative integer, or C<undef>. Default: C<undef> (no limit). The
most characters the text may hold, counted in grapheme clusters; in a
text area every line break counts as one. Typing and pasting stop at the
limit: pasted text is cut to fit. Dies if the initial C<value> is longer.

=item C<accept>

Which characters the user may type or paste. One of:

=over

=item * a string: the body of a character class, written as between the
brackets of C<[...]> in a regular expression. C<'0-9'> accepts digits,
C<'a-zA-Z '> letters and blanks, C<'^0-9'> everything but digits. A
C<-> that is not part of a range goes first or last (C<'0-9-'>), and
C<]> and C<\> are written C<\]> and C<\\>;

=item * a regular expression, matched against each character (strictly,
each grapheme cluster: a letter with its accents, an emoji with its
modifiers): C<qr/\p{L}/> accepts letters of every script;

=item * a code reference, called with each grapheme cluster, that
returns true to accept it: C<< sub ($cluster) { $cluster ne ' ' } >>;

=item * C<undef>, the default: what the C<validator> suggests, if
anything (C<integer> suggests C<'0-9-'>, see
L<Term::Fabulous::Validator/accept>), else every character.

=back

Typing a rejected character does nothing. Pasted text keeps its
accepted characters and drops the rest; when none is accepted, the
paste does nothing, and does not replace the selection either. Line
breaks in a text area are always accepted. Dies if the initial C<value>
has a rejected character. To let the user type every character into a
field whose validator suggests a restriction, give C<< accept => qr/./ >>.
See L</accept>.

=item C<read_only>

A boolean, stored as 1 or 0. Default: 0. A read-only input can still
take the focus, and its text can be selected and copied, but the user
cannot change it: typing and the editing keys are not used and bubble
on to the ancestors. Programmatic writes to C<value> still work. A read-only input looks
like an editable one; disable it (L<Term::Fabulous::Widget::Input/disabled>)
when the user should see that the text cannot be changed. A reference
dies.

=item C<placeholder_color>

A color, in any format L<Term::Fabulous::Widget::Input> accepts.
Default: the theme's C<text_input.placeholder>, C<[120, 126, 138, 255]>
in the dark theme, a gray.

=item C<selection_color>

A color, in any format L<Term::Fabulous::Widget::Input> accepts. The
background of selected text. Default: the theme's
C<text_input.selection>, C<[38, 79, 120, 255]> in the dark theme, a
dark blue.

=item C<background_color>

Any L<Term::Fabulous::Color> format, stored as C<[r, g, b, a]>.
Default: the theme's C<text_input.background>, C<[36, 40, 48, 255]> in
the dark theme, a dark gray, so the input stands out from its
surroundings. Pass C<[0, 0, 0, 0]> for no background of its own.

=back

=head1 METHODS

=head2 value

	my $text = $input->value;
	$input->value("new text");

Accessor for the text, a character string. Writing replaces the whole
text, puts the cursor at its end, clears the selection and the undo
history, marks the input changed, and returns the new text (after line-break
conversion). It fires no C<Change> event. Dies if the new text is not a
string or is longer than C<max_length>.

=head2 max_length

	my $limit = $input->max_length;
	$input->max_length(10);
	$input->max_length(undef);         # no limit

Accessor for the length limit (see the C<max_length> parameter). Returns
the new limit. Dies if the limit is not a non-negative integer or
C<undef>, or if the current text is already longer; the limit then stays as it
was.

=head2 accept

	my $spec = $input->accept;         # as given; undef means the validator's suggestion
	$input->accept('0-9');
	$input->accept(qr/[^\s]/);
	$input->accept(undef);

Accessor for the C<accept> spec (see the C<accept> parameter). The
reader returns the spec as it was given, C<undef> included: what the
input actually uses then is the validator's suggestion, or nothing.
Writing C<undef> goes back to the validator's suggestion; writing
C<qr/./> accepts every character, whatever the validator suggests.
Writing returns the new spec. Dies, and keeps the old spec, for a
string that is not a valid character class body, for a reference of
another kind, and when the current text has a character the new spec
rejects. Setting C<value> to a text with a rejected character dies
too: the restriction is for the user, the program is expected to know
better.

=head2 placeholder

	$input->placeholder('Search');

Accessor for the placeholder text. Writing marks the input changed and
returns the new placeholder; a value that is not a string dies and
leaves the placeholder unchanged.

=head2 read_only

	my $is_read_only = $input->read_only;
	$input->read_only(1);

Accessor for the C<read_only> flag. Returns 1 or 0, also for a value
passed to C<new>. Any plain value is accepted as a boolean; a reference
dies and leaves the flag unchanged. Writing does not change what the
input shows.

=head2 placeholder_color

	$input->placeholder_color('#888888');

Accessor for the placeholder color. Writing marks the input changed and returns the
new color as C<[r, g, b, a]>; an invalid color dies and leaves the color
unchanged.

=head2 selection_color

	$input->selection_color([ 60, 60, 120 ]);

Accessor for the selection background. Writing marks the input changed and returns
the new color as C<[r, g, b, a]>; an invalid color dies and leaves the color
unchanged.

=head2 editor

	my $editor = $input->editor;

The L<Term::Fabulous::Editor> that holds the text, the cursor, the
selection and the undo history. Use it to move the cursor, select or
edit text from your program. Afterwards call C<< $input->mark_changed >>
so that a frame is drawn: the input notices the change of the editor
(L<Term::Fabulous::Editor/revision>) when the frame is drawn, scrolls
the cursor into view and paints the text. Edits made through the editor
fire no C<Change> event.

	$field->editor->select_all;
	$field->mark_changed;

	$area->editor->move_document_start;
	$area->editor->insert("Dear Sir or Madam,\n");
	$area->mark_changed;

=head1 KEYS

The keys below are named as L<Term::Fabulous::Event::KeyPress/main_key_name>
returns them, so the keypad keys a terminal with the kitty keyboard
protocol tells apart work as their main keyboard keys. A text input uses them while it has the focus and is
enabled; they then do not bubble. All other keys bubble on to the
ancestors: for example C<Escape>, C<Tab>, C<BackTab> (C<Shift+Tab>),
C<F1> to C<F12> and C<Alt+> combinations. L<Term::Fabulous> moves the
focus on C<Tab> and C<BackTab> and stops on C<Ctrl+C>, after the key
has been delivered.

=over

=item Typing

A printable character (pressed without C<Ctrl> or C<Alt>) is inserted at
the cursor, replacing the selection.

=item C<Left>, C<Right>

Move the cursor one character left or right, across line breaks. With a
selection, they move to its start (C<Left>) or end (C<Right>) and clear
it.

=item C<Ctrl+Left>, C<Ctrl+Right>

Move to the start of the word before the cursor, or to the end of the
word after it. Words are runs of letters, digits and C<_>.

=item C<Home>, C<End>

Move to the start or end of the line (in a text area: of the text
line, not of the wrapped row).

=item C<Ctrl+Home>, C<Ctrl+End>

Move to the start or end of the whole text.

=item C<Shift+Left>, C<Shift+Right>, C<Ctrl+Shift+Left>, C<Ctrl+Shift+Right>, C<Shift+Home>, C<Shift+End>, C<Ctrl+Shift+Home>, C<Ctrl+Shift+End>

The movements above, extending the selection.

=item C<Ctrl+A>

Selects the whole text.

=item C<Backspace>, C<Delete>

Delete the selection, or else the character before (C<Backspace>) or
after (C<Delete>) the cursor.

=item C<Ctrl+W>, C<Ctrl+Delete>

Delete the selection, or else the word before (C<Ctrl+W>) or after
(C<Ctrl+Delete>) the cursor.

=item C<Ctrl+U>, C<Ctrl+K>

Delete the selection, or else everything from the start of the line to
the cursor (C<Ctrl+U>) or from the cursor to the end of the line
(C<Ctrl+K>). At the very start (end) of a line, they delete the line
break before (after) it.

=item C<Ctrl+X>, C<Shift+Delete>

Cut: copy the selection to the clipboard and delete it.

=item C<Ctrl+Insert>

Copy the selection to the clipboard. C<Ctrl+C> is not copy: it stops
L<Term::Fabulous> (unless the UI was made with
C<< stop_on_ctrl_c =E<gt> 0 >>; the input does not use C<Ctrl+C> either
way, so a program can bind it).

=item C<Ctrl+V>, C<Shift+Insert>

Paste the clipboard at the cursor, replacing the selection.

=item C<Ctrl+Z>, C<Ctrl+Y>

Undo and redo. Consecutive typing is undone one word (or one run of
spaces) at a time; up to 100 steps are kept.

=back

The clipboard is the one of L<Term::Fabulous::Editor/clipboard>: one
string shared by all text inputs of the program. It is not the system
clipboard.

While C<read_only> is set, typing and the keys that change the text
(C<Backspace>, C<Delete>, C<Ctrl+W>, C<Ctrl+Delete>, C<Ctrl+U>,
C<Ctrl+K>, C<Ctrl+X>, C<Shift+Delete>, C<Ctrl+V>, C<Shift+Insert>,
C<Ctrl+Z>, C<Ctrl+Y>) are not used and bubble; movement, selection and
copying still work.

While the text is hidden (a L<Term::Fabulous::Widget::TextField> with a
C<mask>), the word keys act on the whole text, so they cannot tell
where its spaces are: C<Ctrl+Left> and C<Ctrl+Right> move like C<Home>
and C<End>, C<Ctrl+W> and C<Ctrl+Delete> delete like C<Ctrl+U> and
C<Ctrl+K>. C<Ctrl+X>, C<Shift+Delete> and C<Ctrl+Insert> do nothing
and bubble: hidden text is not copied to the clipboard.

L<Term::Fabulous::Widget::TextField> and
L<Term::Fabulous::Widget::TextArea> add keys of their own (C<Enter>,
C<Up>, C<Down>, ...); see their KEYS sections.

=head1 MOUSE

=over

=item Click

A left click places the cursor at the clicked character and focuses the
input.

=item Shift+click

A left click with C<Shift> held extends the selection from the cursor
to the clicked character. Many terminals keep C<Shift> with the mouse
for their own text selection and do not pass such a click on; dragging
works everywhere.

=item Double click

A second left click at the same position within 0.4 seconds selects the
word there (or the single character, when it is not part of a word),
or the whole text while it is hidden.

=item Drag

Moving the pointer with the left button held selects from where the
button went down to the pointer, as long as the pointer stays over the
input.

=back

=head1 EVENTS

=over

=item C<Change>

L<Term::Fabulous::Event::Change> after every change the user makes to
the text (typing, deleting, cutting, pasting, undo, redo), with the new
text as its C<value>. Keys that do not change the text (cursor
movement, copying, typing at C<max_length>) fire nothing. Programmatic
changes through C<value> or C<editor> fire nothing.

=back

L<Term::Fabulous::Widget::TextField> also fires
L<Term::Fabulous::Event::Submit> on C<Enter>.

=head1 KDL PROPERTIES

The properties of L<Term::Fabulous::Widget::Input/KDL PROPERTIES>, plus
C<value>, C<placeholder>, C<max_length>, C<accept> (a character class
body), C<read_only> (C<#true> / C<#false>), C<placeholder_color> and
C<selection_color>. C<max_length>, C<accept> and C<validator> are
applied before C<value>, wherever they stand, so a value that is too
long or has a rejected character dies.

=for highlighter language=kdl

	TextField "nick" {
		max_length 12
		accept "a-zA-Z0-9_"
		value "guest"
		placeholder "Nickname"
	}
	TextField "port" {
		validator "integer"
		required #true
	}

=head1 SUBCLASS INTERFACE

L<Term::Fabulous::Widget::TextField> and
L<Term::Fabulous::Widget::TextArea> build on these; a new kind of text
input would too. A text input lays its text out with a
L<Term::Fabulous::TextView> (L</view>), which does the wrapping, the
scrolling and the mapping between cells and text positions; the text
input keeps the keys, the mouse, the painting and the placeholder.

=head2 is_multi_line

=for highlighter language=perl

	method is_multi_line :common () { return 1 }

Class method. Whether the editor keeps line breaks (1) or turns them
into spaces (0, the default).

=head2 view

	$self->view->set_wrap(1);

The L<Term::Fabulous::TextView> of the input: one row without wrapping
until a subclass changes its settings (see
L<Term::Fabulous::TextView/set_wrap, set_scrollbar>). The input gives it the size
of its buffer and lets it follow the cursor every time a frame is drawn,
and paints the rows it shows. Use it to move the cursor by rows
(L<Term::Fabulous::TextView/move_vertically>) or to scroll
(L<Term::Fabulous::TextView/scroll_rows>); call C<mark_changed> after
changing what it shows.

=head2 natural_size

	method natural_size () { return ( $preferred_columns, 1 ) }

Required; see L<Term::Fabulous::Widget::Input/natural_size>.

=head2 paint

	method paint :override () {
		$self->SUPER::paint;
		...    # paint more, for example a scrollbar
	}

Paints the rows the view shows, with the selection and the cursor, or
the placeholder while the text is empty; see
L<Term::Fabulous::Widget::Input/paint>. Override it to paint more.

=head2 hides_text

	method hides_text :override () { return defined $mask ? 1 : 0 }

Whether the text is not shown as it is. Default: 0; the text field
returns 1 while it has a C<mask>. While it is true, the text cannot be
copied or cut, and the word keys and the double click act on the whole
text (see L</KEYS>).

=head2 display_cluster

	method display_cluster :override ($cluster) { return $shown }

How one grapheme cluster of the text is shown; the view lays the text
out with what this returns. The default replaces control characters
(see L<Term::Fabulous::Unicode/sanitize_text>); the text field returns
its C<mask> instead when one is set. When what it returns changes, call
L<Term::Fabulous::TextView/display_changed>.

=head2 apply_edit

	return $self->apply_edit( $self->editor->insert($text) );

Call after an editor edit made on behalf of the user: marks the input
changed (the next frame scrolls to the cursor and paints the result),
and fires C<Change> when the argument is true (the editor's edit
methods return whether the text changed). Returns 1, so it can be
returned from C<handle_key> directly.

=head1 SEE ALSO

L<Term::Fabulous::Widget::TextField>, L<Term::Fabulous::Widget::TextArea>,
L<Term::Fabulous::Editor>, L<Term::Fabulous::TextView>,
L<Term::Fabulous::Widget::Input>,
L<the editing section of the forms guide|Term::Fabulous::Manual::Forms/EDITING TEXT>,
L<Term::Fabulous::Cookbook::Forms/Copy and paste through the clipboard>.

=cut
