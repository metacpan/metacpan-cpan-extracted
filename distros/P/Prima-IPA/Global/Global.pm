# $Id$
package Prima::IPA::Global;
use strict;
require Exporter;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(close_edges fill_holes area_filter identify_contours 
	fft band_filter butterworth fourier identify_scanlines hough
	hough2lines identify_pixels);
%EXPORT_TAGS = (tracks => [qw(close_edges)]);

sub pow2
{
   my ( $i, $j) = ( 1, $_[0]);
   $i <<= 1, $j >>= 1 while $j > 1;
   return $i == $_[0], $i;
}   
# adjusting image to the power of 2 for the FFT transform

sub pow2wrapper1
{
   my ($i,$profile) = @_;

   my ($ow, $oh) = $i-> size;
   my ( $okw, $w1) = pow2( $oh);
   my ( $okh, $h1) = pow2( $ow);
   my $resize = !$okw || !$okh;
   if ( $resize) {
      unless ( $profile->{lowquality}) {
         $w1 *= 2 unless $okw;
         $h1 *= 2 unless $okh;
      }
      $i = $i-> dup;
      $i-> size( $w1, $h1);
   }
   return ( $i, $ow, $oh, $resize);
}   

sub pow2wrapper2
{
   my ( $i, $ow, $oh, $resize) = @_;
   $i-> size( $ow, $oh) if $i && $resize;
   return $i;
}   

# wrapper for ::band_filter
sub butterworth
{
   my ( $i, %profile) = @_;
   die "Prima::IPA::Global::band: Not an image passed\n" unless $i;
   my @psdata;
   $profile{spatial} = 1 if ($i-> type & im::Category) != im::ComplexNumber;
   ( $i, @psdata) = pow2wrapper1( $i, \%profile) if $profile{spatial};
   $i = band_filter( $i, %profile);
   pow2wrapper2( $i, @psdata) if $profile{spatial};
   return $i;
}   

# wrapper for fft
sub fourier
{
   my ( $i, %profile) = @_;
   die "Prima::IPA::Global::fourier: Not an image passed\n" unless $i;
   my @psdata;
   ( $i, @psdata) = pow2wrapper1( $i, \%profile) if $profile{spatial};
   $i = fft( $i, %profile);
   pow2wrapper2( $i, @psdata);
   return $i;
}   


1;

__DATA__

=pod

=head1 NAME

Prima::IPA::Global - methods that produce images where every pixel is a function of all pixels in the source image

=head1 DESCRIPTION

Contains methods that produce images, where every pixel is a function of all
pixels in the source image.  The process can be described with the mapping
function 

   s = M(R)

where C<s> is the pixel value in the output images, and R is the source image.

=over

=item close_edges IMAGE [ gradient, maxlen, minedgelen, mingradient ]

Closes edges of shapes on IMAGE, according to specified C<gradient> image.
The unclosed shapes converted to the closed if the gradient spot between the
suspected dents falls under C<maxlen> maximal length increment, C<mingradient>
the minimal gradient value and the edge is longer than C<minedgelen>.

Supported types: Byte

Parameters:

=over

=item gradient IMAGE

Specifies the gradient image

=item maxlen INTEGER

Maximal edge length

=item minedgelen INTEGER  

Minimal edge length

=item mingradient INTEGER

Minimal gradient value

=back

=item fill_holes IMAGE [ inPlace = 0, edgeSize = 1, backColor = 0, foreColor = 255, neighborhood = 4]

Fills closed shapes to eliminate the contours with holes in IMAGE.

Supported types: Byte

Parameters:

=over

=item inPlace BOOLEAN

If true, the original image is changed

=item edgeSize INTEGER

The edge breadth that is not touched by the algorithm

=item backColor INTEGER

The pixel value used for determination whether a pixel belongs to
the background.

=item foreColor INTEGER

The pixel value used for hole filling.

=item neighborhood INTEGER

Must be either 4 or 8.
Selects whether the algorithm must assume 4- or 8- pixel connection.

=back

=item area_filter IMAGE [ minArea = 0, maxArea = INT_MAX, inPlace = 0, edgeSize = 1, backColor = 0, foreColor = 255, neighborhood = 4]

Identifies the objects on IMAGE and filters out these that have their area less than C<minArea>
and more than C<maxArea>. The other parameters are identical to those passed to L<fill_holes>.

=item identify_contours IMAGE [ edgeSize = 1, backColor = 0, foreColor = 255, neighborhood = 4]

