package Term::Fabulous::Chart::Marker;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

class Term::Fabulous::Chart::Marker :strict(params) {
	use Carp qw(croak);

	# The subpixels of a cell are numbered row by row from the top-left
	# corner: index = row * columns + column. A mask has bit i set for
	# subpixel i.

	# Braille dots by subpixel (two columns, four rows).
	my @BRAILLE_BIT = ( 0x01, 0x08, 0x02, 0x10, 0x04, 0x20, 0x40, 0x80 );

	my @QUADRANT
		= ( ' ', "\x{2598}", "\x{259D}", "\x{2580}", "\x{2596}", "\x{258C}", "\x{259E}", "\x{259B}", "\x{2597}", "\x{259A}", "\x{2590}", "\x{259C}", "\x{2584}", "\x{2599}", "\x{259F}", "\x{2588}" );

	sub _sextant_glyph ($mask) {
		return ' ' if $mask == 0;
		return "\x{2588}" if $mask == 63;
		return "\x{258C}" if $mask == 21;
		return "\x{2590}" if $mask == 42;
		return chr( 0x1FB00 + $mask - 1 - ( $mask > 21 ? 1 : 0 ) - ( $mask > 42 ? 1 : 0 ) );
	}

	# Vertical eighths: subpixel 0 is the top eighth. The lower blocks fill
	# from the bottom; of the upper ones only the half and the eighth exist.
	sub _vertical_block_glyphs () {
		my %glyph_of_mask = ( 0 => ' ', 0xFF => "\x{2588}", 0x0F => "\x{2580}", 0x01 => "\x{2594}" );
		$glyph_of_mask{ ( ( 1 << $_ ) - 1 ) << ( 8 - $_ ) } = chr( 0x2580 + $_ ) foreach 1 .. 7;
		return \%glyph_of_mask;
	}

	# Horizontal eighths: subpixel 0 is the left eighth.
	sub _horizontal_block_glyphs () {
		my %glyph_of_mask = ( 0 => ' ', 0xFF => "\x{2588}", 0xF0 => "\x{2590}", 0x80 => "\x{2595}" );
		$glyph_of_mask{ ( 1 << $_ ) - 1 } = chr( 0x2590 - $_ ) foreach 1 .. 7;
		return \%glyph_of_mask;
	}

	my %SPEC = (
		braille            => { columns => 2, rows => 4, dots   => 1 },
		half               => { columns => 1, rows => 2, glyphs => { 0 => ' ', 1 => "\x{2580}", 2 => "\x{2584}", 3 => "\x{2588}" } },
		quadrant           => { columns => 2, rows => 2, glyphs => { map { $_ => $QUADRANT[$_] } 0 .. 15 } },
		sextant            => { columns => 2, rows => 3, glyphs => { map { $_ => _sextant_glyph($_) } 0 .. 63 } },
		block              => { columns => 1, rows => 8, glyphs => _vertical_block_glyphs() },
		'block-horizontal' => { columns => 8, rows => 1, glyphs => _horizontal_block_glyphs() },
	);

	my %INSTANCE;

	field $name    :param :reader;
	field $columns :reader;
	field $rows    :reader;
	field $_is_dots;
	field %_glyph_of_mask;
	field @_candidates;    # [ mask, glyph ] of every glyph, for approximations
	field $_full_mask;

