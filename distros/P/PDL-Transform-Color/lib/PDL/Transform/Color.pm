=encoding utf8

=head1 NAME

PDL::Transform::Color - Useful color system conversions for PDL

=head1 SYNOPSIS

     ### Shrink an RGB image with proper linear interpolation:
     ### DEcode the sRGB image values, then interpolate, then ENcode sRGB
     $im = rpic("big_colorimage.jpg");
     $im2 = $im->invert(t_srgb())->match([500,500],{m=>'g'})->apply(t_srgb());

=head1 DESCRIPTION

PDL::Transform::Color includes a variety of useful color conversion
transformations.  It can be used for simple hacks on machine-native
color representations (RGB <-> HSV, etc.), for simple
encoding/decoding of machine-native color representations such as
sRGB, or for more sophisticated manipulation of absolute color
standards including large-gamut or perceptual systems.

The color transforms in this module can be used for converting between
proper color systems, for gamma-converting pixel values, or for
generating pseudocolor from one or two input parameters.  In addition
to transforming color data between different representations, Several
named "color maps" (also called "color tables") are provided.

The module uses linearized sRGB (lsRGB) as a fundamental color basis.
sRGB is the standard color system used by most consumer- to mid-grade
computer equipment, so casual users can use this color representation
without much regard for gamuts, colorimetric standards, etc.

Most of the transform generators convert from lsRGB to various
other systems.  Notable simple ones are HSV (Hue, Saturation, Value),
HSL (Hue, Saturation, Lightness), and CMYK (Cyan, Magenta, Yellow,
blacK).

If you aren't familiar with PDL::Transform, you should read that POD
now, as this is a subclass of PDL::Transform.  Transforms represent
and encapsulate vector transformations -- one- or two-way vector
functions that may be applied, composed, or (if possible) inverted.
They are created through constructor methods that often allow
parametric adjustment at creation time.

If you just want to "manipulate some RGB images" and not learn about
the esoterica of color representations, you can treat all the routines
as working "from RGB" on the interval [0,1], and use C<t_srgb> to
import/export color images from/to "24-bit color" that your computer
probably expects.  If you care about the esoterica, read on.

The output transfer function for sRGB is nonlinear -- the luminance of
a pixel on-screen varies somewhat faster than the square of the input
value -- which is inconvenient for blending, merging, and manipulating
color.  Many common operations work best with a linear photometric
representation.  PDL::Transform::Color works with an internal model
that is a floating-point linear system representing pixels as
3-vectors whose components are proportional to photometric brightness
in the sRGB primary colors.  This system is called "lsRGB" within the
module.

Note that, in general, RGB representations are limited to a particular
narrow gamut of physically accessible values.  While the human eye has
three dominant colorimetric input channels and hence color can be
represented as a 3-vector, the human eye does not cleanly separate the
spectra responsible for red, green, and blue stimuli.  As a result, no
trio of physical primary colors (which must have positive-definite
spectra and positive-definite overall intensities) can represent every
perceivable color -- even though they form a basis of color space.

But in digital representation, there is no hard limit on the values
of the RGB vectors -- they can be negative or arbitrarily large.  This
permits representation of out-of-gamut values using negative or
over-unity intensities.  So floating-point lsRGB allows you to
represent literally any color value that the human eye can perceive,
and many that it can't.  This is useful even though many such colors
can't be rendered on a monitor.  For example, you can change between
several color representations and not be limited by the formal gamut
of each representation -- only by the final export standard.

