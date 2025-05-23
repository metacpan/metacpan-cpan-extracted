#
# GENERATED WITH PDL::PP from color_space.pd! Don't modify!
#
package PDL::Graphics::ColorSpace;

our @EXPORT_OK = qw(rgb_to_xyz xyz_to_rgb xyz_to_lab lab_to_xyz rgb_to_lch lch_to_rgb rgb_to_lab lab_to_rgb add_rgb_space rgb_to_cmyk cmyk_to_rgb rgb_to_hsl hsl_to_rgb rgb_to_hsv hsv_to_rgb xyY_to_xyz _rgb_to_xyz _xyz_to_rgb _xyz_to_lab _lab_to_xyz lab_to_lch lch_to_lab rgb_to_linear rgb_from_linear );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   our $VERSION = '0.206';
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Graphics::ColorSpace $VERSION;








#line 13 "color_space.pd"

=encoding utf8

=head1 NAME

PDL::Graphics::ColorSpace - colour-space conversions for PDL

=head1 SYNOPSIS

    use PDL::LiteF;
    use PDL::IO::Pic;
    use PDL::Graphics::ColorSpace;

    my $image_rgb = PDL->rpic('photo.jpg') if PDL->rpiccan('JPEG');

    # convert RGB value from [0,255] to [0,1]
    $image_rgb = $image_rgb->double / 255;

    my $image_xyz = $image_rgb->rgb_to_xyz( 'sRGB' );

Or

    my $image_xyz = rgb_to_xyz( $image_rgb, 'sRGB' );

=head1 DESCRIPTION

Does image color space conversions such as RGB to XYZ and Lab to LCH. Derived from Graphics::ColorObject (Izvorski & Reibenschuh, 2005) but since it's implemented in C and PDL, it runs *much* faster.

Often the conversion will return out-of-gamut values. Retaining out-of-gamut values allows chained conversions to be lossless and reverse conversions to produce the original values. You can clip the values to be within-gamut if necessary. Please check the specific color space for the gamut range.

=head1 COLOR SPACES

=head2 RGB

An RGB color space is any additive color space based on the RGB color model. A particular RGB color space is defined by the three chromaticities of the red, green, and blue additive primaries, and can produce any chromaticity that is the triangle defined by those primary colors. The complete specification of an RGB color space also requires a white point chromaticity and a gamma correction curve.

For more info on the RGB color space, see L<http://en.wikipedia.org/wiki/RGB_color_space>.

This module expects and produces RGB values normalized to be in the range of [0,1]. If you have / need integer value between [0,255], divide or multiply the values by 255.

=head2 CMYK

CMYK refers to the four inks used in some color printing: cyan, magenta, yellow, and key (black). The CMYK model works by partially or entirely masking colors on a lighter, usually white, background. The ink reduces the light that would otherwise be reflected. Such a model is called subtractive because inks "subtract" brightness from white.

In additive color models such as RGB, white is the "additive" combination of all primary colored lights, while black is the absence of light. In the CMYK model, it is the opposite: white is the natural color of the paper or other background, while black results from a full combination of colored inks. To save money on ink, and to produce deeper black tones, unsaturated and dark colors are produced by using black ink instead of the combination of cyan, magenta and yellow.

For more info, see L<http://en.wikipedia.org/wiki/CMYK_color_model>.

=head2 HSL

Hue, Saturation and Luminance (or brightness).

The HSL color space defines colors more naturally: Hue specifies the base color, the other two values then let you specify the saturation of that color and how bright the color should be.

Hue is specified here as degrees ranging from 0 to 360. There are 6 base colors:

    0    red
    60    yellow
    120    green
    180    cyan
    240    blue
    300    magenta
    360    red

Saturation specifies the distance from the middle of the color wheel. So a saturation value of 0 (0%) means "center of the wheel", i.e. a grey value, whereas a saturation value of 1 (100%) means "at the border of the wheel", where the color is fully saturated.

Luminance describes how "bright" the color is. 0 (0%) means 0 brightness and the color is black. 1 (100%) means maximum brightness and the color is white.

