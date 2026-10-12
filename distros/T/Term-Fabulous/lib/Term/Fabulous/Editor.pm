package Term::Fabulous::Editor;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Object::Pad 0.825;

class Term::Fabulous::Editor :strict(params) {
	use Feature::Compat::Try;
	use List::Util qw(sum0 uniq);
	use Term::Fabulous::Check qw(describe);
	use Term::Fabulous::Unicode qw(grapheme_clusters);

	use constant UNDO_LIMIT           => 100;
	use constant BOUNDARY_CACHE_LIMIT => 4096;

	# Grapheme cluster boundaries (character offsets) of a line, shared by
	# every editor. Lines are segmented as the renderer segments them.
	my %boundaries_by_line;

	# Shared by every editor of the process, like a desktop clipboard.
	my $clipboard = '';

	field $multi_line :param :reader = 1;
	field $max_length :param = undef;

	# Which grapheme clusters may enter the text: the spec as given (a
	# character class body, a regular expression or a code reference) and
	# the predicate it means; both undef when every cluster may.
	field $accept :param :reader = undef;
	field $is_accepted;

	field @lines = ('');

	# Positions are [row, offset]: a line index and a character offset that
	# is a grapheme cluster boundary of that line. The anchor is the other
	# end of the selection; it is empty when nothing is selected.
	field @cursor = ( 0, 0 );
	field @anchor;

	# Count changes, so views can cache what they derive: of the text, and
	# of the text, the cursor or the selection.
	field $text_revision :reader = 0;
	field $revision      :reader = 0;

	# Undo steps, oldest first: { changes, cursor, anchor, cursor_after }.
	# A change { row, offset, old, new } says that the text $old at
	# (row, offset) was replaced by $new; a step holds the changes of one
	# edit, or of a run of typing, in the order they were made, with the
	# cursor and anchor before the first and the cursor after the last.
	field @undo_stack;
	field @redo_stack;

	# The changes the running edit has made so far.
	field @changes;

	# The kind of the last undo step when typing may extend it: 'word' or
	# 'space'; undef when the next edit starts a new step.
	field $typing_run;

	ADJUST :params ( :$text = '' ) {
		$self->set_max_length($max_length);
		$self->set_accept($accept);
		$self->set_text($text);
	}

	sub _boundaries ($line) {
		my $boundaries = $boundaries_by_line{$line};
		return $boundaries if defined $boundaries;

		%boundaries_by_line = () if keys(%boundaries_by_line) >= BOUNDARY_CACHE_LIMIT;
		my @offsets = (0);
		push @offsets, $offsets[-1] + length $_ foreach grapheme_clusters($line);
		return $boundaries_by_line{$line} = \@offsets;
	}

	sub _compare ( $row_a, $offset_a, $row_b, $offset_b ) {
		return $row_a <=> $row_b || $offset_a <=> $offset_b;
	}

	# ---------------------------------------------------------------------
	# Text
	# ---------------------------------------------------------------------

	# Line breaks become "\n"; a single-line editor turns them into spaces.
	method _normalize ($text) {
		die "Term::Fabulous::Editor: text must be a string, got " . ( ref $text || 'undef' ) unless defined $text && !ref $text;
		$text =~ s/\r\n?/\n/g;
		$text =~ tr/\n/ / unless $multi_line;
		return $text;
	}

	sub _cluster_count ($text) {
		return sum0 map { scalar( @{ _boundaries($_) } ) - 1 } split /\n/, $text, -1;
	}

	# The predicate for a grapheme cluster that an accept spec means: a
	# code reference as it is, a regular expression the cluster must match,
	# a string as the body of a character class. Undef means no restriction.
	sub _acceptance_of ($spec) {
		return undef unless defined $spec;
		return $spec if ref $spec eq 'CODE';
		return sub ($cluster) { $cluster =~ $spec }
			if ref $spec eq 'Regexp';
		die "Term::Fabulous::Editor: accept must be a character class body, a regular expression, a code reference or undef, got " . describe($spec) if ref $spec;

		my $class;
		try {
			$class = qr/\A[$spec]\z/;
		}
		catch ($error) {
			die "Term::Fabulous::Editor: accept '$spec' is not the body of a character class: $error";
		}
		return sub ($cluster) { $cluster =~ $class };
	}

	# The distinct clusters of $text (line breaks aside) that the predicate
	# rejects.
	sub _rejected_by ( $is_accepted, $text ) {
		return () unless defined $is_accepted;
		return uniq grep { !$is_accepted->($_) } map { grapheme_clusters($_) } split /\n/, $text;
	}

	sub _die_for_rejected (@rejected) {
		die 'Term::Fabulous::Editor: the text has characters that accept rejects: "' . join( '', @rejected ) . '"';
	}

