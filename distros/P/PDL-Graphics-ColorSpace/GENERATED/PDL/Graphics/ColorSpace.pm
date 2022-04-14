#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Graphics::ColorSpace;

our @EXPORT_OK = qw(rgb_to_cmyk cmyk_to_rgb hsl_to_rgb rgb_to_hsl rgb_to_hsv hsv_to_rgb rgb_to_xyz xyz_to_rgb xyY_to_xyz xyz_to_lab lab_to_xyz lab_to_lch lch_to_lab rgb_to_lch lch_to_rgb lch_to_lab add_rgb_space rgb_to_cmyk cmyk_to_rgb rgb_to_hsl hsl_to_rgb rgb_to_hsv hsv_to_rgb xyY_to_xyz _rgb_to_xyz _xyz_to_rgb _xyz_to_lab _lab_to_xyz lab_to_lch lch_to_lab );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   our $VERSION = '0.201';
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Graphics::ColorSpace $VERSION;






#line 9 "color_space.pd"


=head1 NAME

PDL::Graphics::ColorSpace

=head1 VERSION

0.1.0

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

The CIE XYZ color space was derived the CIE RGB color space. XYZ are three hypothetical primaries. Y means brightness, Z is quasi-equal to blue stimulation, and X is a mix which looks like red sensitivy curve of cones.  All visible colors can be represented by using only positive values of X, Y, and Z. The main advantage of the CIE XYZ space (and any color space based on it) is that this space is completely device-independent.

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

=head1 OPTIONS

Some conversions require specifying the RGB space which includes gamma curve and white point definitions. Supported RGB space include (aliases in square brackets):

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

You can also add custom RGB space definitions via the function add_rgb_space.


=head1 CONVERSIONS

The full list of exported functions include rgb_to_cmyk, cmyk_to_rgb, rgb_to_hsl, hsl_to_rgb, rgb_to_hsv, hsv_to_rgb, rgb_to_xyz, xyz_to_rgb, xyY_to_xyz, xyz_to_lab, lab_to_xyz, lab_to_lch, lch_to_lab, rgb_to_lch, lch_to_rgb, lch_to_lab.

Some conversions, if not already included as functions, can be achieved by chaining existing functions. For example, RGB to Lab conversion can be achieved by chaining rgb_to_xyz and xyz_to_lab.

    my $lab = xyz_to_lab( rgb_to_xyz( $rgb, 'sRGB' ), 'sRGB' );


=cut

use strict;
use warnings;

use Carp;
use PDL::LiteF;
use PDL::Graphics::ColorSpace::RGBSpace;

$PDL::onlinedoc->scan(__FILE__) if $PDL::onlinedoc;

my $RGB_SPACE = $PDL::Graphics::ColorSpace::RGBSpace::RGB_SPACE;
#line 168 "ColorSpace.pm"






=head1 FUNCTIONS

=cut




#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 rgb_to_cmyk

=for sig

  Signature: (double rgb(c=3); double [o]cmyk(d=4))


=pod

=for ref

Converts an RGB color triple to an CYMK color quadruple.

The first dimension of the piddles holding the rgb values must be size 3, i.e. the dimensions must look like (3, m, n, ...). The first dimension of the piddles holding the cmyk values must be size 4.

=for usage

Usage:

    my $cmyk = rgb_to_cmyk( $rgb );



=for bad

=for bad

If C<rgb_to_cmyk> encounters a bad value in any of the R, G, or B values the output piddle will be marked as bad and the associated C, M, Y, and K values will all be marked as bad.



=cut
#line 218 "ColorSpace.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*rgb_to_cmyk = \&PDL::rgb_to_cmyk;
#line 225 "ColorSpace.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 cmyk_to_rgb

=for sig

  Signature: (double cmyk(d=4); double [o]rgb(c=3))


=pod

=for ref

Converts an CYMK color quadruple to an RGB color triple

The first dimension of the piddles holding the cmyk values must be size 4, i.e. the dimensions must look like (4, m, n, ...). The first dimension of the piddle holding the rgb values must be 3.

=for usage

Usage:

    my $rgb = cmyk_to_rgb( $cmyk );



=for bad

=for bad

If C<cmyk_to_rgb> encounters a bad value in any of the C, M, Y, or K quantities, the output piddle will be marked as bad and the associated R, G, and B color values will all be marked as bad.



=cut
#line 265 "ColorSpace.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*cmyk_to_rgb = \&PDL::cmyk_to_rgb;
#line 272 "ColorSpace.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 rgb_to_hsl

=for sig

  Signature: (double rgb(c=3); double [o]hsl(c=3))


=pod

=for ref

Converts an RGB color triple to an HSL color triple.

The first dimension of the piddles holding the hsl and rgb values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=for usage

Usage:

    my $hsl = rgb_to_hsl( $rgb );



=for bad

=for bad

If C<rgb_to_hsl> encounters a bad value in any of the R, G, or B values the output piddle will be marked as bad and the associated H, S, and L values will all be marked as bad.



=cut
#line 312 "ColorSpace.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*rgb_to_hsl = \&PDL::rgb_to_hsl;
#line 319 "ColorSpace.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 hsl_to_rgb

