package Term::Fabulous::Screenshot::Screen;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

class Term::Fabulous::Screenshot::Screen :strict(params) {
	use Carp qw(croak);
	use Encode qw(decode);
	use MIME::Base64 qw(decode_base64);
	use Term::Fabulous::Render::Attr qw(STYLE_FLAGS);
	use Term::Fabulous::Termbox qw(TB_HI_BLACK);
	use Term::Fabulous::Unicode qw(grapheme_clusters cluster_columns);

	use constant RGB_MASK => 0xFFFFFF;

	# termbox2 attribute flags and SGR parameters, and the style each
	# stands for; Term::Fabulous::Static writes the parameters from the
	# same table.
	use constant STYLE_BY_FLAG => map { $_->[0] => $_->[2] } STYLE_FLAGS;
	use constant STYLE_BY_SGR  => map { $_->[1] => $_->[2] } STYLE_FLAGS;

	field $columns :param :reader;
	field $rows    :param :reader;

	# One array per row of cells: { x, glyph, columns, fg, bg, styles }.
	# fg and bg are 0xRRGGBB or undef for the terminal's default color;
	# styles is a hash of the style names that apply.
	field $cells :param;

	# The sixel pictures over the cells: { x, y, columns, rows, png }, the
	# first cell, the cells covered and the PNG data.
	field $pictures :param = [];

	ADJUST {
		croak "Term::Fabulous::Screenshot::Screen: the screen needs at least one column and one row, got ${columns}x$rows"
			unless $columns >= 1 && $rows >= 1;
		croak "Term::Fabulous::Screenshot::Screen: $rows rows declared, " . scalar(@$cells) . " given" unless @$cells == $rows;
		foreach my $picture (@$pictures) {
			my ( $x, $y, $picture_columns, $picture_rows ) = @$picture{qw(x y columns rows)};
			croak "Term::Fabulous::Screenshot::Screen: the picture of ${picture_columns}x$picture_rows cells at $x,$y is not inside the ${columns}x$rows screen"
				unless $x >= 0 && $y >= 0 && $picture_columns >= 1 && $picture_rows >= 1 && $x + $picture_columns <= $columns && $y + $picture_rows <= $rows;
		}
	}

	method pictures () {
		return @$pictures;
	}

	method row ($y) {
		croak "Term::Fabulous::Screenshot::Screen: there is no row $y" unless $y >= 0 && $y < $rows;
		return @{ $cells->[$y] };
	}