	method set_accept ($spec) {
		my $is_accepted_now = _acceptance_of($spec);
		my @rejected        = _rejected_by( $is_accepted_now, $self->text );
		_die_for_rejected(@rejected) if @rejected;
		( $accept, $is_accepted ) = ( $spec, $is_accepted_now );
		return $self;
	}

	# $text without the clusters that accept rejects; line breaks stay.
	method _accepted ($text) {
		return $text unless defined $is_accepted;
		return join "\n", map { $self->_accepted_line($_) } split /\n/, $text, -1;
	}

	method _accepted_line ($line) {
		return join q{}, grep { $is_accepted->($_) } grapheme_clusters($line);
	}

	method text () {
		return join "\n", @lines;
	}

	method set_text ($text) {
		$text = $self->_normalize($text);
		my $length = _cluster_count($text) + ( $text =~ tr/\n// );
		die "Term::Fabulous::Editor: the text has $length characters, more than max_length $max_length"
			if defined $max_length && $length > $max_length;
		my @rejected = _rejected_by( $is_accepted, $text );
		_die_for_rejected(@rejected) if @rejected;

		@lines      = split /\n/, $text, -1;
		@lines      = ('') unless @lines;
		@cursor     = ( $#lines, length $lines[-1] );
		@anchor     = ();
		@undo_stack = @redo_stack = ();
		$typing_run = undef;
		$text_revision++;
		$revision++;
		return $self;
	}

	method lines () {
		return @lines;
	}

	method line ($row) {
		return undef if $row < 0;
		return $lines[$row];
	}

	method line_count () {
		return scalar @lines;
	}

	method boundaries ($row) {
		return @{ _boundaries( $lines[$row] ) };
	}

	# In grapheme clusters; every line break counts as one.
	method character_count () {
		return sum0( map { scalar( @{ _boundaries($_) } ) - 1 } @lines ) + $#lines;
	}

	method max_length () {
		return $max_length;
	}

	# undef removes the limit; a limit below the current length dies.
	method set_max_length ($limit) {
		die "Term::Fabulous::Editor: max_length must be a non-negative integer or undef, got " . describe($limit)
			if defined $limit && !( !ref $limit && $limit =~ /\A[0-9]+\z/ );
		die "Term::Fabulous::Editor: the text has " . $self->character_count . " characters, more than max_length $limit"
			if defined $limit && $self->character_count > $limit;
		$max_length = defined $limit ? $limit + 0 : undef;
		return $self;
	}

	method is_empty () {
		return @lines == 1 && $lines[0] eq '';
	}

	# ---------------------------------------------------------------------
	# Cursor and selection
	# ---------------------------------------------------------------------

	method cursor () {
		return @cursor;
	}

	method has_selection () {
		return @anchor && _compare( @anchor, @cursor ) != 0 ? 1 : 0;
	}

	method selection () {
		return () unless $self->has_selection;
		return _compare( @anchor, @cursor ) < 0 ? ( @anchor, @cursor ) : ( @cursor, @anchor );
	}

	method selected_text () {
		my ( $row_0, $offset_0, $row_1, $offset_1 ) = $self->selection;
		return '' unless defined $row_0;
		return $self->_text_between( $row_0, $offset_0, $row_1, $offset_1 );
	}

	method _text_between ( $row_0, $offset_0, $row_1, $offset_1 ) {
		return substr( $lines[$row_0], $offset_0, $offset_1 - $offset_0 ) if $row_0 == $row_1;
		return join "\n", substr( $lines[$row_0], $offset_0 ), @lines[ $row_0 + 1 .. $row_1 - 1 ], substr( $lines[$row_1], 0, $offset_1 );
	}

	# The boundary at or before (direction -1) or after (+1) an offset.
	method _snap ( $row, $offset, $direction ) {
		my $boundaries = _boundaries( $lines[$row] );
		return $boundaries->[-1] if $offset >= $boundaries->[-1];
		return 0 if $offset <= 0;
		my $index = 0;
		$index++ while $boundaries->[ $index + 1 ] <= $offset;
		return $boundaries->[$index] if $boundaries->[$index] == $offset || $direction < 0;
		return $boundaries->[ $index + 1 ];
	}

	method _clamped_position ( $row, $offset ) {
		die "Term::Fabulous::Editor: a position needs integer row and offset, got " . describe($row) . ', ' . describe($offset)
			unless grep( { defined && !ref && /\A-?[0-9]+\z/ } $row, $offset ) == 2;
		$row = 0 if $row < 0;
		$row = $#lines if $row > $#lines;
		return ( $row, $self->_snap( $row, $offset, -1 ) );
	}

	# Moves the cursor; with $extend the selection grows from where the
	# cursor was, otherwise it is cleared.
	method move_to ( $row, $offset, $extend = 0 ) {
		my @target = $self->_clamped_position( $row, $offset );
		if ($extend) {
			@anchor = @cursor unless @anchor;
		}
		else {
			@anchor = ();
		}
		@cursor     = @target;
		$typing_run = undef;
		$revision++;
		return $self;
	}

	method set_selection ( $anchor_row, $anchor_offset, $cursor_row, $cursor_offset ) {
		my @from = $self->_clamped_position( $anchor_row, $anchor_offset );
		$self->move_to( $cursor_row, $cursor_offset );
		@anchor = @from;
		$revision++;
		return $self;
	}

	method select_all () {
		return $self->set_selection( 0, 0, $#lines, length $lines[-1] );
	}

	method clear_selection () {
		@anchor = ();
		$revision++;
		return $self;
	}

	# The word (or, between words, the single cluster) starting at or
	# covering a position. A cluster belongs to a word when its first
	# character is a word character.
	method select_word_at ( $row, $offset ) {
		( $row, $offset ) = $self->_clamped_position( $row, $offset );
		my $line       = $lines[$row];
		my @boundaries = @{ _boundaries($line) };
		return $self->move_to( $row, $offset ) if @boundaries == 1;

		my @is_word = map { substr( $line, $boundaries[$_], 1 ) =~ /\w/ ? 1 : 0 } 0 .. $#boundaries - 1;
		my ($index) = grep { $boundaries[$_] <= $offset } reverse 0 .. $#is_word;    # the last cluster at the end

		my ( $first, $last ) = ( $index, $index );
		if ( $is_word[$index] ) {
			$first-- while $first > 0 && $is_word[ $first - 1 ];
			$last++ while $last < $#is_word && $is_word[ $last + 1 ];
		}
		return $self->set_selection( $row, $boundaries[$first], $row, $boundaries[ $last + 1 ] );
	}

	method _position_left_of ( $row, $offset ) {
		return ( $row - 1, length $lines[ $row - 1 ] ) if $offset == 0 && $row > 0;
		return ( $row,     $self->_snap( $row, $offset - 1, -1 ) );
	}

	method _position_right_of ( $row, $offset ) {
		return ( $row + 1, 0 ) if $offset == length( $lines[$row] ) && $row < $#lines;
		return ( $row,     $self->_snap( $row, $offset + 1, 1 ) );
	}

	# Start of the word before the position, crossing to the previous line
	# from the start of a line.
	method _word_start_before ( $row, $offset ) {
		return ( $row - 1, length $lines[ $row - 1 ] ) if $offset == 0 && $row > 0;
		my $start = substr( $lines[$row], 0, $offset ) =~ /(\w+)\W*\z/ ? $-[1] : 0;
		return ( $row, $self->_snap( $row, $start, -1 ) );
	}

	# End of the word after the position, crossing to the next line from
	# the end of a line.
	method _word_end_after ( $row, $offset ) {
		my $line = $lines[$row];
		return ( $row + 1, 0 ) if $offset == length($line) && $row < $#lines;
		my $end = substr( $line, $offset ) =~ /\A\W*\w+/ ? $offset + $+[0] : length $line;
		return ( $row, $self->_snap( $row, $end, 1 ) );
	}

	# Without $extend, a selection collapses to its start (left) or end
	# (right) instead of moving.
	method move_left ( $extend = 0 ) {
		my @selection = $self->selection;
		return $self->move_to( @selection[ 0, 1 ] ) if @selection && !$extend;
		return $self->move_to( $self->_position_left_of(@cursor), $extend );
	}

	method move_right ( $extend = 0 ) {
		my @selection = $self->selection;
		return $self->move_to( @selection[ 2, 3 ] ) if @selection && !$extend;
		return $self->move_to( $self->_position_right_of(@cursor), $extend );
	}

	method move_word_left ( $extend = 0 ) {
		return $self->move_to( $self->_word_start_before(@cursor), $extend );
	}

	method move_word_right ( $extend = 0 ) {
		return $self->move_to( $self->_word_end_after(@cursor), $extend );
	}

	method move_line_start ( $extend = 0 ) {
		return $self->move_to( $cursor[0], 0, $extend );
	}

	method move_line_end ( $extend = 0 ) {
		return $self->move_to( $cursor[0], length $lines[ $cursor[0] ], $extend );
	}

	method move_document_start ( $extend = 0 ) {
		return $self->move_to( 0, 0, $extend );
	}

	method move_document_end ( $extend = 0 ) {
		return $self->move_to( $#lines, length $lines[-1], $extend );
	}

	# ---------------------------------------------------------------------
	# Editing. Every edit returns whether the text changed; an edit that
	# changes it can be undone.
	# ---------------------------------------------------------------------

	# Runs an edit and records an undo step when it changed the text. Typing
	# extends the last step while the typed text stays words or stays
	# spaces, so undo takes back a word at a time.
	method _edit ( $run, $code ) {
		my @before = ( [@cursor], [@anchor] );
		@changes = ();
		$code->();
		my @made = grep { $_->{old} ne $_->{new} } splice @changes;
		$revision++ if @made || "@{ $before[0] };@{ $before[1] }" ne "@cursor;@anchor";
		if ( !@made ) {
			$typing_run = undef;
			return 0;
		}

		my $extends_step = defined $run && defined $typing_run && $run eq $typing_run && @undo_stack;
		if ($extends_step) {
			push @{ $undo_stack[-1]{changes} }, @made;
			$undo_stack[-1]{cursor_after} = [@cursor];
		}
		else {
			push @undo_stack, { changes => \@made, cursor => $before[0], anchor => $before[1], cursor_after => [@cursor] };
		}
		shift @undo_stack while @undo_stack > UNDO_LIMIT;
		@redo_stack = ();
		$typing_run = $run;
		$text_revision++;
		return 1;
	}

	# Replaces the text between two ordered positions, recording the change
	# for undo; the cursor ends up after the new text, without a selection.
	method _replace ( $row_0, $offset_0, $row_1, $offset_1, $text ) {
		push @changes, { row => $row_0, offset => $offset_0, old => $self->_text_between( $row_0, $offset_0, $row_1, $offset_1 ), new => $text };
		my @end = $self->_splice_text( $row_0, $offset_0, $row_1, $offset_1, $text );
		@cursor = ( $end[0], $self->_snap( @end, 1 ) );
		@anchor = ();
		return;
	}

	# Puts $text between two ordered positions; returns the position after it.
	method _splice_text ( $row_0, $offset_0, $row_1, $offset_1, $text ) {
		my @new_lines = split /\n/, $text, -1;
		@new_lines = ('') unless @new_lines;
		my $after = substr( $lines[$row_1], $offset_1 );
		$new_lines[0] = substr( $lines[$row_0], 0, $offset_0 ) . $new_lines[0];
		my @end = ( $row_0 + $#new_lines, length $new_lines[-1] );
		$new_lines[-1] .= $after;

		splice @lines, $row_0, $row_1 - $row_0 + 1, @new_lines;
		return @end;
	}

	# The position after $text written at ($row, $offset).
	sub _end_of ( $row, $offset, $text ) {
		my @segments = split /\n/, $text, -1;
		return ( $row,              $offset + length $text ) if @segments <= 1;
		return ( $row + $#segments, length $segments[-1] );
	}

	method _delete_selection () {
		my @selection = $self->selection;
		return 0 unless @selection;
		$self->_replace( @selection, '' );
		return 1;
	}

	# The longest prefix of $text that keeps the editor within max_length
	# once the selection is replaced.
	method _fitting ($text) {
		return $text unless defined $max_length;
		my $selected = $self->selected_text;
		my $room     = $max_length - $self->character_count + _cluster_count($selected) + ( $selected =~ tr/\n// );
		return '' if $room <= 0;

		my ( $taken, $length ) = ( 0, 0 );
		foreach my $line ( split /(\n)/, $text ) {
			my @offsets  = @{ _boundaries($line) };
			my $clusters = $line eq "\n" ? 1 : $#offsets;
			if ( $taken + $clusters > $room ) {
				$length += $offsets[ $room - $taken ] if $line ne "\n";
				return substr( $text, 0, $length );
			}
			$taken  += $clusters;
			$length += length $line;
		}
		return $text;
	}

	# The selection, or the empty range at the cursor.
	method _replaced_range () {
		my @range = $self->selection;
		return @range ? @range : ( @cursor, @cursor );
	}

	# What of $text may go in at the cursor: normalized, without the
	# clusters accept rejects, cut to fit max_length. Undef when the text
	# was not empty but nothing of it is accepted; such an edit does
	# nothing, not even replace the selection.
	method _insertable ($text) {
		my $normalized = $self->_normalize($text);
		my $accepted   = $self->_accepted($normalized);
		return undef if length $normalized && !length $accepted;
		return $self->_fitting($accepted);
	}

	method insert ($text) {
		$text = $self->_insertable($text) // return 0;
		return 0 unless length $text || $self->has_selection;
		return $self->_edit( undef, sub { $self->_replace( $self->_replaced_range, $text ) } );
	}

	# Like insert, for text the user types: consecutive typing is undone
	# word by word.
	method type ($text) {
		$text = $self->_insertable($text) // return 0;
		return 0 unless length $text || $self->has_selection;
		my $run = !length $text ? undef : $text =~ /\A\s+\z/ ? 'space' : 'word';
		return $self->_edit( $run, sub { $self->_replace( $self->_replaced_range, $text ) } );
	}

	method _delete_to ( $row, $offset ) {
		return $self->_edit(
			undef,
			sub {
				return if $self->_delete_selection;
				my @range = _compare( $row, $offset, @cursor ) < 0 ? ( $row, $offset, @cursor ) : ( @cursor, $row, $offset );
				$self->_replace( @range, '' );
			}
		);
	}

	method delete_backward () {
		return $self->_delete_to( $self->_position_left_of(@cursor) );
	}

	method delete_forward () {
		return $self->_delete_to( $self->_position_right_of(@cursor) );
	}

	method delete_word_backward () {
		return $self->_delete_to( $self->_word_start_before(@cursor) );
	}

	method delete_word_forward () {
		return $self->_delete_to( $self->_word_end_after(@cursor) );
	}

	# At the start (end) of a line, joins it with the previous (next) one.
	method delete_to_line_start () {
		return $self->delete_backward if $cursor[1] == 0 && !$self->has_selection;
		return $self->_delete_to( $cursor[0], 0 );
	}

	method delete_to_line_end () {
		return $self->delete_forward if $cursor[1] == length( $lines[ $cursor[0] ] ) && !$self->has_selection;
		return $self->_delete_to( $cursor[0], length $lines[ $cursor[0] ] );
	}

	# ---------------------------------------------------------------------
	# Clipboard
	# ---------------------------------------------------------------------

	# A plain sub, so that it can be called on the class and on an editor.
	sub clipboard ( $invocant, @new ) {
		return $clipboard unless @new;
		die "Term::Fabulous::Editor: the clipboard holds a string, got " . ( ref $new[0] || 'undef' ) unless defined $new[0] && !ref $new[0];
		return $clipboard = $new[0];
	}

	method copy () {
		return 0 unless $self->has_selection;
		$clipboard = $self->selected_text;
		return 1;
	}

	method cut () {
		return 0 unless $self->has_selection;
		$clipboard = $self->selected_text;
		return $self->_edit( undef, sub { $self->_delete_selection } );
	}

	method paste () {
		return $self->insert($clipboard);
	}

	# ---------------------------------------------------------------------
	# Undo
	# ---------------------------------------------------------------------

	method can_undo () {
		return @undo_stack ? 1 : 0;
	}

	method can_redo () {
		return @redo_stack ? 1 : 0;
	}

	# Takes back the changes of the last step, newest first, and puts the
	# cursor where it was before them.
	method undo () {
		my $step = pop @undo_stack // return 0;
		foreach my $change ( reverse @{ $step->{changes} } ) {
			my @at = @$change{qw(row offset)};
			$self->_splice_text( @at, _end_of( @at, $change->{new} ), $change->{old} );
		}
		$self->_after_history( $step->{cursor}, $step->{anchor} );
		push @redo_stack, $step;
		return 1;
	}

	# Makes the changes of the last undone step again, oldest first.
	method redo () {
		my $step = pop @redo_stack // return 0;
		foreach my $change ( @{ $step->{changes} } ) {
			my @at = @$change{qw(row offset)};
			$self->_splice_text( @at, _end_of( @at, $change->{old} ), $change->{new} );
		}
		$self->_after_history( $step->{cursor_after}, [] );
		push @undo_stack, $step;
		return 1;
	}

	method _after_history ( $cursor, $anchor ) {
		@cursor     = @$cursor;
		@anchor     = @$anchor;
		$typing_run = undef;
		$text_revision++;
		$revision++;
		return;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Editor - Text, cursor, selection, undo and clipboard of
a text input

=head1 SYNOPSIS

	use Term::Fabulous::Editor;

	my $editor = Term::Fabulous::Editor->new( text => "Hello\nworld" );

	$editor->move_document_start;
	$editor->move_word_right(1);         # select "Hello"
	$editor->type('Goodbye');            # replaces the selection
	say $editor->text;                   # "Goodbye\nworld"

	$editor->undo;
	say $editor->text;                   # "Hello\nworld"

	# Inside a text input widget:
	my $field_editor = $text_field->editor;
	$field_editor->select_all;
	$text_field->mark_changed;           # the next frame scrolls and paints it

=head1 DESCRIPTION

C<Term::Fabulous::Editor> is the editing model behind
L<Term::Fabulous::Widget::TextField> and
L<Term::Fabulous::Widget::TextArea>, without any drawing: a list of
lines, a cursor, an optional selection, an undo history and a
clipboard. The widgets translate key presses and clicks into calls of
these methods and draw the result. You use the editor directly when you
want to move the cursor, select or change text of an input from your
program (through C<< $input->editor >>), or when you build a text widget
of your own.

The text is a Perl character string (decoded text), not UTF-8 encoded
bytes. Internally it is kept as a list of lines without their line
breaks; C<text> joins them with C<"\n">.

The cursor moves by grapheme clusters: what a reader sees as one
character, such as C<e> followed by a combining accent, an emoji with a
skin tone modifier, or a flag made of two regional indicators. The
segmentation is the same as the renderer's (L<Term::Fabulous::Unicode>),
so the cursor never lands inside a character. Words, for word movement
and word deletion, are runs of C<\w> characters (letters, digits and
C<_>).

Changes made through the editor of an input widget fire no C<Change>
event. Call C<< $input->mark_changed >> afterwards so that a frame is
drawn: the input notices the new L</revision> then, scrolls the cursor
into view and paints the text (see
L<Term::Fabulous::Widget::TextInput/editor>).

=head1 CONSTRUCTOR

=head2 new

	my $editor = Term::Fabulous::Editor->new(
		text       => '',
		multi_line => 1,
		max_length => undef,
		accept     => undef,
	);

All parameters are optional. Unknown parameters die, and so do invalid
values, with a message that starts with C<Term::Fabulous::Editor:>.
Through a text input, the message names the input's class instead (see
L<Term::Fabulous::Widget::TextInput/max_length>).

=over

=item C<text>

A character string. Default: C<''>. The initial text, as for
L</set_text>. Dies if it is longer than C<max_length>.

=item C<multi_line>

A boolean. Default: 1. A single-line editor (0) turns every line break
it is given into a space, so its text is always one line.

=item C<max_length>

A non-negative integer, or C<undef>. Default: C<undef> (no limit). The
most grapheme clusters the text may hold; every line break counts as
one. Inserted and typed text is cut to fit. Dies if it is not a
non-negative integer or C<undef>.

=item C<accept>

Which grapheme clusters may enter the text, as for L</set_accept>.
Default: C<undef> (every cluster). Dies, as C<set_accept> does, if the
initial text has a cluster the spec rejects.

=back

=head1 POSITIONS

Several methods take or return a position: a line index C<$row> (from
0) and a character offset C<$offset> into that line (from 0, in Perl
characters, not columns). A valid position lies on a grapheme cluster
boundary. Methods that take a position clamp it to the text (a row past
the last line means the last line, an offset past the end of a line
means its end) and move an offset inside a cluster back to the start of
that cluster. A row or offset that is not an integer dies.

=head1 METHODS: TEXT

=head2 text

	my $text = $editor->text;

The whole text, a character string with lines joined by C<"\n">.

=head2 set_text

	$editor->set_text("new\ntext");

Replaces the whole text. C<"\r\n"> and C<"\r"> become C<"\n"> (and every
line break becomes a space in a single-line editor). Puts the cursor at
the end, clears the selection and the undo and redo history. Returns the
editor. Dies if the text is not a string or is longer than
C<max_length>.

=head2 lines

	my @lines = $editor->lines;

The lines of the text, without line breaks. There is always at least
one line (an empty text has one empty line).

=head2 line

	my $line = $editor->line($row);

One line of the text, without its line break. Valid rows are 0 to
C<< line_count - 1 >>; a row past the end or below 0 returns C<undef>.

=head2 line_count

	my $count = $editor->line_count;

The number of lines, at least 1.

=head2 boundaries

	my @offsets = $editor->boundaries($row);

The grapheme cluster boundaries of a line as character offsets, from 0
up to and including the length of the line. For C<"ae\x{301}"> they are
C<(0, 1, 3)>.

=head2 character_count

	my $count = $editor->character_count;

The number of grapheme clusters in the text, line breaks included (each
counts as one). This is what C<max_length> limits.

=head2 is_empty

	if ( $editor->is_empty ) { ... }

True when the text is the empty string.

=head2 max_length

	my $limit = $editor->max_length;

The length limit, or C<undef> for none.

=head2 set_max_length

	$editor->set_max_length(80);
	$editor->set_max_length(undef);

Sets the length limit. Returns the editor. Dies if the limit is not a
non-negative integer or C<undef>, or if the text is already longer.

=head2 accept

	my $spec = $editor->accept;

The accept spec as it was given to L</set_accept>, or C<undef> for
none.

=head2 set_accept

	$editor->set_accept('0-9');                             # digits only
	$editor->set_accept(qr/\p{L}/);                         # letters of any script
	$editor->set_accept( sub ($cluster) { $cluster ne ' ' } );
	$editor->set_accept(undef);                             # everything again

Restricts which grapheme clusters may enter the text. The spec is the
body of a character class (what a KDL layout writes; C<'0-9'> means
C<qr/[0-9]/>), a regular expression that every cluster must match, a
code reference called with each cluster that returns true to accept
it, or C<undef> for no restriction. Returns the editor.

L</insert> and L</type> drop the clusters the spec rejects and keep
the rest, so pasting C<+49 170 1234> into a digits-only editor inserts
the digits; an insertion of which nothing is accepted does nothing at
all, not even replace the selection. Line breaks are never subject to
the spec. L</set_text> is for the program and dies instead, as it does
for C<max_length>; so does C<set_accept> itself when the text already
has a rejected cluster. Dies for a string that is not a valid
character class body and for any other kind of value.

=head2 revision

	my $revision = $editor->revision;

A number that grows whenever the text, the cursor or the selection
changes: edits, C<set_text>, undo, redo, every cursor movement and
selection change, also one that ends where it started. Compare it with
an earlier value to know whether a view of the editor is still up to
date; L<Term::Fabulous::Widget::TextInput> repaints and scrolls to the
cursor when it grew.

=head2 text_revision

	my $revision = $editor->text_revision;

Like L</revision>, but grows only when the text changes (edits,
C<set_text>, undo, redo), for what is derived from the text alone, such
as the line wrapping of L<Term::Fabulous::Widget::TextArea>.

=head2 multi_line

	my $keeps_line_breaks = $editor->multi_line;

True for a multi-line editor (see the C<multi_line> parameter).

=head1 METHODS: CURSOR AND SELECTION

The cursor is where typing inserts text. A selection reaches from an
anchor (where the selection started) to the cursor. The movement methods
below take an optional C<$extend> argument: when true, the selection is
extended to the new cursor position (starting at the old cursor
position if there was no selection); when false or omitted, the
selection is cleared. Movement and selection methods return the editor,
so calls can be chained.

=head2 cursor

	my ( $row, $offset ) = $editor->cursor;

The position of the cursor.

=head2 move_to

	$editor->move_to( $row, $offset );
	$editor->move_to( $row, $offset, 1 );    # extend the selection

Moves the cursor to a position (see L</POSITIONS>).

=head2 move_left

	$editor->move_left;
	$editor->move_left(1);

Moves one grapheme cluster to the left, to the end of the previous line
from the start of a line. Without C<$extend> and with a selection, the
cursor goes to the start of the selection instead and the selection is
cleared.

=head2 move_right

	$editor->move_right;
	$editor->move_right(1);

Moves one grapheme cluster to the right, to the start of the next line
from the end of a line. Without C<$extend> and with a selection, the
cursor goes to the end of the selection instead and the selection is
cleared.

=head2 move_word_left

	$editor->move_word_left($extend);

Moves to the start of the word before the cursor (skipping non-word
characters in between). From the start of a line, moves to the end of
the previous line.

=head2 move_word_right

	$editor->move_word_right($extend);

Moves to the end of the word after the cursor. From the end of a line,
moves to the start of the next line.

=head2 move_line_start

	$editor->move_line_start($extend);

Moves to the start of the cursor's line.

=head2 move_line_end

	$editor->move_line_end($extend);

Moves to the end of the cursor's line.

=head2 move_document_start

	$editor->move_document_start($extend);

Moves to the start of the text.

=head2 move_document_end

	$editor->move_document_end($extend);

Moves to the end of the text.

=head2 set_selection

	$editor->set_selection( $anchor_row, $anchor_offset, $cursor_row, $cursor_offset );

Selects from the anchor position to the cursor position (either may
come first) and puts the cursor at the second position. Selecting an
empty range leaves no selection.

=head2 select_all

	$editor->select_all;

Selects the whole text, with the cursor at its end.

=head2 clear_selection

	$editor->clear_selection;

Removes the selection; the cursor stays where it is.

=head2 select_word_at

	$editor->select_word_at( $row, $offset );

Selects the word containing the grapheme cluster at the position (at the
end of a line: the last cluster). When that cluster is not part of a
word (its first character does not match C<\w>), selects just that one
cluster. On an empty line, only moves the cursor there. This is what a
double click does.

=head2 has_selection

	if ( $editor->has_selection ) { ... }

True when there is a non-empty selection.

=head2 selection

	my ( $row_0, $offset_0, $row_1, $offset_1 ) = $editor->selection;

The start and end positions of the selection, in text order (the start
comes first, whatever direction it was made in), or the empty list when
nothing is selected.

=head2 selected_text

	my $text = $editor->selected_text;

The selected text (lines joined with C<"\n">), or C<''> when nothing is
selected.

=head1 METHODS: EDITING

Every edit method returns 1 when it changed the text and 0 when it did
not. An edit that changes the text replaces the selection (if there is
one), leaves no selection behind, puts the cursor after the inserted
text, and can be undone. None of them fires events; they are plain
methods on the text model.

=head2 insert

	$editor->insert('text');

Inserts a character string at the cursor, replacing the selection. Line
breaks are converted as in L</set_text>. With an L</accept> spec, the
clusters it rejects are left out; when that leaves nothing of a
non-empty string, nothing happens and 0 is returned. With
C<max_length>, only as much of the text as fits is inserted. Inserting
an empty string with a selection deletes the selection.

=head2 type

	$editor->type('a');

Like L</insert>, for text the user types: consecutive calls are merged
into one undo step per word and per run of spaces, so undo takes back a
word at a time. Any cursor movement, and any other edit, ends the
current step. Typing an empty string with a selection deletes the
selection, as C<insert> does, in an undo step of its own.

=head2 delete_backward

	$editor->delete_backward;

Deletes the selection, or else the grapheme cluster (or line break)
before the cursor. This is C<Backspace>.

=head2 delete_forward

	$editor->delete_forward;

Deletes the selection, or else the grapheme cluster (or line break)
after the cursor. This is C<Delete>.

=head2 delete_word_backward

	$editor->delete_word_backward;

Deletes the selection, or else everything from the start of the word
before the cursor to the cursor.

=head2 delete_word_forward

	$editor->delete_word_forward;

Deletes the selection, or else everything from the cursor to the end of
the word after it.

=head2 delete_to_line_start

	$editor->delete_to_line_start;

Deletes the selection, or else everything from the start of the line to
the cursor. At the start of a line, deletes the line break before it
(joining the line with the previous one).

=head2 delete_to_line_end

	$editor->delete_to_line_end;

Deletes the selection, or else everything from the cursor to the end of
the line. At the end of a line, deletes the line break after it.

=head1 METHODS: CLIPBOARD

=head2 copy

	$editor->copy;

Puts the selected text on the clipboard. Returns 1, or 0 (and leaves the
clipboard alone) when nothing is selected. Does not change the text.

=head2 cut

	$editor->cut;

Puts the selected text on the clipboard and deletes it. Returns 1, or 0
when nothing is selected.

=head2 paste

	$editor->paste;

Inserts the clipboard at the cursor, like L</insert>. Returns whether
the text changed.

=head2 clipboard

	my $text = Term::Fabulous::Editor->clipboard;
	Term::Fabulous::Editor->clipboard('text to paste');
	$editor->clipboard('text to paste');    # the same clipboard

Reads or sets the clipboard, called on the class or on any editor: one character
string shared by all editors, and therefore by all text inputs, of the
program. It is not connected to the clipboard of your desktop; set it
yourself to bring text in from there. Setting anything but a string
dies.

=head1 METHODS: UNDO

=head2 undo

	$editor->undo;

Takes back the last edit, restoring the text, the cursor and the
selection as they were before it. Returns 1, or 0 when there is nothing
to undo. Up to 100 steps are kept; older ones are forgotten. A step
keeps only the text it replaced and the text it wrote, so the history
stays small however long the text is.

=head2 redo

	$editor->redo;

Redoes the last undone edit and puts the cursor after it, without a
selection. Returns 1, or 0 when there is nothing to redo. Any new edit
clears the redo steps.

=head2 can_undo

	if ( $editor->can_undo ) { ... }

True when L</undo> would do something.

=head2 can_redo

	if ( $editor->can_redo ) { ... }

True when L</redo> would do something.

=head1 EXAMPLES

=head2 Insert a timestamp at the cursor of a text area

	use POSIX qw(strftime);

	my $editor = $notes->editor;
	if ( $editor->insert( strftime( '%Y-%m-%d %H:%M ', localtime ) ) ) {
		$notes->mark_changed;    # the next frame scrolls to the cursor
	}

=head2 Select the second line of a text area

	my $editor = $area->editor;
	$editor->set_selection( 1, 0, 1, length $editor->line(1) );
	$area->mark_changed;

=head2 Load the system clipboard on a key press

The clipboard is not the desktop clipboard. This listener on the root
widget copies the desktop clipboard (through the C<xclip> program) into
it when the user presses C<F2>; C<F2> bubbles up from text inputs, and
C<Ctrl+V> then pastes the text.

	use Clay::UI::Enum::Result;
	use Encode qw(decode);

	$root->on( KeyPress => sub ($event) {
		return Clay::UI::Enum::Result->CONTINUE unless ( $event->key_name // '' ) eq 'F2';
		my $bytes = qx{xclip -o -selection clipboard};    # UTF-8 bytes
		Term::Fabulous::Editor->clipboard( decode( 'UTF-8', $bytes ) ) if defined $bytes;
		return;
	} );

=head1 SEE ALSO

L<Term::Fabulous::Widget::TextInput>, L<Term::Fabulous::Widget::TextField>,
L<Term::Fabulous::Widget::TextArea>, L<Term::Fabulous::TextView>,
L<Term::Fabulous::Unicode>,
L<the editing section of the forms guide|Term::Fabulous::Manual::Forms/EDITING TEXT>,
L<Term::Fabulous::Cookbook::Forms/Copy and paste through the clipboard>.

=cut
