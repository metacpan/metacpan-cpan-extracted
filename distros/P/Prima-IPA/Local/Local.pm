# $Id$
package Prima::IPA::Local;

use strict;
require Exporter;

use constant sobelColumn         => 1;
use constant sobelRow            => 2;
use constant sobelNWSE           => 4;
use constant sobelNESW           => 8;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(crispening 
                sobel 
                GEF 
                SDEF 
                deriche
                filter3x3 
                median 
                unionFind
		hysteresis
                gaussian
                laplacian
                gradients
                canny
                nms
                scale
                ridge
                convolution
                zerocross
               );
%EXPORT_TAGS = (enhancement => [qw(crispening)], 
                edgedetect => [qw(sobel GEF SDEF deriche hysteresis canny)]);

1;

__DATA__

=pod

=head1 NAME

Prima::IPA::Local - methods that produce images where every pixel is a function of pixels in the neighborhood

=head1 DESCRIPTION

Contains functions that operate in the vicinity of a pixel, and produce
image where every pixel is dependant on the values of the source pixel
and the values of its neighbors.
The process can be described with the mapping function 

         |r(i,j),r(i+1,j)...|
   s = M |...               |
         |r(j+1,i) ...      |

where C<r> and C<s> are the pixel values in the input and output images, respectively.

=over

=item crispening IMAGE

Applies the crispening algorithm to IMAGE and returns the result.

Supported types: Byte

=item sobel IMAGE [ jobMask = sobelNWSE|sobelNESW, conversionType = conversionScaleAbs, combineType = combineMaxAbs, divisor = 1]

Applies Sobel edge detector to IMAGE. 

Supported types: Byte

Parameters:

=over

=item jobMask INTEGER

Combination of the integer constants, that mask the pixels in Sobel 3x3 kernel.
If the kernel is to be drawn as

  | (-1,1) (0,1) (1,1) |
  | (-1,0) (0,0) (1,0) |
  | (-1,-1)(0,-1)(1,-1)|

Then the constants mask the following points:

   sobelRow      - (-1,0),(1,0)
   sobelColumn   - (0,1),(0,-1)
   sobelNESW     - (1,1),(-1,-1)
   sobelNWSE     - (-1,1),(1,-1)

(0,0) point is always masked.

=item divisor INTEGER 

The resulting pixel value is divided to C<divisor> value after the kernel convolution is applied.

=back

C<conversionType> and <combineType> parameters described in L<combine>.

=item GEF IMAGE [ a0 = 1.3, s = 0.7]

Applies GEF algorithm ( first derivative operator for symmetric exponential filter) to IMAGE.

Supported types: Byte

=item SDEF IMAGE [ a0 = 1.3, s = 0.7]

Applies SDEF algorithm ( second derivative operator for symmetric exponential filter) to IMAGE.

Supported types: Byte

=item deriche IMAGE [ alpha ]

Applies Deriche edge detector.

Supported types: Byte

=item filter3x3 IMAGE [ matrix, expandEdges = 0, edgecolor = 0, conversionType = conversionScaleAbs, rawOutput = 0, divisor = 1 ]

Applies convolution with a custom 3x3 kernel, passed in C<matrix>.

Supported types: Byte

Parameters:

=over

=item matrix ARRAY

Array of 9 integers, a 3x3 kernel, to be convoluted with IMAGE. Indexes are:

  |0 1 2|
  |3 4 5|
  |6 7 8|

=item expandEdges BOOLEAN

If false, the edge pixels ( borders ) not used in the convolution as center
pixels. If true, the edge pixels used, and in this case C<edgecolor> value
is used to substitute the pixels outside the image.

=item edgecolor INTEGER

Integer value, used for substitution of pixel values outside IMAGE, when 
C<expandEdges> parameter is set to 1. 

=item divisor INTEGER 

The resulting pixel value is divided to C<divisor> value after the kernel convolution is applied.

=item conversionType

See L<combine>

=item rawOutput

See L<combine>

=back

=item median IMAGE [ w = 3, h = 3 ]

Performs adaptive thresholding with median filter with window dimensions C<w> and C<h>.

=item unionFind IMAGE [ method, threshold  ]

Applies a union find algorithm selected by C<method>. The only implemented
method is average-based region grow ( 'ave' string constant ). Its only
parameter is C<threshold>, integer value of the balance merger function.

Supported types: Byte

=item hysteresis IMAGE, thresold => [ thr0, thr1], neighborhood => 4 or 8

Perform binary hysteresis thresholding of Byte image with two thresholds,
thr0 and thr1. A pixel is set to 1, if its value is larger than thr1 or
if it is larger than thr0 and the pixel is adjacent to already marked pixels.

Default value of neighborhood is 8.

Supported types: Byte

=item gaussian SIZE, SIGMA

Generates a square image of the given SIZe and populates with with gaussian
function with given SIGMA.

=item laplacian SIZE, SIGMA

Generates a square image of the given SIZe and populates with with inverse 
gaussian function with given SIGMA.

=item gradients IMAGE

This function computes a two-dimensional gradient (magnitude and direction) of
an image, using two convolution kernels.  The magnitude is computed as the
vector magnitude of the output of the two kernels, and the direction is
computed as the angle between the two orthogonal gradient vectors.                        

The convolution kernels are (currently limited to) 3x3 masks for calculating
separate vertical and horizontal derivatives.

(Copyright (c) 1988 by the University of Arizona Digital Image Analysis Lab).

=item canny IMAGE [ size = 3, sigma = 2, ridge = 0 ]

First part of the Canny edge detector (without ridge strength
selection). The ridge strength must be supplied by the user.

=item nms IMAGE [ set = 255, clear = 0 ]

Applies non-maximal suppression to the image, and replaces all
non-maximal pixels with the C<clear> color, and maximal with C<set> color.

=item scale IMAGE [ size = 3, sigma_square = 4 ]

Convolves a given image with a gaussian, where the latter is
calculated with the given size and square root of sigma_square.

=item ridge IMAGE [ anorm = false, mul = 1, scale = 2, size = 3 ]

First part of the Lindeberg edge detector (without scale selection).  The scale
must be supplied by the user. C<size> is used in generation of the gaussian
kernel. C<mul> is the custom multiply factor to the calclated ridge strength,
the maximum absolute value to the principal curvatures. C<anorm> selects
whether the Laplacian blob response should be included ( C<false> ) ), or
suppressed ( C<true> ).

=item convolution IMAGE, KERNEL

Convolves IMAGE with the given KERNEL.

=item zerocross IMAGE, cmp = 0

Creates a map from IMAGE where white pixels are assigned to spots
where image crosses the zero plane. The zero level is 0 by default,
but can be changed by setting the C<cmp> argument.

=back

=cut
