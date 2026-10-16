package Term::Fabulous::TextView;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

class Term::Fabulous::TextView :strict(params) {
	use List::Util qw(max min sum0);
	use Scalar::Util qw(blessed);
	use Term::Fabulous::Unicode qw(sanitize_text cluster_columns);
	use Term::Fabulous::Viewport qw(clamp_offset max_offset reveal_range);

	field $editor    :param :reader;
	field $display   :param = \&sanitize_text;
	field $wrap      :param :reader = 0;
	field $scrollbar :param :reader = 0;

	field $columns :reader = 0;
	field $rows    :reader = 0;

	# The first visual row shown, and (without wrapping) the columns
	# scrolled out on the left: always where a cluster of the cursor's
	# line starts.
	field $top  :reader(top_row)     = 0;
	field $left :reader(left_column) = 0;

	# Grows when the display function changes, which changes the widths.
	field $display_generation = 0;

	# The visual rows for the current text and size, see _layout, and
	# "width:wrap:generation" => { line text => [ its parts ] } for the
	# lines the last layout showed: an edit wraps only the lines it changed.
	field $layout_cache;
	field %parts_by_key;

	# What the view last followed the cursor for.
	field $followed = '';

	# [ $column, $row, $offset ]: the column vertical moves aim for, kept
	# while the cursor stays where the last vertical move put it.
	field @goal;

	ADJUST {
		die "Term::Fabulous::TextView: editor must be a Term::Fabulous::Editor, got " . ( ref $editor || ( defined $editor ? "'$editor'" : 'undef' ) )
			unless blessed $editor && $editor->isa('Term::Fabulous::Editor');
		_check_display($display);
		( $wrap, $scrollbar ) = ( _flag( wrap => $wrap ), _flag( scrollbar => $scrollbar ) );
	}

	sub _check_display ($code) {
		die "Term::Fabulous::TextView: display must be a code reference, got " . ( ref $code || ( defined $code ? "'$code'" : 'undef' ) )
			unless ref $code eq 'CODE';
		return;
	}

	sub _flag ( $name, $value ) {
		die "Term::Fabulous::TextView: $name must be a plain boolean value, got a " . ref($value) . " reference" if ref $value;
		return $value ? 1 : 0;
	}

	# ---------------------------------------------------------------------
	# Settings
	# ---------------------------------------------------------------------

	method set_size ( $new_columns, $new_rows ) {
		die "Term::Fabulous::TextView: set_size needs a non-negative integer size, got " . join( ' x ', map { defined ? "'$_'" : 'undef' } $new_columns, $new_rows )
			unless 2 == grep { defined && !ref && /\A[0-9]+\z/ } $new_columns, $new_rows;
		( $columns, $rows ) = ( $new_columns + 0, $new_rows + 0 );
		return $self;
	}

	method set_wrap ($value) {
		$wrap = _flag( wrap => $value );
		$left = 0;
		return $self;
	}

	method set_scrollbar ($value) {
		$scrollbar = _flag( scrollbar => $value );
		return $self;
	}

	method set_display ($code) {
		_check_display($code);
		$display = $code;
		return $self->display_changed;
	}

	# The display function shows clusters differently now.
	method display_changed () {
		$display_generation++;
		return $self;
	}

	# Back to the top-left, as for a new text.
	method home () {
		( $top, $left ) = ( 0, 0 );
		return $self;
	}

	# ---------------------------------------------------------------------
	# Clusters
	# ---------------------------------------------------------------------

	method clusters ( $line, $from, $to ) {
		my $text       = $editor->line($line);
		my @boundaries = grep { $_ >= $from && $_ <= $to } $editor->boundaries($line);
		return map {
			my $shown = $display->( substr( $text, $boundaries[$_], $boundaries[ $_ + 1 ] - $boundaries[$_] ) );
			[ $boundaries[$_], $shown, cluster_columns($shown) ]
		} 0 .. $#boundaries - 1;
	}

