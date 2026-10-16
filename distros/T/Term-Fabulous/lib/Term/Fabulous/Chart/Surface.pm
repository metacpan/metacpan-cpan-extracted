package Term::Fabulous::Chart::Surface;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

class Term::Fabulous::Chart::Surface :strict(params) {
	use Carp qw(croak);
	use Term::Fabulous::Render::Attr qw(cell_color_attr);
	use Term::Fabulous::Unicode qw(grapheme_clusters cluster_columns sanitize_text string_columns);

	use constant ELLIPSIS => "\x{2026}";

	# Stored in the cell right of a wide glyph.
	use constant TAIL => '';

	# The neighbors a line may be hit from, nearest first.
	my @NEIGHBORS = ( [ -1, 0 ], [ 1, 0 ], [ 0, -1 ], [ 0, 1 ], [ -1, -1 ], [ 1, -1 ], [ -1, 1 ], [ 1, 1 ] );

	field $columns    :param :reader;
	field $rows       :param :reader;
	field $background :param :reader = undef;    # what an untouched cell shows: 0xRRGGBB or undef

	# By cell index y * columns + x.
	field @_glyph;    # a grapheme cluster, TAIL, or undef for a space
	field @_fg;
	field @_bg;
	field @_flags;    # termbox2 style bits for the foreground (TB_BOLD, ...)
	field @_stroke_owner;
	field @_fill_owner;
	field %_dominant;    # by cell index: the color most of a two-color cell shows