For more info, see L<http://www.chaospro.de/documentation/html/paletteeditor/colorspace_hsl.htm>.

=head2 XYZ and xyY

The CIE XYZ color space was derived the CIE RGB color space. XYZ are three hypothetical primaries. Y means brightness, Z is quasi-equal to blue stimulation, and X is a mix which looks like red sensitivity curve of cones.  All visible colors can be represented by using only positive values of X, Y, and Z. The main advantage of the CIE XYZ space (and any color space based on it) is that this space is completely device-independent.

For more info, see L<http://en.wikipedia.org/wiki/CIE_1931_color_space>.

=head2 Lab

A Lab color space is a color-opponent space with dimension L for lightness and a and b for the color-opponent dimensions, based on nonlinearly compressed CIE XYZ color space coordinates. It's derived from the "master" space CIE 1931 XYZ color space but is more perceptually uniform than XYZ. The Lab space is relative to the white point of the XYZ data they were converted from. Lab values do not define absolute colors unless the white point is also specified.

For more info, see L<http://en.wikipedia.org/wiki/Lab_color_space>.

=head2 LCH

This is possibly a little easier to comprehend than the Lab colour space, with which it shares several features. It is more correctly known as  L*C*H*.  Essentially it is in the form of a sphere. There are three axes; L* and C* and H°. 

The L* axis represents Lightness. This is vertical; from 0, which has no lightness (i.e. absolute black), at the bottom; through 50 in the middle, to 100 which is maximum lightness (i.e. absolute white) at the top.

The C* axis represents Chroma or "saturation". This ranges from 0 at the centre of the circle, which is completely unsaturated (i.e. a neutral grey, black or white) to 100 or more at the edge of the circle for very high Chroma (saturation) or "colour purity".

If we take a horizontal slice through the centre, we see a coloured circle. Around the edge of the circle we see every possible saturated colour, or Hue. This circular axis is known as H° for Hue. The units are in the form of degrees° (or angles), ranging from 0 (red) through 90 (yellow), 180 (green), 270 (blue) and back to 0. 

For more info, see L<http://www.colourphil.co.uk/lab_lch_colour_space.html>.

=head1 OPTIONS

Some conversions require specifying the RGB space which includes gamma curve and white point definitions. Supported RGB spaces include (aliases in square brackets):

    Adobe RGB (1998) [Adobe]
    Apple RGB [Apple]
    BestRGB
    Beta RGB
    BruceRGB
    CIE
    ColorMatch
    DonRGB4
    ECI
    Ekta Space PS5
    NTSC [601] [CIE Rec 601]
    PAL/SECAM [PAL] [CIE ITU]
    ProPhoto
    SMPTE-C [SMPTE]
    WideGamut
    sRGB [709] [CIE Rec 709]
    lsRGB

You can also add custom RGB space definitions via the function add_rgb_space.
Alternatively, as of 0.202 you can directly supply the function with a
hash-ref in the same format.

=head1 CONVERSIONS

Some conversions, if not already included as functions, can be achieved
by chaining existing functions. For example, LCH to HSV conversion can
be achieved by chaining lch_to_rgb and rgb_to_hsv:

    my $hsv = rgb_to_hsv( lch_to_rgb( $lch, 'sRGB' ), 'sRGB' );

To generate a local diagram of what conversions are available between
formats, using GraphViz, you can use this script:

  use blib;
  use PDL::Graphics::ColorSpace;
  print "digraph {\n";
  print join(' -> ', split /_to_/), "\n"
    for grep !/^_/ && /_to_/, @PDL::Graphics::ColorSpace::EXPORT_OK;
  print "}\n";
  # then:
  perl scriptname >d.dot; dot -Tsvg d.dot >d.svg; display d.svg

(As of 0.202, this is everything to and from C<rgb>, plus C<xyz> <->
C<lab> <-> C<lch>)

=cut

use strict;
use warnings;

use Carp;
use PDL::LiteF;
use PDL::Graphics::ColorSpace::RGBSpace;

my $RGB_SPACE = $PDL::Graphics::ColorSpace::RGBSpace::RGB_SPACE;
#line 181 "ColorSpace.pm"


