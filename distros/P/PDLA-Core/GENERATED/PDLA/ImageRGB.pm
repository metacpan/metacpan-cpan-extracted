
#
# GENERATED WITH PDLA::PP! Don't modify!
#
package PDLA::ImageRGB;

@EXPORT_OK  = qw(  interlrgb rgbtogr bytescl cquant  PDLA::PP cquant_c );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDLA::Core;
use PDLA::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDLA::Exporter','DynaLoader' );
   push @PDLA::Core::PP, __PACKAGE__;
   bootstrap PDLA::ImageRGB ;





=head1 NAME

PDLA::ImageRGB -- some utility functions for RGB image data handling

=head1 DESCRIPTION

Collection of a few commonly used routines involved in handling of RGB, palette
and grayscale images. Not much more than a start. Should be a good place to
exercise some of the thread/map/clump PP stuff.

Other stuff that should/could go here:

=over 3

=item *
color space conversion

=item *
common image filters

=item *
image rebinning

=back

=head1 SYNOPSIS

 use PDLA::ImageRGB;

=cut


use vars qw( $typecheck $EPS );

use PDLA::Core;
use PDLA::Basic;
use PDLA::Primitive;
use PDLA::Types;

use Carp;
use strict 'vars';


$PDLA::ImageRGB::EPS = 1e-7;     # there is probably a more portable way

=head1 FUNCTIONS

=head2 cquant

=for ref

quantize and reduce colours in 8-bit images

=for usage

    ($out, $lut) = cquant($image [,$ncols]);

This function does color reduction for <=8bit displays and accepts 8bit RGB
and 8bit palette images. It does this through an interface to the ppm_quant
routine from the pbmplus package that implements the median cut routine which
intellegently selects the 'best' colors to represent your image on a <= 8bit
display (based on the median cut algorithm). Optional args: $ncols sets the
maximum nunmber of colours used for the output image (defaults to 256).
There are images where a different color
reduction scheme gives better results (it seems this is true for images
containing large areas with very smoothly changing colours).

Returns a list containing the new palette image (type PDLA_Byte) and the RGB
colormap.

=cut

# full threading support intended
*cquant = \&PDLA::cquant;
sub PDLA::cquant {
    barf 'Usage: ($out,$olut) = cquant($image[,$ncols])'
       if $#_<0 || $#_>1;
    my $image = shift;
    my $ncols;
    if ($#_ >= 0 ) { $ncols=shift; } else { $ncols = 256; };
    my @Dims = $image->dims;
    my ($out, $olut) = (null,null);

    barf "input must be byte (3,x,x)" if (@Dims < 2) || ($Dims[0] != 3)
	    || ($image->get_datatype != $PDLA_B);
    cquant_c($image,$out,$olut,$ncols);
    return ($out,$olut);
}


=head2 interlrgb

=for ref

Make an RGB image from a palette image and its lookup table.

=for usage

    $rgb = $palette_im->interlrgb($lut)

Input should be of an integer type and the lookup table (3,x,...). Will perform
the lookup for any N-dimensional input pdl (i.e. 0D, 1D, 2D, ...). Uses the
index command but will not dataflow by default. If you want it to dataflow the
dataflow_forward flag must be set in the $lut piddle (you can do that by saying
$lut->set_dataflow_f(1)).

=cut

# interlace a palette image, input as 8bit-image, RGB-lut (3,x,..) to
# (R,G,B) format for each pixel in the image
# should already support threading
*interlrgb=\&PDLA::interlrgb;
sub PDLA::interlrgb {
    my ($pdl,$lut) = @_;
    my $res;
    # for our purposes $lut should be (3,z) where z is the number
    # of colours in the lut
    barf "expecting (3,x) input" if ($lut->dims)[0] != 3;
    # do the conversion as an implicitly threaded index lookup
    if ($lut->fflows) {
      $res = $lut->xchg(0,1)->index($pdl->dummy(0));
    } else {
      $res = $lut->xchg(0,1)->index($pdl->dummy(0))->sever;
    }
    return $res;
}


=head2 rgbtogr

=for ref

Converts an RGB image to a grey scale using standard transform

=for usage

   $gr = $rgb->rgbtogr

Performs a conversion of an RGB input image (3,x,....) to a
greyscale image (x,.....) using standard formula:

   Grey = 0.301 R + 0.586 G + 0.113 B

=cut

# convert interlaced rgb image to grayscale
# will convert any (3,...) dim pdl, i.e. also single lines,
# stacks of RGB images, etc since implicit threading takes care of this
# should already support threading
*rgbtogr = \&PDLA::rgbtogr;
sub PDLA::rgbtogr {
    barf "Usage: \$im->rgbtogr" if $#_ < 0;
    my $im = shift;
    barf "rgbtogr: expecting RGB (3,...) input"
         if (($im->dims)[0] != 3);

    my $type = $im->get_datatype;
    my $rgb = float([77,150,29])/256;  # vector for rgb conversion
    my $oim = null;  # flag PP we want it to allocate
    inner($im,$rgb,$oim); # do the conversion as a threaded inner prod

    return $oim->convert($type);  # convert back to original type
}

=head2 bytescl

=for ref

Scales a pdl into a specified data range (default 0-255)

=for usage

	$scale = $im->bytescl([$top])

By default $top=255, otherwise you have to give the desired top value as an
argument to C<bytescl>. Normally C<bytescl> doesn't rescale data that fits
already in the bounds 0..$top (it only does the type conversion if required).
If you want to force it to rescale so that the max of the output is at $top and
the min at 0 you give a negative $top value to indicate this.

=cut

# scale any pdl linearly so that its data fits into the range
# 0<=x<=$ncols where $ncols<=255
# returns scaled data with type converted to byte
# doesn't rescale but just typecasts if data already fits into range, i.e.
# data ist not necessarily stretched to 0..$ncols
# needs some changes for full threading support ?? (explicit threading?)
*bytescl = \&PDLA::bytescl;
sub PDLA::bytescl {
    barf 'Usage: bytescl $im[,$top]' if $#_ < 0;
    my $pdl = shift;
    my ($top,$force) = (255,0);
    $top = shift if $#_ > -1;
    if ($top < 0) { $force=1; $top *= -1; }
    $top = 255 if $top > 255;

    print "bytescl: scaling from 0..$top\n" if $PDLA::debug;
    my ($max, $min);
    $max = max $pdl;
    $min = min $pdl;
    return byte $pdl if ($min >= 0  && $max <= $top && !$force);

    # check for pathological cases
    if (($max-$min) < $EPS) {
	print "bytescl: pathological case\n" if $PDLA::debug;
	return byte $pdl
	    if (abs($max) < $EPS) || ($max >= 0 && $max <= $top);
	return byte ($pdl/$max);
    }

    my $type = $pdl->get_datatype > $PDLA_F ? $PDLA_D : $PDLA_F;
    return byte ($top*($pdl->convert($type)-$min)/($max-$min)+0.5);
}

;# Exit with OK status

1;

=head1 BUGS

This package doesn't yet contain enough useful functions!

=head1 AUTHOR

Copyright 1997 Christian Soeller <c.soeller@auckland.ac.nz>
All rights reserved. There is no warranty. You are allowed
to redistribute this software / documentation under certain
conditions. For details, see the file COPYING in the PDLA
distribution. If this file is separated from the PDLA distribution,
the copyright notice should be included in the file.


=cut










*cquant_c = \&PDLA::cquant_c;



;



# Exit with OK status

1;

		   