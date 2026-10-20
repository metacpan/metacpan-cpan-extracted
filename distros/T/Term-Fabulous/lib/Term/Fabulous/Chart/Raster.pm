package Term::Fabulous::Chart::Raster;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

use Term::Fabulous::Chart::Marker;

class Term::Fabulous::Chart::Raster :strict(params) {
	use Carp qw(croak);
	use List::Util qw(max min);
	use POSIX qw(ceil floor);
	use Term::Fabulous::Chart::Palette qw(mix_rgb);
	use Term::Fabulous::Render::Geometry qw(line_steps);

	field $marker  :param :reader;
	field $columns :param :reader;    # in cells
	field $rows    :param :reader;

	field $width  :reader;    # in subpixels
	field $height :reader;
	field $_cell_columns;    # subpixels per cell
	field $_cell_rows;

	field @_color;    # by subpixel index y * width + x: packed 0xRRGGBB or undef
	field @_owner;    # by subpixel index: whatever the caller tags it with
	field @_drawn;    # by subpixel index: when it was drawn (a growing count)
	field $_count = 0;
	field @_touched_cells;    # cell indexes with drawn subpixels, in drawing order
	field %_is_touched;

	# Where the dash pattern of a line continues; see start_pattern.
	field $_pattern;
	field $_pattern_step = 0;

