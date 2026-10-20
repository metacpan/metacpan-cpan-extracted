package Term::Fabulous::Render::Geometry;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Exporter 'import';
our @EXPORT_OK = qw(cell_rect intersect_cell_rects visible_cell_rect rects_overlap row_spans_outside cell_coordinate line_steps);

use List::Util qw(min max);
use Scalar::Util qw(looks_like_number);

# Every edge is rounded to the nearest cell on its own. Two boxes that
# meet share the same edge value up to float32 noise (one's x + width is
# the other's x), so they land on the same cell, while flooring would
# leave a blank column between an edge of 70.9999 and one of 71.
sub cell_rect ($bbox) {
	my ( $x, $y ) = @{$bbox}{qw(x y)};
	return ( _cell_edge($x), _cell_edge($y), _cell_edge( $x + $bbox->{width} ), _cell_edge( $y + $bbox->{height} ) );
}

# Rounds to the nearest cell, halves up; int() and a comparison are much
# cheaper than POSIX::floor.
sub _cell_edge ($value) {
	my $shifted = $value + 0.5;
	my $whole   = int $shifted;
	return $whole <= $shifted ? $whole : $whole - 1;
}

sub intersect_cell_rects ( $first, $second ) {
	my $x0 = max( $first->[0], $second->[0] );
	my $y0 = max( $first->[1], $second->[1] );
	my $x1 = max( $x0,         min( $first->[2], $second->[2] ) );
	my $y1 = max( $y0,         min( $first->[3], $second->[3] ) );
	return [ $x0, $y0, $x1, $y1 ];
}

sub visible_cell_rect ( $bbox, $clip ) {
	my ( $x0, $y0, $x1, $y1 ) = @{ intersect_cell_rects( [ cell_rect($bbox) ], $clip ) };
	return if $x0 >= $x1 || $y0 >= $y1;
	return ( $x0, $y0, $x1, $y1 );
}

# Rounds down; int() and a comparison are much cheaper than POSIX::floor.
sub cell_coordinate ( $what, $value ) {
	die "Term::Fabulous::Render::Geometry: $what must be a finite number, got " . ( defined $value ? "'$value'" : 'undef' )
		unless looks_like_number($value) && $value == $value && $value - $value == 0;
	my $whole = int $value;
	return $whole <= $value ? $whole : $whole - 1;
}

# Bresenham: the line passes every pixel from one end to the other, both
# included. Along the longer (major) axis every step moves one pixel, and
# after $i steps the shorter axis has moved round($i * minor / major)
# pixels, halves rounded up. The steps whose major coordinate lies in the
# raster are computed directly, so a line far longer than the raster
# costs no more than one across it.
sub line_steps ( $x0, $y0, $x1, $y1, $width, $height ) {
	my ( $dx, $dy ) = ( abs( $x1 - $x0 ), abs( $y1 - $y0 ) );
	my ( $step_x, $step_y ) = ( $x0 < $x1 ? 1 : -1, $y0 < $y1 ? 1 : -1 );
	if ( $dx >= $dy ) {
		my ( $first, $last ) = _steps_inside( $x0, $step_x, $dx, $width );
		return ( $first, map { [ $x0 + $step_x * $_, $y0 + $step_y * _minor_steps( $_, $dy, $dx ) ] } $first .. $last );
	}
	my ( $first, $last ) = _steps_inside( $y0, $step_y, $dy, $height );
	return ( $first, map { [ $x0 + $step_x * _minor_steps( $_, $dx, $dy ), $y0 + $step_y * $_ ] } $first .. $last );
}

# The first and last step $i of 0 .. $length at which $start + $step * $i
# lies in 0 .. $limit - 1 (first above last when there is none).
sub _steps_inside ( $start, $step, $length, $limit ) {
	my ( $first, $last ) = $step > 0 ? ( -$start, $limit - 1 - $start ) : ( $start - $limit + 1, $start );
	return ( max( $first, 0 ), min( $last, $length ) );
}

sub _minor_steps ( $i, $minor, $major ) {
	return 0 unless $major;
	return int( ( 2 * $minor * $i + $major ) / ( 2 * $major ) );
}

sub rects_overlap ( $first, $second ) {
	my ( $x0, $y0, $x1, $y1 ) = @{ intersect_cell_rects( $first, $second ) };
	return $x0 < $x1 && $y0 < $y1;
}

sub row_spans_outside ( $y, $x0, $x1, @rects ) {
	my @holes = sort { $a->[0] <=> $b->[0] } map { [ max( $x0, $_->[0] ), min( $x1, $_->[2] ) ] } grep { $y >= $_->[1] && $y < $_->[3] && $_->[0] < $x1 && $_->[2] > $x0 } @rects;

	my ( @spans, $from );
	$from = $x0;
	foreach my $hole (@holes) {
		push @spans, [ $from, $hole->[0] ] if $hole->[0] > $from;
		$from = max( $from, $hole->[1] );
	}
	push @spans, [ $from, $x1 ] if $x1 > $from;
	return @spans;
}

1;

__END__

=head1 NAME

Term::Fabulous::Render::Geometry - Snap Clay's layout boxes to terminal
cells, and step lines through a raster