=head1 FUNCTIONS

=cut






=head2 rgb_to_cmyk

=for sig

 Signature: (rgb(c=3); [o]cmyk(d=4))
 Types: (double)

=pod

=for ref

Converts an RGB color triple to an CMYK color quadruple.

The first dimension of the ndarrays holding the rgb values must be size 3, i.e. the dimensions must look like (3, m, n, ...). The first dimension of the ndarrays holding the cmyk values must be size 4.

=for usage

Usage:

    my $cmyk = rgb_to_cmyk( $rgb );

=pod

Broadcasts over its inputs.

=for bad

=for bad

If C<rgb_to_cmyk> encounters a bad value in any of the R, G, or B values the output ndarray will be marked as bad and the associated C, M, Y, and K values will all be marked as bad.

=cut




*rgb_to_cmyk = \&PDL::rgb_to_cmyk;






=head2 cmyk_to_rgb

=for sig

 Signature: (cmyk(d=4); [o]rgb(c=3))
 Types: (double)

=pod

=for ref

Converts an CMYK color quadruple to an RGB color triple

The first dimension of the ndarrays holding the cmyk values must be size 4, i.e. the dimensions must look like (4, m, n, ...). The first dimension of the ndarray holding the rgb values must be 3.

=for usage

Usage:

    my $rgb = cmyk_to_rgb( $cmyk );

=pod

Broadcasts over its inputs.

=for bad

=for bad

If C<cmyk_to_rgb> encounters a bad value in any of the C, M, Y, or K quantities, the output ndarray will be marked as bad and the associated R, G, and B color values will all be marked as bad.

=cut




*cmyk_to_rgb = \&PDL::cmyk_to_rgb;






=head2 rgb_to_hsl

=for sig

 Signature: (rgb(c=3); [o]hsl(c=3))
 Types: (double)

=pod

=for ref

Converts an RGB color triple to an HSL color triple.

The first dimension of the ndarrays holding the hsl and rgb values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=for usage

Usage:

    my $hsl = rgb_to_hsl( $rgb );

=pod

Broadcasts over its inputs.

=for bad

=for bad

If C<rgb_to_hsl> encounters a bad value in any of the R, G, or B values the output ndarray will be marked as bad and the associated H, S, and L values will all be marked as bad.

=cut




*rgb_to_hsl = \&PDL::rgb_to_hsl;






=head2 hsl_to_rgb

=for sig

 Signature: (hsl(c=3); [o]rgb(c=3))
 Types: (double)

=pod

=for ref

Converts an HSL color triple to an RGB color triple

The first dimension of the ndarrays holding the hsl and rgb values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=for usage

Usage:

    my $rgb = hsl_to_rgb( $hsl );

=pod

Broadcasts over its inputs.

=for bad

=for bad

If C<hsl_to_rgb> encounters a bad value in any of the H, S, or V quantities, the output ndarray will be marked as bad and the associated R, G, and B color values will all be marked as bad.

=cut




*hsl_to_rgb = \&PDL::hsl_to_rgb;






=head2 rgb_to_hsv

=for sig

 Signature: (rgb(c=3); [o]hsv(c=3))
 Types: (double)

=pod

=for ref

Converts an RGB color triple to an HSV color triple.

The first dimension of the ndarrays holding the hsv and rgb values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=for usage

Usage:

    my $hsv = rgb_to_hsv( $rgb );

=pod

Broadcasts over its inputs.

=for bad

=for bad

If C<rgb_to_hsv> encounters a bad value in any of the R, G, or B values the output ndarray will be marked as bad and the associated H, S, and V values will all be marked as bad.

=cut




*rgb_to_hsv = \&PDL::rgb_to_hsv;






=head2 hsv_to_rgb

=for sig

 Signature: (hsv(c=3); [o]rgb(c=3))
 Types: (double)

=pod

=for ref

Converts an HSV color triple to an RGB color triple

The first dimension of the ndarrays holding the hsv and rgb values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=for usage

Usage:

    my $rgb = hsv_to_rgb( $hsv );

=pod