=for sig

  Signature: (double hsl(c=3); double [o]rgb(c=3))


=pod

=for ref

Converts an HSL color triple to an RGB color triple

The first dimension of the piddles holding the hsl and rgb values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=for usage

Usage:

    my $rgb = hsl_to_rgb( $hsl );



=for bad

=for bad

If C<hsl_to_rgb> encounters a bad value in any of the H, S, or V quantities, the output piddle will be marked as bad and the associated R, G, and B color values will all be marked as bad.



=cut
#line 359 "ColorSpace.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*hsl_to_rgb = \&PDL::hsl_to_rgb;
#line 366 "ColorSpace.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 rgb_to_hsv

=for sig

  Signature: (double rgb(c=3); double [o]hsv(c=3))


=pod

=for ref

Converts an RGB color triple to an HSV color triple.

The first dimension of the piddles holding the hsv and rgb values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=for usage

Usage:

    my $hsv = rgb_to_hsv( $rgb );



=for bad

=for bad

If C<rgb_to_hsv> encounters a bad value in any of the R, G, or B values the output piddle will be marked as bad and the associated H, S, and V values will all be marked as bad.



=cut
#line 406 "ColorSpace.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*rgb_to_hsv = \&PDL::rgb_to_hsv;
#line 413 "ColorSpace.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 hsv_to_rgb

=for sig

  Signature: (double hsv(c=3); double [o]rgb(c=3))


=pod

=for ref

Converts an HSV color triple to an RGB color triple

The first dimension of the piddles holding the hsv and rgb values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=for usage

Usage:

    my $rgb = hsv_to_rgb( $hsv );



=for bad

=for bad

If C<hsv_to_rgb> encounters a bad value in any of the H, S, or V quantities, the output piddle will be marked as bad and the associated R, G, and B color values will all be marked as bad.



=cut
#line 453 "ColorSpace.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*hsv_to_rgb = \&PDL::hsv_to_rgb;
#line 460 "ColorSpace.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 xyY_to_xyz

=for sig

  Signature: (double xyY(c=3); double [o]xyz(c=3))

=for ref

Internal function for white point calculation. Use it if you must.

=for bad

xyY_to_xyz processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 485 "ColorSpace.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*xyY_to_xyz = \&PDL::xyY_to_xyz;
#line 492 "ColorSpace.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*_rgb_to_xyz = \&PDL::_rgb_to_xyz;
#line 499 "ColorSpace.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*_xyz_to_rgb = \&PDL::_xyz_to_rgb;
#line 506 "ColorSpace.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*_xyz_to_lab = \&PDL::_xyz_to_lab;
#line 513 "ColorSpace.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*_lab_to_xyz = \&PDL::_lab_to_xyz;
#line 520 "ColorSpace.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 lab_to_lch

=for sig

  Signature: (double lab(c=3); double [o]lch(c=3))


=pod

=for ref

Converts an Lab color triple to an LCH color triple.

The first dimension of the piddles holding the lab values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=for usage

Usage:

    my $lch = lab_to_lch( $lab );



=for bad

=for bad

If C<lab_to_lch> encounters a bad value in any of the L, a, or b values the output piddle will be marked as bad and the associated L, C, and H values will all be marked as bad.



=cut
#line 560 "ColorSpace.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*lab_to_lch = \&PDL::lab_to_lch;
#line 567 "ColorSpace.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 lch_to_lab

=for sig

  Signature: (double lch(c=3); double [o]lab(c=3))


=pod

=for ref

Converts an LCH color triple to an Lab color triple.

The first dimension of the piddles holding the lch values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=for usage

Usage:

    my $lab = lch_to_lab( $lch );



=for bad

=for bad

If C<lch_to_lab> encounters a bad value in any of the L, C, or H values the output piddle will be marked as bad and the associated L, a, and b values will all be marked as bad.



=cut
#line 607 "ColorSpace.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*lch_to_lab = \&PDL::lch_to_lab;
#line 614 "ColorSpace.pm"



#line 711 "color_space.pd"



=head2 rgb_to_xyz

=for ref

Converts an RGB color triple to an XYZ color triple.

The first dimension of the piddles holding the rgb values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=for bad

If C<rgb_to_xyz> encounters a bad value in any of the R, G, or B values the output piddle will be marked as bad and the associated X, Y, and Z values will all be marked as bad.

=for usage

Usage:

    my $xyz = rgb_to_xyz( $rgb, 'sRGB' );

=cut

*rgb_to_xyz = \&PDL::rgb_to_xyz;
sub PDL::rgb_to_xyz {
    my ($rgb, $space) = @_;

    croak "Please specify RGB Space ('sRGB' for generic JPEG images)!"
        if !$space;

    my @m = pdl( $RGB_SPACE->{$space}{m} )->dog;

    return _rgb_to_xyz( $rgb, $RGB_SPACE->{$space}{gamma}, @m );
}


=head2 xyz_to_rgb

=for ref

Converts an XYZ color triple to an RGB color triple.