	ADJUST {
		croak "Term::Fabulous::Chart::Raster: marker must be a Term::Fabulous::Chart::Marker"
			unless ref $marker && $marker->isa('Term::Fabulous::Chart::Marker');
		foreach my $size ( [ columns => $columns ], [ rows => $rows ] ) {
			croak "Term::Fabulous::Chart::Raster: $size->[0] must be a non-negative integer, got " . ( $size->[1] // 'undef' )
				unless defined $size->[1] && $size->[1] =~ /\A[0-9]+\z/;
		}
		( $_cell_columns, $_cell_rows ) = ( $marker->columns, $marker->rows );
		( $width, $height ) = ( $columns * $_cell_columns, $rows * $_cell_rows );
	}

	# ---------------------------------------------------------------------
	# Subpixels
	# ---------------------------------------------------------------------

	method _touch ( $x, $y ) {
		my $cell = int( $y / $_cell_rows ) * $columns + int( $x / $_cell_columns );
		push @_touched_cells, $cell unless $_is_touched{$cell}++;
		return;
	}

	# Colors one subpixel (whole coordinates); outside the raster nothing
	# happens.
	method set ( $x, $y, $color, $owner = undef ) {
		return if $x < 0 || $y < 0 || $x >= $width || $y >= $height;
		my $index = $y * $width + $x;
		( $_color[$index], $_owner[$index], $_drawn[$index] ) = ( $color, $owner, ++$_count );
		$self->_touch( $x, $y );
		return;
	}

	# Mixes $opacity of $color into a subpixel: into its color when it has
	# one, else into $base.
	method blend ( $x, $y, $color, $opacity, $base, $owner = undef ) {
		return if $x < 0 || $y < 0 || $x >= $width || $y >= $height;
		my $index = $y * $width + $x;
		$_color[$index] = $opacity >= 1 ? $color : mix_rgb( $_color[$index] // $base, $color, $opacity );
		$_owner[$index] = $owner;
		$_drawn[$index] = ++$_count;
		$self->_touch( $x, $y );
		return;
	}

	method color_at ( $x, $y ) {
		return undef if $x < 0 || $y < 0 || $x >= $width || $y >= $height;
		return $_color[ $y * $width + $x ];
	}

	method owner_at ( $x, $y ) {
		return undef if $x < 0 || $y < 0 || $x >= $width || $y >= $height;
		return $_owner[ $y * $width + $x ];
	}

	# ---------------------------------------------------------------------
	# Lines
	# ---------------------------------------------------------------------

	# The dash pattern of the lines drawn next: an array of run lengths in
	# subpixel steps, alternately drawn and skipped ([3, 2]: three on, two
	# off), or undef for solid lines. The pattern runs on from line to line,
	# so a polyline drawn as segments keeps an even rhythm.
	method start_pattern ($pattern) {
		$_pattern      = defined $pattern && @$pattern ? [@$pattern] : undef;
		$_pattern_step = 0;
		return $self;
	}

	method _pattern_allows () {
		return 1 unless $_pattern;
		my $period = 0;
		$period += $_ foreach @$_pattern;
		my $phase = $_pattern_step++ % $period;
		foreach my $index ( 0 .. $#$_pattern ) {
			return $index % 2 == 0 ? 1 : 0 if $phase < $_pattern->[$index];
			$phase -= $_pattern->[$index];
		}
		return 1;
	}

	# Every subpixel the line between two points passes (the subpixels
	# that contain the points included); coordinates are continuous, in
	# subpixels. With $opacity below 1 the line is blended into what is
	# there (or $base).
	method line ( $x0, $y0, $x1, $y1, $color, $owner = undef, $opacity = 1, $base = undef ) {
		my ( $first, @pixels ) = line_steps( ( map { floor($_) } $x0, $y0, $x1, $y1 ), $width, $height );
		$_pattern_step += $first if $_pattern;    # the steps before the raster count for the dashes
		foreach my $pixel (@pixels) {
			next unless $self->_pattern_allows;
			$opacity >= 1 ? $self->set( @$pixel, $color, $owner ) : $self->blend( @$pixel, $color, $opacity, $base, $owner );
		}
		return $self;
	}

	# ---------------------------------------------------------------------
	# Fills: the subpixels whose centers lie inside the shape
	# ---------------------------------------------------------------------

	# The whole subpixel indexes whose centers lie in [from, to).
	sub _covered ( $from, $to, $limit ) {
		return () if $to <= $from;
		return ( max( 0, ceil( $from - 0.5 ) ), min( $limit, ceil( $to - 0.5 ) ) - 1 );
	}

	method fill_rect ( $x0, $y0, $x1, $y1, $color, $owner = undef, $opacity = 1, $base = undef ) {
		( $x0, $x1 ) = ( $x1, $x0 ) if $x1 < $x0;
		( $y0, $y1 ) = ( $y1, $y0 ) if $y1 < $y0;
		my ( $left, $right ) = _covered( $x0, $x1, $width ) or return $self;
		my ( $top, $bottom ) = _covered( $y0, $y1, $height ) or return $self;
		foreach my $y ( $top .. $bottom ) {
			foreach my $x ( $left .. $right ) {
				$opacity >= 1 ? $self->set( $x, $y, $color, $owner ) : $self->blend( $x, $y, $color, $opacity, $base, $owner );
			}
		}
		return $self;
	}

	# The subpixels of column $x from $top to $bottom (continuous, either
	# order).
	method fill_column ( $x, $top, $bottom, $color, $owner = undef, $opacity = 1, $base = undef ) {
		return $self if $x < 0 || $x >= $width;
		( $top, $bottom ) = ( $bottom, $top ) if $bottom < $top;
		my ( $first, $last ) = _covered( $top, $bottom, $height ) or return $self;
		foreach my $y ( $first .. $last ) {
			$opacity >= 1 ? $self->set( $x, $y, $color, $owner ) : $self->blend( $x, $y, $color, $opacity, $base, $owner );
		}
		return $self;
	}

	# A polygon ([x, y] corners, continuous), filled by the even-odd rule.
	method fill_polygon ( $corners, $color, $owner = undef, $opacity = 1, $base = undef ) {
		return $self if @$corners < 3;
		my @ys = map { $_->[1] } @$corners;
		my ( $top, $bottom ) = _covered( min(@ys), max(@ys), $height ) or return $self;
		foreach my $y ( $top .. $bottom ) {
			my $center = $y + 0.5;
			my @crossings;
			foreach my $index ( 0 .. $#$corners ) {
				my ( $from, $to )   = ( $corners->[$index], $corners->[ ( $index + 1 ) % @$corners ] );
				my ( $low,  $high ) = $from->[1] <= $to->[1] ? ( $from, $to ) : ( $to, $from );
				next unless $center >= $low->[1] && $center < $high->[1];
				push @crossings, $low->[0] + ( $center - $low->[1] ) * ( $high->[0] - $low->[0] ) / ( $high->[1] - $low->[1] );
			}
			@crossings = sort { $a <=> $b } @crossings;
			while ( my ( $enter, $leave ) = splice @crossings, 0, 2 ) {
				last unless defined $leave;
				my ( $left, $right ) = _covered( $enter, $leave, $width ) or next;
				foreach my $x ( $left .. $right ) {
					$opacity >= 1 ? $self->set( $x, $y, $color, $owner ) : $self->blend( $x, $y, $color, $opacity, $base, $owner );
				}
			}
		}
		return $self;
	}

	# Calls $paint->($x, $y) for every subpixel of the area [x0, x1) x
	# [y0, y1) (whole numbers, clipped); it returns ( $color, $owner ) to
	# draw the subpixel, or the empty list to leave it.
	method paint_area ( $x0, $y0, $x1, $y1, $paint ) {
		foreach my $y ( max( 0, $y0 ) .. min( $height, $y1 ) - 1 ) {
			foreach my $x ( max( 0, $x0 ) .. min( $width, $x1 ) - 1 ) {
				my ( $color, $owner ) = $paint->( $x, $y ) or next;
				$self->set( $x, $y, $color, $owner );
			}
		}
		return $self;
	}

	# ---------------------------------------------------------------------
	# Cells
	# ---------------------------------------------------------------------

	# Every cell with drawn subpixels, in the order they were first drawn:
	# ( $cell_x, $cell_y, \@colors, \@owners, \@drawn ), the subpixels row
	# by row; @drawn tells when each was drawn (later is larger).
	method each_cell ($visit) {
		foreach my $cell (@_touched_cells) {
			my ( $cell_y, $cell_x ) = ( int( $cell / $columns ), $cell % $columns );
			my ( @colors, @owners, @drawn );
			foreach my $row ( 0 .. $_cell_rows - 1 ) {
				my $start = ( $cell_y * $_cell_rows + $row ) * $width + $cell_x * $_cell_columns;
				push @colors, @_color[ $start .. $start + $_cell_columns - 1 ];
				push @owners, @_owner[ $start .. $start + $_cell_columns - 1 ];
				push @drawn,  @_drawn[ $start .. $start + $_cell_columns - 1 ];
			}
			$visit->( $cell_x, $cell_y, \@colors, \@owners, \@drawn );
		}
		return;
	}

	method is_empty () {
		return @_touched_cells ? 0 : 1;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Chart::Raster - A drawing surface with several subpixels
per terminal cell

=head1 SYNOPSIS

	use Term::Fabulous::Chart::Marker;
	use Term::Fabulous::Chart::Raster;

	my $raster = Term::Fabulous::Chart::Raster->new(
		marker  => Term::Fabulous::Chart::Marker->named('braille'),
		columns => 40,    # cells
		rows    => 10,
	);
	# 80 x 40 subpixels
	$raster->line( 0, 39, 79, 0, 0x3987e5, 'sales' );
	$raster->start_pattern( [ 3, 2 ] )->line( 0, 20, 79, 20, 0xd95926 );
	$raster->fill_rect( 10, 30, 20, 40, 0x199e70, undef, 0.4, 0x141923 );

	$raster->each_cell( sub ( $x, $y, $colors, $owners, $drawn ) {
		my ( $glyph, $fg, $bg ) = $raster->marker->cell( $colors, 0x141923, $drawn );
		...
	} );

=head1 DESCRIPTION

The chart widgets draw their series into rasters: grids of subpixels
whose size depends on the L<Term::Fabulous::Chart::Marker> (2 x 4 per cell
for Braille, 1 x 8 for eighth blocks, ...). Each subpixel holds a color
(a packed C<0xRRGGBB> integer) or nothing, and an owner: a value the chart
uses to find what is under the mouse.

Coordinates are in subpixels, from 0 at the top-left corner. Lines take
the subpixels they pass; fills take the subpixels whose centers lie
inside the shape, so two shapes that share an edge do not overlap. Drawing
outside the raster is ignored. A translucent fill (C<$opacity> below 1)
mixes its color into the subpixel's color, or into C<$base> where nothing
was drawn yet.

=head1 CONSTRUCTOR

	my $raster = Term::Fabulous::Chart::Raster->new( marker => $marker, columns => $cells, rows => $cells );

C<marker> is a L<Term::Fabulous::Chart::Marker> object; C<columns> and
C<rows> are the size in cells, non-negative integers. All three are
required.

=head1 METHODS

=head2 set, blend

	$raster->set( $x, $y, $color, $owner );
	$raster->blend( $x, $y, $color, $opacity, $base, $owner );

Draws one subpixel (whole coordinates). C<blend> mixes C<$opacity> (0 to
1) of C<$color> into the subpixel's color, or into C<$base> where nothing
was drawn yet. C<$owner> is optional.

=head2 line

	$raster->line( $x0, $y0, $x1, $y1, $color, $owner, $opacity, $base );

Draws the subpixels on the line between two points (continuous
coordinates; the subpixels of both end points included), following the
dash pattern of L</start_pattern>. With C<$opacity> below 1 the line is
blended as L</set, blend> describes. Returns the raster.

=head2 start_pattern

	$raster->start_pattern( [ $on, $off, ... ] );
	$raster->start_pattern(undef);    # solid

Sets the dash pattern of the following lines and restarts it: run
lengths in subpixel steps, alternately drawn and skipped (C<[ 3, 2 ]>:
three on, two off). The pattern runs on from one line to the next.
Returns the raster, so a line can follow.

=head2 fill_rect

	$raster->fill_rect( $x0, $y0, $x1, $y1, $color, $owner, $opacity, $base );

The subpixels whose centers lie in the rectangle between two corners
(continuous coordinates, in either order). C<$owner>, C<$opacity>
(default 1) and C<$base> work as for L</set, blend>.

=head2 fill_column

	$raster->fill_column( $x, $top, $bottom, $color, $owner, $opacity, $base );

The subpixels of column C<$x> whose centers lie between two heights
(continuous, in either order).

=head2 fill_polygon

	$raster->fill_polygon( [ [ $x, $y ], ... ], $color, $owner, $opacity, $base );

The subpixels whose centers lie inside the polygon of the corners
(continuous coordinates), by the even-odd rule. Fewer than three
corners draw nothing.

=head2 paint_area

	$raster->paint_area( $x0, $y0, $x1, $y1, sub ( $x, $y ) { return ( $color, $owner ) } );

Asks a function for the color of every subpixel from C<($x0, $y0)> up
to, but not including, C<($x1, $y1)> (whole numbers, cut to the
raster). A function that returns the empty list leaves the subpixel as
it is. Pie charts use it.

=head2 color_at, owner_at

What one subpixel holds.

=head2 each_cell

	$raster->each_cell( sub ( $cell_x, $cell_y, $colors, $owners, $drawn ) { ... } );

Visits every cell that has drawn subpixels, with the colors and owners of
its subpixels row by row (C<undef> where nothing was drawn), and when each
was drawn: a number that is larger for later drawing.

=head2 is_empty

True while nothing was drawn.

=head2 marker, columns, rows, width, height

The marker, the size in cells and the size in subpixels.

=head1 SEE ALSO

L<Term::Fabulous::Chart::Marker>, L<Term::Fabulous::Chart::Surface>.

=cut
