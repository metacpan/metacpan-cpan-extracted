package Term::Fabulous::Render::Target::Mask;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

role Term::Fabulous::Render::Target::Mask {
	use Scalar::Util qw(refaddr);
	use Term::Fabulous::Render::Geometry qw(row_spans_outside);

	# Provided by the target: reset every cell outside the given rects, show
	# the frame, and write cells unconditionally.
	method clear_cells;
	method present_cells;
	method put_cell;
	method put_extension;
	method put_row;

	# Rects whose cells this frame must leave alone, until they are released.
	field @_kept_rects;

	sub _is_kept ( $x, $y, $rects ) {
		foreach my $rect (@$rects) {
			return 1 if $x >= $rect->[0] && $x < $rect->[2] && $y >= $rect->[1] && $y < $rect->[3];
		}
		return 0;
	}

	method begin_frame (@kept_rects) {
		@_kept_rects = @kept_rects;
		$self->clear_cells(@kept_rects);
		return;
	}

	method end_frame () {
		@_kept_rects = ();
		$self->present_cells;
		return;
	}

	method release_rect ($rect) {
		@_kept_rects = grep { refaddr($_) != refaddr($rect) } @_kept_rects;
		return;
	}

	method set_cell ( $x, $y, $glyph, $fg, $bg ) {
		return if @_kept_rects && _is_kept( $x, $y, \@_kept_rects );
		$self->put_cell( $x, $y, $glyph, $fg, $bg );
		return;
	}

	method extend_cell ( $x, $y, $character ) {
		return if @_kept_rects && _is_kept( $x, $y, \@_kept_rects );
		$self->put_extension( $x, $y, $character );
		return;
	}

	method fill_row ( $x, $y, $columns, $bg ) {
		if ( !@_kept_rects ) {
			$self->put_row( $x, $y, $columns, $bg );
			return;
		}
		foreach my $span ( row_spans_outside( $y, $x, $x + $columns, @_kept_rects ) ) {
			my ( $from, $to ) = @$span;
			$self->put_row( $from, $y, $to - $from, $bg );
		}
		return;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Render::Target::Mask - Base role of the cell targets:
protect kept cells during a frame

=head1 SYNOPSIS

	use v5.32;
	use Object::Pad 0.825;
	use Term::Fabulous::Render::Target::Mask;

	# A cell target that records which cells were written.
	class My::Target::Log :does(Term::Fabulous::Render::Target::Mask) {
		field @written;

		method clear_cells (@kept_rects)            { @written = (); return }
		method present_cells ()                     { say scalar(@written), ' cells'; return }
		method put_cell ( $x, $y, $glyph, $fg, $bg ) { push @written, [ $x, $y, $glyph ]; return }
		method put_extension ( $x, $y, $character ) { $written[-1][2] .= $character; return }
		method put_row ( $x, $y, $columns, $bg )    { push @written, map { [ $_, $y, ' ' ] } $x .. $x + $columns - 1; return }

		# Not a primitive of this role, but every target needs it.
		method painted_cell ( $x, $y ) {
			my ($cell) = grep { $_->[0] == $x && $_->[1] == $y } reverse @written;
			return defined $cell ? ( $cell->[2], 0, 0 ) : ();
		}
	}

=head1 DESCRIPTION

Most programs never use this module directly. Read on if you want to
paint Term::Fabulous frames somewhere other than the terminal
(L<Term::Fabulous::Terminal::Termbox::Cells>) or memory
(L<Term::Fabulous::Render::Target::Grid>).

A I<cell target> is the object that receives the cells
L<Term::Fabulous::Render> paints (see
L<Term::Fabulous::Render/CELL TARGET>). The class of a cell target
composes this role. This role implements the
target methods the renderer calls (C<begin_frame>, C<end_frame>,
C<release_rect>, C<set_cell>, C<extend_cell>, C<fill_row>) on top of
five simple primitives that a concrete target provides; the target
also provides C<painted_cell> (see L</REQUIRED METHODS>). On the way, it
implements I<kept rectangles>: parts of the previous frame that must
stay as they are, because an unchanged canvas is there (see
L<Term::Fabulous::Render::Canvas/Painting only the changes>). Writes
into a kept rectangle are dropped until the rectangle is released.

=head1 METHODS

=head2 begin_frame

	$target->begin_frame(@kept_rects);

Remembers the kept C<[x0, y0, x1, y1]> rectangles and calls
L</clear_cells> with them.

=head2 end_frame

	$target->end_frame;

Forgets all kept rectangles and calls L</present_cells>.

=head2 release_rect

	$target->release_rect($rect);

Stops protecting one kept rectangle. C<$rect> must be the same array
reference that was given to L</begin_frame>.

=head2 set_cell

	$target->set_cell( $x, $y, $glyph, $fg, $bg );

Calls L</put_cell>, unless the cell lies in a kept rectangle.

=head2 extend_cell

	$target->extend_cell( $x, $y, $character );

Calls L</put_extension>, unless the cell lies in a kept rectangle.

=head2 fill_row

	$target->fill_row( $x, $y, $columns, $bg );

Calls L</put_row> for the parts of the row that lie outside every kept
rectangle.

=head1 REQUIRED METHODS

A role or class composing this role provides these primitives. They are
called with coordinates inside the viewport only.

=head2 clear_cells

	method clear_cells (@kept_rects) { ... }

Resets every cell outside the given rectangles to empty (a space in the
terminal default colors), and leaves the cells inside them as the
previous frame left them. Without rectangles, resets everything.

=head2 present_cells

	method present_cells () { ... }

Shows the finished frame, if the target needs a step for that.

=head2 put_cell

	method put_cell ( $x, $y, $glyph, $fg, $bg ) { ... }

Writes one cell: C<$glyph> is a character string of one character,
C<$fg> and C<$bg> are termbox2 attributes (see
L<Term::Fabulous::Render::Attr>).

=head2 put_extension

	method put_extension ( $x, $y, $character ) { ... }

Appends a combining character (a character string of length one) to the
cell written last at that position.

=head2 put_row

	method put_row ( $x, $y, $columns, $bg ) { ... }

Writes C<$columns> cells of spaces with the background attribute C<$bg>
and the terminal default foreground, from C<($x, $y)> to the right.

=head2 painted_cell

	method painted_cell ( $x, $y ) { ... }

Not used by this role, but the renderer calls it on every target (see
L<Term::Fabulous::Render/painted_cell>): returns the glyph, foreground
and background attribute painted at a cell in this frame, or an empty
list. It is called only for a translucent background with
C<glyphs_show_through>, but a target without it dies there.

=head1 SEE ALSO

L<Term::Fabulous::Render/CELL TARGET>,
L<Term::Fabulous::Terminal::Termbox::Cells>,
L<Term::Fabulous::Render::Target::Grid>.

=cut