	method _columns_to ( $line, $from, $offset ) {
		return sum0 map { $_->[2] } $self->clusters( $line, $from, $offset );
	}

	# The boundary of the part [from, to) of a line shown at a column: the
	# start of the cluster covering it, or $to past the end.
	method _offset_at_column ( $line, $from, $to, $column ) {
		my $x = 0;
		foreach my $cluster ( $self->clusters( $line, $from, $to ) ) {
			return $cluster->[0] if $column < $x + $cluster->[2];
			$x += $cluster->[2];
		}
		return $to;
	}

	# ---------------------------------------------------------------------
	# Visual rows: every line is cut into the parts shown on one row each.
	# A row is [ $line, $from, $to, $is_last_part, $shown_from ]: the part
	# [from, to) of the line, shown from $shown_from on.
	# ---------------------------------------------------------------------

	# The parts [from, to, shown_from] of a line for a text width.
	# Wrapping breaks after the last blank that fits, or else before the
	# cluster that does not fit. A blank that does not fit any more hangs
	# at the break: it starts the next part, unseen (shown_from is after
	# it), so no row starts with the blank that ended the row above. A
	# line whose last part fills the width gets an empty part after it,
	# where the cursor can stand at its end.
	method _wrap_line ( $line, $width ) {
		my $end = length $editor->line($line);
		return [ 0, $end, 0 ] unless $wrap;

		my @clusters  = $self->clusters( $line, 0, $end );
		my $offset_of = sub ($index) { $index < @clusters ? $clusters[$index][0] : $end };
		my $part      = sub ( $start, $shown, $stop ) {
			[ map { $offset_of->($_) } $start, $stop, $shown ]
		};

		my ( @parts, $break );
		my ( $start, $shown, $used ) = ( 0, 0, 0 );
		foreach my $index ( 0 .. $#clusters ) {
			my ( undef, $display_cluster, $cluster_columns ) = @{ $clusters[$index] };
			my $is_blank = $display_cluster =~ /\A\s\z/;
			if ( $used + $cluster_columns > $width && $index > $shown ) {
				if ($is_blank) {
					push @parts, $part->( $start, $shown, $index );
					( $start, $shown, $used ) = ( $index, $index + 1, 0 );
					undef $break;
					next;
				}
				my $cut = defined $break && $break > $shown ? $break : $index;
				push @parts, $part->( $start, $shown, $cut );
				( $start, $shown ) = ( $cut, $cut );
				$used = sum0 map { $_->[2] } @clusters[ $cut .. $index - 1 ];
				undef $break;

				# The word carried over to the new row may leave no room for
				# this cluster either.
				if ( $used + $cluster_columns > $width && $index > $shown ) {
					push @parts, $part->( $start, $shown, $index );
					( $start, $shown, $used ) = ( $index, $index, 0 );
				}
			}
			$used += $cluster_columns;
			$break = $index + 1 if $is_blank;
		}
		push @parts, $part->( $start, $shown, scalar @clusters );
		push @parts, [ $end, $end, $end ] if @clusters && $used >= $width;
		return @parts;
	}

	# { key, width, scrollbar, rows => [ visual rows ], first => [ the first
	# visual row of each line ] } for the current text and size. The row
	# count at the full width decides whether a scrollbar is needed.
	method _layout () {
		my $key = join ':', $editor->text_revision, $columns, $rows, $wrap, $scrollbar, $display_generation;
		return $layout_cache if defined $layout_cache && $layout_cache->{key} eq $key;

		my @lines = $editor->lines;
		my %parts_now;
		my ( $width, $has_scrollbar ) = ( max( $columns, 1 ), 0 );
		my $parts = $self->_parts_of_lines( \@lines, $width, \%parts_now );
		if ( $scrollbar && $columns > 1 && sum0( map { scalar @$_ } @$parts ) > $rows ) {
			( $width, $has_scrollbar ) = ( $columns - 1, 1 );
			$parts = $self->_parts_of_lines( \@lines, $width, \%parts_now );
		}
		%parts_by_key = %parts_now;

		my ( @visual_rows, @first );
		foreach my $line ( 0 .. $#$parts ) {
			push @first,       scalar @visual_rows;
			push @visual_rows, map { [ $line, @$_ ] } @{ $parts->[$line] };
		}
		return $layout_cache = { key => $key, width => $width, scrollbar => $has_scrollbar, rows => \@visual_rows, first => \@first };
	}