	ADJUST {
		foreach my $size ( [ columns => $columns ], [ rows => $rows ] ) {
			croak "Term::Fabulous::Chart::Surface: $size->[0] must be a non-negative integer, got " . ( $size->[1] // 'undef' )
				unless defined $size->[1] && $size->[1] =~ /\A[0-9]+\z/;
		}
		@_bg = ($background) x ( $columns * $rows );
	}

	method _index ( $x, $y ) {
		return undef if $x < 0 || $y < 0 || $x >= $columns || $y >= $rows;
		return $y * $columns + $x;
	}

	method contains ( $x, $y ) {
		return defined $self->_index( $x, $y ) ? 1 : 0;
	}

	method glyph_at ( $x, $y ) {
		my $index = $self->_index( $x, $y ) // return undef;
		return $_glyph[$index];
	}

	method fg_at ( $x, $y ) {
		my $index = $self->_index( $x, $y ) // return undef;
		return $_fg[$index];
	}

	method bg_at ( $x, $y ) {
		my $index = $self->_index( $x, $y ) // return $background;
		return $_bg[$index];
	}

	method flags_at ( $x, $y ) {
		my $index = $self->_index( $x, $y ) // return 0;
		return $_flags[$index] // 0;
	}

	# A wide glyph cut by a write shows a space in its other cell.
	method _release ($index) {
		my $x = $index % $columns;
		if ( defined $_glyph[$index] && $_glyph[$index] eq TAIL && $x > 0 ) {
			$_glyph[ $index - 1 ] = ' ';
		}
		elsif ( defined $_glyph[$index] && cluster_columns( $_glyph[$index] ) > 1 && $x + 1 < $columns ) {
			$_glyph[ $index + 1 ] = ' ';
		}
		return;
	}

	# Sets the background of a rectangle and removes its glyphs.
	method fill ( $x, $y, $width, $height, $color ) {
		foreach my $row ( $y .. $y + $height - 1 ) {
			foreach my $column ( $x .. $x + $width - 1 ) {
				my $index = $self->_index( $column, $row ) // next;
				$self->_release($index);
				delete $_dominant{$index};
				( $_glyph[$index], $_fg[$index], $_flags[$index], $_bg[$index] ) = ( undef, undef, 0, $color );
			}
		}
		return $self;
	}

	# One glyph one column wide; an undef $bg keeps the cell's background.
	method put ( $x, $y, $glyph, $fg, $bg = undef, $flags = 0 ) {
		my $index = $self->_index( $x, $y ) // return $self;
		$self->_release($index);
		delete $_dominant{$index};
		( $_glyph[$index], $_fg[$index], $_flags[$index] ) = ( $glyph, $fg, $flags );
		$_bg[$index] = $bg if defined $bg;
		return $self;
	}

	# Writes text from ($x, $y) to the right, at most $options{max}
	# columns (cut with an ellipsis); returns the columns written.
	method text ( $x, $y, $text, $fg, %options ) {
		my ( $bg, $flags, $limit ) = ( $options{bg}, $options{flags} // 0, $options{max} );
		my @clusters = grapheme_clusters( sanitize_text($text) );
		my $total    = 0;
		$total += cluster_columns($_) foreach @clusters;
		if ( defined $limit && $total > $limit ) {
			return 0 if $limit < 1;
			my $room = $limit - 1;
			my @kept;
			foreach my $cluster (@clusters) {
				last if cluster_columns($cluster) > $room;
				$room -= cluster_columns($cluster);
				push @kept, $cluster;
			}
			@clusters = ( @kept, ELLIPSIS );
		}

		my $column = $x;
		foreach my $cluster (@clusters) {
			my $wide = cluster_columns($cluster);
			last if $column + $wide > $columns;
			$self->put( $column, $y, $cluster, $fg, $bg, $flags );
			if ( $wide > 1 ) {
				my $index = $self->_index( $column + 1, $y );
				( $_glyph[$index], $_fg[$index] ) = ( TAIL, $fg ) if defined $index;
				$_bg[$index] = $bg if defined $index && defined $bg;
			}
			$column += $wide;
		}
		return $column - $x;
	}

	# The columns text takes, as text() counts them.
	method text_columns :common ($text) {
		return string_columns( sanitize_text($text) );
	}

	# Draws a raster's cells over the surface with its marker, its cell
	# (0, 0) at ($left, $top); each drawn cell is owned, in $layer
	# ('stroke' or 'fill'), by the owner most of its subpixels have.
	#
	# A block marker splits a cell in two colors; the color most of the
	# cell shows is remembered, and a Braille pattern drawn over the cell
	# later (a line along the top of an area) takes it as its background.
	method composite ( $raster, $layer, $left = 0, $top = 0 ) {
		my $owners = $layer eq 'stroke' ? \@_stroke_owner : $layer eq 'fill' ? \@_fill_owner : croak "Term::Fabulous::Chart::Surface: unknown layer '$layer'";
		my $marker = $raster->marker;
		my $dots   = $marker->name eq 'braille';
		$raster->each_cell(
			sub ( $x, $y, $colors, $cell_owners, $drawn ) {
				my $index = $self->_index( $left + $x, $top + $y ) // return;
				my $under = $dots && exists $_dominant{$index} ? $_dominant{$index} : $_bg[$index];
				my ( $glyph, $fg, $bg, $dominant ) = $marker->cell( $colors, $under, $drawn ) or return;
				$self->put( $left + $x, $top + $y, $glyph, $fg, $bg );
				if ($dots) {
					$_bg[$index] = $under;
					delete $_dominant{$index};
				}
				else {
					$_dominant{$index} = $dominant;
				}
				my $owner = _most_frequent($cell_owners);
				$owners->[$index] = $owner if defined $owner;
				return;
			}
		);
		return $self;
	}

	sub _most_frequent ($values) {
		my ( %count, $best, $most );
		foreach my $value ( grep { defined } @$values ) {
			my $seen = ++$count{$value};
			( $best, $most ) = ( $value, $seen ) if !defined $most || $seen > $most;
		}
		return $best;
	}

	method set_owner ( $x, $y, $layer, $owner ) {
		my $index = $self->_index( $x, $y ) // return $self;
		( $layer eq 'stroke' ? \@_stroke_owner : \@_fill_owner )->[$index] = $owner;
		return $self;
	}

	method owner ( $x, $y, $layer ) {
		my $index = $self->_index( $x, $y ) // return undef;
		return ( $layer eq 'stroke' ? \@_stroke_owner : \@_fill_owner )->[$index];
	}

	# What the pointer at a cell points at: a line or point drawn there, a
	# fill (bar, area, slice, legend entry) drawn there, or a line in a
	# neighboring cell, so thin lines are easy to hit.
	method owner_near ( $x, $y ) {
		my $index = $self->_index( $x, $y ) // return undef;
		return $_stroke_owner[$index] // $_fill_owner[$index] // do {
			my $found;
			foreach my $offset (@NEIGHBORS) {
				my $neighbor = $self->_index( $x + $offset->[0], $y + $offset->[1] ) // next;
				$found = $_stroke_owner[$neighbor] // next;
				last;
			}
			$found;
		};
	}

	# Writes every cell into a canvas of the same size; cells showing the
	# surface background stay unset, so the canvas's own background shows.
	method paint ($canvas) {
		$canvas->clear;
		foreach my $y ( 0 .. $rows - 1 ) {
			foreach my $x ( 0 .. $columns - 1 ) {
				my $index = $y * $columns + $x;
				my ( $glyph, $bg ) = ( $_glyph[$index], $_bg[$index] );
				next if defined $glyph && $glyph eq TAIL;
				my $own_bg = defined $bg && ( !defined $background || $bg != $background ) ? $bg : undef;
				next if !defined $own_bg && ( !defined $glyph || $glyph eq ' ' );
				my $fg = defined $_fg[$index] ? cell_color_attr( fg => $_fg[$index] ) | ( $_flags[$index] // 0 ) : undef;
				$canvas->put_attrs( $x, $y, $glyph // ' ', $fg, cell_color_attr( bg => $own_bg ) );
			}
		}
		return;
	}

	# The cells as text, one string per row (for tests and debugging).
	method lines () {
		return map {
			my $y = $_;
			join '', map { my $glyph = $_glyph[ $y * $columns + $_ ]; !defined $glyph ? ' ' : $glyph eq TAIL ? '' : $glyph } 0 .. $columns - 1;
		} 0 .. $rows - 1;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Chart::Surface - The cells of a chart while it is drawn

=head1 SYNOPSIS

	use Term::Fabulous::Chart::Surface;
	use Term::Fabulous::Termbox qw(TB_BOLD);

	# $raster is a Term::Fabulous::Chart::Raster, $canvas the chart's canvas.
	my $surface = Term::Fabulous::Chart::Surface->new( columns => 40, rows => 12, background => 0x141923 );
	$surface->text( 0, 0, 'Sales', 0xFFFFFF, flags => TB_BOLD );
	$surface->put( $_, 5, "\x{2500}", 0x2c3340 ) foreach 0 .. 39;    # a grid line
	$surface->composite( $raster, 'stroke' );                       # lines over it
	my $owner = $surface->owner_near( 12, 4 );                        # what the mouse is on
	$surface->paint($canvas);

=head1 DESCRIPTION

A chart widget draws a frame in a surface first and copies it into its
canvas cells at the end. A surface holds a glyph, a foreground color, a
background color and style bits per cell (colors as packed C<0xRRGGBB>
integers), and two owner maps that record what was drawn where: lines and
points in the C<stroke> layer, fills (bars, areas, slices, legend entries)
in the C<fill> layer. The owners let the chart find what the mouse
pointer is on.

Rasters (L<Term::Fabulous::Chart::Raster>) are drawn over the cells with
L</composite>: their marker turns each cell's subpixels into a glyph over
the background the cell has at that moment, so a line drawn over an area
fill keeps the fill as its background.

=head1 METHODS

=head2 new

	Term::Fabulous::Chart::Surface->new( columns => $columns, rows => $rows, background => $rgb );

C<columns> and C<rows> (non-negative integers) are required.
C<background> is what every cell shows at first (C<undef> for the
terminal's default background).

=head2 columns, rows, background

The size and the background given to the constructor.

=head2 fill

	$surface->fill( $x, $y, $width, $height, $rgb );

Sets the background of a rectangle and removes its glyphs.

=head2 put

	$surface->put( $x, $y, $glyph, $fg, $bg, $flags );

Sets one cell to a glyph one column wide. An C<undef> background keeps the
cell's background; C<$flags> are termbox2 style bits such as C<TB_BOLD>.

=head2 text

	my $columns = $surface->text( $x, $y, $text, $fg, bg => $rgb, flags => TB_BOLD, max => 20 );

Writes a character string, two cells per wide character. With C<max>, text
wider than that is cut and ends in an ellipsis. Returns the number of
columns written; text that would cross the right edge is cut there.

=head2 text_columns

	my $width = Term::Fabulous::Chart::Surface->text_columns($text);

The columns C<text> takes for a string (a class method).

=head2 composite

	$surface->composite( $raster, $layer, $left, $top );

Draws a raster over the surface, the raster's cell (0, 0) at
C<($left, $top)> (default: 0, 0). C<$layer> is C<stroke> or C<fill>:
each drawn cell is owned in that layer by the owner most of its
subpixels have. Dies for another layer.

=head2 set_owner, owner

	$surface->set_owner( $x, $y, $layer, $owner );
	my $owner = $surface->owner( $x, $y, $layer );

Set and read the owner of one cell in a layer (C<stroke> or C<fill>);
charts set the owners of the points they draw as characters.

=head2 owner_near

The owner the pointer at a cell points at: a stroke in the cell, else a
fill in the cell, else a stroke in one of the eight neighbors. C<undef>
when there is none.

=head2 glyph_at, fg_at, bg_at, flags_at, contains

Read one cell.

=head2 paint

	$surface->paint($canvas);

Clears the canvas and writes every cell into it. Cells that only show the
surface's background stay unset.

=head2 lines

The glyphs as one string per row; for tests.

=head1 SEE ALSO

L<Term::Fabulous::Chart::Raster>, L<Term::Fabulous::Widget::Chart>.

=cut
