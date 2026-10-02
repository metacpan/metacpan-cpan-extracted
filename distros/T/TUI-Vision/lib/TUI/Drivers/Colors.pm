package TUI::Drivers::Colors;
# ABSTRACT: defines color conversion functions

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT_OK = qw(
  BIOStoXTerm16
  RGBtoBIOS
  RGBtoXTerm16
  RGBtoXTerm256
  XTerm16toBIOS
  XTerm256toRGB
  XTerm256toXTerm16
);

our %EXPORT_TAGS = (
  all => \@EXPORT_OK,
);

use PerlX::Assert::PP;
use Scalar::Util qw(
  looks_like_number
);

use constant HUE_PRECISION => 32;
use constant HUE_MAX       => 6 * HUE_PRECISION;

sub _pack {    # $rgb ($r, $g, $b)
  return ( ( ( $_[0] << 8 ) | $_[1] ) << 8 ) | $_[2];
}

sub _rgb8 {    # @rgb ($rgb)
  return (
    ( $_[0] >> 16 ) & 0xff,
    ( $_[0] >> 8  ) & 0xff,
      $_[0]         & 0xff,
  );
}

sub _RGBtoHCL {    # @hcl ($r, $g, $b)
  my ( $r, $g, $b ) = @_;

  my $xmin = $r < $g ? $r : $g;
     $xmin = $xmin < $b ? $xmin : $b;

  my $xmax = $r > $g ? $r : $g;
     $xmax = $xmax > $b ? $xmax : $b;

  my $v = $xmax;
  my $l = int( ( $xmax + $xmin ) / 2 );
  my $c = $xmax - $xmin;
  my $h = 0;

  if ( $c ) {
    if ( $v == $r ) {
      $h = int( HUE_PRECISION * ( $g - $b ) / $c );
    }
    elsif ( $v == $g ) {
      $h = int( HUE_PRECISION * ( $b - $r ) / $c )
         + 2 * HUE_PRECISION;
    }
    else {
      $h = int( HUE_PRECISION * ( $r - $g ) / $c )
         + 4 * HUE_PRECISION;
    }

    if ( $h < 0 ) {
      $h += HUE_MAX;
    }
    elsif ( $h >= HUE_MAX ) {
      $h -= HUE_MAX;
    }
  }

  return ( $h, $c, $l );
}

sub BIOStoXTerm16 {    # $xterm16 ($bios)
  my ( $c ) = @_;
  assert ( looks_like_number $c );

  # BIOS uses RGBI bit order, XTerm16 uses ANSI order.
  # Swap red and blue, keep green and intensity.
  return ( $c & 0x0a )
       | ( ( $c & 0x01 ) << 2 )
       | ( ( $c & 0x04 ) >> 2 );
}

sub XTerm16toBIOS {    # $bios ($xterm16)
  goto &BIOStoXTerm16;
}

sub RGBtoXTerm16 {     # $xterm16 ($rgb)
  my ( $rgb ) = @_;
  assert ( looks_like_number $rgb );

  my ( $r, $g, $b ) = _rgb8( $rgb );
  my ( $h, $c, $l ) = _RGBtoHCL( $r, $g, $b );

  if ( $c >= 12 ) {    # Color if Chroma >= 12.
    my @normal = ( 0x1, 0x3, 0x2, 0x6, 0x4, 0x5 );
    my @bright = ( 0x9, 0xb, 0xa, 0xe, 0xc, 0xd );

    my $index = int(
      (
        $h < HUE_MAX - HUE_PRECISION / 2
          ? $h + HUE_PRECISION / 2
          : $h - ( HUE_MAX - HUE_PRECISION / 2 )
      ) / HUE_PRECISION
    );

    return $normal[$index] if $l < int( 0.5   * 255 );
    return $bright[$index] if $l < int( 0.925 * 255 );
    return 15;
  }

  return 0 if $l < int( 0.25  * 255 );
  return 8 if $l < int( 0.625 * 255 );
  return 7 if $l < int( 0.875 * 255 );
  return 15;
}

sub RGBtoBIOS {        # $bios ($rgb)
  my ( $rgb ) = @_;
  assert ( looks_like_number $rgb );

  return XTerm16toBIOS(
    RGBtoXTerm16( $rgb )
  );
}

my @XTERM256_TO_RGB;
my @XTERM256_TO_XTERM16;

BEGIN {
  @XTERM256_TO_RGB     = (0) x 256;
  @XTERM256_TO_XTERM16 = (0) x 256;

  for my $i ( 0 .. 15 ) {
    $XTERM256_TO_XTERM16[$i] = $i;
  }

  for my $r_idx ( 0 .. 5 ) {
    my $r = $r_idx ? 55 + $r_idx * 40 : 0;

    for my $g_idx ( 0 .. 5 ) {
      my $g = $g_idx ? 55 + $g_idx * 40 : 0;

      for my $b_idx ( 0 .. 5 ) {
        my $b = $b_idx ? 55 + $b_idx * 40 : 0;

        my $idx = 16 + ( $r_idx * 6 + $g_idx ) * 6 + $b_idx;
        my $rgb = _pack( $r, $g, $b );

        $XTERM256_TO_RGB[$idx]     = $rgb;
        $XTERM256_TO_XTERM16[$idx] = RGBtoXTerm16( $rgb );
      }
    }
  }

  for my $i ( 0 .. 23 ) {
    my $l = $i * 10 + 8;
    my $idx = 232 + $i;
    my $rgb = _pack( $l, $l, $l );

    $XTERM256_TO_RGB[$idx]     = $rgb;
    $XTERM256_TO_XTERM16[$idx] = RGBtoXTerm16( $rgb );
  }
}