Broadcasts over its inputs.

=for bad

=for bad

If C<hsv_to_rgb> encounters a bad value in any of the H, S, or V quantities, the output ndarray will be marked as bad and the associated R, G, and B color values will all be marked as bad.

=cut




*hsv_to_rgb = \&PDL::hsv_to_rgb;






=head2 xyY_to_xyz

=for sig

 Signature: (xyY(c=3); [o]xyz(c=3))
 Types: (double)

=for usage

 $xyz = xyY_to_xyz($xyY);
 xyY_to_xyz($xyY, $xyz);    # all arguments given
 $xyz = $xyY->xyY_to_xyz;   # method call
 $xyY->xyY_to_xyz($xyz);
 $xyY->inplace->xyY_to_xyz; # can be used inplace
 xyY_to_xyz($xyY->inplace);

=for ref

Internal function for white point calculation. Use it if you must.

=pod

Broadcasts over its inputs.

=for bad

C<xyY_to_xyz> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*xyY_to_xyz = \&PDL::xyY_to_xyz;




*_rgb_to_xyz = \&PDL::_rgb_to_xyz;




*_xyz_to_rgb = \&PDL::_xyz_to_rgb;




*_xyz_to_lab = \&PDL::_xyz_to_lab;




*_lab_to_xyz = \&PDL::_lab_to_xyz;






=head2 lab_to_lch

=for sig

 Signature: (lab(c=3); [o]lch(c=3))
 Types: (double)

=pod

=for ref

Converts an Lab color triple to an LCH color triple.

The first dimension of the ndarrays holding the lab values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=for usage

Usage:

    my $lch = lab_to_lch( $lab );

=pod

Broadcasts over its inputs.

=for bad

=for bad

If C<lab_to_lch> encounters a bad value in any of the L, a, or b values the output ndarray will be marked as bad and the associated L, C, and H values will all be marked as bad.

=cut




*lab_to_lch = \&PDL::lab_to_lch;






=head2 lch_to_lab

=for sig

 Signature: (lch(c=3); [o]lab(c=3))
 Types: (double)

=pod

=for ref

Converts an LCH color triple to an Lab color triple.

The first dimension of the ndarrays holding the lch values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=for usage

Usage:

    my $lab = lch_to_lab( $lch );

=pod

Broadcasts over its inputs.

=for bad

=for bad

If C<lch_to_lab> encounters a bad value in any of the L, C, or H values the output ndarray will be marked as bad and the associated L, a, and b values will all be marked as bad.

=cut




*lch_to_lab = \&PDL::lch_to_lab;






=head2 rgb_to_linear

=for sig

 Signature: (rgb(c=3); gamma(); [o]out(c=3))
 Types: (double)

=for ref

Converts an RGB color triple (presumably with gamma) to an RGB color triple
with linear values.

=for usage

Usage:

    my $rgb_linear = rgb_to_linear( $gammaed, 2.2 );

=pod

Broadcasts over its inputs.

=for bad

=for bad

If C<rgb_to_linear> encounters a bad value in any of the R, G, or B
values the output ndarray will be marked as bad and the associated R,
G, and B values will all be marked as bad.

=cut




*rgb_to_linear = \&PDL::rgb_to_linear;






=head2 rgb_from_linear

=for sig

 Signature: (rgb(c=3); gamma(); [o]out(c=3))
 Types: (double)

=for ref

Converts an RGB color triple (presumably linear) to an RGB color triple
with the specified gamma.

=for usage

Usage:

    my $gammaed = rgb_from_linear( $rgb_linear, 2.2 );

=pod

Broadcasts over its inputs.

=for bad

=for bad

If C<rgb_from_linear> encounters a bad value in any of the R, G, or B
values the output ndarray will be marked as bad and the associated R,
G, and B values will all be marked as bad.

=cut




*rgb_from_linear = \&PDL::rgb_from_linear;





#line 752 "color_space.pd"

=head2 rgb_to_xyz

=for ref

Converts an RGB color triple to an XYZ color triple.

The first dimension of the ndarrays holding the rgb values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=for bad