Three major output formats are supported: sRGB (standard "24-bit
color" with the industry standard transfer function); bRGB (bytescaled
RGB with a controllable gamma function (default 2.2, matching the
average gamma value of most CRTs and calibrated flat monitors); or
CMYK (direct linear inversion of the RGB values, with byte
scaling). These are created by applying the transforms C<t_srgb>,
C<t_brgb>, and C<t_cmyk>, respectively, to an lsRGB color triplet.

The C<t_srgb> export routine will translate represented colors in
floating-point lsRGB to byte-encoded sRGB (or, if inverted, vice
versa), using the correct (slightly more complicated than gamma
functions) nonlinear scaling.  In general, you can use C<!t_srgb> to
import existing images you may have found lying around the net;
manipulate their hue, etc.; and re-export with C<t_srgb>.

If you prefer to work with direct gamma functions or straight
scaling, you can import/export from/to byte values with C<t_brgb>
instead.  For example, to export a color in the CIE RGB system
(different primaries than sRGB), use C<t_brgb() x t_ciergb>.

There are also some pseudocolor transformations, which convert a
single data value to normalized RGB.  These transformations are
C<t_pc> for photometric (typical scientific) values and C<t_pcp> for
perceptual (typical consumer camera) values.  They are described
below, along with a collection of named pseudocolor maps that are
supplied with the module.

=head1 OVERVIEW OF COLOR THEORY

Because of the biophysics of the human eye, color is well represented
as a 3-vector of red, green, and blue brightness values representing
brightness in the long, middle, and short portions of the visible
spectrum.  However, the absorption/sensitivity bands overlap
significantly, therefore no physical light (of any wavelength) can
form a proper "primary color" (orthonormal basis element) of this
space.  While any vector in color space can be represented as a linear
sum of three indepenent basis vectors ("primary colors"), there is no
such thing as a negative intensity and therefore any tricolor
representation of the color space is limited to a "gamut" that can be
formed by I<positive> linear combinations of the selected primary colors.

Some professional color representations (e.g. 5- and 7-color dye
processes) expand this gamut to better match the overall spectral
response of the human eye, at the cost of over-determining color
values in what is fundamentally a 3-space.

RGB color representations require the specification of particular
primary colors that represent particular spectral profiles.  The
choice of primaries depends on the technical solution being used for
I/O.  The most universal "standard" representation is the CIE RGB
standard developed in 1931 by the Commission Internationale de
l'Eclairage (CIE; International Commission on Illumination).  The 1931
CIE RGB system is also called simply CIERGB by many sources.  It uses
primary wavelengths of 700nm (red), 546.1 nm (green), and 435.8 nm
(blue).

The most universal "computer" representation is the sRGB standard
defined by Anderson et al.  (1996), which uses on slightly different
primary colors than does the 1931 CIE RGB standard.  This is because
sRGB is based on the colorimetric output of color television phosphors
in CRTs, while CIE RGB was developed based on easily lab-reproducible
spectra.

The C<PDL::Transform::Color> transformations are all relative to the
sRGB color basis.  Negative values are permitted, allowing
representation of all colors -- possible or impossible.

CIE defined several other important color systems: first, an XYZ
system based on nonphysical primaries X, Y, and Z that correspond to
red, green, and blue, respectively. The XYZ system can represent all
colors detectable to the human eye with positive-definite intensities
of the "primaries": the necessary negative intensities are hidden in
the formal spectrum of each of the primaries.  The Y primary of this
system corresponds closely to green, and is used by CIE as a proxy for
overall luminance.

The CIE also separated "chrominance" and "luminance" signals, in a
separate system called "xyY", which represents color as sum-normalized
vectors "x=X/(X+Y+Z), "y=Y/(X+Y+Z)", and "z=Z/(X+Y+Z)".  By construction,
x+y+z=1, so "x" and "y" alone describe the color range of the system, and
"Y" stands in for overall luminance.

A linear RGB system is specified exactly by the chrominance (CIE XYZ
or xyY) coordinates of the three primaries, and a white point
chrominance.  The white point chrominance sets the relative scaling
between the brightnesses of the primaries to achieve a color-free
("white") luminance.  Different systems with the same R, G, B primary
vectors can have different gains between those colors, yielding a
slightly different shade of color at the R=G=B line.  This "white"
reference chrominance varies across systems, with the most common
"white" standard being CIE's D65 spectrum based on a 6500K black body
-- but CIE, in particular, specifies a large number of white
standards, and some systems use none of those but instead specify CIE
XYZ values for the white point.

Similarly, real RGB systems typically use dynamic range compression
via a nonlinear transfer function which is most typically a "gamma
function".  A built-in database tracks about 15 standard named
systems, so you can convert color values between them.  Or you can
specify your own system with a standard hash format (see C<get_rgb>).

Provision exists for converting between different RGB systems with
different primaries and different white points, by linearizing and
then scaling.  The most straightforward way to use this module to
convert between two RGB systems (neither of which is lsRGB) is to
inverse-transform one to lsRGB, then transform forward to the other.
This is accomplished with the C<t_shift_rgb> transform.

Many other representations than RGB exist to separate chromatic
value from brightness.  In general, these can be divided into polar
coordinates that represent hue as a single value divorced from the rgb
basis, and those that represent it as a combination of two values like
the 'x' and 'y' of the CIE xyY space.  These are all based on the
Munsell and Ostwald color systems, which were worked out at about the
same time as the CIE system.  Both Ostwald and Munsell worked around
the start of the 20th century pioneered colorimetric classification.

Ostwald worked with quasi-linear representations of chromaticity as a
2-vector independent of brightness; these representations relate to
CIERGB, CIEXYZ, and related systems via simple geometric projection;
the CIE xyY space is an example.  The most commonly used variant of
xyY is CIELAB, a perceptual color space that separates color into a
perceived lightness parameter L, and separate chromaticities 'a' and
'b'.  CIELAB is commonly used by graphic artists and related
professions, because it is an absolute space like XYZ (so that each
LAB value corresponds to a particular perceivable color), and because
the Cartesian norm between vectors in LAB space is approximately
proportional to perceived difference between the corresponding colors.
The system is thus useful for communicating color values precisely
across different groups or for developing perceptually-uniform display
maps for generated data.  The L, A, and B coordinates are highly
nonlinear to approximately match the typical human visual system.

Other related systems include YUV, YPbPr, and YCbCr -- which are used
for representing color for digital cinema and for video transmission.

Munsell developed a color system based on separating the "hue" of a
color into a single value separate from both its brightness and
saturation level.  This system is closely related to cylindrical polar
coordinates in an RGB space, with the center of the cylinder on top of
the line of values corresponding to neutral shades from "black"
through "grey" to "white".

Two simple Munsell-like representations that work within the gamut of
a particular RGB basis are HSL and HSV.  Both of these systems are
loose representations that are best defined relative to a particular
RGB system. They are both designed specifically to represent an entire
RGB gamut with a quasi-polar coordinate system, and are based on
hexagonal angle -- i.e. they are not exactly polar in nature.

HSL separates "Hue" and "Saturation" from "Lightness".  Hue represents
the spectral shade of the color as a direction from the central white
reference line through RGB space: the R=G=B line.  Saturation is a
normalized chromaticity measuring fraction of the distance from the
white locus to the nearest edge of the RGB gamut at a particular hue
and lightness.  Lightness is an approximately hue- independent measure
of total intensity.  Deeply objectively "saturated" colors are only
accessible at L=0.5; the L=0.5 surface includes all the additive and
subtractive primary colors of the RGB system.  Darker colors are
less-saturated shades, while brighter colors fade to pastels.

HSV is similar to HSL, but tracks only the brightest component among
the RGB triplet as "Value" rather than the derived "Lightness".  As a
result, highly saturated HSV values have lower overall luminance than
unsaturated HSV values with the same V, and the V=1 surface includes
all the primary and secondary colors of the parent RGB system.  This system takes
advantage of the of the "Helmholtz-Kolhrausch effect" that
I<perceived> brightness increases with saturation, so V better
approximates perceived brightness at a given hue and saturation, than
does L.

Modern display devices generally produce physical brightnesses that
are proportional not to their input signal, but to a nonlinear
function of the input signal.  The most common nonlinear function is a
simple power law ("gamma function"): output is approximately
proportional to the "gamma" power of the input.  Raising a signal
value to the power "1/gamma" is C<gamma-encoding> it, and raising it
to the power "gamma" is C<gamma-decoding> it.

The sRGB 24-bit color standard specifies a slightly more complicated
transfer curve, that consists of a linear segment spliced onto a
horizontally-offset power law with gamma=2.4.  This reduces
quantization noise for very dark pxels, but approximates an overall
power law with gamma=2.2.  Hence, C<t_brgb> (which supports general
power law transfer functions) defaults to an output gamma of 2.2, but
C<t_srgb> yields a more accurate export transfer in typical use.  The
gamma value of 2.2 was selected in the early days of the television
era, to approximately match the perceptual response of the human eye,
and for nearly 50 years cathode-ray-tube (CRT) displays were
specifically designed for a transfer gamma of 2.2 between applied
voltage at the electron gun input stage and luminance (luminous energy
flux) at the display screen.

Incidentally, some now-obsolete display systems (early MacOS systems
and Silcon Graphics displays) operated with a gamma factor of 1.8,
slightly less nonlinear than the standard.  This derives from early
use of checkerboard (and similar) pixelwise dithering to achieve a
higher-bit-depth color palette than was otherwise possible, with early
equipment.  The display gamma of 2.2 interacted with direct dithering
of digital values in the nonlinear space, to produce an effective gamma
closer to 1.8 than 2.2.


=head1 STANDARD OPTIONS

=over 3

=item gamma

This is a gamma correction exponent used to get physical luminance
values from the represented RGB values in the source RGB space.  Most
color manipulation is performed in linear (gamma=1) representation --
i.e. if you specify a gamma to a conversion transform, the normalized
RGB values are B<decoded> to linear physical values before processing
in the forward direction, or B<encoded> after processing in the
reverse direction.

For example, to square the normalized floating-point lsRGB values
before conversion to bRGB, use C<t_brgb(gamma=>2)>.  The "gamma"
option specifies that the desired brightness of the output device
varies as the square of the pixel value in the stored data.

Since lsRGB is the default working space for most transforms, you
don't normally need to specify C<gamma> -- the default value of 1.0
is correct.

Contrariwise, the C<t_brgb> export transform has a C<display_gamma> option
that specifies the gamma function for the output bytes.  Therefore,
C<< t_brgb(display_gamma=>2) >> square-roots the data before export (so that
squaring them would yield numbers proportional to the desired luminance
of a display device).

The C<gamma> option is kept for completeness, but unless you know it's
what you really want, you probably don't actually want it: instead,
you should consider working in a linear space and decoding/encoding
the gamma of your import/export color space only as you read in or write
out values.  For example, generic images found on the internet are
typically in the sRGB system, and can be imported to lsRGB via the
C<!t_srgb> transform or exported with C<t_srgb> -- or other
gamma-corrected 24-bit color systems can be handled directly with
C<t_brgb> and its C<display_gamma> option.

=back

=head1 FUNCTIONS

=cut

package PDL::Transform::Color;

use strict;
use warnings;
use base 'Exporter';
use PDL::LiteF;
use PDL::Transform;
use PDL::Math;
use PDL::Options;
use PDL::Graphics::ColorSpace;
use Carp;

our @ISA = ( 'Exporter', 'PDL::Transform' );
our $VERSION = '1.007';
$VERSION = eval $VERSION;

our @EXPORT_OK = qw/ t_gamma t_brgb t_srgb t_shift_illuminant t_shift_rgb t_cmyk t_rgi t_cieXYZ t_xyz t_xyY t_xyy t_lab t_xyz2lab t_hsl t_hsv t_pc t_pcp/;
our @EXPORT = @EXPORT_OK;
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

our $PI = 3.141592653589793238462643383279502;

our $srgb2cxyz_inv = $PDL::Graphics::ColorSpace::RGBSpace::RGB_SPACE->{sRGB}{mstar}->transpose;
our $srgb2cxyz_mat = $PDL::Graphics::ColorSpace::RGBSpace::RGB_SPACE->{sRGB}{m}->transpose;

sub _new { __PACKAGE__->new(@_) }

sub new {
    my $me = shift->SUPER::new;
    my $parse = pop;
    $me->{name} = pop;
    @$me{qw(u_opt idim odim)} = ({@_}, 3, 3);
    $me->{params} = {parse($parse, $me->{u_opt})};
    return $me;
}

## Compose with gamma correction if necessary
sub gammify {
    my $me = shift;
    return $me if ($me->{params}{gamma} // 1) == 1;
    # Decode gamma from source
    return ( $me x t_gamma($me->{params}{gamma}) );
}

##############################

=head2 t_gamma

=for usage

    $t = t_gamma($gamma);

=for ref

This is an internal generator that is used to implement the standard
C<gamma> parameter for all color transforms.  It is exported as well
because many casual users just want to apply a gamma curve to existing
data rather than doing anything more rigorous.

In the forward direction, C<t_gamma> applies/decodes the gamma correction
indicated -- e.g. if the C<$gamma> parameter at generation time is 2,
then the forward direction squares its input, and the inverse direction
takes the square root (encodes the gamma correction).

Gamma correction is implemented using a sign-tolerant approach:
all values have their magnitude scaled with the power law, regardless
of the sign of the value.

=cut

sub t_gamma {
    my $gamma = shift;
    my ($me) = _new("gamma",{});

    $me->{params} = {gamma=>$gamma};
    $me->{name} .= sprintf("=%g",$gamma);
    $me->{idim} = 3;
    $me->{odim} = 3;

    $me->{func} = sub {
	my ($in, $opt) = @_;
	my $out = $in->new_or_inplace;
	if($opt->{gamma} != 1) {
	    $out *= ($in->abs + ($in==0)) ** ($opt->{gamma}-1);
	}
	$out;
    };

    $me->{inv} = sub {
	my ($in, $opt) = @_;
	my $out = $in->new_or_inplace;
	if($opt->{gamma} != 1) {
	    $out *= ($in->abs + ($in==0)) ** (1.0/$opt->{gamma} - 1);
	}
	$out;
    };

    $me;
}

##############################

=head2 t_brgb

=for usage

    $t = t_brgb();

=for ref

Convert lsRGB (normalized to [0,1]) to byte-scaled RGB ( [0,255] ).
By default, C<t_brgb> prepares byte values tuned for a display gamma
of 2.2, which approximates sRGB (the standard output color coding for
most computer displays).  The difference between C<t_brgb> and
C<t_srgb> in this usage is that C<t_srgb> uses the actual
spliced-curve approximation specified in the sRGB standard, while
C<t_brgb> uses a simple gamma law for export.

C<t_brgb> accepts the following options, all of which may be abbreviated:

=over 3

=item gamma (default 1)

If set, this is a gamma-encoding value for the original lsRGB, which
is decoded before the transform.

=item display_gamma (default 2.2)

If set, this is the gamma of the display for which the output is
intended.  The default compresses the brightness vector before output
(taking approximately the square root).  This matches the "standard
gamma" applied by MacOS and Microsoft Windows displays, and approximates
the sRGB standard.  See also C<t_srgb>.

=item clip (default 1)

If set, the output is clipped to [0,256) in the forward direction and
to [0,1] in the reverse direction.

=item byte (default 1)

If set, the output is converted to byte type in the forward direction.
This is a non-reversible operation, because precision is lost in the
conversion to bytes. (The reverse transform always creates a floating
point value, since lsRGB exists on the interval [0,1] and an integer
type would be useless.)

=back

=cut

sub t_brgb {
    my($me) = _new(@_,'encode bytescaled RGB',
		   {clip=>1,
		    byte=>1,
		    gamma=>1.0,
		    display_gamma=>2.2,
		   }
	);

    $me->{func} = sub {
	my($in, $opt) = @_;
	my $out = $in->new_or_inplace;

	if($opt->{display_gamma} != 1) {
	    $out *= ($out->abs)**(1.0/$opt->{display_gamma} - 1);
	}

	$out *= 255.0;

	if($opt->{byte}) {
	    $out = byte($out->rint->clip(0,255));
	} elsif($opt->{clip}) {
	    $out->inplace->clip(0,255.49999);
	}

	$out;
    };

    $me->{inv} = sub {
	my($in,$opt) = @_;

	my $out = $in / 255.0;

	if($opt->{display_gamma} != 1) {
	    $out *= ($out->abs)**($opt->{display_gamma}-1);
	}

	if($opt->{clip}) {
	    $out->inplace->clip(0,1);
	}
	$out;
    };

    return gammify($me);
}

=head2 t_srgb

=for ref

Converts lsRGB (the internal floating-point base representation) to
sRGB - the typical RGB encoding used by most computing devices.  Since
most computer terminals use sRGB, the representation's gamut is well
matched to most computer monitors.

sRGB is a spliced standard, rather than having a direct gamma
correction.  Hence there is no way to adjust the output gamma.  If you
want to do that, use C<t_brgb> instead.

C<t_srgb> accepts the following options, all of which may be abbreviated:

=over 3

=item gamma (default 1)

If set, this is a gamma-encoding value for the original lsRGB, which
is decoded before the transform.

=item byte (default 1)

If set, this causes the output to be clipped to the range [0,255] and rounded
to a byte type PDL ("24-bit color").  (The reverse transform always creates
a floating point value, since lsRGB exists on the interval [0,1] and an integer
type would be useless.)

=item clip (default 0)

If set, this causes output to be clipped to the range [0,255] even if the
C<byte> option is not set.

=back

=cut

sub t_srgb {
    my($me) = _new(@_,'encode 24-bit sRGB',
		   {clip=>0,
		    byte=>1,
		    gamma=>1.0
		   }
	);
    $me->{func} = sub {
	my($in,$opt) = @_;
	# Convert from CIE RGB to sRGB primaries
	my($rgb) = $in->new_or_inplace();
	rgb_from_linear($rgb->inplace, -1);
	$rgb->set_inplace(0); # needed as bug in PDL <2.082
	my $out;
	$rgb *= 255;
	if($opt->{byte}) {
	    $out = byte( $rgb->rint->clip(0,255) );
	} elsif($opt->{clip}) {
	    $out = $rgb->clip(0,255.49999);
	} else {
	    $out = $rgb;
	}
	$out;
    };

    $me->{inv} = sub {
	my($in,$opt) = @_;
	my $rgb = $in / pdl(255.0);
	rgb_to_linear($rgb->inplace, -1);
	$rgb->set_inplace(0); # needed as bug in PDL <2.082
	$rgb;
    };

    return gammify($me);
}


######################################################################
######################################################################

=head2 t_pc and t_pcp

=for ref

These two transforms implement  a general purpose pseudocolor
transformation.  You input a monochromatic value (zero active dims)
and get out an RGB value (one active dim, size 3).  Because the most
common use case is to generate sRGB values, the default output is sRGB
-- you have to set a flag for lsRGB output, for example if you want to
produce output in some other system by composing t_pc with a color
transformation.

C<t_pc> generates pseudocolor transforms ("color maps") with
a photometric interpretation of the input:  the input data are
considered to be proportional to some kind of measured luminance
or similar physical parameter.   This produces "correct" renderings
of scenes captured by scientific cameras and similar instrumentation.

C<t_pcp> generates pseudocolor transforms ("color maps") with a
perceptual interpretation of the input: the input data are considered
to be proportional to the *perceptual* variation desired across the
display.  This produces "correct" renderings of many non-luminant
types of data, such as temperature, Doppler shift, frequency plots,
etc.

Both C<t_pc> and C<t_pcp> generate transforms based on a collection
of named transformations stored in an internal database (the global
hash ref C<$PDL::Transform::Color::pc_tab>).  The transformations
come in two basic sorts:  quasi-photometric transformations,
which use luminance as the dominant varying parameter; and non-
photometric transformations, which use hue or saturation as the
dominant varying parameter.  Only the photometric transformations
get modified by C<t_pc> vs C<t_pcp> -- for example, C<t_pcp('rainbow')>
will yield the same transform as C<t_pc('rainbow')>.

Some of the color transformations are "split" and intended for display of signed
data -- for example, the C<dop> transformation fades red-to-white-to-blue and
is intended for display of Doppler or similar signals.

NOTE: C<t_pc> and C<t_pcp> work BACKWARDS from most of the
transformations in this package: they convert FROM a data value TO sRGB
or lsRGB.

There are options to adjust input gamma and the domain of the
transformation (e.g. if your input data are on [0,1000] instead of
[0,1]).

If you feed in no arguments at all, either C<t_pc> or C<t_pcp> will
list a collection of named pseudocolor transformations that work, on
the standard output.

Options accepted are:

=over 3

=item gamma (default 1) - presumed encoding gamma of the input

The input is *decoded* from this gamma value.  1 treats it as linear
in luminance.

=item lsRGB (default 0) - produce lsRGB output instead of sRGB.

(this may be abbreviated "l" for "linear")

=item domain - domain of the input; synonym for irange.

=item irange (default [0,1]) - input range of the data

Input data are by default clipped to [0,1] before application of the
color map.  Specifying an undefined value causes the color map to be
autoscaled to the input data, e.g. C<ir=>[0,undef]> causes the color map
to be scaled from 0 to the maximum value of the input.  For full
autoscaling, use C<ir=>[]>.

=item combination (default 0) - recombine r,g,b post facto

This option allows you to perturb maps you like by mixing up r, g, and
b after all the other calculations are done.  You feed in a number
from 0 to 5.  If it's nonzero, you get a different combination of the
three primaries.  You can mock this up more compactly by appending
C<-Cn> to the (possibly abbreviated) name of the table.  (Replace
the 'n' with a number).

For example, if you specify the color table C<sepia> or C<sepia-c0> you'll
get the sepiatone color table.  If you specify C<sepia-c5> you'll get
almost the exact same color table as C<grepia>.

=back

You can abbreviate color table names with unique abbreviations.
Tables currently accepted, and their intended uses are:

=over 3

=item QUASI-PHOTOMETRIC PSEUDOCOLOR MAPS FOR NORMAL USE

=over 3

=item  grey, gray, or mono (photometric)

Simple monochrome.

=item sepia, blepia, grepia, vepia, ryg - sepiatone and variants

These use color scaling to enhance contrast in a simple luminance
transfer.  C<sepia> is a black-brown-white curve reminiscent of sepia
ink.  The others are similar, but emphasize different primary colors.
The 'ryg' duplicates sepiatone, but with green highlights to increase
contrast in near-saturated parts of an image.

=item heat

This black-red-yellow-white is reminiscent of blackbody curves
(but does not match them rigorously).

=item pm3d, voy

"pm3d" is the default color table for Gnuplot.  It's a colorblind-friendly,
highly saturated table with horrible aesthetics but good contrast throughout.
"voy" is violet-orange-yellow.  It's a more aesthetically pleasing colorblind-
friendly map with a ton of contrast throughout the range.

=item ocean

deep green through blue to white

=item spring, summer, autumn, winter

These are reminiscent of the "seasonal" colors provided by MatLab.  The
"spring" is horrendous but may be useful for certain aesthetic presentations.
Summer and Winter are similar to the sepia-like tables, but with different
color paths.  Autumn is similar to heat, but less garish.

=back

=item SPLIT PSEUDOCOLOR MAPS FOR SIGNED QUANTITIES

=over 3

=item dop, dop1, dop2, dop3

These are various presentations of signed information, originally
intended to display Doppler shift.  They are all quasi-photometric
and split.

=item vbg

This is a violet-black-green signed fade useful for non-Doppler
signed quantities.  Quasi-photometric and split.

=back

=item NON-PHOTOMETRIC PSEUDOCOLOR MAPS

=over 3


=item rainbow

Colors of the rainbow, red through "violet" (magenta)

=item wheel

The full "color wheel", including the controversial magenta-to-red segment

=back

=back


=cut


## pc_tab defines transformation subs for R, G, B from the grayscale.
## The initial few are translated direct from the C<$palettesTab> in
## C<PDL::Graphics::Gnuplot>; others follow.  Input is on the domain
## [0,1].  Output is clipped to [0,1] post facto.
##
## names should be lowercase.
##
## Meaning of fields:

## type     Color system being used ('rgb' or 'hsv' at present)
## subs     List ref containing three subs that accept scaled input [0,1] and
##            return each color coordinate value (e.g. r, g, b)
## doc      Short one-line string describing the pseudocolor map
## igamma   Scaled input is *decoded* from this gamma (raised to this power) if present
## ogamma   Output is *encoded to this gamma (rooted by this power) if present
## phot     Flag: if set, this pseudocolor map is approximately photometric and can be
##            scaled differently by the direct and perceptual color table methods
## split    This is the "zero point" on [0-1] of the color map.  Default is 0.  Useful
##            for gamma scaling etc; primarily used by doppler and other signed tables.
##            (Note that it's the user's responsibility to make sure the irange places
##            the zero here, since the subs accept pre-scaled input on [0,1]

our $pc_tab = {
    gray       => { type=>'rgb', subs=> [ sub{$_[0]},       sub{$_[0]},        sub{$_[0]}       ],
		  doc=>"greyscale", phot=>1 },

    grey       => { type=>'rgb', subs=> [ sub{$_[0]},       sub{$_[0]},        sub{$_[0]}       ],
		    doc=>"greyscale", phot=>1 },

    blepia     => { type=>'rgb', subs=> [ sub{$_[0]**2},    sub{$_[0]},        sub{sqrt($_[0])} ],
		  doc=>"a simple sepiatone, in blue" , phot=>1, igamma=>0.75 },

    dop        => { type=>'rgb', subs=> [ sub{2-2*$_[0]},   sub{1-abs($_[0]-0.5)*2},   sub{2*$_[0]} ],
		    doc=>"red-white-blue fade", ogamma=>1.5, igamma=>0.6, phot=>1, split=>.5},

    dop1       => { type=>'rgb', subs=> [ sub{2-2*$_[0]},   sub{1-abs($_[0]-0.5)*2},   sub{2*$_[0]} ],
		    doc=>"dop synonym", ogamma=>1.5, igamma=>0.6, phot=>1, split=>.5},

    dop2       => { type=>'rgb', subs=> [ sub{(1-2*$_[0])},  sub{(($_[0]-0.5)->abs->clip(0,0.5))**2},    sub{(-1+2*$_[0])} ],
		  doc=>'red-black-blue fade (mostly saturated)', ogamma=>1.5, igamma=>0.5, phot=>1, split=>0.5 },

    dop3       => { type=>'rgb', subs=> [ sub{1-$_[0]*2},   sub{(0.1+abs($_[0]-0.5))**2},                  sub{-1+$_[0]*2} ],
		  doc=>'orange-black-lightblue fade (lightly saturated)', ogamma=>1.5, igamma=>0.5, phot=>1, split=>0.5 },

    vbg        => { type=>'rgb', subs=> [ sub{1 - (2*$_[0])},  sub{abs($_[0]-0.5)*1.5},    sub{1 - 2*$_[0]} ],
		  doc=>'violet-black-green signed fade', ogamma=>1.5, igamma=>0.5, phot=>1, split=>0.5 },



    grepia     => { type=>'rgb', subs=> [ sub{$_[0]},       sub{sqrt($_[0])},  sub{$_[0]**2}    ],
		  doc=>"a simple sepiatone, in green", igamma=>0.9, phot=>1 },

    heat       => { type=>'rgb', subs=> [ sub{2*$_[0]},      sub{2*$_[0]-0.5},    sub{2*$_[0]-1} ],
		  doc=>"heat-map (AFM): black-red-yellow-white", phot=>1, igamma=>0.667 },

    pm3d       => { type=>'rgb', subs=> [ sub{sqrt($_[0])}, sub{$_[0]**3},     sub{sin($_[0]*2*$PI)} ],
		  doc=>"duplicates the PM3d colortable in gnuplot (RG colorblind)", phot=>1},

    grv        => { type=>'rgb', subs=> [ sub{sqrt($_[0]*0.5)},     sub{1-2*$_[0]},  sub{$_[0]**3.5}    ],
		    doc=>"green-red-violet", igamma=>0.75, phot=>1 },

    mono       => { type=>'rgb', subs=> [ sub{$_[0]},       sub{$_[0]},         sub{$_[0]}       ],
		  doc=>"synonym for grey"},

    ocean      => { type=>'rgb', subs=> [ sub{(3*$_[0]-2)->clip(0) ** 2}, sub{$_[0]},  sub{$_[0]**0.33*0.5+$_[0]*0.5}    ],
		  doc=>"green-blue-white", phot=>1, igamma=>0.8},

    rainbow    => { type=>'hsv', subs=> [ sub{$_[0]*0.82},     sub{pdl(1)},               sub{pdl(1)}          ],
		  doc=>"rainbow red-yellow-green-blue-violet"},

    rgb        => { type=>'rgb', subs=> [ sub{cos($_[0]*$PI/2)}, sub{sin($_[0]*$PI)}, sub{sin($_[0]*$PI/2)} ],
		  doc=>"red-green-blue fade", phot=>1 },

    sepia      => { type=>'rgb', subs=> [ sub{sqrt($_[0])}, sub{$_[0]},        sub{$_[0]**2}    ],
		  doc=>"a simple sepiatone", phot=>1  },

    vepia      => { type=>'rgb', subs=> [ sub{$_[0]},       sub{$_[0]**2},     sub{sqrt($_[0])} ],
		  doc=>"a simple sepiatone, in violet", phot=>1, ogamma=>0.9 },

    wheel      => { type=>'hsv', subs=> [ sub{$_[0]},         sub{pdl(1)},                sub{pdl(1)}         ],
		      doc=>"full color wheel red-yellow-green-blue-violet-red" },

    ryg     => { type=>'hsv', subs=> [ sub{ (0.5*($_[0]-0.333/2))%1 }, sub{0.8+0.2*$_[0]}, sub{$_[0]} ],
		 doc=>"A quasi-sepiatone (R/Y) with green highlights",phot=>1, igamma=>0.7 },

    extra   => { type=>'hsv', subs=>[ sub{ (0.85*($_[0]**0.75-0.333/2))%1}, sub{0.8+0.2*$_[0]-0.8*$_[0]**6},
				      sub { 1 - exp(-$_[0]/0.15) - 0.08 }],
	          doc=>"Extra-broad photometric; also try -c1 etc.",phot=>1,igamma=>0.55 },

    voy     => { type=>'rgb', subs=> [ sub{pdl(1)*$_[0]}, sub{$_[0]**2*$_[0]}, sub{(1-$_[0])**4 * $_[0]}],
                    doc=>"A colorblind-friendly map with lots of contrast", phot=>1, igamma=>0.7},

    ### Seasons: these are sort of like the Matlab colortables of the same names...

    spring     => { type=>'rgb', subs=> [ sub{pdl(1)}, sub{$_[0]**2}, sub{(1-$_[0])**4}],
                    doc=>"Springy colors fading from magenta to yellow", phot=>1, igamma=>0.45},

    summer     => { type=>'hsv', subs=> [ sub{ 0.333*(1- $_[0]/2) }, sub{0.7+0.1*$_[0]}, sub{0.01+0.99*$_[0]} ],
		    doc=>"Summery colors fading from dark green to light yellow",phot=>1, igamma=>0.8 },

    autumn     => { type=>'hsv', subs=> [ sub { $_[0] * 0.333/2 }, sub{pdl(1)}, sub{0.01+0.99*$_[0]} ],
		    doc=>"Autumnal colors fading from dark red through orange to light yellow",phot=>1,igamma=>0.7},

    winter     => { type=>'hsv', subs=> [ sub { 0.667-0.333*$_[0] }, sub{1.0-sin($PI/2*$_[0])**2*0.2}, sub{$_[0]}],
		    doc=>"Wintery colors fading from dark blue through lightish green",phot=>1,igamma=>0.5},

};

# Generate the abbrevs table: find minimal substrings that match only one result.
our $pc_tab_abbrevs = {};
{
    my $pc_tab_foo = {};
    for my $k(keys %$pc_tab) {
	for my $i(0..length($k)){
	    my $s = substr($k,0,$i);
	    if($pc_tab_foo->{$s} and length($s)<length($k)) {
		# collision with earlier string -- if that's a real abbreviation, zap it.
		delete($pc_tab_abbrevs->{$s})
		   unless( length($pc_tab_abbrevs->{$s}||'') == length($s) );
	    } else {
		# no collision -- figure it's a valid abbreviation.
		$pc_tab_abbrevs->{$s} = $k;
	    }
	    $pc_tab_foo->{$s}++;
	}
    }
}
# Hand-code some abbreviations..
$pc_tab_abbrevs->{g} = "grey";
for(qw/m monoc monoch monochr monochro monochrom monochrome/) {$pc_tab_abbrevs->{_} = "mono";}


### t_pcp - t_pc, but perceptual flag defaults to 1
sub t_pcp {
    my $name = (0+@_ % 2) ? shift : undef;
    return t_pc(defined($name) ? $name : (), @_, perceptual => 1);
}

our @_t_pc_combinatorics =(
    [0,1,2],[1,2,0],[2,0,1],[0,2,1],[2,1,0],[1,0,2]
    );

sub t_pc {
    # No arguments
    unless(0+@_){
	my $s = "Usage: 't_pc(\$colortab_name, %opt)'. Named pseudocolor mappings available:\n";
	$s .= "  (tables marked 'phot' are luminance based.  Use t_pc for photometric data, or\n  t_pcp for near-constant perceptual shift per input value.\n  Add '-c<n>' suffix (n in [0..5]) for RGB combinatoric variations.)\n";
	our $pc_tab;
	for my $k(sort keys %{$pc_tab}) {
	    $s .= sprintf("  %8s - %s%s\n",$k,$pc_tab->{$k}->{doc},($pc_tab->{$k}->{phot}?" (phot)":""));
	}
	die $s."\n";
    }


    # Parse the color table name.
    # Odd number of params -- expect a table name and options.
    # even number of params -- just options.
    my $lut_name = ((0+@_) % 2) ? shift() : "monochrome";


    ###
    # Table names can have combinatoric modifiers.  Parse those out.
    my $mod_combo = undef;
    if( $lut_name =~ s/\-C([0-5])$//i ) {
	# got a combinatoric modifier
	$mod_combo = $1;
    }

    ## Look up the table by name
    $lut_name = $pc_tab_abbrevs->{lc($lut_name)};
    unless($lut_name) {
	t_pc(); # generate usage message
    }


    # Generate the object
    my($me) = _new(@_, "pseudocolor sRGB encoding ($lut_name)",
		   {
		       clip=>1,
		       byte=>1,
		       gamma=>1.0,
		       lsRGB=>0,
		       domain=>undef,
		       irange=>[0,1],
		       perceptual=>0,
		       combination=>0
		   }
	);

    $me->{params}->{lut_name} = $lut_name;
    $me->{params}->{lut} = $pc_tab->{$lut_name};
    unless(defined($pc_tab->{$lut_name})){
	die "t_pc: internal error (name $lut_name resolves but points to nothing)";
    }

    # Handle domain-irange synonym
    $me->{params}->{irange} = $me->{params}->{domain} if(defined($me->{params}->{domain}));

    # Check that range is correct
    $me->{params}->{irange} = [] unless(defined($me->{params}->{irange}));
    unless( ref($me->{params}->{irange}) eq 'ARRAY'
	){
	die "t_pc: 'domain' or 'irange' parameter must be an array ref ";
    }
    if($me->{params}->{irange}->[0] == $me->{params}->{irange}->[1]  and
       (defined($me->{params}->{irange}->[0]) && defined($me->{params}->{irange}->[1]))) {
	die "t_pc: 'domain' or 'irange' parameter must specify a nonempty range";
    }


    # Check the RGB recombination parameter
    if($mod_combo) {
	die "t_pc / t_pcp: can't specify RGB combinatorics in both parameters and table\n  suffix at the same time" if(	$me->{params}->{combination} );
	$me->{params}->{combination} = $mod_combo;
    }


    if($me->{params}->{combination} < 0 || $me->{params}->{combination} > 5) {
	die "t_pc/t_pcp: 'combination' parameter must be between 0 and 5 inclusive";
    }

    # Copy the conversion subs from the map table entry to the object, with combinatorics as
    # needed.

    if($me->{params}->{lut}->{type} eq 'hsv') {

	# hsv - copy subs in from table, and implement combinatorics with a hue transform

	$me->{params}->{subs} = [  @{$me->{params}->{lut}->{subs}}  ]; # copy the subs for the map
	if($me->{params}->{combination}) {
	    my $s0 = $me->{params}->{subs}->[0];
	    $me->{params}->{subs}->[0] =
		sub {
		    my $a = &$s0(@_);
		    $a += 0.33 * $me->{params}->{combination};
		    $a *= -1 if($me->{params}->{combination} > 2);
		    $a .= $a % 1;
		    return $a;
	    };
	} # end of 'combination' handler for hsv
    } else {

	# rgb - do any combinatorics as needed
	$me->{params}->{subs} = [ @{$me->{params}->{lut}->{subs}}[ (@{  $_t_pc_combinatorics[$me->{params}->{combination}] })  ]  ];

    }

    # Generate the forward transform
    $me->{func} = sub {
	my($in,$opt) = @_;

	my $in2 = $in->new_or_inplace;

	my ($min,$max) = @{$opt->{irange}};

	unless(defined($min) || defined($max)) {
	    ($min,$max) = $in->minmax;
	} elsif( !defined($min) ){
	    $min = $in->min;
	} elsif( !defined($max) ) {
	    $max = $in->max;
	}

	if($min==$max || !isfinite($min) || !isfinite($max)) {
	    die "t_pc transformation: range is zero or infinite ($min to $max)!  Giving up!";
	}

	# Translate to (0,1)
	$in2 -= $min;
	$in2 /= $max;

	my $split = 0;
	# Deal with split color tables
	if($opt->{lut}->{split}) {
	    $split = $opt->{lut}->{split};
	    $in2 -= $split;
	    if($split==0.5) {
		$in2 *= 2;
	    } else {
		$in2->where($in2<0) /= $split;
		$in2->where($in2>0) /= (1.0-$split);
	    }
	}

	# Default to sRGB coding for perceptual curves
	if($opt->{lut}->{phot} && $opt->{perceptual}) {
	    rgb_to_linear($in2->inplace, -1);
	    $in2->set_inplace(0); # needed as bug in PDL <2.082
	}

	if($opt->{clip}) {
	    if($split) {
		$in2->inplace->clip( -1,1 );
	    } else {
		$in2->inplace->clip(0,1);
	    }
	}

	if(defined($opt->{lut}->{igamma})) {
	    $in2 *= ($in2->abs+1e-10) ** ($opt->{lut}->{igamma} - 1);
	}

	if($split) {
	    if($split==0.5) {
		$in2 /=2;
	    } else {
		$in2->where($in2<0) *= $split;
		$in2->where($in2>0) *= (1.0-$split);
		$in2 += $split;
	    }
	    $in2 += $split;

	    if($opt->{clip}) {
		$in2->clip(0,1);
	    }
	}

	# apply the transform
	my $out = zeroes(3,$in2->dims);

	## These are the actual transforms.  They're figured by the constructor,
	## which does any combinatorics in setting up the subs.
	$out->slice('(0)') .= $opt->{subs}->[0]->($in2)->clip(0,1);
	$out->slice('(1)') .= $opt->{subs}->[1]->($in2)->clip(0,1);
	$out->slice('(2)') .= $opt->{subs}->[2]->($in2)->clip(0,1);

	if(defined($opt->{lut}->{ogamma})) {
	    $out *= ($out->abs) ** ($opt->{lut}->{ogamma}-1);
	}
	return $out;
    };

    my $out = $me;

    if($me->{params}->{lut}->{type} eq 'hsv') {
	$out = (!t_hsv()) x $out;
    }

    if(abs($me->{params}->{gamma}-1.0) > 1e-5) {
	$out = $out x t_gamma($me->{params}->{gamma});
    }

    unless($me->{params}->{lsRGB}) {
	$out = t_srgb(clip=>$me->{params}->{clip}, byte=>$me->{params}->{byte}) x $out;
    }

    return $out;
}

################################################################################
################################################################################



##############################

=head2 t_cieXYZ, t_xyz

=for ref

The C<t_cieXYZ> transform (also C<t_xyz>, which is a synonym)
converts the module-native lsRGB to the CIE XYZ representation.  CIE
XYZ is a nonphysical RGB-style system that minimally represents every
physical color it is possible for humans to perceive in steady
illumination.  It is related to sRGB by a linear transformation
(i.e. matrix multiplication) and forms the basis of many other color
systems (such as CIE xyY).

CIE XYZ values are defined in such a way that they are positive
definite for all human-perceptible colors, at the cost that the
primaries are nonphysical (they correspond to no possible spectral
color)

C<t_ciexyz> accepts the following options:

=over 3

=item gamma (default 1)

This is taken to be a coded gamma value in the original lsRGB, which
is decoded before conversion to the CIE XYZ system.

=item rgb_system (default undef)

If present, this must be either the name of an RGB system or an RGB system
descriptor hash as described in C<t_shift_rgb>.  If none is specified, then
the standard linearized sRGB used by the rest of the module is assumed.

=item use_system_gamma (default 0)

If this flag is set, and C<rgb_system> is set also, then the RGB side
of the transform is taken to be gamma-encoded with the default value for
that RGB system.  Unless you explicitly specify an RGB system (with a name
or a hash), this flag is ignored.

=back

=cut


*t_cieXYZ = \&t_xyz;

sub _M_relativise {
  my ($M, $w) = @_;
  my $Minv = $M->inv;
  my $XYZw = xyY_to_xyz($w);
  my $Srgb = ($Minv x $XYZw->slice('*1'))->slice('(0)'); # row vector
  $M * $Srgb;
}

sub t_xyz {
    my ($me) = _new(@_, 'CIE XYZ',
		    {gamma=>1,
		     rgb_system=>undef,
		     use_system_gamma=>0
		    }
	);

    # shortcut the common case
    unless(defined($me->{params}->{rgb_system})) {

	$me->{params}->{mat} = $srgb2cxyz_mat;
	$me->{params}->{inv} = $srgb2cxyz_inv;

    } else {
	my $rgb = get_rgb($me->{params}{rgb_system});
	my $M = _M_relativise(xyY_to_xyz(pdl(@$rgb{qw(r g b)}))->transpose, $rgb->{w});
	@{$me->{params}}{qw(mat inv)} = ($M, $M->inv);
	$me->{params}{gamma} = $rgb->{gamma} if $me->{params}{use_system_gamma};
    }

    # func and inv get linearized versions (gamma handled below)
    $me->{func} = sub {
	my($in, $opt) = @_;

	my $out = ( $opt->{mat} x $in->slice('*1') )->slice('(0)')->sever;

	if($in->is_inplace) {
	    $in .= $out;
	    $out = $in;
	}
	return $out;
    };

    $me->{inv} = sub {
	my($in, $opt) = @_;
	my $out = ( $opt->{inv} x $in->slice('*1') )->slice('(0)')->sever;

	if($in->is_inplace) {
	    $in .= $out;
	    $out = $in;
	}
	return $out;
    };

    return gammify($me);
}



=head2 t_rgi

=for ref

Convert RGB to RG chroma with a separate intensity channel.

Note that intensity is just the average of the R, G, and B values.
If you want perceptible luminance, use t_rgl or t_ycbcr instead.

=cut

sub t_rgi {
    my($me) = _new(@_, 'RGI',
		   {gamma=>1,
		   }
	);

    $me->{func} = sub {
	my($in,$opt) = @_;
	my $i = $in->sumover->slice('*1');
	my $out = zeroes($in);
	$out->slice('0:1') .= $in->slice('0:1') / ($i+($i==0));
	$out->slice('2') .= $i/3;
	if($in->is_inplace) {
	    $in .= $out;
	    return $in;
	}
	return $out;
    };
    $me->{inv} = sub {
	my($in,$opt) = @_;
	my $out = zeroes($in);
	$out->slice('0:1') .= $in->slice('0:1');
	$out->slice('(2)') .= 1 - $in->slice('0:1')->sumover;
	$out *= $in->slice('2') * 3;
	if($in->is_inplace) {
	    $in .= $out;
	    return $in;
	}
	return $out;
    };

    return $me;
}



=head2 t_xyy and t_xyY

=for ref

Convert from sRGB to CIE xyY.  The C<xyY> system is part of the CIE
1931 color specification.  Luminance is in the 2 coordinate, and
chrominance x and y are in the 0 and 1 coordinates.

This is the coordinate system in which "chromaticity diagrams" are
plotted.  It is capable of representing every illuminant color that
can be perceived by the typical human eye, and also many that can't,
with positive-definite coordinates.

Most of the domain space (which runs over [0-1] in all three dimensions)
is inaccessible to most displays, because RGB gamuts are generally
smaller than the actual visual gamut, which in turn is a subset of the
actual xyY data space.

=cut

*t_xyY = \&t_xyy;

sub t_xyy {
    my ($me) = _new(@_, 'CIE xyY',
		    {gamma=>1,
		    }
	);

    $me->{func} = sub {
	my($XYZ, $opt) = @_;
	my $out = $XYZ/$XYZ->sumover->slice('*1');
	$out->slice('(2)') .= $XYZ->slice('(1)');
	if($XYZ->is_inplace) {
	    $XYZ .= $out;
	    $out = $XYZ;
	}
	return $out;
    };

    $me->{inv} = sub {
	my($in,$opt) = @_;
	# make xYy
	my $XYZ = zeroes($in);

	# stuff X and Z in there.
	my $in1 = $in->slice('(1)')+($in->slice('(1)')==0);
	$XYZ->slice('(0)') .= $in->slice('(0)') * $in->slice('(2)') / $in1;
	$XYZ->slice('(1)') .= $in->slice('(2)');
	$XYZ->slice('(2)') .= $in->slice('(2)') * (1 - $in->slice('(0)') - $in->slice('(1)')) / $in1;

	if($in->is_inplace) {
	    $in .= $XYZ;
	    $XYZ = $in;
	}
	return $XYZ;
    };
    return gammify( $me x t_xyz() );
}


######################################################################

=head2 t_cielab or t_lab

=for usage

    $t = t_cielab();

=for ref

Convert RGB to CIE Lab colors.  C<Lab> stands for Lightness,
"a", and "b", representing the overall luminance detection and
two opponent systems (a: red/green, and b:yellow/blue) in the human
eye.  Lab colors are approximately perceptually uniform:  they're
mapped using a nonlinear transformation involving cube roots.  Lab
has the property that Euclidean distances of equal size in the space
yield approximately equal perceptual shifts in the represented color.

Lightness runs 0-100, and the a and b opponent systems run -100 to +100.

The Lab space includes the entire CIE XYZ gamut and many "impossible colors".
that cannot be represented directly with physical light.  Many of these
"impossible colors" (also "chimeric colors") can be experienced directly
using visual fatigue effects, and can be classified using Lab.

Lab is easiest to convert directly from XYZ space, so the C<t_lab> constructor
returns a compound transform of C<t_xyz2lab> and C<t_xyz>.

=head2 t_xyz2lab

=for usage

    $t = t_xyz2lab();

=for ref

Converts CIE XYZ to CIE Lab.

=cut

sub t_xyz2lab {

    my ($me) = _new(@_,'XYZ->Lab',
		    {
			white=>"D65",
		    }
	);

    # get and store illuminant XYZ
    my $wp_xyy = xyy_from_illuminant($me->{params}{white});
    $me->{params}{wp_xy} = $wp_xyy->slice('0:1')->sever;
    # input is XYZ by the time it gets here
    $me->{func} = sub {
	my($in,$opt) = @_;
	my $out = xyz_to_lab($in, {white_point=>$me->{params}{wp_xy}});
	if($in->is_inplace) {
	    $in .= $out;
	    $out = $in;
	}
	return $out;
    };

    $me->{inv} = sub {
	my($in,$opt) = @_;
	my $out = lab_to_xyz($in, {white_point=>$me->{params}{wp_xy}});
	if($in->is_inplace) {
	    $in .= $out;
	    $out = $in;
	}
	return $out;
    };

    return $me;
}



sub t_lab {
    my ($me) = _new(@_, 'Lab',
		    {
			gamma => 1.0,
			white=>'D65',
		    }
	);
    return (
	t_xyz2lab(white=>$me->{params}->{white} )  x
	t_xyz( gamma=>$me->{params}->{gamma})
	);
}


=head2 t_cmyk

converts rgb to cmyk in the most straightforward way (by subtracting
RGB values from unity).

CMYK and other process spaces are very complicated; this transform
presents only a relatively simple conversion that does not take into
account ink gamut variation or many other effects.

There *is* a provision for halftone gamma correction: "htgamma", which
works exactly like the rgb gamma correction but is applied to the CMYK
output.

Options:

=over 3

=item gamma (default 1)

The standard gamma affecting the RGB cube

=item htgamma (default 1)

A "halftone gamma" that is suitable for non-wash output processes
such as halftoning. it acts on the CMYK values themselves.

=item byte (default 0)

If present, the CMYK side is scaled to 0-255 and converted to a byte type.

=back

=cut
;
sub t_cmyk {
    my($me) = _new(@_, "CMYK",
		   {gamma=>1,
		    pigment=>0,
		    density=>2,
		    htgamma=>1,
		    clip=>0,
		    byte=>0
		   }
	);
    $me->{idim} = 3;
    $me->{odim} = 4;

    $me->{func} = sub {
	my($in,$opt) = @_;
	my $out = zeroes( 4, $in->slice('(0)')->dims );

	my $Kp = $in->maximum->slice('*1');
	(my $K = $out->slice('3')) .= 1 - $Kp;
	$out->slice('0:2') .= ($Kp - $in->slice('0:2')) / $Kp;
	$out->slice('(3)')->where($Kp==0) .= 1;
	$out->slice('0:2')->mv(0,-1)->where($Kp==0) .= 0;

	if(defined($opt->{htgamma}) && $opt->{htgamma} != 1) {
	    $out *= ($out->abs) ** ($opt->{htgamma} - 1);
	}

	if($opt->{clip}) {
	    $out->inplace->clip(0,1);
	}

	if($opt->{byte}) {
	    $out = (256*$out)->clip(0,255.99999);
	}
	return $out;
    };

    $me->{inv} = sub {
	my($in,$opt) = @_;
	my $out = zeroes( 3, $in->slice('(0)')->dims );

	$in = $in->new_or_inplace;

	if($opt->{byte}) {
	    $in = $in / pdl(256); # makes copy
	}

	if(defined($opt->{htgamma}) && $opt->{htgamma} != 1) {
	    $in *= ($in->abs) ** (1.0/$opt->{htgamma} - 1);
	}
	my $Kp = 1.0 - $in->slice('3');
	$out .= $Kp * ( 1 - $in->slice('0:2') );
	return $out;
    };

    return gammify($me);

}

=head2 t_hsl and t_hsv

=for usage

    $rgb = $hsl->invert($t_hsl());

=for ref

HSL stands for Hue, Saturation, Lightness.  It's not an absolute
color space, simply derived from each RGB (by default, linearized
sRGB).  it has the same gamut as the host RGB system.  The coordinates
are hexagonal on the (RYGCBM) hexagon, following the nearest face of
the (diagonally sliced) RGB cube.

HSL is a double-cone system, so iso-L surfaces are close to the plane
perpendicular to the double-diagonal white/illuminant line R=G=B.
This has the effect of reducing saturation at high lightness levels,
but maintains luminosity independent of saturation.  Maximum
saturation occurs when S=1 and L=0.5; at higher values of L, colors
grow less saturated and more pastel, so that L follows total
luminosity of the output.

HSV is a stacked-cone system: iso-V surfaces are parallel to the
bright faces of the RGB cube, so maximal bright saturation occurs when
S=1 and V=1.  This means that output luminosity drops with saturation,
but due to Helmholtz-Kolrausch effect (linking saturation to apparent
brightness) the I<perceived> brightness is less S-dependent: V follows
total I<apparent brightness> of the output, though output luminosity
drops with S.

You can represent out-of-gamut values in either system, by using
S values greater than unity, or "illegal" V or L values.

Hue, Saturation, and (Lightness or Value) each run from 0 to 1.

By default, the hue value follows a sin**4 scaling along each side of
the RYGCBM hexagon.  This softens the boundaries near the edges of the
RGB cube, giving a better peceptual "color-wheel" transition between
hues.  There is a flag to switch to the linear behavior described in,
e.g., the Wikipedia article on the HSV system.

You can encode the Lightness or Value with a gamma value ("lgamma") if
desired.

Options:

=over 3

=item gamma (default 1)

Treat the base RGB as gamma-encoded (default 1 is linear)

=item lgamma (default 1)

Treat the L coordinate as gamma-encoded (default 1 is linear).

=item hsv (default 0 if called as "t_hsl", 1 if called as "t_hsv")

Sets which of the HSL/HSV transform is to be used.

=item hue_linear (default 0)

This flag determines how the hue ("angle") is calculated.  By default,
a sin**4 scaling is used along each branch of the RYGCBM hexagon,
to soften the perceptual effects at the corners.  If you set this flag,
then the calculated "hue" is linear along each branch of the hexagon,
to match (e.g.) the Wikipedia definition.

=back

=cut

sub t_hsl {
    my($me) = _new(@_,"HSL",
		   {gamma=>1,
		    lgamma=>1,
		    hue_linear=>0,
		    hsv=>0
		   }
	);

    $me->{name} = "HSV" if($me->{params}->{hsv});

    $me->{func} = sub {
	my($in, $opt) = @_;
	my $out = zeroes($in);

	my $Cmax = $in->maximum;
	my $Cmin = $in->minimum;
	my $maxdex = $in->qsorti->slice('(2)')->sever;
	my $Delta = ( $Cmax - $Cmin );

	my $dexes = ($maxdex->slice('*1') + pdl(0,1,2)) % 3;

	my $H = $out->slice('(0)');

	if($opt->{hue_linear}) {
	    ## Old linear method
	 $H .= (
	    (($in->index1d($dexes->slice('1')) - $in->index1d($dexes->slice('2')))->slice('(0)')/($Delta+($Delta==0)))
		+ 2 * $dexes->slice('(0)')  ) ;

	 $H += 6*($H<0);
	 $H /= 6;
	} else {
	    ## New hotness: smooth transitions at corners
	    my $Hint = 2*$dexes->slice('(0)');
	    my $Hfrac = (($in->index1d($dexes->slice('1')) - $in->index1d($dexes->slice('2')))->slice('(0)')/($Delta+($Delta==0)));
	    my $Hfs = -1*($Hfrac<0) + ($Hfrac >= 0);
	    $Hfrac .= $Hfs * (    asin(  ($Hfrac->abs) ** 0.25  ) * 2/$PI    );
	    $H .= $Hint + $Hfrac;
	    $H /= 6;
	}

	$H += ($H<0);

	# Lightness and Saturation
	my $L = $out->slice('(2)');
	if($opt->{hsv}) {
	    $L .= $Cmax;
	    $out->slice('(1)') .= $Delta / ($L + ($L==0));
	} else {
	    $L .= ($Cmax + $Cmin)/2;
	    $out->slice('(1)') .= $Delta / (1 - (2*$L-1)->abs + (($L==0) | ($L==1)));
	}


	if( $opt->{lgamma} != 1 ){
	    $L .= $L * (($L->abs + ($L==0)) ** (1.0/$opt->{lgamma} - 1));
	}

	if($in->is_inplace) {
	    $in .= $out;
	    $out = $in;
	}
	return $out;
    };

    $me->{inv} = sub {
	my($in,$opt) = @_;

	my $H = $in->slice('(0)')*6;
	my $S = $in->slice('(1)');
	my $L = $in->slice('(2)');

	if($opt->{lgamma} != 1) {
	    $L = $L * (($L->abs + ($L==0)) ** ($opt->{lgamma}-1));
	}

	my $ZCX = zeroes($in);
	my $C = $ZCX->slice('(1)');
	my $m;
	if($opt->{hsv}) {
	    $C .= $L * $S;
	    $m = $L - $C;
	} else {
	    $C .= (1 - (2*$L - 1)->abs) * $S;
	    $m = $L - $C/2;
	}

	if($opt->{hue_linear}){
	    ## Old linear method
	    $ZCX->slice('(2)') .= $C * (1 - ($H % 2 - 1)->abs);
	} else {
	    ## New hotness: smooth transitions at corners.
	    $ZCX->slice('(2)') .= $C * sin($PI/2 * (1 - ($H % 2 - 1)->abs))**4;
	}

	my $dexes = pdl( [1,2,0], [2,1,0], [0,1,2], [0,2,1], [2,0,1], [1,0,2] )->mv(1,0)->sever;
	my $dex = $dexes->index1d($H->floor->slice('*1,*1') % 6)->slice('(0)')->sever; # 3x(threads)
	my $out = $ZCX->index1d($dex)->sever + $m->slice('*1');

	if($in->is_inplace) {
	    $in .= $out;
	    $out = $in;
	}

	return $out;
    };

    return gammify($me);
}


sub t_hsv {
        my($me) = _new(@_,"HSL",
		   {gamma=>1,
		    lgamma=>1,
		    hsv=>1
		   }
	);
	return t_hsl(%{$me->{params}});
}



=head2 t_shift_illuminant

=for ref

C<t_new_illuminant> shifts a color from an old RGB system to a new one
with a different white point.  It accepts either a PDL containing a
CIE xyY representation of the new illuminant, or a name of the new illuminant,
and some options.

Because this is shifting RGB to RGB in the same representation, gamma
transformations get re-encoded afterward: if you use, for example,
C<< gamma=>2 >>, then the RGB values are squared, then transformed, then
square-rooted.

Options are:

=over 3

=item gamma (default=1)

If present, this is the gamma coefficient for the representation of
both the source and destination RGB spaces.

=item from (default="D65")

If present, this is the xyY or name of the OLD illuminant.  The default
is D65, the illuminant for sRGB (and therefore lsRGB as well).

=item basis (default="sRGB")

If present, this needs to be either "sRGB" or "XYZ" (case insensitive).
If it's sRGB, the input and output are treated as standard lsRGB coordinates.
If it's XYZ, then the input and output are in CIE XYZ coordinates.

=item method (default="Bradford")

This can be "Bradford", "Von Kries", "XYZ", or a 3x3 matrix Ma (see
C<http://www.brucelindbloom.com/index.html?WorkingSpaceInfo.html>)

=back

=cut

sub t_shift_illuminant {
    my $new_illuminant = shift;
    my($me) = _new(@_, 'New illuminant',
		   {gamma =>1,
		    from => "D65",
		    basis => 'rgb',
		    method=>"Bradford"
		   }
	);

    unless(UNIVERSAL::isa($new_illuminant, 'PDL')) {
	$new_illuminant = xyy_from_illuminant($new_illuminant);
    }
    unless(UNIVERSAL::isa($me->{params}->{from}, 'PDL')) {
	$me->{params}->{from} = xyy_from_illuminant($me->{params}->{from});
    }
    $me->{params}->{to} = $new_illuminant;

    if(UNIVERSAL::isa($me->{params}->{method},"PDL")) {
	if($me->{params}->{method}->ndims==2 &&
	   $me->{params}->{method}->dim(0)==3 &&
	   $me->{params}->{method}->dim(1)==3) {
	    $me->{params}->{Ma} = $me->{params}->{method}->copy;
	} else {
	    die "t_new_illuminant: method must be a 3x3 matrix or {Bradford|Von Kries|XYZ}";
	}
    } elsif( $me->{params}->{method} =~ m/^B/i || length($me->{params}->{method})==0) {
	# Bradford
	$me->{params}->{Ma} = pdl( [  0.8951000,  0.2664000, -0.1614000 ],
				   [ -0.7502000,  1.7135000,  0.0367000 ],
				   [  0.0389000, -0.0685000,  1.0296000 ]
	    );
    } elsif($me->{params}->{method} =~ m/^[VK]/i) {
	# von Kries or Kries
	$me->{params}->{Ma} = pdl( [  0.4002400,  0.7076000, -0.0808100 ],
				   [ -0.2263000,  1.1653200,  0.0457000 ],
				   [  0.0000000,  0.0000000,  0.9182200 ]
	    );
    } elsif($me->{params}->{method} =~ m/^[XC]/i) {
	# XYZ or CIE
	$me->{params}->{Ma} = pdl( [1, 0, 0], [0, 1, 0], [0, 0, 1] );
    } else {
	print "Unknown method '$me->{params}->{method}'\n";
    }

    $me->{params}->{Ma_inv} = $me->{params}->{Ma}->inv;

    $me->{func} = sub {
	my($in, $opt) = @_;
	my $rhgabe_fr = ( $opt->{Ma} x $opt->{from}->slice('*1') )->slice('(0)')->sever;
	my $rhgabe_to = ( $opt->{Ma} x $opt->{to}  ->slice('*1') )->slice('(0)')->sever;
	my $M = $opt->{Ma_inv} x ( ( $rhgabe_to / $rhgabe_fr )->slice('*1') * $opt->{Ma} );

	if($opt->{basis} =~ m/^X/i) {
	    return  ((  $M x $in->slice('*1') )->slice('(0)')->sever);
	} else {
	    return  ((  ( $srgb2cxyz_inv x $M x $srgb2cxyz_mat ) x $in->slice('*1')  )->slice('(0)')->sever);
	}

    };

    $me->{inv} = sub {
	my($in, $opt) = @_;
	my $rhgabe_fr = ( $opt->{Ma} x $opt->{from}->slice('*1') )->slice('(0)')->sever;
	my $rhgabe_to = ( $opt->{Ma} x $opt->{to}  ->slice('*1') )->slice('(0)')->sever;
	my $M = $opt->{Ma_inv} x ( ( $rhgabe_fr / $rhgabe_to )->slice('*1') * $opt->{Ma} );

	if($opt->{basis} =~ m/^X/i) {
	    return (( $M x $in->slice('*1')  )->slice('(0)')->sever);
	} else {
	    return (( ( $srgb2cxyz_inv x $M x $srgb2cxyz_mat ) x $in->slice('*1')  )->slice('(0)')->sever);
	}
    };

    return $me if ($me->{params}{gamma} // 1) == 1;
    return t_gamma(1.0/$me->{params}->{gamma}) x $me x t_gamma($me->{params}->{gamma});
}

=head2 t_shift_rgb

=for usage

  $t = t_shift_rgb("NTSC",{from=>"sRGB"});

=for ref

Shifts the primary color basis of the lsrgb TO the destination system.
Most named RGB systems have an associated preferred gamma, but that is
ignored by default: the RGB values are treated as if they are all
linear representations.  You can specify EITHER the name of the system
OR the specific RGB parameters for that system.

The RGB parameters, if you specify them, need to be in the form of a
hash ref.  The hash keys should be the same as would be returned by
C<PDL::Transform::Color::get_rgb>.  All the keys must be present,
except for gamma (which is ignored).

Alternatively, you can use the name of a known system.  These are listed in the
documentation for C<PDL::Transform::Color::get_rgb>.

C<t_shift_rgb> takes several options.

=over 3

=item gamma (default 1)

The input triplets are assumed to be encoded with this gamma function.
The default assumes linear representation.

=item ogamma (default gamma)

The output triplets are assumed to need encoding with this gamma function.

=item use_system_gammas (default 0)

This overrides the settings of "gamma" and "ogamma", and
encodes/decodes according to the original system.

=item wp_method (default undef)

This is the whitepoint shift method used to change illuminant value between
systems with different whitepoints.  See C<t_shift_illuminant> for an
explanation.

=item from (default "sRGB")

This is the RGB system to convert from, in the same format as the
system to convert to (names or a hash ref as described).

=back

=cut

sub t_shift_rgb {
    my $new_rgb = shift;
    my($me) = _new(@_, 'New RGB system',
		   {gamma =>1,
		    ogamma=>undef,
		    use_system_gammas=>0,
		    wp_method=>undef,
		    from=>"sRGB"
		   }
	);


    my $to_rgb   = get_rgb($new_rgb);
    my $from_rgb = get_rgb($me->{params}->{from});

    my ($from_gamma, $to_gamma);
    if($me->{params}->{use_system_gammas}) {
	$from_gamma = $me->{params}->{from_rgb}->{gamma};
	$to_gamma   = $me->{params}->{to_rgb}->{gamma};
    } else {
	$from_gamma = $me->{params}->{gamma};
	$to_gamma   = $me->{params}->{ogamma};
	$to_gamma   = $me->{params}->{gamma} if !defined $to_gamma;
    }

    my $out =
	!t_xyz(rgb_system=>$to_rgb, gamma=>$me->{params}->{gamma}, use_system_gamma=>$me->{params}->{use_system_gamma}) x
	t_shift_illuminant($to_rgb->{w},basis=>"XYZ",from=>$from_rgb->{w},method=>$me->{params}->{wp_method}) x
	t_xyz(rgb_system=>$from_rgb, gamma=>$me->{params}->{gamma}, use_system_gamma=>$me->{params}->{use_system_gamma});

    return $out;

}

##############################
# Reference illuminants
# (aka "white points")

=head2 PDL::Transform::Color::xyy_from_D

=for usage

     $xyy = PDL::Transform::Color::xyy_from_D($D_value)

=for ref

This utility routine generates CIE xyY system colorimetric values for
standard CIE D-class illuminants (e.g., D50 or D65).  The illuminants are
calculated from a standard formula and correspond to black body
temperatures between 4,000K and 250,000K.  The D value is the
temperature in K divided by 100, e.g. broad daylight is D65,
corresponding to 6500 Kelvin.

This is used for calculating standard reference illuminants, to convert
RGB values between illuminants.

For example, sRGB uses a D65 illuminant, but many other color standards
refer to a D50 illuminant.

The colorimetric values are xy only; the Y coordinate can be specified via
an option, or defaults to 0.5.

This routine is mainly used by C<xyy_from_illuminant>, which handles most
of the CIE-recognized standard illuminant sources including the D's.

See C<t_xyy> for a description of the CIE xyY absolute colorimetric system.

C<xyy_from_D> accepts the following options:

=over 3

=item Y - the Y value of the output xyY coordinate

=back

=cut

sub xyy_from_D {
    my $D = pdl(shift);
    my $u_opt = shift || {};
    my %opt = parse({
	Y=>1
		    },
	$u_opt);

    die "cie_xy_from_D: D must be between 40 and 250" if(any($D< 40) || any($D > 250));
    my $T = $D*100 * 1.4388/1.438; # adjust for 6504K not 6500K

    my $Xd;
    $Xd = ($D<=70) * ( 0.244063 + 0.09911e3/$T + 2.9678e6/$T/$T - 4.6070e9/$T/$T/$T ) +
	  ($D> 70) * ( 0.237040 + 0.24748e3/$T + 1.9018e6/$T/$T - 2.0064e9/$T/$T/$T );

    return pdl( $Xd, -3*$Xd*$Xd + 2.870*$Xd - 0.275, $opt{Y} )->mv(-1,0)->sever;
}

# xy data for FL3.x standards, from CIE "Colorimetry" 3rd edition Table T.8.2
my $fl3tab = [
    [],
    [0.4407, 0.4033],
    [0.3808, 0.3734],
    [0.3153, 0.3439],
    [0.4429, 0.4043],
    [0.3749, 0.3672],
    [0.3488, 0.3600],
    [0.4384, 0.4045],
    [0.3820, 0.3832],
    [0.3499, 0.3591],
    [0.3455, 0.3460],
    [0.3245, 0.3434],
    [0.4377, 0.4037],
    [0.3830, 0.3724],
    [0.3447, 0.3609],
    [0.3127, 0.3288]
    ];
# xy data for FLx standards, from CIE "Colorimetry" 3rd edition Table T.7
my $fltab = [
    [],
    [0.3131, 0.3371],
    [0.3721, 0.3751],
    [0.4091, 0.3941],
    [0.4402, 0.4031],
    [0.3138, 0.3452],
    [0.3779, 0.3882],
    [0.3129, 0.3292],
    [0.3458, 0.3586],
    [0.3741, 0.3727],
    [0.3458, 0.3588],
    [0.3805, 0.3769],
    [0.4370, 0.4042]
    ];
# xy data for HPx standards, from CIE "Colorimetry" 3rd edition table T.9
my $hptab = [
    [],
    [0.5330, 0.4150],
    [0.4778, 0.4158],
    [0.4302, 0.4075],
    [0.3812, 0.3797],
    [0.3776, 0.3713]
    ];



=head2 PDL::Transform::Color::xyy_from_illuminant

=for usage

     $xyy = PDL::Transform::Color::xyy_from_illuminant($name)

=for ref

This utility routine generates CIE xyY system colorimetric values for
all of the standard CIE illuminants.  The illuminants are looked up in
a table populated from the CIE publication I<Colorimetry>, 3rd
edition.

The illuminant of a system is equivalent to its white point -- it is
the location in xyY absolute colorimetric space that corresponds to
"white".

CIE recognizes many standard illuminants, and (as of 2017) is in the
process of creating a new set -- the "L" series illuminants -- that is
meant to represent LED lighting.

Proper treatment of an illuminant requires a full spectral representation,
which the CIE specifies for each illuminant.  Analysis of that spectrum is
a major part of what CIE calls "Color rendering index (CRI)" for a particular
light source.  PDL::Transform::Color is a strictly tri-coordinate system
and does not handle the nuances of spectral effects on CRI.  In effect,
all illuminants are treated as having a CRI of unity (perfect).

Illuminants that are understood are:

=over 3

=item * a 3-PDL in CIE xyY coordinates

=item * a CIE standard name

=back

The CIE names are:

=over 3

=item A - a gas-filled tungsten filament lamp at 2856K

=item B - not supported (deprecated by CIE)

=item C - early daylight simulant, replaced by the D[n] sources

=item D[n] - Blackbody radiation at 100[n] Kelvin (e.g. D65)

=item F[n] - Fluorescent lights of various types (n=1-12 or 3.1-3.15)

=item HP[n] - High Pressure discharge lamps (n=1-5)

=item L[n] - LED lighting (not yet supported)

=back

=cut

sub xyy_from_illuminant {
    my $name = shift;
    if(UNIVERSAL::isa($name,"PDL")) {
	if(($name->nelem==2 || $name->nelem==3) && $name->dim(0)==$name->nelem) {
	    return $name;
	} else {
	    die "xyy_from_illuminant:  PDL must be a 2-PDL or a 3-PDL";
	}
    }
    my $u_opt = shift || {};
    my %opt = parse({
	Y=>1
		    }, $u_opt);
    if($name =~ m/^A/i) {
	return pdl(0.44758, 0.40745, $opt{Y});
    } elsif($name =~ m/^B/) {
	die "Illuminant B is not supported (deprecated by CIE)";
    } elsif($name =~ m/^C/) {
	return pdl(0.31006, 0.31616, $opt{Y});
    } elsif( $name =~ m/^D(.*)$/i) {
	return xyy_from_D($1,$u_opt);
    } elsif( $name =~ m/^E/i) {
	return pdl(0.33333,0.33333,$opt{Y});
    } elsif( $name =~ m/^FL?([\d+])(\.[\d])?$/i) {
	my $flno = $1+0;
	my $flsubno = $2+0;
	die "Illuminant $name not recognized (FL1-FL12, or FL3.1-FL3.15)"
	    if($flno < 1 || $flno > 12 ||
	       ($flsubno && $flno != 3) ||
	       ($flsubno > 15)
	    );

	if($flno==3 && $flsubno) {
	    return pdl(@{$fl3tab->[$flsubno]},$opt{Y});
	} else {
	    return pdl(@{$fltab->[$flno]},$opt{Y});
	}
    } elsif( $name =~ m/^HP?(\d)/i ) {
	my $hpno = $1+0;
	die "Unknown HP illuminant no. $hpno" if($hpno<1 || $hpno > 5);
	return pdl(@{$hptab->[$hpno]}, $opt{Y});
    } elsif( $name =~ m/^L/i) {
	die "Illuminant L is not (yet) supported";
    } else {
	die "Unknown illuminant $name";
    }
}


##############################
# Database of standard RGB color systems from Bruce Lindbloom
# Make a database of xyY values of primaries, illuminants, and standard gammas for common RGB systems
# Also stash matrices for converting those systems to lsRGB.
#
# Columns:  gamma, illuminant, xyY for R (3 cols), xyY for G (3 cols), xyY for B (3 cols), abbrev char count
our $rgbtab_src = {
    "Adobe"        => [2.2, "D65", 0.6400, 0.3300, 0.297361, 0.2100, 0.7100, 0.627355, 0.1500, 0.0600, 0.075285, 2],
    "Apple"        => [1.8, "D65", 0.6250, 0.3400, 0.244634, 0.2800, 0.5950, 0.672034, 0.1550, 0.0700, 0.083332, 2],
    "Best"         => [2.2, "D50", 0.7347, 0.2653, 0.228457, 0.2150, 0.7750, 0.737352, 0.1300, 0.0350, 0.034191, 3],
    "Beta"         => [2.2, "D50", 0.6888, 0.3112, 0.303273, 0.1986, 0.7551, 0.663786, 0.1265, 0.0352, 0.032941, 3],
    "Bruce"        => [2.2, "D65", 0.6400, 0.3300, 0.240995, 0.2800, 0.6500, 0.683554, 0.1500, 0.0600, 0.075452, 2],
    "BT 601"       => [2.2, "D65", 0.6300, 0.3400, 0.299000, 0.3100, 0.5950, 0.587000, 0.1550, 0.0700, 0.114000, 3],
    "BT 709"       => [2.2, "D65", 0.6300, 0.3400, 0.212600, 0.3100, 0.5950, 0.715200, 0.1550, 0.0700, 0.072200, 3],
    "CIE"          => [2.2, "E",   0.7350, 0.2650, 0.176204, 0.2740, 0.7170, 0.812985, 0.1670, 0.0090, 0.010811, 2],
    "ColorMatch"   => [1.8, "D50", 0.6300, 0.3400, 0.274884, 0.2950, 0.6050, 0.658132, 0.1500, 0.0750, 0.066985, 2],
    "Don 4"        => [2.2, "D50", 0.6960, 0.3000, 0.278350, 0.2150, 0.7650, 0.687970, 0.1300, 0.0350, 0.033680, 1],
    "ECI v2"       => [1.0, "D50", 0.6700, 0.3300, 0.320250, 0.2100, 0.7100, 0.602071, 0.1400, 0.0800, 0.077679, 2],
    "Ekta PS5"     => [2.2, "D50", 0.6950, 0.3050, 0.260629, 0.2600, 0.7000, 0.734946, 0.1100, 0.0050, 0.004425, 2],
    "NTSC"         => [2.2, "C",   0.6700, 0.3300, 0.298839, 0.2100, 0.7100, 0.586811, 0.1400, 0.0800, 0.114350, 1],
    "PAL"          => [2.2, "D65", 0.6400, 0.3300, 0.222021, 0.2900, 0.6000, 0.706645, 0.1500, 0.0600, 0.071334, 2],
    "ProPhoto"     => [1.8, "D50", 0.7347, 0.2653, 0.288040, 0.1596, 0.8404, 0.711874, 0.0366, 0.0001, 0.000086, 2],
    "SMPTE-C"      => [2.2, "D65", 0.6300, 0.3400, 0.212395, 0.3100, 0.5950, 0.701049, 0.1550, 0.0700, 0.086556, 2],
    "sRGB"         => [2.2, "D65", 0.6400, 0.3300, 0.212656, 0.3000, 0.6000, 0.715158, 0.1500, 0.0600, 0.072186, 2],
    "wgRGB"        => [2.2, "D50", 0.7350, 0.2650, 0.258187, 0.1150, 0.8260, 0.724938, 0.1570, 0.0180, 0.016875, 1]
};
$rgbtab_src->{SECAM} = $rgbtab_src->{PAL};
$rgbtab_src->{ROMM} = $rgbtab_src->{ProPhoto};

##############################
# RGB color systems in more code-approachable form.  Parse the table to create hash refs by name, and an
# abbrev table that allows abbreviated naming
#
our $rgbtab = {};
our $rgb_abbrevs = {};
for my $k(keys %$rgbtab_src) {
    my $v = $rgbtab_src->{$k};
    my $spec = $rgbtab->{$k} = {
	gamma  => $v->[0],
	w_name => $v->[1],
	w      => xyy_from_illuminant($v->[1]),
	r      => pdl(@$v[2..4]),
	g      => pdl(@$v[5..7]),
	b      => pdl(@$v[8..10])
    };
    $spec->{white_point} = $spec->{w}->slice('0:1'); # PGCS: xy only
    my $str = $k;
    $str =~ tr/A-Z/a-z/;
    $str =~ s/\s\-//g;
    for my $i($v->[11]..length($str)){
	$rgb_abbrevs->{substr($str,0,$i)} = $k;
    }
}

# Gets an rgb descriptor hash from an input that might be a hash or a name.
# If it's a hash, check to make sure it's copacetic.

=head2 PDL::Transform::Color::get_rgb

=for usage

    my $rgb_hash = get_rgb( $name );

=for ref

C<PDL::Transform::Color::get_rgb> is an internal routine that retrieves a set of
RGB primary colors from an internal database.  There are several named RGB systems,
with different primary colors for each.  The primary colors are represented as
CIE xyY values in a returned hash ref.

The return value is a hash ref with the following fields:

=over 3

=item gamma - the specified gamma of that RGB system (or 2.2, for sRGB)

=item w_name - the name of the illuminant / white-point for that system

=item w - the xyY value of the illuminant / white-point for that system

=item r - the xyY value of the red primary color at unit intensity

=item g - the xyY value of the green primary color at unit intensity

=item b - the xyY value of the blue primary color at unit intensity

=back

As of 1.007, because this module now uses L<PDL::Graphics::ColorSpace>
for some calculations, the hash ref will also include fields used by
that module.

Recognized RGB system names are:

=over 3

=item Adobe - Adobe's 1998 RGB, intended to encompass nearly all of the CMYK gamut (gamma=2.2, white=D65)

=item Apple - Apple's display standard from c. 1990 - c. 2010 (gamma=1.8, white=D65)

=item Best - Wide-gamut RGB developed by Don Hutcheson (L<www.hutchcolor.com>) (gamma=2.2, white=D50)

=item Beta - Bruce Lindbloom's optimized ultra-wide-gamut RGB (gamma=2.2, white=D50)

=item Bruce - Bruce Fraser's conservative-gamut RGB space for 8-bit editing (gamma=2.2, white=D65)

=item BT 601 - ITU-R standard BT.601 (used for MPEG & SDTV) (gamma=2.2, white=D65)

=item BT 709 - ITU-R standard BT.709 (used for HDTV) (gamma=2.2, white=D65)

=item CIE - CIE 1931 calibrated color space (based on physical emission lines) (gamma=2.2, white=E)

=item ColorMatch - quasi-standard from c.1990 -- matches Radius Pressview CRT monitors.  (gamma=1.8, white=D50)

=item Don 4 - wide-gamut D50 working space gets the Ektachrome color gamut (gamma=2.2, white=D50)

=item ECI v2 - RGB standard from the European Color Initiative (gamma=1, white=D50)

=item Ekta PS5 - developed by Joseph Holms (L<www.josephholmes.com>) for scanned Ektachrome slides (gamma=2.2, white=D50)

=item NTSC - National Television System Committee (U.S. analog TV standard) (gamma=2.2, white=C)

=item PAL - Phase Alternating Line (U.K. analog TV standard) (gamma = 2.2, white=D65)

=item ProPhoto - Wide gamut from Kodak, designed for photo output. (gamma=1.8, white=D60)

=item ROMM - Synonym for ProPhoto (gamma=1.8, white=D60)

=item SECAM - Séquentiel de Couleur À Mémoire (French analog TV standard) (gamma=2.2, white=D65)

=item SMPTE-C - Soc. Motion Pict. & TV Engineers (current U.S. TV standard) (gamma=2.2, white=D65)

=item sRGB - Standard for consumer computer monitors (gamma~2.2, white=D65)

=item wgRGB - Wide Gamut RGB (gamma=2.2, white=D50)

=back

=cut

sub get_rgb {
    my $new_rgb = shift;
    if (ref $new_rgb eq 'HASH') {
	for my $k (qw/w r g b/) {
	    die "Incorrect RGB primaries hash -- see docs" unless( defined($new_rgb->{$k}) and UNIVERSAL::isa($new_rgb->{$k},"PDL") and $new_rgb->{$k}->nelem==3 and $new_rgb->{$k}->dim(0)==3);
	}
	$new_rgb = { gamma=>1, %$new_rgb };
	$new_rgb->{white_point} = $new_rgb->{w}->slice('0:1') # PGCS: xy only
	  if !exists $new_rgb->{white_point};
	return $new_rgb;
    }
    die "bad RGB specification -- see docs" if ref $new_rgb;
    $new_rgb=~tr/A-Z/a-z/; $new_rgb =~ s/\s\-//g;
    die join "\n\t","Unknown RGB system '$new_rgb'\nKnown ones are:", (sort keys %$rgbtab),""
      if !($new_rgb = $rgbtab->{$rgb_abbrevs->{$new_rgb}});
    return $new_rgb;
}

=head1 AUTHOR

Copyright 2017, Craig DeForest (deforest@boulder.swri.edu).  This
module may be modified and distributed under the same terms as PDL
itself.  The module comes with NO WARRANTY.

=cut

1;