sub XTerm256toRGB {    # $rgb ($xterm256)
  my ( $idx ) = @_;
  assert ( looks_like_number $idx );

  return $XTERM256_TO_RGB[ $idx & 0xff ];
}

sub XTerm256toXTerm16 {    # $xterm16 ($xterm256)
  my ( $idx ) = @_;
  assert ( looks_like_number $idx );

  return $XTERM256_TO_XTERM16[ $idx & 0xff ];
}

sub RGBtoXTerm256 {    # $xterm256 ($rgb)
  my ( $rgb ) = @_;
  assert ( looks_like_number $rgb );

  my ( $r, $g, $b ) = _rgb8( $rgb );

  my $best_i = 16;
  my $best_d = 0x7fffffff;

  for my $i ( 16 .. 255 ) {
    my ( $pr, $pg, $pb ) = _rgb8( $XTERM256_TO_RGB[$i] );

    my $d =
          ( $r - $pr ) * ( $r - $pr )
        + ( $g - $pg ) * ( $g - $pg )
        + ( $b - $pb ) * ( $b - $pb );

    if ( $d < $best_d ) {
      $best_d = $d;
      $best_i = $i;
    }
  }

  return $best_i;
}

1;

__END__

=pod

=head1 NAME

TUI::Drivers::Colors - color conversion functions for BIOS, XTerm and RGB colors

=head1 SYNOPSIS

  use TUI::Drivers::Colors qw(
    BIOStoXTerm16
    RGBtoBIOS
    RGBtoXTerm16
    RGBtoXTerm256
    XTerm16toBIOS
    XTerm256toRGB
    XTerm256toXTerm16
  );

  my $bios    = RGBtoBIOS(0x7F00BB);
  my $xterm16 = RGBtoXTerm16(0x7F00BB);
  my $xterm256 = RGBtoXTerm256(0x7F00BB);

  my $rgb = XTerm256toRGB(196);

=head1 DESCRIPTION

This module provides a collection of color conversion functions used by the 
L<TUI::Vision> color system.

The functions convert between BIOS colors, XTerm 16-color values,
XTerm 256-color values and 24-bit RGB colors.

This module is purely functional and does not define any objects.

=head2 RGB to XTerm16 Conversion

XTerm16 colors form a 4-bit RGBI palette and are not a regular RGB color
space.

The conversion algorithm implemented by L</RGBtoXTerm16> follows the
approach used by the I<A modern port of Turbo Vision 2.0>.

The RGB color is first transformed into an intermediate hue, chroma and
lightness representation.

The algorithm then:

=over

=item *

Determines whether the color should be represented as a grayscale value or
as a chromatic color.

=item *

Chooses between normal and bright variants based on lightness.

=item *

Selects the final XTerm16 color from the hue value.

=back

This approach provides a perceptually closer approximation than a simple
nearest-color lookup while remaining efficient enough for real-time use.

=head1 FUNCTIONS

=head2 BIOStoXTerm16

  my $xterm16 = BIOStoXTerm16($bios);

Converts a BIOS color value into the equivalent XTerm16 color index.

=head2 RGBtoBIOS

  my $bios = RGBtoBIOS($rgb);

Converts a 24-bit RGB color into the closest BIOS color.

=head2 RGBtoXTerm16

  my $xterm16 = RGBtoXTerm16($rgb);

Converts a 24-bit RGB color into the closest XTerm16 color.

=head2 RGBtoXTerm256

  my $xterm256 = RGBtoXTerm256($rgb);

Converts a 24-bit RGB color into the closest XTerm256 color.

=head2 XTerm16toBIOS

  my $bios = XTerm16toBIOS($xterm16);

Converts an XTerm16 color index into the equivalent BIOS color value.

=head2 XTerm256toRGB

  my $rgb = XTerm256toRGB($xterm256);

Returns the RGB value corresponding to an XTerm256 palette entry.

For compatibility with the original Turbo Vision implementation this function 
is primarily intended for XTerm256 indices 16 through 255.

=head2 XTerm256toXTerm16

  my $xterm16 = XTerm256toXTerm16($xterm256);

Approximates an XTerm256 color using the closest XTerm16 color.

=head1 SEE ALSO

L<TColor|TUI::Drivers::Color>,
L<TColorAttr|TUI::Drivers::ColorAttr>

=head1 AUTHORS

=over

=item * magiblot <magiblot@hotmail.com> (original color conversion design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2019-2026 the L</AUTHORS> listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