If C<rgb_to_xyz> encounters a bad value in any of the R, G, or B values the output ndarray will be marked as bad and the associated X, Y, and Z values will all be marked as bad.

=for usage

Usage:

    my $xyz = rgb_to_xyz( $rgb, 'sRGB' );
    my $xyz = rgb_to_xyz( $rgb, \%rgb_spec );

=cut

*rgb_to_xyz = \&PDL::rgb_to_xyz;
sub PDL::rgb_to_xyz {
    my ($rgb, $space) = @_;
    my $spec = get_space($space);
    my $m = PDL->topdl( $spec->{m} );
    return _rgb_to_xyz( $rgb, $spec->{gamma}, $m );
}

=head2 xyz_to_rgb

=for ref

Converts an XYZ color triple to an RGB color triple.

The first dimension of the ndarrays holding the xyz and rgb values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=for bad

If C<xyz_to_rgb> encounters a bad value in any of the X, Y, or Z values the output ndarray will be marked as bad and the associated R, G, and B values will all be marked as bad.

=for usage

Usage:

    my $rgb = xyz_to_rgb( $xyz, 'sRGB' );
    my $rgb = xyz_to_rgb( $xyz, \%rgb_spec );

=cut

*xyz_to_rgb = \&PDL::xyz_to_rgb;
sub PDL::xyz_to_rgb {
    my ($xyz, $space) = @_;
    my $spec = get_space($space);
    my $mstar = exists $spec->{mstar} ? PDL->topdl( $spec->{mstar} ) : PDL->topdl( $spec->{m} )->inv;
    return _xyz_to_rgb( $xyz, $spec->{gamma}, $mstar );
}

=head2 xyz_to_lab

=for ref

Converts an XYZ color triple to an Lab color triple.

The first dimension of the ndarrays holding the xyz values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=for bad

If C<xyz_to_lab> encounters a bad value in any of the X, Y, or Z values the output ndarray will be marked as bad and the associated L, a, and b values will all be marked as bad.

=for usage

Usage:

    my $lab = xyz_to_lab( $xyz, 'sRGB' );
    my $lab = xyz_to_lab( $xyz, \%rgb_spec );

=cut

*xyz_to_lab = \&PDL::xyz_to_lab;
sub PDL::xyz_to_lab {
    my ($xyz, $space) = @_;
    my $spec = get_space($space);
    my $w = PDL->topdl($spec->{white_point});
    return _xyz_to_lab( $xyz, $w );
}

=head2 lab_to_xyz

=for ref

Converts an Lab color triple to an XYZ color triple.

The first dimension of the ndarrays holding the lab values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=for bad

If C<lab_to_xyz> encounters a bad value in any of the L, a, or b values the output ndarray will be marked as bad and the associated X, Y, and Z values will all be marked as bad.

=for usage

Usage:

    my $xyz = lab_to_xyz( $lab, 'sRGB' );
    my $xyz = lab_to_xyz( $lab, \%rgb_spec );

=cut

*lab_to_xyz = \&PDL::lab_to_xyz;
sub PDL::lab_to_xyz {
    my ($lab, $space) = @_;
    my $spec = get_space($space);
    my $w = PDL->topdl($spec->{white_point});
    return _lab_to_xyz( $lab, $w );
}

=head2 rgb_to_lch

=for ref

Converts an RGB color triple to an LCH color triple.

The first dimension of the ndarrays holding the rgb values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=for bad

If C<rgb_to_lch> encounters a bad value in any of the R, G, or B values the output ndarray will be marked as bad and the associated L, C, and H values will all be marked as bad.

=for usage

Usage:

    my $lch = rgb_to_lch( $rgb, 'sRGB' );
    my $lch = rgb_to_lch( $rgb, \%rgb_spec );

=cut

*rgb_to_lch = \&PDL::rgb_to_lch;
sub PDL::rgb_to_lch {
    my ($rgb, $space) = @_;
    my $spec = get_space($space);
    my $lab = xyz_to_lab( rgb_to_xyz( $rgb, $spec ), $spec );
    return lab_to_lch( $lab );
}

=head2 lch_to_rgb