	# A screen read from termbox2's front buffer by the harness:
	# { columns, rows, cells => [ [ [ glyph, columns, fg, bg ], ... ], ... ],
	# pictures => [ { x, y, columns, rows, png => BASE64 }, ... ] }.
	sub from_capture ( $class, $capture ) {
		my ( $width, $height ) = @$capture{qw(columns rows)};
		my @rows;
		foreach my $captured_row ( @{ $capture->{cells} } ) {
			my ( $x, @row ) = (0);
			foreach my $captured (@$captured_row) {
				my ( $glyph, $glyph_columns, $fg, $bg ) = @$captured;
				push @row, _cell( $x, $glyph, $glyph_columns, _attr_rgb($fg), _attr_rgb($bg), _attr_styles( $fg | $bg ) );
				$x += $glyph_columns;
			}
			croak "Term::Fabulous::Screenshot::Screen: captured row " . scalar(@rows) . " covers $x columns instead of $width" unless $x == $width;
			push @rows, \@row;
		}
		my @pictures = map {
			{ %$_, png => decode_base64( $_->{png} ) }
		} @{ $capture->{pictures} // [] };
		return $class->new( columns => $width, rows => $height, cells => \@rows, pictures => \@pictures );
	}

	# A screen from what a program printed into a terminal $width columns
	# wide: UTF-8 text with the SGR sequences Term::Fabulous::Static writes,
	# lines ending in CR LF (the terminal turns LF into CR LF). Each line
	# is one row; trailing empty lines are dropped.
	sub from_output ( $class, $bytes, $width ) {
		my $text  = decode( 'UTF-8', $bytes, Encode::FB_CROAK | Encode::LEAVE_SRC );
		my @lines = split /\r\n/, $text, -1;
		pop @lines while @lines && $lines[-1] eq '';
		croak 'Term::Fabulous::Screenshot::Screen: the program printed nothing' unless @lines;

		my @rows = map { _parse_line( $lines[$_], $_, $width ) } 0 .. $#lines;
		return $class->new( columns => $width, rows => scalar(@rows), cells => \@rows );
	}

	sub _cell ( $x, $glyph, $glyph_columns, $fg, $bg, $styles ) {
		return { x => $x, glyph => $glyph, columns => $glyph_columns, fg => $fg, bg => $bg, styles => $styles };
	}

	sub _attr_rgb ($attr) {
		return 0 if $attr & TB_HI_BLACK;
		my $rgb = $attr & RGB_MASK;
		return $rgb == 0 ? undef : $rgb;
	}

	sub _attr_styles ($attrs) {
		my %style_by_flag = STYLE_BY_FLAG;
		return { map { $style_by_flag{$_} => 1 } grep { $attrs & $_ } keys %style_by_flag };
	}

	# Splits a line into SGR sequences and text, and lays the text out in
	# cells with the current style. Any other control sequence means the
	# output is not a printed report.
	sub _parse_line ( $line, $number, $width ) {
		my %style = ( fg => undef, bg => undef, styles => {} );
		my @row;
		my $x = 0;
		foreach my $token ( split /(\e\[[0-9;]*m)/, $line ) {
			next unless length $token;
			if ( $token =~ /\A\e\[([0-9;]*)m\z/ ) {
				_apply_sgr( \%style, $1, $number );
				next;
			}
			if ( $token =~ /([\x00-\x1f\x7f])/ ) {
				croak sprintf "Term::Fabulous::Screenshot::Screen: line %d of the output contains the control character 0x%02x; "
					. "only text and color sequences can be turned into a screenshot (did a full-screen program end before the screenshot was taken?)",
					$number + 1, ord $1;
			}
			foreach my $cluster ( grapheme_clusters($token) ) {
				my $cluster_columns = cluster_columns($cluster);
				push @row, _cell( $x, $cluster, $cluster_columns, $style{fg}, $style{bg}, { %{ $style{styles} } } );
				$x += $cluster_columns;
			}
		}
		croak "Term::Fabulous::Screenshot::Screen: line " . ( $number + 1 ) . " of the output is $x columns wide, the terminal only $width" if $x > $width;
		push @row, _cell( $_, ' ', 1, undef, undef, {} ) foreach $x .. $width - 1;
		return \@row;
	}

	sub _apply_sgr ( $style, $parameters, $line_number ) {
		my @codes        = length $parameters ? split( /;/, $parameters, -1 ) : (0);
		my %style_by_sgr = STYLE_BY_SGR;
		while (@codes) {
			my $code = shift @codes;
			if ( $code eq '' || $code == 0 ) {
				%$style = ( fg => undef, bg => undef, styles => {} );
			}
			elsif ( exists $style_by_sgr{$code} ) {
				$style->{styles}{ $style_by_sgr{$code} } = 1;
			}
			elsif ( ( $code == 38 || $code == 48 ) && @codes >= 4 && $codes[0] == 2 ) {
				my ( undef, $red, $green, $blue ) = splice @codes, 0, 4;
				$style->{ $code == 38 ? 'fg' : 'bg' } = ( $red << 16 ) | ( $green << 8 ) | $blue;
			}
			else {
				croak "Term::Fabulous::Screenshot::Screen: line " . ( $line_number + 1 ) . " of the output uses the unsupported SGR parameters '$parameters'";
			}
		}
		return;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Screenshot::Screen - The cells a terminal shows

=head1 SYNOPSIS

	use Term::Fabulous::Screenshot::Screen;

	my $screen = Term::Fabulous::Screenshot::Screen->from_capture($capture);
	my $report = Term::Fabulous::Screenshot::Screen->from_output( $printed_bytes, 80 );

	foreach my $y ( 0 .. $screen->rows - 1 ) {
		foreach my $cell ( $screen->row($y) ) {
			printf "%d: %s\n", $cell->{x}, $cell->{glyph};
		}
	}

=head1 DESCRIPTION

Maintainer tool, not installed. A screen is a grid of C<columns> by
C<rows> cells, what a terminal shows at one moment. The image renderers
(L<Term::Fabulous::Screenshot::Render::SVG>,
L<Term::Fabulous::Screenshot::Render::PNG>) draw it.

Every row covers exactly C<columns> columns. A wide character is one
cell that spans two columns; the column it covers is not a cell of its
own. Sixel pictures the terminal shows lie over the cells; see
L</pictures>.

=head1 CONSTRUCTORS

=head2 from_capture

	my $screen = Term::Fabulous::Screenshot::Screen->from_capture($capture);

From the screen L<Term::Fabulous::Screenshot::Harness> read from
termbox2's front buffer, with the sixel pictures of the program's last
frame. Dies when a row does not cover the width of the screen.

=head2 from_output

	my $screen = Term::Fabulous::Screenshot::Screen->from_output( $bytes, $columns );

From the bytes a program printed into a terminal C<$columns> wide: UTF-8
text, lines ending in CR LF, and the SGR sequences
L<Term::Fabulous::Static> writes (reset, 24-bit colors and the style
parameters of L<Term::Fabulous::Render::Attr/STYLE_FLAGS>). Each line becomes a row, padded with blank cells;
trailing empty lines are dropped. Dies on invalid UTF-8, on any other
control character or escape sequence, on a line wider than C<$columns>,
and when nothing was printed. Such a screen has no pictures.

=head2 new

	Term::Fabulous::Screenshot::Screen->new( columns => $c, rows => $r, cells => \@rows, pictures => \@pictures );

From cells directly; see L</row> for their form. C<pictures> is
optional; see L</pictures> for its form. Dies when a picture is not
inside the screen.

=head1 METHODS

=head2 columns, rows

The size of the screen.

=head2 row

	my @cells = $screen->row($y);

The cells of row C<$y>, left to right. Each cell is a hash reference:

=over

=item C<x>

The first column the cell covers, from 0.

=item C<glyph>

The grapheme cluster shown, a character string.

=item C<columns>

How many columns it covers: 1, or 2 for a wide character.

=item C<fg>, C<bg>

The text and background colors as C<0xRRGGBB>, or C<undef> for the
terminal's default color.

=item C<styles>

A hash whose keys are the styles that apply, the names of
L<Term::Fabulous::Render::Attr/STYLE_FLAGS>: C<bold>, C<dim>,
C<italic>, C<underline>, C<blink>, C<reverse>, C<invisible>,
C<strikeout>, C<double_underline>, C<overline>.

=back

=head2 pictures

	foreach my $picture ( $screen->pictures ) { ... }

The sixel pictures the terminal shows over the cells, in the order
they were drawn. Each is a hash reference:

=over

=item C<x>, C<y>

The cell the picture's top left corner covers.

=item C<columns>, C<rows>

The cells the picture covers; the picture is stretched to them.

=item C<png>

The picture as PNG data, a byte string.

=back

=cut
