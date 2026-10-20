package Term::Fabulous::Render::Target::Sixel;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

role Term::Fabulous::Render::Target::Sixel {

	# The pixels of a cell, or nothing when the target cannot show sixel.
	method sixel_cell_size;

	# The cells of a frame a picture may cover.
	method sixel_area;

	# The pictures of the frame being painted.
	method show_sixels;
}

1;

__END__

=head1 NAME

Term::Fabulous::Render::Target::Sixel - Role of the cell targets that
show sixel pictures

=head1 SYNOPSIS

	use v5.32;
	use Object::Pad 0.825;
	use Term::Fabulous::Render::Target::Mask;
	use Term::Fabulous::Render::Target::Sixel;

	class My::Target
		:does(Term::Fabulous::Render::Target::Mask)
		:does(Term::Fabulous::Render::Target::Sixel)
	{
		field @pictures;

		method sixel_cell_size ()              { return ( 10, 20 ) }    # or () without sixel
		method sixel_area ( $width, $height )  { return [ 0, 0, $width, $height ] }
		method show_sixels (@placements)       { @pictures = @placements; return }

		# ... the primitives of Term::Fabulous::Render::Target::Mask
	}

=head1 DESCRIPTION

Most programs never use this module directly. Read on if you write a
cell target (see L<Term::Fabulous::Render/CELL TARGET>) that can show
the pictures of L<Term::Fabulous::Widget::Sixel>.

Sixel pictures are not cells: the terminal draws them over the cells,
from the cell at the cursor on. A cell target that composes this role
tells L<Term::Fabulous::Render> the size of a cell in pixels, and the
renderer hands it the pictures of every frame, with the cells each one
covers, after the frame's cells are painted and before
C<end_frame>. A target without this role, or one whose
L</sixel_cell_size> is empty, shows no pictures: the Sixel widgets show
a notice instead.

The role has no methods of its own; the target provides all three.
L<Term::Fabulous::Terminal::Termbox::Cells> composes it for the real
terminal, L<Term::Fabulous::Render::Target::Grid> for
L<Term::Fabulous::Terminal::Memory> and L<Term::Fabulous::Static>.

=head1 REQUIRED METHODS

=head2 sixel_cell_size

	my ( $width, $height ) = $target->sixel_cell_size;

The width and the height of a cell in pixels, both whole numbers of at
least 1, when the target can show sixel pictures; else an empty list.
The answer may change between frames, for example when the terminal's
font size changes.

=head2 sixel_area

	my $rect = $target->sixel_area( $width, $height );

The C<[x0, y0, x1, y1]> rectangle of cells a picture may cover in a
frame of C<$width> x C<$height> cells, inside the frame. The renderer
cuts every picture to it. A terminal leaves out its last row, for
example, because a picture that reaches it makes the screen scroll.

=head2 show_sixels

	$target->show_sixels(@placements);

Called once per frame, after the frame's cells are painted and before
C<end_frame>, with the frame's pictures in paint order, none when the
frame has none. Each placement is a hash reference:

=over

=item C<x>, C<y>

The cell the picture's top left corner covers.

=item C<columns>, C<rows>

The cells the picture covers, at least 1 each; the picture is
C<columns> times the cell width wide and C<rows> times the cell height
high.

=item C<data>

The picture as SIXEL data: a byte string that starts with C<ESC P>.

=back

The pictures of a frame replace those of the frame before: a picture
that is not given again must disappear, and the cells it covered must
show what the frame painted there. Transparent pixels of a picture
leave the cells below them visible; the renderer makes the pixels of
cells that something painted over the picture transparent.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Sixel>, L<Term::Fabulous::Render/CELL TARGET>,
L<Term::Fabulous::Render::Target::Mask>.

=cut