Identifies the objects on IMAGE and returns the contours as array of anonymous arrays of
4- or 8- connected pixel coordinates.

The parameters are identical to those passed to L<fill_holes>.

Supported types: Byte

See also L<Prima::IPA::Region>.

=item identify_scanlines IMAGE [ edgeSize = 1, backColor = 0, foreColor = 255, neighborhood = 4]

Same as C<identify_contours> but returns a set of scan lines.

=item identify_pixels IMAGE [ match => 0, eq => 0 ]

Returns coordinates of all pixels that match (if C<eq> is 1) or not match (C<eq> is 0)
color C<match>.

=item fft IMAGE [ inverse = 0 ]

Performs direct and inverse ( governed by C<inverse> boolean flag )
fast Fourier transform. IMAGE must have dimensions of power of 2.
The resulted image is always of DComplex type.

Supported types: all

=item fourier IMAGE [ inverse = 0 ]

Performs direct and inverse ( governed by C<inverse> boolean flag )
fast Fourier transform. If IMAGE dimensions not of power of 2, then
IMAGE is scaled up to the closest power of 2, and the result is scaled
back to the original dimensions.

The resulted image is always of DComplex type.

Supported types: all

=item band_filter IMAGE [ low = 0, spatial = 1, homomorph = 0, power = 2.0, cutoff = 20.0, boost = 0.7 ]

Performs band filtering of IMAGE in frequency domain. 
IMAGE must have dimensions of power of 2.
The resulted image is always of DComplex type.

Supported types: all

Parameters:

=over

=item low BOOLEAN

Boolean flag, indicates whether the low-pass or the high-pass is to be performed.

=item spatial BOOLEAN

Boolean flag, indicates if IMAGE must be treated as if it is in the spatial domain,
and therefore conversion to the frequency domain must be performed first.

=item homomorph BOOLEAN

Boolean flag, indicates if the homomorph ( exponential ) equalization must be performed. Cannot
be set to true if the image is in frequency domain ( if C<spatial> parameter set to true ).

=item power FLOAT

Power operator applied to the input frequency.

=item cutoff FLOAT

Threshold value of the filter.

=item boost FLOAT

Multiplication factor used in homomorph equalization.

=back

=item butterworth IMAGE [ low = 0, spatial = 1, homomorph = 0, power = 2.0, cutoff = 20.0, boost = 0.7 ]

Performs band filtering of IMAGE in frequency domain. 
If IMAGE dimensions not of power of 2, then
IMAGE is scaled up to the closest power of 2, and the result is scaled
back to the original dimensions.

The resulted image is always of DComplex type.

Supported types: all

The parameters are same as those passed to L<band_filter>.

=item hough IMAGE [ type = "line", direct = 1, resolution = 500 ]

Realizes Hough transform. If type is "line", linear transform is performed.
With direct transform, C<resolution> is width of the resulted image.

Note: Returns a 8-bit grayscale image, which means that for all practical
purposes the image shouldn't possibly contain more than 256 line candidates.

Supported types: all

=item hough2lines IMAGE [ width = 1000, height = 1000 ]

Takes a Hough-transformed image, where each pixel is a line. For each non-zero
pixel a line projection on a rectangle with given width and height is
calculated.  Returns array of quad values in format [x0,y0,x1,y2] where the
coordinates stand for the start and the end of a line.

So, if the direct transform was called as
   
   $h = hough( $i ); 

then plotting lines back (after $h was filtered) would be

   $i-> line(@$_) for @{ hough2lines( $h,
   	width  => $i-> width, 
	height => $i-> height
   ) };

Supported types: 8-bit (expects result from C<hough> function).

=back

=head2 Optimized plotting

The following functions can draw lines on images, and are optimized for speed,
because Prima doesn't support drawing on images outside C<begin_paint>/C<end_paint> scope.

=over

=item bar IMAGE, X1, Y1, X2, Y2, COLOR

Fill the given rectangular area with COLOR.

=item hlines IMAGE, OFFSET_X, OFFSET_Y, LINES, COLOR

Draws set of horizontal lines as defined by LINES with COLOR.  LINES is an
array of triplet integers, where each contains [X1, X2, Y] coordinates -
beginning of hline, end of hline, and vline.

=item line IMAGE, X1, Y1, X2, Y2, COLOR

Draws a single line from X1,Y1 to X2,Y2 .

=back

=cut