=for ref

Converts an LCH color triple to an RGB color triple.

The first dimension of the ndarrays holding the lch values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=for bad

If C<lch_to_rgb> encounters a bad value in any of the L, C, or H values the output ndarray will be marked as bad and the associated R, G, and B values will all be marked as bad.

=for usage

Usage:

    my $rgb = lch_to_rgb( $lch, 'sRGB' );
    my $rgb = lch_to_rgb( $lch, \%rgb_spec );

=cut

*lch_to_rgb = \&PDL::lch_to_rgb;
sub PDL::lch_to_rgb {
    my ($lch, $space) = @_;
    my $spec = get_space($space);
    my $xyz = lab_to_xyz( lch_to_lab( $lch ), $spec );
    return xyz_to_rgb( $xyz, $spec );
}

=head2 rgb_to_lab

=for ref

Converts an RGB color triple to an LAB color triple.

The first dimension of the ndarrays holding the rgb values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=for bad

If C<rgb_to_lab> encounters a bad value in any of the R, G, or B values the output ndarray will be marked as bad and the associated L, A, and B values will all be marked as bad.

=for usage

Usage:

    my $lab = rgb_to_lab( $rgb, 'sRGB' );
    my $lab = rgb_to_lab( $rgb, \%rgb_spec );

=cut

*rgb_to_lab = \&PDL::rgb_to_lab;
sub PDL::rgb_to_lab {
    my ($rgb, $space) = @_;
    my $spec = get_space($space);
    return xyz_to_lab( rgb_to_xyz( $rgb, $spec ), $spec );
}

=head2 lab_to_rgb

=for ref

Converts an LAB color triple to an RGB color triple.

The first dimension of the ndarrays holding the lab values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=for bad

If C<lab_to_rgb> encounters a bad value in any of the L, A, or B values the output ndarray will be marked as bad and the associated R, G, and B values will all be marked as bad.

=for usage

Usage:

    my $rgb = lab_to_rgb( $lab, 'sRGB' );
    my $rgb = lab_to_rgb( $lab, \%rgb_spec );

=cut

*lab_to_rgb = \&PDL::lab_to_rgb;
sub PDL::lab_to_rgb {
    my ($lab, $space) = @_;
    my $spec = get_space($space);
    return xyz_to_rgb( lab_to_xyz( $lab, $spec ), $spec );
}

=head2 add_rgb_space

Supports adding custom RGB space definitions. The C<m> and C<white_point>
can be supplied as PDL ndarrays if desired. As of 0.202, you don't need
to provide an C<mstar> since the inverse of the C<m> will be calculated
(once) as a default.

Usage:

    my %custom_space = (
        custom_1 => {
          'gamma' => '2.2',
          'm' => [
                   [
                     '0.467384242424242',
                     '0.240995',
                     '0.0219086363636363'
                   ],
                   [
                     '0.294454030769231',
                     '0.683554',
                     '0.0736135076923076'
                   ],
                   [
                     '0.18863',
                     '0.075452',
                     '0.993451333333334'
                   ]
                 ],
          'white_point' => [
                             '0.312713',
                             '0.329016'
                           ],
        },
        custom_2 => { ... },
    );

    add_rgb_space( \%custom_space );

    my $rgb = lch_to_rgb( $lch, 'custom_1' );

=cut

*add_rgb_space = \&PDL::Graphics::ColorSpace::RGBSpace::add_rgb_space;
*get_space = \&PDL::Graphics::ColorSpace::RGBSpace::get_space;

=head1 SEE ALSO

Graphics::ColorObject

=head1 AUTHOR

~~~~~~~~~~~~ ~~~~~ ~~~~~~~~ ~~~~~ ~~~ `` ><(((">

Copyright (C) 2012 Maggie J. Xiong <maggiexyz+github@gmail.com>

Original work sponsored by Shutterstock, LLC L<http://www.shutterstock.com/>

All rights reserved. There is no warranty. You are allowed to redistribute this software / documentation as described in the file COPYING in the PDL distribution.

=cut
#line 974 "ColorSpace.pm"

# Exit with OK status

1;