The first dimension of the piddles holding the xyz and rgb values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=for bad

If C<xyz_to_rgb> encounters a bad value in any of the X, Y, or Z values the output piddle will be marked as bad and the associated R, G, and B values will all be marked as bad.

=for usage

Usage:

    my $rgb = xyz_to_rgb( $xyz, 'sRGB' );

=cut

*xyz_to_rgb = \&PDL::xyz_to_rgb;
sub PDL::xyz_to_rgb {
    my ($xyz, $space) = @_;

    croak "Please specify RGB Space ('sRGB' for generic JPEG images)!"
        if !$space;

    my @mstar = pdl( $RGB_SPACE->{$space}{mstar} )->dog;

    return _xyz_to_rgb( $xyz, $RGB_SPACE->{$space}{gamma}, @mstar );
}


=head2 xyz_to_lab

=for ref

Converts an XYZ color triple to an Lab color triple.

The first dimension of the piddles holding the xyz values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=for bad

If C<xyz_to_lab> encounters a bad value in any of the X, Y, or Z values the output piddle will be marked as bad and the associated L, a, and b values will all be marked as bad.

=for usage

Usage:

    my $lab = xyz_to_lab( $xyz, 'sRGB' );

=cut

*xyz_to_lab = \&PDL::xyz_to_lab;
sub PDL::xyz_to_lab {
    my ($xyz, $space) = @_;

    croak "Please specify RGB Space ('sRGB' for generic JPEG images)!"
        if !$space;

    my $w = pdl $RGB_SPACE->{$space}{white_point};

    return _xyz_to_lab( $xyz, $w );
}


=head2 lab_to_xyz

=for ref

Converts an Lab color triple to an XYZ color triple.

The first dimension of the piddles holding the lab values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=for bad

If C<lab_to_xyz> encounters a bad value in any of the L, a, or b values the output piddle will be marked as bad and the associated X, Y, and Z values will all be marked as bad.

=for usage

Usage:

    my $xyz = lab_to_xyz( $lab, 'sRGB' );

=cut

*lab_to_xyz = \&PDL::lab_to_xyz;
sub PDL::lab_to_xyz {
    my ($lab, $space) = @_;

    croak "Please specify RGB Space ('sRGB' for generic JPEG images)!"
        if !$space;

    my $w = pdl $RGB_SPACE->{$space}{white_point};

    return _lab_to_xyz( $lab, $w );
}


=head2 rgb_to_lch

=for ref

Converts an RGB color triple to an LCH color triple.

The first dimension of the piddles holding the rgb values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=for bad

If C<rgb_to_lch> encounters a bad value in any of the R, G, or B values the output piddle will be marked as bad and the associated L, C, and H values will all be marked as bad.

=for usage

Usage:

    my $lch = rgb_to_lch( $rgb, 'sRGB' );

=cut

*rgb_to_lch = \&PDL::rgb_to_lch;
sub PDL::rgb_to_lch {
    my ($rgb, $space) = @_;

    croak "Please specify RGB Space ('sRGB' for generic JPEG images)!"
        if !$space;

    my $lab = xyz_to_lab( rgb_to_xyz( $rgb, $space ), $space );

    return lab_to_lch( $lab );
}


=head2 lch_to_rgb

=for ref

Converts an LCH color triple to an RGB color triple.

The first dimension of the piddles holding the lch values must be size 3, i.e. the dimensions must look like (3, m, n, ...).

=for bad

If C<lch_to_rgb> encounters a bad value in any of the L, C, or H values the output piddle will be marked as bad and the associated R, G, and B values will all be marked as bad.

=for usage

Usage:

    my $rgb = lch_to_rgb( $lch, 'sRGB' );

=cut

*lch_to_rgb = \&PDL::lch_to_rgb;
sub PDL::lch_to_rgb {
    my ($lch, $space) = @_;

    croak "Please specify RGB Space ('sRGB' for generic JPEG images)!"
        if !$space;

    my $xyz = lab_to_xyz( lch_to_lab( $lch ), $space );

    return xyz_to_rgb( $xyz, $space );
}

=head2 add_rgb_space

Supports adding custom RGB space definitions.

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
          'mstar' => [
                       [
                         '2.74565437614039',
                         '-0.969256810842655',
                         '0.0112706581772173'
                       ],
                       [
                         '-1.1358911781912',
                         '1.87599300082369',
                         '-0.113958877125197'
                       ],
                       [
                         '-0.435056564214666',
                         '0.0415556222493375',
                         '1.01310694059653'
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


=head1 SEE ALSO

Graphics::ColorObject

=head1 AUTHOR

~~~~~~~~~~~~ ~~~~~ ~~~~~~~~ ~~~~~ ~~~ `` ><(((">

Copyright (C) 2012 Maggie J. Xiong <maggiexyz+github@gmail.com>

Original work sponsored by Shutterstock, LLC L<http://www.shutterstock.com/>

All rights reserved. There is no warranty. You are allowed to redistribute this software / documentation as described in the file COPYING in the PDL distribution.

=cut
#line 894 "ColorSpace.pm"






# Exit with OK status

1;