	# The parts of every line as [ $from, $to, $is_last, $shown_from ].
	# Wrapping depends on the text of a line, the width, wrap and the
	# display only, so the parts of a line come from the last layout when
	# it had the line.
	method _parts_of_lines ( $lines, $width, $parts_now ) {
		my $key    = "$width:$wrap:$display_generation";
		my $before = $parts_by_key{$key} // {};
		my $now    = $parts_now->{$key} //= {};
		return [
			map {
				my $text = $lines->[$_];
				$now->{$text} //= $before->{$text} // do {
					my @parts = $self->_wrap_line( $_, $width );
					[ map { [ @{ $parts[$_] }[ 0, 1 ], $_ == $#parts ? 1 : 0, $parts[$_][2] ] } 0 .. $#parts ];
				};
			} 0 .. $#$lines
		];
	}

	method visual_rows () {
		return map { [@$_] } @{ $self->_layout->{rows} };
	}

	method visual_row_count () {
		return scalar @{ $self->_layout->{rows} };
	}

	method visible_rows () {
		my $all   = $self->_layout->{rows};
		my $first = min( $top, $self->max_top );
		return map { [ @{ $all->[$_] } ] } $first .. min( $first + $rows, scalar @$all ) - 1;
	}

	method text_columns () {
		return $self->_layout->{width};
	}

	method has_scrollbar () {
		return $self->_layout->{scrollbar};
	}

	method max_top () {
		return max_offset( $self->visual_row_count, $rows );
	}

	# The visual row showing an editor position: the end of a wrapped
	# part shows at the start of the next one.
	method visual_row_of ( $line, $offset ) {
		my $layout = $self->_layout;
		my $index  = $layout->{first}[$line];
		$index++ while !$layout->{rows}[$index][3] && $offset >= $layout->{rows}[$index][2];
		return $index;
	}

	# ---------------------------------------------------------------------
	# Scrolling and positions
	# ---------------------------------------------------------------------

	# Scrolls to the cursor when the editor or the view changed since the
	# last call; a view scrolled away from the cursor (the mouse wheel)
	# stays where it is otherwise.
	method follow_cursor () {
		my $key = join ':', $editor->revision, $columns, $rows, $wrap, $scrollbar, $display_generation;
		return $self if $key eq $followed;
		$followed = $key;
		return $self->scroll_to_cursor;
	}

	method scroll_to_cursor () {
		return $self if $columns < 1 || $rows < 1;
		my ( $line, $offset ) = $editor->cursor;
		my $visual = $self->visual_row_of( $line, $offset );
		$top = reveal_range( $self->visual_row_count, $rows, $top, $visual, $visual + 1 );
		$self->_scroll_sideways_to( $line, $offset ) unless $wrap;
		return $self;
	}

	# Shows the cursor and the cell after its line when the cursor is at
	# the end, scrolls no further than needed to fill the view, and starts
	# the view where a cluster of the cursor's line starts.
	method _scroll_sideways_to ( $line, $offset ) {
		my $width    = $self->text_columns;
		my @clusters = $self->clusters( $line, 0, length $editor->line($line) );
		my ( $cursor_x, $cursor_columns, $end_x ) = ( undef, 1, 0 );
		foreach my $cluster (@clusters) {
			( $cursor_x, $cursor_columns ) = ( $end_x, $cluster->[2] ) if $cluster->[0] == $offset;
			$end_x += $cluster->[2];
		}
		$cursor_x //= $end_x;

		$left = min( $left, max( 0, $end_x + 1 - $width ) );
		$left = $cursor_x if $cursor_x < $left;
		$left = $cursor_x + $cursor_columns - $width if $cursor_x + $cursor_columns > $left + $width;
		$left = 0 if $left < 0;

		my $start = 0;
		foreach my $cluster (@clusters) {
			last if $start >= $left;
			$start += $cluster->[2];
		}
		$left = $start;
		return;
	}

	# Scrolls by visual rows within the text; returns how many it moved.
	method scroll_rows ($count) {
		my $before = $top;
		$top = clamp_offset( $self->visual_row_count, $rows, $top + $count );
		return $top - $before;
	}

	# The view cell of the cursor, or the empty list when it is out of view.
	method cursor_cell () {
		my ( $line, $offset ) = $editor->cursor;
		my $visual = $self->visual_row_of( $line, $offset );
		my $y      = $visual - $top;
		return () if $y < 0 || $y >= $rows;
		my ( undef, undef, undef, undef, $shown ) = @{ $self->_layout->{rows}[$visual] };
		my $x = $self->_columns_to( $line, $shown, max( $offset, $shown ) ) - ( $wrap ? 0 : $left );
		return () if $x < 0 || $x >= $self->text_columns;
		return ( $x, $y );
	}

	# The editor position shown at a view cell. A click past the end of a
	# wrapped part stays on its row, before its last cluster, since the
	# end itself is shown at the start of the next row.
	method position_at ( $column, $row ) {
		my $all   = $self->_layout->{rows};
		my $index = min( $top + $row, $#$all );
		my ( $line, undef, $to, $is_last, $shown ) = @{ $all->[$index] };
		my $offset = $self->_offset_at_column( $line, $shown, $to, $column + ( $wrap ? 0 : $left ) );
		$offset = $self->_last_cluster_of( $line, $shown, $to ) if !$is_last && $offset == $to && $to > $shown;
		return ( $line, $offset );
	}

	method _last_cluster_of ( $line, $from, $to ) {
		my @clusters = $self->clusters( $line, $from, $to );
		return $clusters[-1][0];
	}

	# Moves the cursor by visual rows, aiming for the column it had when
	# vertical movement started. Beyond the first (last) row it goes to the
	# start (end) of the text, which starts a new aim.
	method move_vertically ( $count, $extend = 0 ) {
		my $all = $self->_layout->{rows};
		my ( $line, $offset ) = $editor->cursor;
		my $visual      = $self->visual_row_of( $line, $offset );
		my $goal_column = @goal && $goal[1] == $line && $goal[2] == $offset ? $goal[0] : $self->_columns_to( $line, $all->[$visual][4], max( $offset, $all->[$visual][4] ) );

		my $target = $visual + $count;
		if ( $target < 0 || $target > $#$all ) {
			$target < 0 ? $editor->move_document_start($extend) : $editor->move_document_end($extend);
			@goal = ();
			return $self;
		}

		my ( $target_line, undef, $to, $is_last, $shown ) = @{ $all->[$target] };
		my $target_offset = $self->_offset_at_column( $target_line, $shown, $to, $goal_column );
		$target_offset = $self->_last_cluster_of( $target_line, $shown, $to ) if !$is_last && $target_offset == $to && $to > $shown;
		$editor->move_to( $target_line, $target_offset, $extend );
		@goal = ( $goal_column, $editor->cursor );
		return $self;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::TextView - Lay out the text of an editor in a view of
rows and columns

=head1 SYNOPSIS

	use Term::Fabulous::Editor;
	use Term::Fabulous::TextView;

	my $editor = Term::Fabulous::Editor->new( text => "The quick brown fox\njumps" );
	my $view   = Term::Fabulous::TextView->new( editor => $editor, wrap => 1 );
	$view->set_size( 10, 3 );
	$view->follow_cursor;

	foreach my $row ( $view->visible_rows ) {
		my ( $line, $from, $to, $is_last, $shown_from ) = @$row;
		my @clusters = $view->clusters( $line, $shown_from, $to );    # [ $offset, $shown, $columns ]
		say join '', map { $_->[1] } @clusters;                      # "The quick ", "brown fox", "jumps"
	}

	my ( $line, $offset ) = $view->position_at( 3, 1 );    # under a click
	$view->move_vertically(1);                               # Down

=head1 DESCRIPTION

Most programs never use this module directly. It is the layout behind
L<Term::Fabulous::Widget::TextInput>: given a L<Term::Fabulous::Editor>,
how its clusters are shown, a size and whether to wrap, it works out
which part of which line is shown on which row, where the cursor is,
how far the view is scrolled, which text position a cell shows, and
where the cursor goes when it moves up or down by rows. It knows nothing
of Clay::UI or canvases: L<Term::Fabulous::Widget::TextField> is a view
of one row without wrapping, L<Term::Fabulous::Widget::TextArea> one of
its height that wraps or not.

=head2 Visual rows

Every line of the editor is cut into I<parts>, each shown on one
I<visual row>. Without wrapping a line is one part. With wrapping, a
line breaks after the last blank that fits the width, or else before
the cluster that does not fit (a word wider than the view breaks
anywhere). A blank that does not fit any more I<hangs> at the break: it
belongs to the next part but is not shown there, so no row starts with
the blank that ended the row above. A line whose last part fills the
width gets an empty part after it, where the cursor can stand at the
end of the line. The end of a wrapped part is shown at the start of the
next row, so the cursor there is shown at the start of the next row.

A visual row is an array reference
C<[ $line, $from, $to, $is_last, $shown_from ]>: the part C<[from, to)>
(character offsets) of the editor line C<$line>, shown from
C<$shown_from> on (after a hanging blank), and whether it is the line's
last part.

=head2 Scrolling

The view keeps its scroll position: the first visual row shown
(L</top_row>) and, without wrapping, the columns scrolled out on the
left (L</left_column>). Scrolling to the cursor moves just far enough to
show the cursor's row, and sideways the cursor's cell (the cell after
the line when the cursor is at its end), but not so far that the view
would end in empty cells while text is hidden on the left. Sideways
scrolling has one rule: the view always starts where a cluster of the
cursor's line starts, never inside a wide character.

=head1 CONSTRUCTOR

=head2 new

	my $view = Term::Fabulous::TextView->new(
		editor    => $editor,                  # required
		display   => sub ($cluster) { '*' },   # how a cluster is shown
		wrap      => 1,
		scrollbar => 1,
	);

=over

=item C<editor>

Required. The L<Term::Fabulous::Editor> to show.

=item C<display>

A code reference that turns a grapheme cluster of the text into what is
shown for it, one cluster; its width in columns
(L<Term::Fabulous::Unicode/cluster_columns>) is what the cluster takes.
Default: L<Term::Fabulous::Unicode/sanitize_text>, so no control
character reaches the terminal. A password field shows a mask instead.

=item C<wrap>

A boolean, default 0: whether long lines wrap (see L</Visual rows>).

=item C<scrollbar>

A boolean, default 0: whether the last column is given to a scrollbar
when the text has more visual rows than the view, which then lays the
text out one column narrower (see L</has_scrollbar>).

=back

Invalid values die with a message starting with
C<Term::Fabulous::TextView:>.

=head1 METHODS

=head2 set_size

	$view->set_size( $columns, $rows );

The size of the view in cells, non-negative integers. Returns the view.
A view without columns or rows scrolls nowhere. Dies unless both are
non-negative integers.

=head2 columns

The width of the view, in cells.

=head2 rows

The height of the view, in cells.

=head2 set_wrap, set_scrollbar

	$view->set_wrap(0);
	$view->set_scrollbar(1);

Change the C<wrap> and C<scrollbar> settings; C<set_wrap> also scrolls
back to the left edge. Return the view. Any plain value is taken as a
boolean; a reference dies.

=head2 wrap, scrollbar

The settings.

=head2 set_display

	$view->set_display( sub ($cluster) { '*' } );

Changes how clusters are shown, which may change their widths. Returns
the view. Dies unless given a code reference.

=head2 display_changed

	$view->display_changed;

Tells the view that its display function now shows clusters
differently (a password field switched its mask on), so the layout and
the scroll position are worked out again. Returns the view.

=head2 editor

The editor.

=head2 home

	$view->home;

Scrolls back to the first row and the left edge. Returns the view.

=head2 visual_rows

	my @rows = $view->visual_rows;

Every visual row of the text, as new array references (see
L</Visual rows>).

=head2 visual_row_count

The number of visual rows of the text.

=head2 visible_rows

	my @rows = $view->visible_rows;

The visual rows shown, from L</top_row> on, at most L</rows> of them.

=head2 clusters

	my @clusters = $view->clusters( $line, $from, $to );

The clusters of the part C<[from, to)> of a line, each as
C<[ $offset, $shown, $columns ]>: where it starts in the line, what the
display function shows for it and how many columns that takes. C<$from>
and C<$to> are cluster boundaries.

=head2 text_columns

The columns the text is laid out in: L</columns>, or one less while the
view shows a scrollbar.

=head2 has_scrollbar

1 when C<scrollbar> is on, the view has more than one column and the
text has more visual rows than the view at its full width.

=head2 visual_row_of

	my $index = $view->visual_row_of( $line, $offset );

The index of the visual row that shows an editor position.

=head2 top_row

The first visual row shown, counted from 0.

=head2 left_column

The columns scrolled out on the left; always 0 while wrapping.

=head2 max_top

The highest L</top_row> there is: the visual rows less the rows of the
view, at least 0.

=head2 follow_cursor

	$view->follow_cursor;

Scrolls to the cursor (L</scroll_to_cursor>) when the editor (its
L<Term::Fabulous::Editor/revision>), the size or a setting changed since
the last call; otherwise it leaves the view where it is, also when it
was scrolled away from the cursor with L</scroll_rows>. Returns the
view.

=head2 scroll_to_cursor

Scrolls just far enough to show the cursor (see L</Scrolling>). Returns
the view.

=head2 scroll_rows

	my $moved = $view->scroll_rows(3);

Scrolls by visual rows (negative: up), staying within the text, without
moving the cursor. Returns how many rows it moved, negative when it
moved up, and 0 when it is already at that end.

=head2 cursor_cell

	my ( $x, $y ) = $view->cursor_cell;

The view cell the cursor is shown in, or the empty list when it is out
of view. At the end of a line the cursor is in the cell after its last
cluster.

=head2 position_at

	my ( $line, $offset ) = $view->position_at( $column, $row );

The editor position shown at a view cell: the start of the cluster
covering the cell, or the end of the part when the cell is past it. A
cell past the end of a wrapped part gives the position before its last
cluster, since the end itself is shown on the next row. Rows below the
text give the last row.

=head2 move_vertically

	$view->move_vertically( 1 );          # Down
	$view->move_vertically( -1, 1 );      # Shift+Up
	$view->move_vertically( $view->rows - 1 );    # PageDown

Moves the editor's cursor by visual rows, extending the selection with
a true second argument. It aims for the column the cursor had when
vertical movement started, as long as the cursor stays where the last
vertical move put it. Beyond the first or last row it goes to the start
or the end of the text. Returns the view.

=head1 SEE ALSO

L<Term::Fabulous::Widget::TextInput>, L<Term::Fabulous::Editor>,
L<Term::Fabulous::Unicode>.

=cut