=head1 SYNOPSIS

	use Term::Fabulous::Render::Geometry qw(cell_rect intersect_cell_rects visible_cell_rect);

	my ( $x0, $y0, $x1, $y1 ) = cell_rect( { x => 1.7, y => 2, width => 3.6, height => 2 } );    # (2, 2, 5, 4)
	my $both    = intersect_cell_rects( [ 0, 0, 10, 5 ], [ 8, 3, 12, 9 ] );                      # [8, 3, 10, 5]
	my @visible = visible_cell_rect( $command->{boundingBox}, $ui->clip_rect );

=head1 DESCRIPTION

Most programs never use this module directly. It is used by the render
roles and the canvas widgets.

Clay places boxes at fractional positions, which may be negative or
reach past the viewport. Terminal output needs whole cells. These
functions convert boxes to cells the same way everywhere: every edge
is rounded to the nearest cell (halves up), the left edge from C<x>,
the right edge from C<x + width>, and likewise for the top and bottom.
Boxes that meet, such as the cells of a table row, share an edge value
up to the noise of Clay's single-precision floats, so rounding puts
them on the same cell where flooring would open a blank column between
an edge of 70.9999 and one of 71.

Cell rectangles are written C<[x0, y0, x1, y1]>: C<x0>, C<y0> is the
top-left cell, and C<x1>, C<y1> are I<exclusive>, so the rectangle
covers the columns C<x0 .. x1 - 1> and the rows C<y0 .. y1 - 1>. A
rectangle with C<x1 == x0> or C<y1 == y0> is empty.

=head1 FUNCTIONS

Nothing is exported by default. Import the functions you need by name.
All but L</line_steps> work on cells; L</line_steps> works on the pixels
of any raster.

=head2 cell_rect

	my ( $x0, $y0, $x1, $y1 ) = cell_rect($bbox);

The cell rectangle of a Clay bounding box, a hash reference with C<x>,
C<y>, C<width> and C<height>, as a list, each edge rounded to the
nearest cell. It is not clipped, so it may lie partly or fully outside
the viewport. A box narrower than half a cell may come out empty.

=head2 intersect_cell_rects

	my $common = intersect_cell_rects( $first, $second );

The cells two rectangles have in common, as a new array reference
C<[x0, y0, x1, y1]>. When they do not overlap, the result is an empty
rectangle (C<x1 == x0> or C<y1 == y0>).

=head2 visible_cell_rect

	my ( $x0, $y0, $x1, $y1 ) = visible_cell_rect( $bbox, $clip );

L</cell_rect> of C<$bbox>, intersected with the rectangle C<$clip>
(usually L<Term::Fabulous::Render/clip_rect>), as a list. Returns
the empty list when nothing of the box is visible.

=head2 rects_overlap

	if ( rects_overlap( $first, $second ) ) { ... }

True if the two rectangles share at least one cell. Rectangles that
only touch (one ends where the other starts) do not overlap.

=head2 row_spans_outside

	my @spans = row_spans_outside( $y, $x0, $x1, @rects );

The parts of row C<$y> between the columns C<$x0> (inclusive) and
C<$x1> (exclusive) that none of the rectangles C<@rects> covers, as a
list of C<[from, to]> pairs (C<to> exclusive), from left to right.
Without rectangles it returns the whole span C<[$x0, $x1]>.

	row_spans_outside( 1, 0, 10, [ 2, 0, 4, 3 ], [ 6, 1, 8, 2 ] );    # ([0, 2], [4, 6], [8, 10])

=head2 line_steps

	my ( $first, @pixels ) = line_steps( $x0, $y0, $x1, $y1, $width, $height );
	set_pixel(@$_) foreach @pixels;

The pixels of a straight line between two pixels (whole numbers), both
ends included, as Bresenham's algorithm steps through them, clipped to
a raster of C<$width> x C<$height> pixels: each pixel as C<[x, y]>, in
order from C<($x0, $y0)>. The line takes one step per pixel along its
longer axis (x when both are equally long), and only the steps whose
coordinate along that axis lies in the raster are returned, however
long the line is. On the other axis a returned pixel may still lie
outside the raster (a line that leaves a wide raster through its top),
so the caller's pixel writer skips those, as it skips any pixel
outside.

C<$first> is the index of the first returned step (0 for a line that
starts inside the raster): a caller that counts steps, such as the
dash pattern of L<Term::Fabulous::Chart::Raster>, advances its count by
it. When no step lies inside, C<@pixels> is empty.

	my ( $first, @pixels ) = line_steps( -2, 0, 3, 1, 4, 4 );    # (2, [0, 0], [1, 1], [2, 1], [3, 1])

L<Term::Fabulous::Widget::PixelCanvas/draw_line> and
L<Term::Fabulous::Chart::Raster> draw their lines with it.

=head2 cell_coordinate

	my $column = cell_coordinate( x => $x );

A coordinate or size given to a canvas drawing method, rounded down to
a whole cell: C<3.9> becomes 3, C<-0.5> becomes -1. Dies unless the
value is a finite number (NaN and infinities die); the first argument
names the value in the message:

=for highlighter language=text

	Term::Fabulous::Render::Geometry: x must be a finite number, got 'inf'

=head1 SEE ALSO

L<Term::Fabulous::Render>, L<Term::Fabulous::Render::Frame>.

=cut
