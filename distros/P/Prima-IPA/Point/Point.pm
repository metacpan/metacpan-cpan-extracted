# $Id$
package Prima::IPA::Point;
use strict;
require Exporter;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter );
@EXPORT = qw();
@EXPORT_OK = qw(combine threshold gamma remap subtract mask equalize ab log exp average);
%EXPORT_TAGS = ();

# histogram equalization
sub equalize
{
   my $i = $_[0];
   my @h = Prima::IPA::Misc::histogram( $i);
   my $factor = 255 / ($i-> width * $i-> height);
   my @map;
   my $sum = 0;
   for (@h) {
       $sum += $_;
       my $v = $sum * $factor;
       push @map, ($v > 255) ? 255 : int($v); 
   }
   return Prima::IPA::Point::remap( $i, lookup => \@map);
}


1;

__DATA__

=pod

=head1 NAME

Prima::IPA::Point - single pixel transformations and image arithmetic

=head1 DESCRIPTION

Single-pixel processing is a simple method of image enhancement. 
This technique determines a pixel value in the enhanced image dependent only 
on the value of the corresponding pixel in the input image. 
The process can be described with the mapping function 

   s = M(r)

where C<r> and C<s> are the pixel values in the input and output images, respectively.

=over   

=item combine [ images, conversionType = conversionScale, combineType = combineSum, rawOutput = 0]

Combines set of images of same dimension and bit depth into one
and returns the resulting image. 

Supported types: Byte, Short, Long.

Parameters:

=over

=item images ARRAY

Array of image objects.

=item conversionType INTEGER

An integer constant, one of the following, that indicates how the
resulting image would be adjusted in accord to the minimal and maximal
values of the result. C<Trunc> constants cut off the output values to the 
bit maximum, for example, a result vector in 8-bit image [-5,0,100,300]
would be transformed to [0,0,100,255]. C<Scale> constants scale the whole
image without the cutoff; the previous example vector would be transformed
into [0,4,88,255]. The C<Abs> suffix shows whether the range calculation would
use the whole domain, including the negative values, or the absolute values
only.

   conversionTruncAbs
   conversionTrunc
   conversionScale
   conversionScaleAbs

Default is C<conversionScale>.

=item combineType INTEGER

An integer constant, indicates the type of action performed
between pixels of same [x,y] coordinates.

   combineMaxAbs          - store the maximal absolute pixel value
   combineSignedMaxAbs    - compute the maximal absolute value, but store its original ( before abs()) value
   combineSumAbs          - store the sum of absolute pixel values
   combineSum             - store the sum of pixel values
   combineSqrt            - store the square root of the sum of the squares of the pixel values

Default is C<combineSum>.

=item rawOutput BOOLEAN

Discards C<conversionType> parameter and performs no conversion.
If set to true value, the conversion step is omitted. 

Default is 0.

=back

=item threshold IMAGE [ minvalue, maxvalue = 255]

Performs the binary thresholding, governed by
C<minvalue> and C<maxvalue>.
The pixels, that are below C<minvalue> and above C<maxvalue>,
are mapped to value 0; the other values mapped to 255.

Supported types: Byte

=item gamma IMAGE [ origGamma = 1, destGamma = 1]

Performs gamma correction of IMAGE by a product of
C<origGamma> and C<destGamma>.

Supported types: Byte

=item remap IMAGE [ lookup ] 

Performs image mapping by a passed C<lookup> array
of 256 integer values. Example: 

   Prima::IPA::Point::remap( $i, lookup => [ (0) x 128, (255) x 127]);

is an equivalent of

   Prima::IPA::Point::threshold( $i, minvalue => 128);

Supported types: 8-bit

=item subtract IMAGE1, IMAGE2, [ conversionType = conversionScale, rawOutput = 0]

Subtracts IMAGE2 from IMAGE1. The images must be of same dimension.
For description of C<conversionType> and C<rawOutput> see L<combine>.

Supported types: Byte

=item mask IMAGE [ test, match, mismatch ]

Test every pixel of IMAGE whether it equals to C<test>, and
assigns the resulting pixel with either C<match> or C<mismatch> value.
All C<test>, C<match>, and C<mismatch> scalars can be either integers
( in which case C<mask> operator is similar to L<threshold> ),
or image objects. If the image objects passed, they must be of the same 
dimensions and bit depth as IMAGE.

Supported types: Byte, Short, Long.

=item average LIST

Combines images of same dimensions and bit depths, passed as an
anonymous array in LIST and returns the average image.

Supported types: Byte, Short, Long, 64-bit integer.

=item equalize IMAGE

Returns a histogram-equalized image.

Supported types: Byte

=item ab IMAGE, a, b

Returns C<IMAGE*a+b>.

=item exp IMAGE

Retuns C<exp(IMAGE)>

=item log IMAGE

Retuns C<log(IMAGE)>

=back

=cut