	ADJUST {
		my $spec = $SPEC{$name} // croak "Term::Fabulous::Chart::Marker: unknown marker '$name' (known: " . join( ', ', sort keys %SPEC ) . ")";
		( $columns, $rows, $_is_dots ) = ( $spec->{columns}, $spec->{rows}, $spec->{dots} // 0 );
		%_glyph_of_mask = %{ $spec->{glyphs} // {} };
		@_candidates    = map { [ $_, $_glyph_of_mask{$_} ] } sort { $a <=> $b } keys %_glyph_of_mask;
		$_full_mask     = ( 1 << ( $columns * $rows ) ) - 1;
	}

	method names :common () {
		my @names = sort keys %SPEC;
		return @names;
	}

	method is_name :common ($candidate) {
		return defined $candidate && !ref $candidate && exists $SPEC{$candidate} ? 1 : 0;
	}

	# The shared instance of a marker; markers hold no state of their own.
	method named :common ($wanted) {
		return $INSTANCE{ $wanted // '' } //= $class->new( name => $wanted );
	}

	method subpixels () {
		return $columns * $rows;
	}

	# The glyph showing the subpixel colors of one cell (packed 0xRRGGBB,
	# undef where nothing was drawn) over the cell's background $under
	# (undef for none): ( $glyph, $fg, $bg ), where an undef $bg keeps the
	# cell's background. The empty list when no subpixel was drawn.
	method cell ( $colors, $under, $drawn = undef ) {
		return $_is_dots ? _dots_cell( $colors, $drawn ) : $self->_two_color_cell( $colors, $under );
	}

	# Braille: every drawn subpixel is a dot in one color: that of the dot
	# drawn last, when the order is known (what is drawn on top wins), else
	# the color most of them have.
	sub _dots_cell ( $colors, $drawn ) {
		my ( $bits, %count, $color, $most, $latest ) = (0);
		foreach my $index ( 0 .. 7 ) {
			my $dot = $colors->[$index] // next;
			$bits |= $BRAILLE_BIT[$index];
			if ( $drawn && defined $drawn->[$index] ) {
				( $color, $latest ) = ( $dot, $drawn->[$index] ) if !defined $latest || $drawn->[$index] > $latest;
				next;
			}
			my $seen = ++$count{$dot};
			( $color, $most ) = ( $dot, $seen ) if !defined $latest && ( !defined $most || $seen > $most );
		}
		return () unless $bits;
		return ( chr( 0x2800 + $bits ), $color, undef );
	}

	# Block characters show two colors: the glyph's shape in the
	# foreground over the background. Subpixels of other colors take the
	# nearer of the two most frequent ones.
	method _two_color_cell ( $colors, $under ) {
		my ( %count, @keys, %is_drawn );
		$is_drawn{$_} = 1 foreach grep { defined } @$colors;
		return () unless %is_drawn;
		my @shown = map { $_ // $under } @$colors;
		foreach my $color (@shown) {
			my $key = $color // 'none';
			push @keys, $key unless $count{$key}++;
		}
		return ( ' ', undef, $shown[0], $shown[0] ) if @keys == 1 && defined $shown[0];
		return () if @keys == 1;

		# The most frequent color is the foreground; on a tie, a drawn color
		# rather than the background below.
		my %first = map { $keys[$_] => $_ } 0 .. $#keys;
		my ( $first, $second ) = ( sort { $count{$b} <=> $count{$a} || ( $is_drawn{$b} // 0 ) <=> ( $is_drawn{$a} // 0 ) || $first{$a} <=> $first{$b} } @keys )[ 0, 1 ];
		my $mask = 0;
		foreach my $index ( 0 .. $#shown ) {
			my $key = $shown[$index] // 'none';
			$key = _nearer( $key, $first, $second, $under ) unless $key eq $first || $key eq $second;
			$mask |= 1 << $index if $key eq $first;
		}
		my ( $fg, $bg ) = map { $_ eq 'none' ? undef : $_ } $first, $second;

		# What most of the cell shows; on a tie the background below, so a
		# fill never looks larger than it is.
		my $under_key = $under                                                                                                      // 'none';
		my $dominant  = $is_drawn{$first} && $count{$first} == ( $count{$under_key} // 0 ) && !$is_drawn{$under_key} ? $under : $fg // $under;
		( $mask, $fg, $bg ) = ( $_full_mask & ~$mask, $bg, $fg ) unless defined $fg;
		return ( $self->_glyph_cell( $mask, $fg, $bg ), $dominant );
	}

	sub _nearer ( $key, $first, $second, $under ) {
		my @rgb = map { $_ eq 'none' ? $under // 0 : $_ } $key, $first, $second;
		return _distance( @rgb[ 0, 1 ] ) <= _distance( @rgb[ 0, 2 ] ) ? $first : $second;
	}

	sub _distance ( $one, $other ) {
		my $sum = 0;
		$sum += ( ( ( $one >> $_ ) & 0xFF ) - ( ( $other >> $_ ) & 0xFF ) )**2 foreach 16, 8, 0;
		return $sum;
	}

	# The cell for $mask drawn in $fg (defined) over $bg (undef for the
	# cell's background). Markers without a glyph for every mask take the
	# glyph that differs in the fewest subpixels, in either orientation.
	method _glyph_cell ( $mask, $fg, $bg ) {
		return ( ' ', undef, $fg ) if $mask == $_full_mask;
		if ( defined( my $glyph = $_glyph_of_mask{$mask} ) ) {
			return $mask ? ( $glyph, $fg, $bg ) : ( ' ', undef, $bg );
		}
		my $inverse = $_full_mask & ~$mask;
		return ( $_glyph_of_mask{$inverse}, $bg, $fg ) if defined $bg && defined $_glyph_of_mask{$inverse};

		my ( $best, $best_cost );
		foreach my $candidate (@_candidates) {
			my ( $shape, $glyph ) = @$candidate;
			my @options = ( [ _bits( $shape ^ $mask ), $glyph, $fg, $bg ] );
			push @options, [ _bits( $shape ^ $inverse ), $glyph, $bg, $fg ] if defined $bg;
			foreach my $option (@options) {
				( $best, $best_cost ) = ( $option, $option->[0] ) if !defined $best_cost || $option->[0] < $best_cost;
			}
		}
		my ( undef, $glyph, $glyph_fg, $glyph_bg ) = @$best;
		return $glyph eq ' ' ? ( ' ', undef, $glyph_bg ) : ( $glyph, $glyph_fg, $glyph_bg );
	}

	sub _bits ($value) {
		my $count = 0;
		while ($value) {
			$value &= $value - 1;
			$count++;
		}
		return $count;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Chart::Marker - The character sets charts draw with

=head1 SYNOPSIS

	use Term::Fabulous::Chart::Marker;

	my $braille = Term::Fabulous::Chart::Marker->named('braille');
	say $braille->columns, 'x', $braille->rows;    # 2x4 subpixels per cell

	# The cell for the drawn subpixels of one cell (undef = not drawn):
	my ( $glyph, $fg, $bg ) = $braille->cell( [ 0xFF0000, undef, undef, 0xFF0000, ( undef ) x 4 ], 0x141923 );
	# ( "\x{2811}", 0xFF0000, undef ): two dots in red, background kept

=head1 DESCRIPTION

A chart draws its lines, areas, bars and points into a grid of
I<subpixels>, several per terminal cell, and turns each cell's subpixels
into one character with a foreground and a background color. A marker
is the set of characters used for that, and decides how many subpixels a
cell has. The chart widgets take the marker names as the C<marker> of a
series (see L<Term::Fabulous::Widget::XYChart/Rendering styles>).

=over

=item C<braille>

2 x 4 subpixels: the Braille patterns U+2800 to U+28FF, one dot per
subpixel. The finest resolution, for lines and points. A cell has only one
foreground color, so where series cross, the cell takes the color of the
dot drawn last (see L</cell>); the background stays as it was.

=item C<block>

1 x 8 subpixels: the lower eighth blocks U+2581 to U+2588, for bars and
areas that grow from the bottom: a bar's top is placed to an eighth of a
cell. The upper half and upper eighth blocks complete it.

=item C<block-horizontal>

8 x 1 subpixels: the left eighth blocks U+2589 to U+258F, for horizontal
bars. Charts use it for C<block> when the bars are horizontal.

=item C<half>

1 x 2 subpixels: the upper and lower half blocks, two colors per cell.
The subpixels are about square.

=item C<quadrant>

2 x 2 subpixels: the quadrant blocks U+2596 to U+259F.

=item C<sextant>

2 x 3 subpixels: the sextant blocks U+1FB00 to U+1FB3B of the "Symbols
for Legacy Computing". Smoother than quadrants, but not every font has
them; terminals that draw block characters themselves (kitty, WezTerm,
foot, Ghostty and others) show them everywhere.

=back

The block markers show two colors per cell: the character's shape in the
foreground color over the background color. A cell whose subpixels have
more colors shows the two most frequent ones, and every other subpixel
takes the nearer of the two. C<block> and C<block-horizontal> cannot show
every shape; a shape they lack is shown as the most similar one.

The C<box> style of chart lines is not a marker: the chart draws box
lines in cells, without subpixels.

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/cookbook-chart-styles.svg" alt="Nine small charts of one wave: lines in Braille, half blocks, quadrants, sextants and box drawing lines, an area in eighth blocks, and bars in quadrants, blocks and Braille"></p>

=end html

The program is in
L<Term::Fabulous::Cookbook::ChartStyles/Draw with Braille, blocks or box lines (marker)>.

=head1 CLASS METHODS

=head2 named

	my $marker = Term::Fabulous::Chart::Marker->named($name);

The marker of a name (C<braille>, C<block>, C<block-horizontal>,
C<half>, C<quadrant>, C<sextant>); the same object every time. Dies for
unknown names.

=head2 names

The names of all markers, sorted.

=head2 is_name

1 for the name of a marker, else 0.

=head1 METHODS

=head2 name

The marker's name.

=head2 columns, rows

The subpixels per cell across and down.

=head2 subpixels

C<columns * rows>.

=head2 cell

	my ( $glyph, $fg, $bg, $dominant ) = $marker->cell( \@colors, $under, \@drawn );

The character for one cell. C<@colors> holds a color (a packed
C<0xRRGGBB> integer) or C<undef> for each subpixel, row by row from the
top-left corner. C<$under> is the cell's background, which undrawn
subpixels show (C<undef> for none). C<@drawn>, optional, tells for each
subpixel when it was drawn (larger is later; see
L<Term::Fabulous::Chart::Raster/each_cell>): a Braille cell then takes
the color of the dot drawn last, so a series drawn on top of others keeps
its color where they cross; without it, the color most dots have.

Returns the glyph and its colors; an C<undef> background means "keep the
cell's background". The block markers return a fourth value, the color
most of the cell shows (C<undef> for the cell's background; on a tie, the
background below, so a fill never looks larger than it is): a Braille
line drawn over the cell later uses it as its background, so a fill keeps
its shape to half a cell. Returns the empty list when no subpixel was
drawn, so the cell keeps what it shows.

=head1 SEE ALSO

L<Term::Fabulous::Chart::Raster>, L<Term::Fabulous::Widget::Chart>.

=cut
