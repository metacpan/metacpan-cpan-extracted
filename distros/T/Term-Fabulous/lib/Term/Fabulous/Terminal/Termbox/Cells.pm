package Term::Fabulous::Terminal::Termbox::Cells;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Object::Pad 0.825;

use Term::Fabulous::Render::Target::Mask;
use Term::Fabulous::Render::Target::Sixel;

class Term::Fabulous::Terminal::Termbox::Cells
	:does(Term::Fabulous::Render::Target::Mask)
	:does(Term::Fabulous::Render::Target::Sixel)
	:strict(params)
{
	use List::Util qw(any min);
	use Term::Fabulous::Termbox qw(
		tb_clear tb_present tb_set_cell tb_extend_cell tb_get_cell tb_print tb_width tb_height tb_send tf_flush
		tf_cells_differ tf_invalidate_cells TB_DEFAULT TB_OK
	);
	use Term::Fabulous::Render::Geometry qw(row_spans_outside);

	# In inline mode, the terminal row of row 0 and the rows of the region.
	field $region_top  :reader = undef;
	field $region_rows :reader = undef;

	# The pixels of a cell while the terminal shows sixel, else empty; the
	# pictures of the frame being painted, and those on the screen.
	field @_cell_size;
	field @_sixels_due;
	field @_sixels_shown;

	method place_region ( $top, $rows ) {
		die "Term::Fabulous::Terminal::Termbox::Cells: place_region needs both a top row and a number of rows, or neither"
			if defined $top != defined $rows;
		( $region_top, $region_rows ) = ( $top, $rows );
		return;
	}

	# termbox2 keeps its back buffer between frames, so the cells of kept
	# rects still hold what the previous frame painted there.
	method clear_cells (@kept_rects) {
		if ( !@kept_rects ) {
			tb_clear();
			return;
		}
		my $width = tb_width();
		my $rows  = $region_rows // tb_height();
		foreach my $y ( 0 .. $rows - 1 ) {
			foreach my $span ( row_spans_outside( $y, 0, $width, @kept_rects ) ) {
				my ( $from, $to ) = @$span;
				tb_print( $from, $self->_terminal_row($y), TB_DEFAULT, TB_DEFAULT, ' ' x ( $to - $from ) );
			}
		}
		return;
	}

	method set_sixel_cell_size (@size) {
		die "Term::Fabulous::Terminal::Termbox::Cells: set_sixel_cell_size needs a width and a height of at least 1 pixel, or nothing"
			unless !@size || ( @size == 2 && !grep { !defined || !/\A[1-9][0-9]*\z/ } @size );
		@_cell_size = @size;
		return;
	}

	method sixel_cell_size () {
		return @_cell_size;
	}

	# A picture that reaches the terminal's last row makes the terminal
	# scroll the screen up, as the cursor moves below the picture.
	method sixel_area ( $width, $height ) {
		my $last_row = tb_height() - 1 - ( $region_top // 0 );
		return [ 0, 0, $width, min( $height, $last_row ) ];
	}

	method show_sixels (@placements) {
		@_sixels_due = @placements;
		return;
	}

	# The terminal forgets the pictures when termbox2 starts again.
	method forget_sixels () {
		( @_sixels_due, @_sixels_shown ) = ();
		return;
	}

	# termbox2 sends only the cells that changed, so a picture that is
	# gone gets the cells below it drawn again, which erases it. A picture
	# is sent after the cells, again whenever a cell below it changed.
	# In inline mode the hidden cursor waits at the start of the region's
	# first row: a terminal that rewraps its lines on a resize moves it
	# along, so asking for it finds the region again.
	method present_cells () {
		my @gone = grep {
			my $shown = $_;
			!any { _same_sixel( $shown, $_ ) } @_sixels_due
		} @_sixels_shown;
		$self->_invalidate_sixel($_) foreach @gone;
		my @new = grep {
			my $due = $_;
			!( any { _same_sixel( $due, $_ ) } @_sixels_shown ) || $self->_sixel_cells_differ($due)
		} @_sixels_due;
		@_sixels_shown = @_sixels_due;
		@_sixels_due   = ();

		tb_present();
		tb_send( sprintf( "\e[%d;%dH", $self->_terminal_row( $_->{y} ) + 1, $_->{x} + 1 ) . $_->{data} ) foreach @new;
		tb_send( "\e[" . ( $region_top + 1 ) . ";1H" ) if defined $region_top;
		tf_flush() if @new || defined $region_top;
		return;
	}

	sub _same_sixel ( $one, $other ) {
		return $one->{x} == $other->{x} && $one->{y} == $other->{y} && $one->{columns} == $other->{columns} && $one->{rows} == $other->{rows} && $one->{data} eq $other->{data};
	}

	method _invalidate_sixel ($placement) {
		tf_invalidate_cells( $placement->{x}, $self->_terminal_row( $placement->{y} ), $placement->{columns}, $placement->{rows} );
		return;
	}

	method _sixel_cells_differ ($placement) {
		my $rc = tf_cells_differ( $placement->{x}, $self->_terminal_row( $placement->{y} ), $placement->{columns}, $placement->{rows}, \my $differ );
		die "Term::Fabulous::Terminal::Termbox::Cells: tf_cells_differ failed (status $rc)" unless $rc == TB_OK;
		return $differ;
	}

	method put_cell ( $x, $y, $glyph, $fg, $bg ) {
		tb_set_cell( $x, $self->_terminal_row($y), $glyph, $fg, $bg );
		return;
	}

	method put_extension ( $x, $y, $character ) {
		tb_extend_cell( $x, $self->_terminal_row($y), $character );
		return;
	}

	method put_row ( $x, $y, $columns, $bg ) {
		tb_print( $x, $self->_terminal_row($y), TB_DEFAULT, $bg, ' ' x $columns );
		return;
	}

	# A cleared cell holds a space, so the back buffer always has a glyph.
	method painted_cell ( $x, $y ) {
		my ( $status, $glyph, $fg, $bg ) = tb_get_cell( $x, $self->_terminal_row($y), 1 );
		return () unless $status == TB_OK;
		return ( $glyph, $fg, $bg );
	}

	method _terminal_row ($y) {
		return $y + ( $region_top // 0 );
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Terminal::Termbox::Cells - Cell target that paints into
the terminal through termbox2

=head1 SYNOPSIS

	# Created and placed by Term::Fabulous::Terminal::Termbox:
	my $cells = $terminal->cell_target;
	$cells->place_region( $top, $rows );    # inline mode
	$cells->place_region( undef, undef );   # full screen

=head1 DESCRIPTION

Most programs never use this module directly. It is the cell target
(see L<Term::Fabulous::Render/CELL TARGET>) of
L<Term::Fabulous::Terminal::Termbox>: it writes the painted cells into
termbox2's back buffer and shows the frame with C<tb_present>, which
sends only the cells that changed since the last frame. It builds on
L<Term::Fabulous::Render::Target::Mask>, so it also provides
C<begin_frame>, C<end_frame>, C<release_rect>, C<set_cell>,
C<extend_cell> and C<fill_row>.

In inline mode, row 0 of a frame is the first row of the region, and
the hidden cursor is left at the start of that row after every frame.
The terminal must be open (C<tb_init> or C<tf_init_inline>);
otherwise termbox2 ignores the drawing.

=head1 METHODS

=head2 place_region

	$cells->place_region( $top, $rows );

Paints into the C<$rows> rows of an inline region starting at the
terminal row C<$top> (from 0); with C<undef> for both, into the whole
screen, which is the default. Dies when only one of them is given.

=head2 region_top, region_rows

The values of the last L</place_region>: C<undef> for the full screen.

=head2 clear_cells

Primitive for L<Term::Fabulous::Render::Target::Mask>. Without kept
rectangles, clears the back buffer (C<tb_clear>); otherwise overwrites
every cell of the screen (or region) outside them with a space in the
default colors, so that the kept cells hold what the previous frame
painted.

=head2 present_cells

Primitive: C<tb_present>, then the sixel pictures that must be sent
(see L</show_sixels>), each after a cursor move to its top left cell;
then in inline mode the cursor goes to the start of the region.

=head2 put_cell, put_extension, put_row

Primitives: C<tb_set_cell>, C<tb_extend_cell> and C<tb_print> of
spaces, at the terminal row of the frame row.

=head2 painted_cell

	my ( $glyph, $fg, $bg ) = $cells->painted_cell( $x, $y );

Reads a cell back from termbox2's back buffer (C<tb_get_cell>). See
L<Term::Fabulous::Render/painted_cell>.

=head2 set_sixel_cell_size

	$cells->set_sixel_cell_size( 10, 20 );
	$cells->set_sixel_cell_size;

Called by L<Term::Fabulous::Terminal::Termbox>: the terminal shows
sixel graphics with cells of the given width and height in pixels,
whole numbers of at least 1; without arguments, it shows none. Anything
else dies.

=head2 sixel_cell_size

	my ( $width, $height ) = $cells->sixel_cell_size;

From L<Term::Fabulous::Render::Target::Sixel>: the last
L</set_sixel_cell_size>, empty at first.

=head2 sixel_area

	my $rect = $cells->sixel_area( $width, $height );

From L<Term::Fabulous::Render::Target::Sixel>: the frame without the
terminal's last row. A picture that reaches it makes the terminal
scroll the screen up, as the cursor moves below the picture.

=head2 show_sixels

	$cells->show_sixels(@placements);

From L<Term::Fabulous::Render::Target::Sixel>: the pictures of the
frame being painted, which L</present_cells> shows. termbox2 sends only
the cells that changed since the last frame, and knows nothing of the
pictures, so L</present_cells>:

=over

=item *

makes termbox2 draw the cells of a picture of the last frame that is
not shown again at the same place with the same data
(C<tf_invalidate_cells>), which erases it;

=item *

sends a picture that is new, moved or changed, or whose cells termbox2
draws in this frame (C<tf_cells_differ>), since drawing a cell erases
the picture's pixels there.

=back

=head2 forget_sixels

	$cells->forget_sixels;

Forgets the pictures on the screen and those of the frame being
painted, for a new termbox2 session, which starts with a clear screen.

=head1 SEE ALSO

L<Term::Fabulous::Terminal::Termbox>, L<Term::Fabulous::Render/CELL TARGET>,
L<Term::Fabulous::Render::Target::Mask>, L<Term::Fabulous::Termbox>.

=cut
