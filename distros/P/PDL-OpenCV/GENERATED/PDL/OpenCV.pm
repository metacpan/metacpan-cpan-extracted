#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::OpenCV;

our @EXPORT_OK = qw( cubeRoot fastAtan2 borderInterpolate copyMakeBorder add subtract multiply divide divide2 scaleAdd addWeighted convertScaleAbs convertFp16 LUT sumElems countNonZero findNonZero mean meanStdDev norm norm2 PSNR batchDistance normalize minMaxLoc reduce merge split mixChannels extractChannel insertChannel flip rotate repeat hconcat vconcat bitwise_and bitwise_or bitwise_xor bitwise_not absdiff copyTo inRange compare min max sqrt pow exp log polarToCart cartToPolar phase magnitude checkRange patchNaNs gemm mulTransposed transpose transform perspectiveTransform completeSymm setIdentity determinant trace invert solve sort sortIdx solveCubic solvePoly eigen eigenNonSymmetric calcCovarMatrix PCACompute PCACompute2 PCACompute3 PCACompute4 PCAProject PCABackProject SVDecomp SVBackSubst Mahalanobis dft idft dct idct mulSpectrums getOptimalDFTSize setRNGSeed randu randn randShuffle kmeans DECOMP_LU DECOMP_SVD DECOMP_EIG DECOMP_CHOLESKY DECOMP_QR DECOMP_NORMAL NORM_INF NORM_L1 NORM_L2 NORM_L2SQR NORM_HAMMING NORM_HAMMING2 NORM_TYPE_MASK NORM_RELATIVE NORM_MINMAX CMP_EQ CMP_GT CMP_GE CMP_LT CMP_LE CMP_NE GEMM_1_T GEMM_2_T GEMM_3_T DFT_INVERSE DFT_SCALE DFT_ROWS DFT_COMPLEX_OUTPUT DFT_REAL_OUTPUT DFT_COMPLEX_INPUT DCT_INVERSE DCT_ROWS BORDER_CONSTANT BORDER_REPLICATE BORDER_REFLECT BORDER_WRAP BORDER_REFLECT_101 BORDER_TRANSPARENT BORDER_REFLECT101 BORDER_DEFAULT BORDER_ISOLATED ACCESS_READ ACCESS_WRITE ACCESS_RW ACCESS_MASK ACCESS_FAST USAGE_DEFAULT USAGE_ALLOCATE_HOST_MEMORY USAGE_ALLOCATE_DEVICE_MEMORY USAGE_ALLOCATE_SHARED_MEMORY __UMAT_USAGE_FLAGS_32BIT SORT_EVERY_ROW SORT_EVERY_COLUMN SORT_ASCENDING SORT_DESCENDING COVAR_SCRAMBLED COVAR_NORMAL COVAR_USE_AVG COVAR_SCALE COVAR_ROWS COVAR_COLS KMEANS_RANDOM_CENTERS KMEANS_PP_CENTERS KMEANS_USE_INITIAL_LABELS REDUCE_SUM REDUCE_AVG REDUCE_MAX REDUCE_MIN ROTATE_90_CLOCKWISE ROTATE_180 ROTATE_90_COUNTERCLOCKWISE CV_8U CV_8UC1 CV_8UC2 CV_8UC3 CV_8UC4 CV_8UC CV_8S CV_8SC1 CV_8SC2 CV_8SC3 CV_8SC4 CV_8SC CV_16U CV_16UC1 CV_16UC2 CV_16UC3 CV_16UC4 CV_16UC CV_16S CV_16SC1 CV_16SC2 CV_16SC3 CV_16SC4 CV_16SC CV_32S CV_32SC1 CV_32SC2 CV_32SC3 CV_32SC4 CV_32SC CV_32F CV_32FC1 CV_32FC2 CV_32FC3 CV_32FC4 CV_32FC CV_64F CV_64FC1 CV_64FC2 CV_64FC3 CV_64FC4 CV_64FC CV_PI CV_2PI CV_LOG2 INT_MAX );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   our $VERSION = '0.001';
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::OpenCV $VERSION;






#line 5 "opencv.pd"

use strict;
use warnings;

=head1 NAME

PDL::OpenCV - PDL interface to OpenCV

=head1 SYNOPSIS

  use PDL::OpenCV::Videoio; # ucfirsted name of the OpenCV "module"
  my $vfile='t/frames.avi';
  my $vc = PDL::OpenCV::VideoCapture->new; # name of the OpenCV class
  die "Failed to open $vfile" if !$vc->open($vfile);
  my ($frame, $res) = $vc->read;
  die "Failed to read" if !$res;
  my $writer = PDL::OpenCV::VideoWriter->new;
  # note 4th arg is an OpenCV "Size" - PDL upgrades array-ref to ndarray
  $writer->open($outfile, PDL::OpenCV::VideoWriter::fourcc('M','P','4','V'), 20, [map $frame->dim($_), 1,2], 1);
  while ($res) {
    $writer->write($frame);
    # and/or display it, or feed it to a Tracker, or...
    ($frame, $res) = $vc->read;
  }

=head1 DESCRIPTION

Use PDL::OpenCV to call OpenCV functions on your data using Perl/PDL.

As can be seen above, this distribution is structured to very closely
match the structure of OpenCV v4 itself. That means the submodules
match the "classes" and/or "modules" in OpenCV, with the obvious exception
of the C<Mat> class which needs special handling to thinly wrap ndarrays
going into and coming back from OpenCV.

=head1 BINDING NOTES

This includes method/function names which are exactly the same
as in OpenCV, without being modified for the common Perl idiom
of snake_casing. This is intended to make the OpenCV documentation
trivially easy to use for the PDL binding (where a binding exists),
including available tutorials.

The API is generated from the Python bindings that are part of OpenCV. In
imitation of that, you are not currently able, as with "normal" PDL
functions, to pass in output ndarrays.

Where things do not work as you would expect from a PDL and/or OpenCV
point of view, and it is not documented as doing so, this is a bug -
please report it as shown at L</BUGS> below.

=head2 Image formats

In PDL, images are often C<byte,3,x,y> or occasionally (e.g. in
L<PDL::Graphics::Simple>) C<byte,x,y,3>. The 3 is always R,G,B. Sometimes
4 is supported, in which case the 4th column will be an alpha
(transparency) channel, or 1, which means the image is grayscale.

OpenCV has the concepts of "depth" and "channels".

"Depth" is bit-depth (and data type) per pixel and per channel: the
bit-depth will be a multiple of 8, and the data type will be integer
(signed or unsigned) or floating-point.

"Channels" resembles the above 1/3/4 point, with the important caveat
that the default for OpenCV image-reading is to format data not as R,G,B,
but B,G,R. This is for historical reasons, being the format returned by
the cameras first used at the start of OpenCV. Use
L<PDL::OpenCV::Imgproc/cvtColor> if your application requires otherwise.

PDL data for use with OpenCV must be dimensioned C<(channels,x,y)>
where C<channels> might be 1 if grayscale. This module will not use
heuristics to guess what you meant if you only supply 2-dimensional data.
This can lead to surprising results: e.g. with
L<PDL::OpenCV::ImgProc/EMD>, the two histogram inputs must be 3D, with
a C<channels> of 1. From the relevant test:

  my $a = pdl float, q[[1 1] [1 2] [0 3] [0 4] [1 5]];
  my $b = pdl float, q[[0 1] [1 2] [0 3] [1 4]];
  my ($flow,$res) = EMD($a->dummy(0),$b->dummy(0),DIST_L2);

If you get an exception C<Unrecognized or unsupported array type>,
that is the cause.

Be careful when scaling byte-valued inputs to maximise dynamic range:

  $frame = ($frame * (255/$max))->byte; # works
  $frame = ($frame * 255/$max)->byte;   # multiply happens first and overflows

=head2 OpenCV minor data-types

In OpenCV, as well as the most important type (C<Mat>), there are various
helper types including C<Rect>, C<Size>, and C<Scalar> (often used for
specifying colours). This distribution wraps these as ndarrays of
appropriate types and dimensions.

While in C++ there are often default values for the constructors
and/or polymorphic ways to call them with fewer than the full number
of arguments, this is currently not possible in PDL. Therefore, e.g. with
a C<Scalar>, you have to supply all four values (just give zeroes for
the ones that don't matter, e.g. the alpha value for a colour on a
non-alpha image).

=head2 Modules and packages

This distro reproduces the structure of OpenCV's various
modules, so that e.g. the C<tracking> module is made available
as L<PDL::OpenCV::Tracking>. Loading that makes available the
C<PDL::OpenCV::Tracker> package which has various methods like C<new>.

=head2 Constants

OpenCV defines various constants in its different modules. This distro
will remove C<cv::> from the beginning of these, then put them in
their loading module. E.g. in C<imgproc>, C<COLOR_GRAY2RGB> will be
C<PDL::OpenCV::Imgproc::COLOR_GRAY2RGB> (and exported by default).

However, further-namespaced constants, like C<cv::Subdiv2D::PTLOC_VERTEX>,
will I<not> be exported, and will be available as
e.g. C<PDL::OpenCV::Imgproc::Subdiv2D::PTLOC_VERTEX>.

=cut
#line 148 "OpenCV.pm"






=head1 FUNCTIONS

=cut




#line 274 "./genpp.pl"

=head2 cubeRoot

=for ref

Computes the cube root of an argument.

=for example

 $res = cubeRoot($val);

The function cubeRoot computes C<<< \sqrt[3]{\texttt{val}} >>>. Negative arguments are handled correctly.
NaN and Inf are not handled. The accuracy approaches the maximum possible accuracy for
single-precision data.

Parameters:

=over

=item val

A function argument.

=back


=cut
#line 190 "OpenCV.pm"



#line 275 "./genpp.pl"

*cubeRoot = \&PDL::OpenCV::cubeRoot;
#line 197 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 fastAtan2

=for ref

Calculates the angle of a 2D vector in degrees.

=for example

 $res = fastAtan2($y,$x);

The function fastAtan2 calculates the full-range angle of an input 2D vector. The angle is measured
in degrees and varies from 0 to 360 degrees. The accuracy is about 0.3 degrees.

Parameters:

=over

=item x

x-coordinate of the vector.

=item y

y-coordinate of the vector.

=back


=cut
#line 232 "OpenCV.pm"



#line 275 "./genpp.pl"

*fastAtan2 = \&PDL::OpenCV::fastAtan2;
#line 239 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 borderInterpolate

=for ref

Computes the source location of an extrapolated pixel.

=for example

 $res = borderInterpolate($p,$len,$borderType);

The function computes and returns the coordinate of a donor pixel corresponding to the specified
extrapolated pixel when using the specified extrapolation border mode. For example, if you use
cv::BORDER_WRAP mode in the horizontal direction, cv::BORDER_REFLECT_101 in the vertical direction and
want to compute value of the "virtual" pixel Point(-5, 100) in a floating-point image img , it
looks like:

 {.cpp}
     float val = img.at<float>(borderInterpolate(100, img.rows, cv::BORDER_REFLECT_101),
                               borderInterpolate(-5, img.cols, cv::BORDER_WRAP));

Normally, the function is not called directly. It is used inside filtering functions and also in
copyMakeBorder.
\<0 or \>= len

Parameters:

=over

=item p

0-based coordinate of the extrapolated pixel along one of the axes, likely

=item len

Length of the array along the corresponding axis.

=item borderType

Border type, one of the #BorderTypes, except for #BORDER_TRANSPARENT and
#BORDER_ISOLATED . When borderType==#BORDER_CONSTANT , the function always returns -1, regardless
of p and len.

=back

See also:
copyMakeBorder


=cut
#line 294 "OpenCV.pm"



#line 275 "./genpp.pl"

*borderInterpolate = \&PDL::OpenCV::borderInterpolate;
#line 301 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 copyMakeBorder

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] top(); int [phys] bottom(); int [phys] left(); int [phys] right(); int [phys] borderType(); double [phys] value(n8))

=for ref

Forms a border around an image. NO BROADCASTING.

=for example

 $dst = copyMakeBorder($src,$top,$bottom,$left,$right,$borderType); # with defaults
 $dst = copyMakeBorder($src,$top,$bottom,$left,$right,$borderType,$value);

The function copies the source image into the middle of the destination image. The areas to the
left, to the right, above and below the copied source image will be filled with extrapolated
pixels. This is not what filtering functions based on it do (they extrapolate pixels on-fly), but
what other more complex functions, including your own, may do to simplify image boundary handling.
The function supports the mode when src is already in the middle of dst . In this case, the
function does not copy src itself but simply constructs the border, for example:

 {.cpp}
     // let border be the same in all directions
     int border=2;
     // constructs a larger image to fit both the image and the border
     Mat gray_buf(rgb.rows + border*2, rgb.cols + border*2, rgb.depth());
     // select the middle part of it w/o copying data
     Mat gray(gray_canvas, Rect(border, border, rgb.cols, rgb.rows));
     // convert image from RGB to grayscale
     cvtColor(rgb, gray, COLOR_RGB2GRAY);
     // form a border in-place
     copyMakeBorder(gray, gray_buf, border, border,
                    border, border, BORDER_REPLICATE);
     // now do some custom filtering ...
     ...

@note When the source image is a part (ROI) of a bigger image, the function will try to use the
pixels outside of the ROI to form a border. To disable this feature and always do extrapolation, as
if src was not a ROI, use borderType | #BORDER_ISOLATED.

Parameters:

=over

=item src

Source image.

=item dst

Destination image of the same type as src and the size Size(src.cols+left+right,
src.rows+top+bottom) .

=item top

the top pixels

=item bottom

the bottom pixels

=item left

the left pixels

=item right

Parameter specifying how many pixels in each direction from the source image rectangle
to extrapolate. For example, top=1, bottom=1, left=1, right=1 mean that 1 pixel-wide border needs
to be built.

=item borderType

Border type. See borderInterpolate for details.

=item value

Border value if borderType==BORDER_CONSTANT .

=back

See also:
borderInterpolate


=for bad

copyMakeBorder ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 402 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::copyMakeBorder {
  barf "Usage: PDL::OpenCV::copyMakeBorder(\$src,\$top,\$bottom,\$left,\$right,\$borderType,\$value)\n" if @_ < 6;
  my ($src,$top,$bottom,$left,$right,$borderType,$value) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $value = empty(double) if !defined $value;
  PDL::OpenCV::_copyMakeBorder_int($src,$dst,$top,$bottom,$left,$right,$borderType,$value);
  !wantarray ? $dst : ($dst)
}
#line 417 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*copyMakeBorder = \&PDL::OpenCV::copyMakeBorder;
#line 424 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 add

=for sig

  Signature: ([phys] src1(l1,c1,r1); [phys] src2(l2,c2,r2); [o,phys] dst(l3,c3,r3); [phys] mask(l4,c4,r4); int [phys] dtype())

=for ref

Calculates the per-element sum of two arrays or an array and a scalar. NO BROADCASTING.

=for example

 $dst = add($src1,$src2); # with defaults
 $dst = add($src1,$src2,$mask,$dtype);

The function add calculates:
=over
=back
The first function in the list above can be replaced with matrix expressions:

 {.cpp}
     dst = src1 + src2;
     dst += src1; // equivalent to add(dst, src1, dst);

The input arrays and the output array can all have the same or different depths. For example, you
can add a 16-bit unsigned array to a 8-bit signed array and store the sum as a 32-bit
floating-point array. Depth of the output array is determined by the dtype parameter. In the second
and third cases above, as well as in the first case, when src1.depth() == src2.depth(), dtype can
be set to the default -1. In this case, the output array will have the same depth as the input
array, be it src1, src2 or both.
@note Saturation is not applied when the output array has the depth CV_32S. You may even get
result of an incorrect sign in the case of overflow.

Parameters:

=over

=item src1

first input array or a scalar.

=item src2

second input array or a scalar.

=item dst

output array that has the same size and number of channels as the input array(s); the
depth is defined by dtype or src1/src2.

=item mask

optional operation mask - 8-bit single channel array, that specifies elements of the
output array to be changed.

=item dtype

optional depth of the output array (see the discussion below).

=back

See also:
subtract, addWeighted, scaleAdd, Mat::convertTo


=for bad

add ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 504 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::add {
  barf "Usage: PDL::OpenCV::add(\$src1,\$src2,\$mask,\$dtype)\n" if @_ < 2;
  my ($src1,$src2,$mask,$dtype) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $mask = PDL->zeroes(sbyte,0,0,0) if !defined $mask;
  $dtype = -1 if !defined $dtype;
  PDL::OpenCV::_add_int($src1,$src2,$dst,$mask,$dtype);
  !wantarray ? $dst : ($dst)
}
#line 520 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*add = \&PDL::OpenCV::add;
#line 527 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 subtract

=for sig

  Signature: ([phys] src1(l1,c1,r1); [phys] src2(l2,c2,r2); [o,phys] dst(l3,c3,r3); [phys] mask(l4,c4,r4); int [phys] dtype())

=for ref

Calculates the per-element difference between two arrays or array and a scalar. NO BROADCASTING.

=for example

 $dst = subtract($src1,$src2); # with defaults
 $dst = subtract($src1,$src2,$mask,$dtype);

The function subtract calculates:
=over
=back
The first function in the list above can be replaced with matrix expressions:

 {.cpp}
     dst = src1 - src2;
     dst -= src1; // equivalent to subtract(dst, src1, dst);

The input arrays and the output array can all have the same or different depths. For example, you
can subtract to 8-bit unsigned arrays and store the difference in a 16-bit signed array. Depth of
the output array is determined by dtype parameter. In the second and third cases above, as well as
in the first case, when src1.depth() == src2.depth(), dtype can be set to the default -1. In this
case the output array will have the same depth as the input array, be it src1, src2 or both.
@note Saturation is not applied when the output array has the depth CV_32S. You may even get
result of an incorrect sign in the case of overflow.

Parameters:

=over

=item src1

first input array or a scalar.

=item src2

second input array or a scalar.

=item dst

output array of the same size and the same number of channels as the input array.

=item mask

optional operation mask; this is an 8-bit single channel array that specifies elements
of the output array to be changed.

=item dtype

optional depth of the output array

=back

See also:
add, addWeighted, scaleAdd, Mat::convertTo


=for bad

subtract ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 605 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::subtract {
  barf "Usage: PDL::OpenCV::subtract(\$src1,\$src2,\$mask,\$dtype)\n" if @_ < 2;
  my ($src1,$src2,$mask,$dtype) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $mask = PDL->zeroes(sbyte,0,0,0) if !defined $mask;
  $dtype = -1 if !defined $dtype;
  PDL::OpenCV::_subtract_int($src1,$src2,$dst,$mask,$dtype);
  !wantarray ? $dst : ($dst)
}
#line 621 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*subtract = \&PDL::OpenCV::subtract;
#line 628 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 multiply

=for sig

  Signature: ([phys] src1(l1,c1,r1); [phys] src2(l2,c2,r2); [o,phys] dst(l3,c3,r3); double [phys] scale(); int [phys] dtype())

=for ref

Calculates the per-element scaled product of two arrays. NO BROADCASTING.

=for example

 $dst = multiply($src1,$src2); # with defaults
 $dst = multiply($src1,$src2,$scale,$dtype);

The function multiply calculates the per-element product of two arrays:
\f[\texttt{dst} (I)= \texttt{saturate} ( \texttt{scale} \cdot \texttt{src1} (I)  \cdot \texttt{src2} (I))\f]
There is also a @ref MatrixExpressions -friendly variant of the first function. See Mat::mul .
For a not-per-element matrix product, see gemm .
@note Saturation is not applied when the output array has the depth
CV_32S. You may even get result of an incorrect sign in the case of
overflow.

Parameters:

=over

=item src1

first input array.

=item src2

second input array of the same size and the same type as src1.

=item dst

output array of the same size and type as src1.

=item scale

optional scale factor.

=item dtype

optional depth of the output array

=back

See also:
add, subtract, divide, scaleAdd, addWeighted, accumulate, accumulateProduct, accumulateSquare,
Mat::convertTo


=for bad

multiply ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 697 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::multiply {
  barf "Usage: PDL::OpenCV::multiply(\$src1,\$src2,\$scale,\$dtype)\n" if @_ < 2;
  my ($src1,$src2,$scale,$dtype) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $scale = 1 if !defined $scale;
  $dtype = -1 if !defined $dtype;
  PDL::OpenCV::_multiply_int($src1,$src2,$dst,$scale,$dtype);
  !wantarray ? $dst : ($dst)
}
#line 713 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*multiply = \&PDL::OpenCV::multiply;
#line 720 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 divide

=for sig

  Signature: ([phys] src1(l1,c1,r1); [phys] src2(l2,c2,r2); [o,phys] dst(l3,c3,r3); double [phys] scale(); int [phys] dtype())

=for ref

Performs per-element division of two arrays or a scalar by an array. NO BROADCASTING.

=for example

 $dst = divide($src1,$src2); # with defaults
 $dst = divide($src1,$src2,$scale,$dtype);

The function cv::divide divides one array by another:
\f[\texttt{dst(I) = saturate(src1(I)*scale/src2(I))}\f]
or a scalar by an array when there is no src1 :
\f[\texttt{dst(I) = saturate(scale/src2(I))}\f]
Different channels of multi-channel arrays are processed independently.
For integer types when src2(I) is zero, dst(I) will also be zero.
@note In case of floating point data there is no special defined behavior for zero src2(I) values.
Regular floating-point division is used.
Expect correct IEEE-754 behaviour for floating-point data (with NaN, Inf result values).
@note Saturation is not applied when the output array has the depth CV_32S. You may even get
result of an incorrect sign in the case of overflow.

Parameters:

=over

=item src1

first input array.

=item src2

second input array of the same size and type as src1.

=item scale

scalar factor.

=item dst

output array of the same size and type as src2.

=item dtype

optional depth of the output array; if -1, dst will have depth src2.depth(), but in
case of an array-by-array division, you can only pass -1 when src1.depth()==src2.depth().

=back

See also:
multiply, add, subtract


=for bad

divide ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 793 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::divide {
  barf "Usage: PDL::OpenCV::divide(\$src1,\$src2,\$scale,\$dtype)\n" if @_ < 2;
  my ($src1,$src2,$scale,$dtype) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $scale = 1 if !defined $scale;
  $dtype = -1 if !defined $dtype;
  PDL::OpenCV::_divide_int($src1,$src2,$dst,$scale,$dtype);
  !wantarray ? $dst : ($dst)
}
#line 809 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*divide = \&PDL::OpenCV::divide;
#line 816 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 divide2

=for sig

  Signature: (double [phys] scale(); [phys] src2(l2,c2,r2); [o,phys] dst(l3,c3,r3); int [phys] dtype())

=for ref

 NO BROADCASTING.

=for example

 $dst = divide2($scale,$src2); # with defaults
 $dst = divide2($scale,$src2,$dtype);

@overload

=for bad

divide2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 848 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::divide2 {
  barf "Usage: PDL::OpenCV::divide2(\$scale,\$src2,\$dtype)\n" if @_ < 2;
  my ($scale,$src2,$dtype) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $dtype = -1 if !defined $dtype;
  PDL::OpenCV::_divide2_int($scale,$src2,$dst,$dtype);
  !wantarray ? $dst : ($dst)
}
#line 863 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*divide2 = \&PDL::OpenCV::divide2;
#line 870 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 scaleAdd

=for sig

  Signature: ([phys] src1(l1,c1,r1); double [phys] alpha(); [phys] src2(l3,c3,r3); [o,phys] dst(l4,c4,r4))

=for ref

Calculates the sum of a scaled array and another array. NO BROADCASTING.

=for example

 $dst = scaleAdd($src1,$alpha,$src2);

The function scaleAdd is one of the classical primitive linear algebra operations, known as DAXPY
or SAXPY in [BLAS](http://en.wikipedia.org/wiki/Basic_Linear_Algebra_Subprograms). It calculates
the sum of a scaled array and another array:
\f[\texttt{dst} (I)= \texttt{scale} \cdot \texttt{src1} (I) +  \texttt{src2} (I)\f]
The function can also be emulated with a matrix expression, for example:

 {.cpp}
     Mat A(3, 3, CV_64F);
     ...
     A.row(0) = A.row(1)*2 + A.row(2);

Parameters:

=over

=item src1

first input array.

=item alpha

scale factor for the first array.

=item src2

second input array of the same size and type as src1.

=item dst

output array of the same size and type as src1.

=back

See also:
add, addWeighted, subtract, Mat::dot, Mat::convertTo


=for bad

scaleAdd ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 936 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::scaleAdd {
  barf "Usage: PDL::OpenCV::scaleAdd(\$src1,\$alpha,\$src2)\n" if @_ < 3;
  my ($src1,$alpha,$src2) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::_scaleAdd_int($src1,$alpha,$src2,$dst);
  !wantarray ? $dst : ($dst)
}
#line 950 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*scaleAdd = \&PDL::OpenCV::scaleAdd;
#line 957 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 addWeighted

=for sig

  Signature: ([phys] src1(l1,c1,r1); double [phys] alpha(); [phys] src2(l3,c3,r3); double [phys] beta(); double [phys] gamma(); [o,phys] dst(l6,c6,r6); int [phys] dtype())

=for ref

Calculates the weighted sum of two arrays. NO BROADCASTING.

=for example

 $dst = addWeighted($src1,$alpha,$src2,$beta,$gamma); # with defaults
 $dst = addWeighted($src1,$alpha,$src2,$beta,$gamma,$dtype);

The function addWeighted calculates the weighted sum of two arrays as follows:
\f[\texttt{dst} (I)= \texttt{saturate} ( \texttt{src1} (I)* \texttt{alpha} +  \texttt{src2} (I)* \texttt{beta} +  \texttt{gamma} )\f]
where I is a multi-dimensional index of array elements. In case of multi-channel arrays, each
channel is processed independently.
The function can be replaced with a matrix expression:

 {.cpp}
     dst = src1*alpha + src2*beta + gamma;

@note Saturation is not applied when the output array has the depth CV_32S. You may even get
result of an incorrect sign in the case of overflow.

Parameters:

=over

=item src1

first input array.

=item alpha

weight of the first array elements.

=item src2

second input array of the same size and channel number as src1.

=item beta

weight of the second array elements.

=item gamma

scalar added to each sum.

=item dst

output array that has the same size and number of channels as the input arrays.

=item dtype

optional depth of the output array; when both input arrays have the same depth, dtype
can be set to -1, which will be equivalent to src1.depth().

=back

See also:
add, subtract, scaleAdd, Mat::convertTo


=for bad

addWeighted ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1038 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::addWeighted {
  barf "Usage: PDL::OpenCV::addWeighted(\$src1,\$alpha,\$src2,\$beta,\$gamma,\$dtype)\n" if @_ < 5;
  my ($src1,$alpha,$src2,$beta,$gamma,$dtype) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $dtype = -1 if !defined $dtype;
  PDL::OpenCV::_addWeighted_int($src1,$alpha,$src2,$beta,$gamma,$dst,$dtype);
  !wantarray ? $dst : ($dst)
}
#line 1053 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*addWeighted = \&PDL::OpenCV::addWeighted;
#line 1060 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 convertScaleAbs

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); double [phys] alpha(); double [phys] beta())

=for ref

Scales, calculates absolute values, and converts the result to 8-bit. NO BROADCASTING.

=for example

 $dst = convertScaleAbs($src); # with defaults
 $dst = convertScaleAbs($src,$alpha,$beta);

On each element of the input array, the function convertScaleAbs
performs three operations sequentially: scaling, taking an absolute
value, conversion to an unsigned 8-bit type:
\f[\texttt{dst} (I)= \texttt{saturate\_cast<uchar>} (| \texttt{src} (I)* \texttt{alpha} +  \texttt{beta} |)\f]
In case of multi-channel arrays, the function processes each channel
independently. When the output is not 8-bit, the operation can be
emulated by calling the Mat::convertTo method (or by using matrix
expressions) and then by calculating an absolute value of the result.
For example:

 {.cpp}
     Mat_<float> A(30,30);
     randu(A, Scalar(-100), Scalar(100));
     Mat_<float> B = A*5 + 3;
     B = abs(B);
     // Mat_<float> B = abs(A*5+3) will also do the job,
     // but it will allocate a temporary matrix

Parameters:

=over

=item src

input array.

=item dst

output array.

=item alpha

optional scale factor.

=item beta

optional delta added to the scaled values.

=back

See also:
Mat::convertTo, cv::abs(const Mat&)


=for bad

convertScaleAbs ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1134 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::convertScaleAbs {
  barf "Usage: PDL::OpenCV::convertScaleAbs(\$src,\$alpha,\$beta)\n" if @_ < 1;
  my ($src,$alpha,$beta) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $alpha = 1 if !defined $alpha;
  $beta = 0 if !defined $beta;
  PDL::OpenCV::_convertScaleAbs_int($src,$dst,$alpha,$beta);
  !wantarray ? $dst : ($dst)
}
#line 1150 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*convertScaleAbs = \&PDL::OpenCV::convertScaleAbs;
#line 1157 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 convertFp16

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2))

=for ref

Converts an array to half precision floating number. NO BROADCASTING.

=for example

 $dst = convertFp16($src);

This function converts FP32 (single precision floating point) from/to FP16 (half precision floating point). CV_16S format is used to represent FP16 data.
There are two use modes (src -> dst): CV_32F -> CV_16S and CV_16S -> CV_32F. The input array has to have type of CV_32F or
CV_16S to represent the bit depth. If the input array is neither of them, the function will raise an error.
The format of half precision floating point is defined in IEEE 754-2008.

Parameters:

=over

=item src

input array.

=item dst

output array.

=back


=for bad

convertFp16 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1206 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::convertFp16 {
  barf "Usage: PDL::OpenCV::convertFp16(\$src)\n" if @_ < 1;
  my ($src) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::_convertFp16_int($src,$dst);
  !wantarray ? $dst : ($dst)
}
#line 1220 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*convertFp16 = \&PDL::OpenCV::convertFp16;
#line 1227 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 LUT

=for sig

  Signature: ([phys] src(l1,c1,r1); [phys] lut(l2,c2,r2); [o,phys] dst(l3,c3,r3))

=for ref

Performs a look-up table transform of an array. NO BROADCASTING.

=for example

 $dst = LUT($src,$lut);

The function LUT fills the output array with values from the look-up table. Indices of the entries
are taken from the input array. That is, the function processes each element of src as follows:
\f[\texttt{dst} (I)  \leftarrow \texttt{lut(src(I) + d)}\f]
where
\f[d =  \fork{0}{if \(\texttt{src}\) has depth \(\texttt{CV_8U}\)}{128}{if \(\texttt{src}\) has depth \(\texttt{CV_8S}\)}\f]

Parameters:

=over

=item src

input array of 8-bit elements.

=item lut

look-up table of 256 elements; in case of multi-channel input array, the table should
either have a single channel (in this case the same table is used for all channels) or the same
number of channels as in the input array.

=item dst

output array of the same size and number of channels as src, and the same depth as lut.

=back

See also:
convertScaleAbs, Mat::convertTo


=for bad

LUT ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1286 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::LUT {
  barf "Usage: PDL::OpenCV::LUT(\$src,\$lut)\n" if @_ < 2;
  my ($src,$lut) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::_LUT_int($src,$lut,$dst);
  !wantarray ? $dst : ($dst)
}
#line 1300 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*LUT = \&PDL::OpenCV::LUT;
#line 1307 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 sumElems

=for sig

  Signature: ([phys] src(l1,c1,r1); double [o,phys] res(n2=4))

=for ref

Calculates the sum of array elements.

=for example

 $res = sumElems($src);

The function cv::sum calculates and returns the sum of array elements,
independently for each channel.

Parameters:

=over

=item src

input array that must have from 1 to 4 channels.

=back

See also:
countNonZero, mean, meanStdDev, norm, minMaxLoc, reduce


=for bad

sumElems ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1353 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::sumElems {
  barf "Usage: PDL::OpenCV::sumElems(\$src)\n" if @_ < 1;
  my ($src) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::_sumElems_int($src,$res);
  !wantarray ? $res : ($res)
}
#line 1367 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*sumElems = \&PDL::OpenCV::sumElems;
#line 1374 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 countNonZero

=for sig

  Signature: ([phys] src(l1,c1,r1); int [o,phys] res())

=for ref

Counts non-zero array elements.

=for example

 $res = countNonZero($src);

The function returns the number of non-zero elements in src :
\f[\sum _{I: \; \texttt{src} (I) \ne0 } 1\f]

Parameters:

=over

=item src

single-channel array.

=back

See also:
mean, meanStdDev, norm, minMaxLoc, calcCovarMatrix


=for bad

countNonZero ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1420 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::countNonZero {
  barf "Usage: PDL::OpenCV::countNonZero(\$src)\n" if @_ < 1;
  my ($src) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::_countNonZero_int($src,$res);
  !wantarray ? $res : ($res)
}
#line 1434 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*countNonZero = \&PDL::OpenCV::countNonZero;
#line 1441 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 findNonZero

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] idx(l2,c2,r2))

=for ref

Returns the list of locations of non-zero pixels NO BROADCASTING.

=for example

 $idx = findNonZero($src);

Given a binary matrix (likely returned from an operation such
as threshold(), compare(), >, ==, etc, return all of
the non-zero indices as a cv::Mat or std::vector<cv::Point> (x,y)
For example:

 {.cpp}
     cv::Mat binaryImage; // input, binary image
     cv::Mat locations;   // output, locations of non-zero pixels
     cv::findNonZero(binaryImage, locations);

     // access pixel coordinates
     Point pnt = locations.at<Point>(i);

or

 {.cpp}
     cv::Mat binaryImage; // input, binary image
     vector<Point> locations;   // output, locations of non-zero pixels
     cv::findNonZero(binaryImage, locations);

     // access pixel coordinates
     Point pnt = locations[i];

Parameters:

=over

=item src

single-channel array

=item idx

the output array, type of cv::Mat or std::vector<Point>, corresponding to non-zero indices in the input

=back


=for bad

findNonZero ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1508 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::findNonZero {
  barf "Usage: PDL::OpenCV::findNonZero(\$src)\n" if @_ < 1;
  my ($src) = @_;
  my ($idx);
  $idx = PDL->null if !defined $idx;
  PDL::OpenCV::_findNonZero_int($src,$idx);
  !wantarray ? $idx : ($idx)
}
#line 1522 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*findNonZero = \&PDL::OpenCV::findNonZero;
#line 1529 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 mean

=for sig

  Signature: ([phys] src(l1,c1,r1); [phys] mask(l2,c2,r2); double [o,phys] res(n3=4))

=for ref

Calculates an average (mean) of array elements.

=for example

 $res = mean($src); # with defaults
 $res = mean($src,$mask);

The function cv::mean calculates the mean value M of array elements,
independently for each channel, and return it:
\f[\begin{array}{l} N =  \sum _{I: \; \texttt{mask} (I) \ne 0} 1 \\ M_c =  \left ( \sum _{I: \; \texttt{mask} (I) \ne 0}{ \texttt{mtx} (I)_c} \right )/N \end{array}\f]
When all the mask elements are 0's, the function returns Scalar::all(0)

Parameters:

=over

=item src

input array that should have from 1 to 4 channels so that the result can be stored in
Scalar_ .

=item mask

optional operation mask.

=back

See also:
countNonZero, meanStdDev, norm, minMaxLoc


=for bad

mean ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1583 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::mean {
  barf "Usage: PDL::OpenCV::mean(\$src,\$mask)\n" if @_ < 1;
  my ($src,$mask) = @_;
  my ($res);
  $mask = PDL->zeroes(sbyte,0,0,0) if !defined $mask;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::_mean_int($src,$mask,$res);
  !wantarray ? $res : ($res)
}
#line 1598 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*mean = \&PDL::OpenCV::mean;
#line 1605 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 meanStdDev

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] mean(l2,c2,r2); [o,phys] stddev(l3,c3,r3); [phys] mask(l4,c4,r4))

=for ref

 NO BROADCASTING.

=for example

 ($mean,$stddev) = meanStdDev($src); # with defaults
 ($mean,$stddev) = meanStdDev($src,$mask);

Calculates a mean and standard deviation of array elements.
The function cv::meanStdDev calculates the mean and the standard deviation M
of array elements independently for each channel and returns it via the
output parameters:
\f[\begin{array}{l} N =  \sum _{I, \texttt{mask} (I)  \ne 0} 1 \\ \texttt{mean} _c =  \frac{\sum_{ I: \; \texttt{mask}(I) \ne 0} \texttt{src} (I)_c}{N} \\ \texttt{stddev} _c =  \sqrt{\frac{\sum_{ I: \; \texttt{mask}(I) \ne 0} \left ( \texttt{src} (I)_c -  \texttt{mean} _c \right )^2}{N}} \end{array}\f]
When all the mask elements are 0's, the function returns
mean=stddev=Scalar::all(0).
@note The calculated standard deviation is only the diagonal of the
complete normalized covariance matrix. If the full matrix is needed, you
can reshape the multi-channel array M x N to the single-channel array
M*N x mtx.channels() (only possible when the matrix is continuous) and
then pass the matrix to calcCovarMatrix .

Parameters:

=over

=item src

input array that should have from 1 to 4 channels so that the results can be stored in
Scalar_ 's.

=item mean

output parameter: calculated mean value.

=item stddev

output parameter: calculated standard deviation.

=item mask

optional operation mask.

=back

See also:
countNonZero, mean, norm, minMaxLoc, calcCovarMatrix


=for bad

meanStdDev ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1675 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::meanStdDev {
  barf "Usage: PDL::OpenCV::meanStdDev(\$src,\$mask)\n" if @_ < 1;
  my ($src,$mask) = @_;
  my ($mean,$stddev);
  $mean = PDL->null if !defined $mean;
  $stddev = PDL->null if !defined $stddev;
  $mask = PDL->zeroes(sbyte,0,0,0) if !defined $mask;
  PDL::OpenCV::_meanStdDev_int($src,$mean,$stddev,$mask);
  !wantarray ? $stddev : ($mean,$stddev)
}
#line 1691 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*meanStdDev = \&PDL::OpenCV::meanStdDev;
#line 1698 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 norm

=for sig

  Signature: ([phys] src1(l1,c1,r1); int [phys] normType(); [phys] mask(l3,c3,r3); double [o,phys] res())

=for ref

Calculates the  absolute norm of an array.

=for example

 $res = norm($src1); # with defaults
 $res = norm($src1,$normType,$mask);

This version of #norm calculates the absolute norm of src1. The type of norm to calculate is specified using #NormTypes.
As example for one array consider the function C<<< r(x)= \begin{pmatrix} x \\ 1-x \end{pmatrix}, x \in [-1;1] >>>.
The C<<<  L_{1}, L_{2}  >>>and C<<<  L_{\infty}  >>>norm for the sample value C<<< r(-1) = \begin{pmatrix} -1 \\ 2 \end{pmatrix} >>>is calculated as follows
\f{align*}
\| r(-1) \|_{L_1} &= |-1| + |2| = 3 \\
\| r(-1) \|_{L_2} &= \sqrt{(-1)^{2} + (2)^{2}} = \sqrt{5} \\
\| r(-1) \|_{L_\infty} &= \max(|-1|,|2|) = 2
\f}
and for C<<< r(0.5) = \begin{pmatrix} 0.5 \\ 0.5 \end{pmatrix} >>>the calculation is
\f{align*}
\| r(0.5) \|_{L_1} &= |0.5| + |0.5| = 1 \\
\| r(0.5) \|_{L_2} &= \sqrt{(0.5)^{2} + (0.5)^{2}} = \sqrt{0.5} \\
\| r(0.5) \|_{L_\infty} &= \max(|0.5|,|0.5|) = 0.5.
\f}
The following graphic shows all values for the three norm functions C<<< \| r(x) \|_{L_1}, \| r(x) \|_{L_2} >>>and C<<< \| r(x) \|_{L_\infty} >>>.
It is notable that the C<<<  L_{1}  >>>norm forms the upper and the C<<<  L_{\infty}  >>>norm forms the lower border for the example function C<<<  r(x)  >>>.
![Graphs for the different norm functions from the above example](pics/NormTypes_OneArray_1-2-INF.png)
When the mask parameter is specified and it is not empty, the norm is
If normType is not specified, #NORM_L2 is used.
calculated only over the region specified by the mask.
Multi-channel input arrays are treated as single-channel arrays, that is,
the results for all channels are combined.
Hamming norms can only be calculated with CV_8U depth arrays.

Parameters:

=over

=item src1

first input array.

=item normType

type of the norm (see #NormTypes).

=item mask

optional operation mask; it must have the same size as src1 and CV_8UC1 type.

=back


=for bad

norm ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1771 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::norm {
  barf "Usage: PDL::OpenCV::norm(\$src1,\$normType,\$mask)\n" if @_ < 1;
  my ($src1,$normType,$mask) = @_;
  my ($res);
  $normType = NORM_L2() if !defined $normType;
  $mask = PDL->zeroes(sbyte,0,0,0) if !defined $mask;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::_norm_int($src1,$normType,$mask,$res);
  !wantarray ? $res : ($res)
}
#line 1787 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*norm = \&PDL::OpenCV::norm;
#line 1794 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 norm2

=for sig

  Signature: ([phys] src1(l1,c1,r1); [phys] src2(l2,c2,r2); int [phys] normType(); [phys] mask(l4,c4,r4); double [o,phys] res())

=for ref

Calculates an absolute difference norm or a relative difference norm.

=for example

 $res = norm2($src1,$src2); # with defaults
 $res = norm2($src1,$src2,$normType,$mask);

This version of cv::norm calculates the absolute difference norm
or the relative difference norm of arrays src1 and src2.
The type of norm to calculate is specified using #NormTypes.

Parameters:

=over

=item src1

first input array.

=item src2

second input array of the same size and the same type as src1.

=item normType

type of the norm (see #NormTypes).

=item mask

optional operation mask; it must have the same size as src1 and CV_8UC1 type.

=back


=for bad

norm2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1851 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::norm2 {
  barf "Usage: PDL::OpenCV::norm2(\$src1,\$src2,\$normType,\$mask)\n" if @_ < 2;
  my ($src1,$src2,$normType,$mask) = @_;
  my ($res);
  $normType = NORM_L2() if !defined $normType;
  $mask = PDL->zeroes(sbyte,0,0,0) if !defined $mask;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::_norm2_int($src1,$src2,$normType,$mask,$res);
  !wantarray ? $res : ($res)
}
#line 1867 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*norm2 = \&PDL::OpenCV::norm2;
#line 1874 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 PSNR

=for sig

  Signature: ([phys] src1(l1,c1,r1); [phys] src2(l2,c2,r2); double [phys] R(); double [o,phys] res())

=for ref

Computes the Peak Signal-to-Noise Ratio (PSNR) image quality metric.

=for example

 $res = PSNR($src1,$src2); # with defaults
 $res = PSNR($src1,$src2,$R);

This function calculates the Peak Signal-to-Noise Ratio (PSNR) image quality metric in decibels (dB),
between two input arrays src1 and src2. The arrays must have the same type.
The PSNR is calculated as follows:
\f[
\texttt{PSNR} = 10 \cdot \log_{10}{\left( \frac{R^2}{MSE} \right) }
\f]
where R is the maximum integer value of depth (e.g. 255 in the case of CV_8U data)
and MSE is the mean squared error between the two arrays.

Parameters:

=over

=item src1

first input array.

=item src2

second input array of the same size as src1.

=item R

the maximum pixel value (255 by default)

=back


=for bad

PSNR ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1932 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::PSNR {
  barf "Usage: PDL::OpenCV::PSNR(\$src1,\$src2,\$R)\n" if @_ < 2;
  my ($src1,$src2,$R) = @_;
  my ($res);
  $R = 255. if !defined $R;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::_PSNR_int($src1,$src2,$R,$res);
  !wantarray ? $res : ($res)
}
#line 1947 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*PSNR = \&PDL::OpenCV::PSNR;
#line 1954 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 batchDistance

=for sig

  Signature: ([phys] src1(l1,c1,r1); [phys] src2(l2,c2,r2); [o,phys] dist(l3,c3,r3); int [phys] dtype(); [o,phys] nidx(l5,c5,r5); int [phys] normType(); int [phys] K(); [phys] mask(l8,c8,r8); int [phys] update(); byte [phys] crosscheck())

=for ref

naive nearest neighbor finder NO BROADCASTING.

=for example

 ($dist,$nidx) = batchDistance($src1,$src2,$dtype); # with defaults
 ($dist,$nidx) = batchDistance($src1,$src2,$dtype,$normType,$K,$mask,$update,$crosscheck);

see http://en.wikipedia.org/wiki/Nearest_neighbor_search
@todo document

=for bad

batchDistance ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1987 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::batchDistance {
  barf "Usage: PDL::OpenCV::batchDistance(\$src1,\$src2,\$dtype,\$normType,\$K,\$mask,\$update,\$crosscheck)\n" if @_ < 3;
  my ($src1,$src2,$dtype,$normType,$K,$mask,$update,$crosscheck) = @_;
  my ($dist,$nidx);
  $dist = PDL->null if !defined $dist;
  $nidx = PDL->null if !defined $nidx;
  $normType = NORM_L2() if !defined $normType;
  $K = 0 if !defined $K;
  $mask = PDL->zeroes(sbyte,0,0,0) if !defined $mask;
  $update = 0 if !defined $update;
  $crosscheck = 0 if !defined $crosscheck;
  PDL::OpenCV::_batchDistance_int($src1,$src2,$dist,$dtype,$nidx,$normType,$K,$mask,$update,$crosscheck);
  !wantarray ? $nidx : ($dist,$nidx)
}
#line 2007 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*batchDistance = \&PDL::OpenCV::batchDistance;
#line 2014 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 normalize

=for sig

  Signature: ([phys] src(l1,c1,r1); [io,phys] dst(l2,c2,r2); double [phys] alpha(); double [phys] beta(); int [phys] norm_type(); int [phys] dtype(); [phys] mask(l7,c7,r7))

=for ref

Normalizes the norm or value range of an array.

=for example

 normalize($src,$dst); # with defaults
 normalize($src,$dst,$alpha,$beta,$norm_type,$dtype,$mask);

The function cv::normalize normalizes scale and shift the input array elements so that
\f[\| \texttt{dst} \| _{L_p}= \texttt{alpha}\f]
(where p=Inf, 1 or 2) when normType=NORM_INF, NORM_L1, or NORM_L2, respectively; or so that
\f[\min _I  \texttt{dst} (I)= \texttt{alpha} , \, \, \max _I  \texttt{dst} (I)= \texttt{beta}\f]
when normType=NORM_MINMAX (for dense arrays only). The optional mask specifies a sub-array to be
normalized. This means that the norm or min-n-max are calculated over the sub-array, and then this
sub-array is modified to be normalized. If you want to only use the mask to calculate the norm or
min-max but modify the whole array, you can use norm and Mat::convertTo.
In case of sparse matrices, only the non-zero values are analyzed and transformed. Because of this,
the range transformation for sparse matrices is not allowed since it can shift the zero level.
Possible usage with some positive example data:

 {.cpp}
     vector<double> positiveData = { 2.0, 8.0, 10.0 };
     vector<double> normalizedData_l1, normalizedData_l2, normalizedData_inf, normalizedData_minmax;

     // Norm to probability (total count)
     // sum(numbers) = 20.0
     // 2.0      0.1     (2.0/20.0)
     // 8.0      0.4     (8.0/20.0)
     // 10.0     0.5     (10.0/20.0)
     normalize(positiveData, normalizedData_l1, 1.0, 0.0, NORM_L1);

     // Norm to unit vector: ||positiveData|| = 1.0
     // 2.0      0.15
     // 8.0      0.62
     // 10.0     0.77
     normalize(positiveData, normalizedData_l2, 1.0, 0.0, NORM_L2);

     // Norm to max element
     // 2.0      0.2     (2.0/10.0)
     // 8.0      0.8     (8.0/10.0)
     // 10.0     1.0     (10.0/10.0)
     normalize(positiveData, normalizedData_inf, 1.0, 0.0, NORM_INF);

     // Norm to range [0.0;1.0]
     // 2.0      0.0     (shift to left border)
     // 8.0      0.75    (6.0/8.0)
     // 10.0     1.0     (shift to right border)
     normalize(positiveData, normalizedData_minmax, 1.0, 0.0, NORM_MINMAX);

Parameters:

=over

=item src

input array.

=item dst

output array of the same size as src .

=item alpha

norm value to normalize to or the lower range boundary in case of the range
normalization.

=item beta

upper range boundary in case of the range normalization; it is not used for the norm
normalization.

=item norm_type

normalization type (see cv::NormTypes).

=item dtype

when negative, the output array has the same type as src; otherwise, it has the same
number of channels as src and the depth =CV_MAT_DEPTH(dtype).

=item mask

optional operation mask.

=back

See also:
norm, Mat::convertTo, SparseMat::convertTo


=for bad

normalize ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2126 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::normalize {
  barf "Usage: PDL::OpenCV::normalize(\$src,\$dst,\$alpha,\$beta,\$norm_type,\$dtype,\$mask)\n" if @_ < 2;
  my ($src,$dst,$alpha,$beta,$norm_type,$dtype,$mask) = @_;
    $alpha = 1 if !defined $alpha;
  $beta = 0 if !defined $beta;
  $norm_type = NORM_L2() if !defined $norm_type;
  $dtype = -1 if !defined $dtype;
  $mask = PDL->zeroes(sbyte,0,0,0) if !defined $mask;
  PDL::OpenCV::_normalize_int($src,$dst,$alpha,$beta,$norm_type,$dtype,$mask);
  
}
#line 2143 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*normalize = \&PDL::OpenCV::normalize;
#line 2150 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 minMaxLoc

=for sig

  Signature: ([phys] src(l1,c1,r1); double [o,phys] minVal(); double [o,phys] maxVal(); indx [o,phys] minLoc(n4=2); indx [o,phys] maxLoc(n5=2); [phys] mask(l6,c6,r6))

=for ref

Finds the global minimum and maximum in an array.

=for example

 ($minVal,$maxVal,$minLoc,$maxLoc) = minMaxLoc($src); # with defaults
 ($minVal,$maxVal,$minLoc,$maxLoc) = minMaxLoc($src,$mask);

The function cv::minMaxLoc finds the minimum and maximum element values and their positions. The
extremums are searched across the whole array or, if mask is not an empty array, in the specified
array region.
The function do not work with multi-channel arrays. If you need to find minimum or maximum
elements across all the channels, use Mat::reshape first to reinterpret the array as
single-channel. Or you may extract the particular channel using either extractImageCOI , or
mixChannels , or split .

Parameters:

=over

=item src

input single-channel array.

=item minVal

pointer to the returned minimum value; NULL is used if not required.

=item maxVal

pointer to the returned maximum value; NULL is used if not required.

=item minLoc

pointer to the returned minimum location (in 2D case); NULL is used if not required.

=item maxLoc

pointer to the returned maximum location (in 2D case); NULL is used if not required.

=item mask

optional mask used to select a sub-array.

=back

See also:
max, min, compare, inRange, extractImageCOI, mixChannels, split, Mat::reshape


=for bad

minMaxLoc ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2222 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::minMaxLoc {
  barf "Usage: PDL::OpenCV::minMaxLoc(\$src,\$mask)\n" if @_ < 1;
  my ($src,$mask) = @_;
  my ($minVal,$maxVal,$minLoc,$maxLoc);
  $minVal = PDL->null if !defined $minVal;
  $maxVal = PDL->null if !defined $maxVal;
  $minLoc = PDL->null if !defined $minLoc;
  $maxLoc = PDL->null if !defined $maxLoc;
  $mask = PDL->zeroes(sbyte,0,0,0) if !defined $mask;
  PDL::OpenCV::_minMaxLoc_int($src,$minVal,$maxVal,$minLoc,$maxLoc,$mask);
  !wantarray ? $maxLoc : ($minVal,$maxVal,$minLoc,$maxLoc)
}
#line 2240 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*minMaxLoc = \&PDL::OpenCV::minMaxLoc;
#line 2247 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 reduce

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] dim(); int [phys] rtype(); int [phys] dtype())

=for ref

Reduces a matrix to a vector. NO BROADCASTING.

=for example

 $dst = reduce($src,$dim,$rtype); # with defaults
 $dst = reduce($src,$dim,$rtype,$dtype);

The function #reduce reduces the matrix to a vector by treating the matrix rows/columns as a set of
1D vectors and performing the specified operation on the vectors until a single row/column is
obtained. For example, the function can be used to compute horizontal and vertical projections of a
raster image. In case of #REDUCE_MAX and #REDUCE_MIN , the output image should have the same type as the source one.
In case of #REDUCE_SUM and #REDUCE_AVG , the output may have a larger element bit-depth to preserve accuracy.
And multi-channel arrays are also supported in these two reduction modes.
The following code demonstrates its usage for a single channel matrix.
@snippet snippets/core_reduce.cpp example
And the following code demonstrates its usage for a two-channel matrix.
@snippet snippets/core_reduce.cpp example2

Parameters:

=over

=item src

input 2D matrix.

=item dst

output vector. Its size and type is defined by dim and dtype parameters.

=item dim

dimension index along which the matrix is reduced. 0 means that the matrix is reduced to
a single row. 1 means that the matrix is reduced to a single column.

=item rtype

reduction operation that could be one of #ReduceTypes

=item dtype

when negative, the output vector will have the same type as the input matrix,
otherwise, its type will be CV_MAKE_TYPE(CV_MAT_DEPTH(dtype), src.channels()).

=back

See also:
repeat


=for bad

reduce ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2320 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::reduce {
  barf "Usage: PDL::OpenCV::reduce(\$src,\$dim,\$rtype,\$dtype)\n" if @_ < 3;
  my ($src,$dim,$rtype,$dtype) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $dtype = -1 if !defined $dtype;
  PDL::OpenCV::_reduce_int($src,$dst,$dim,$rtype,$dtype);
  !wantarray ? $dst : ($dst)
}
#line 2335 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*reduce = \&PDL::OpenCV::reduce;
#line 2342 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 merge

=for sig

  Signature: ([o,phys] dst(l2,c2,r2); vector_MatWrapper * mv)

=for ref

 NO BROADCASTING.

=for example

 $dst = merge($mv);

@overload

Parameters:

=over

=item mv

input vector of matrices to be merged; all the matrices in mv must have the same
size and the same depth.

=item dst

output array of the same size and the same depth as mv[0]; The number of channels will
be the total number of channels in the matrix array.

=back


=for bad

merge ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2390 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::merge {
  barf "Usage: PDL::OpenCV::merge(\$mv)\n" if @_ < 1;
  my ($mv) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::_merge_int($dst,$mv);
  !wantarray ? $dst : ($dst)
}
#line 2404 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*merge = \&PDL::OpenCV::merge;
#line 2411 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 split

=for sig

  Signature: ([phys] m(l1,c1,r1); [o] vector_MatWrapper * mv)

=for ref

=for example

 $mv = split($m);

@overload

Parameters:

=over

=item m

input multi-channel array.

=item mv

output vector of arrays; the arrays themselves are reallocated, if needed.

=back


=for bad

split ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2455 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::split {
  barf "Usage: PDL::OpenCV::split(\$m)\n" if @_ < 1;
  my ($m) = @_;
  my ($mv);
  
  PDL::OpenCV::_split_int($m,$mv);
  !wantarray ? $mv : ($mv)
}
#line 2469 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*split = \&PDL::OpenCV::split;
#line 2476 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 mixChannels

=for sig

  Signature: (int [phys] fromTo(n3d0); vector_MatWrapper * src; [o] vector_MatWrapper * dst)

=for ref

=for example

 mixChannels($src,$dst,$fromTo);

@overload
*2] is
a 0-based index of the input channel in src, fromTo[k*2+1] is an index of the output channel in
dst; the continuous channel numbering is used: the first input image channels are indexed from 0 to
src[0].channels()-1, the second input image channels are indexed from src[0].channels() to
src[0].channels() + src[1].channels()-1, and so on, the same scheme is used for the output image
channels; as a special case, when fromTo[k*2] is negative, the corresponding output channel is
filled with zero .

Parameters:

=over

=item src

input array or vector of matrices; all of the matrices must have the same size and the
same depth.

=item dst

output array or vector of matrices; all the matrices **must be allocated**; their size and
depth must be the same as in src[0].

=item fromTo

array of index pairs specifying which channels are copied and where; fromTo[k

=back


=for bad

mixChannels ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2533 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::mixChannels {
  barf "Usage: PDL::OpenCV::mixChannels(\$src,\$dst,\$fromTo)\n" if @_ < 3;
  my ($src,$dst,$fromTo) = @_;
    
  PDL::OpenCV::_mixChannels_int($fromTo,$src,$dst);
  
}
#line 2546 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*mixChannels = \&PDL::OpenCV::mixChannels;
#line 2553 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 extractChannel

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] coi())

=for ref

Extracts a single channel from src (coi is 0-based index)
 NO BROADCASTING.

=for example

 $dst = extractChannel($src,$coi);

Parameters:

=over

=item src

input array

=item dst

output array

=item coi

index of channel to extract

=back

See also:
mixChannels, split


=for bad

extractChannel ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2605 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::extractChannel {
  barf "Usage: PDL::OpenCV::extractChannel(\$src,\$coi)\n" if @_ < 2;
  my ($src,$coi) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::_extractChannel_int($src,$dst,$coi);
  !wantarray ? $dst : ($dst)
}
#line 2619 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*extractChannel = \&PDL::OpenCV::extractChannel;
#line 2626 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 insertChannel

=for sig

  Signature: ([phys] src(l1,c1,r1); [io,phys] dst(l2,c2,r2); int [phys] coi())

=for ref

Inserts a single channel to dst (coi is 0-based index)

=for example

 insertChannel($src,$dst,$coi);

Parameters:

=over

=item src

input array

=item dst

output array

=item coi

index of channel for insertion

=back

See also:
mixChannels, merge


=for bad

insertChannel ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2677 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::insertChannel {
  barf "Usage: PDL::OpenCV::insertChannel(\$src,\$dst,\$coi)\n" if @_ < 3;
  my ($src,$dst,$coi) = @_;
    
  PDL::OpenCV::_insertChannel_int($src,$dst,$coi);
  
}
#line 2690 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*insertChannel = \&PDL::OpenCV::insertChannel;
#line 2697 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 flip

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] flipCode())

=for ref

Flips a 2D array around vertical, horizontal, or both axes. NO BROADCASTING.

=for example

 $dst = flip($src,$flipCode);

The function cv::flip flips the array in one of three different ways (row
and column indices are 0-based):
\f[\texttt{dst} _{ij} =
\left\{
\begin{array}{l l}
\texttt{src} _{\texttt{src.rows}-i-1,j} & if\;  \texttt{flipCode} = 0 \\
\texttt{src} _{i, \texttt{src.cols} -j-1} & if\;  \texttt{flipCode} > 0 \\
\texttt{src} _{ \texttt{src.rows} -i-1, \texttt{src.cols} -j-1} & if\; \texttt{flipCode} < 0 \\
\end{array}
\right.\f]
The example scenarios of using the function are the following:
*   Vertical flipping of the image (flipCode == 0) to switch between
top-left and bottom-left image origin. This is a typical operation
in video processing on Microsoft Windows* OS.
*   Horizontal flipping of the image with the subsequent horizontal
shift and absolute difference calculation to check for a
vertical-axis symmetry (flipCode \> 0).
*   Simultaneous horizontal and vertical flipping of the image with
the subsequent shift and absolute difference calculation to check
for a central symmetry (flipCode \< 0).
*   Reversing the order of point arrays (flipCode \> 0 or
flipCode == 0).

Parameters:

=over

=item src

input array.

=item dst

output array of the same size and type as src.

=item flipCode

a flag to specify how to flip the array; 0 means
flipping around the x-axis and positive value (for example, 1) means
flipping around y-axis. Negative value (for example, -1) means flipping
around both axes.

=back

See also:
transpose , repeat , completeSymm


=for bad

flip ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2774 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::flip {
  barf "Usage: PDL::OpenCV::flip(\$src,\$flipCode)\n" if @_ < 2;
  my ($src,$flipCode) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::_flip_int($src,$dst,$flipCode);
  !wantarray ? $dst : ($dst)
}
#line 2788 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*flip = \&PDL::OpenCV::flip;
#line 2795 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 rotate

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] rotateCode())

=for ref

Rotates a 2D array in multiples of 90 degrees.
The function cv::rotate rotates the array in one of three different ways:
*   Rotate by 90 degrees clockwise (rotateCode = ROTATE_90_CLOCKWISE).
*   Rotate by 180 degrees clockwise (rotateCode = ROTATE_180).
*   Rotate by 270 degrees clockwise (rotateCode = ROTATE_90_COUNTERCLOCKWISE).
 NO BROADCASTING.

=for example

 $dst = rotate($src,$rotateCode);

Parameters:

=over

=item src

input array.

=item dst

output array of the same type as src.  The size is the same with ROTATE_180,
and the rows and cols are switched for ROTATE_90_CLOCKWISE and ROTATE_90_COUNTERCLOCKWISE.

=item rotateCode

an enum to specify how to rotate the array; see the enum #RotateFlags

=back

See also:
transpose , repeat , completeSymm, flip, RotateFlags


=for bad

rotate ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2852 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::rotate {
  barf "Usage: PDL::OpenCV::rotate(\$src,\$rotateCode)\n" if @_ < 2;
  my ($src,$rotateCode) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::_rotate_int($src,$dst,$rotateCode);
  !wantarray ? $dst : ($dst)
}
#line 2866 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*rotate = \&PDL::OpenCV::rotate;
#line 2873 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 repeat

=for sig

  Signature: ([phys] src(l1,c1,r1); int [phys] ny(); int [phys] nx(); [o,phys] dst(l4,c4,r4))

=for ref

Fills the output array with repeated copies of the input array. NO BROADCASTING.

=for example

 $dst = repeat($src,$ny,$nx);

The function cv::repeat duplicates the input array one or more times along each of the two axes:
\f[\texttt{dst} _{ij}= \texttt{src} _{i\mod src.rows, \; j\mod src.cols }\f]
The second variant of the function is more convenient to use with @ref MatrixExpressions.

Parameters:

=over

=item src

input array to replicate.

=item ny

Flag to specify how many times the `src` is repeated along the
vertical axis.

=item nx

Flag to specify how many times the `src` is repeated along the
horizontal axis.

=item dst

output array of the same type as `src`.

=back

See also:
cv::reduce


=for bad

repeat ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2934 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::repeat {
  barf "Usage: PDL::OpenCV::repeat(\$src,\$ny,\$nx)\n" if @_ < 3;
  my ($src,$ny,$nx) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::_repeat_int($src,$ny,$nx,$dst);
  !wantarray ? $dst : ($dst)
}
#line 2948 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*repeat = \&PDL::OpenCV::repeat;
#line 2955 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 hconcat

=for sig

  Signature: ([o,phys] dst(l2,c2,r2); vector_MatWrapper * src)

=for ref

 NO BROADCASTING.

=for example

 $dst = hconcat($src);

@overload

 {.cpp}
     std::vector<cv::Mat> matrices = { cv::Mat(4, 1, CV_8UC1, cv::Scalar(1)),
                                       cv::Mat(4, 1, CV_8UC1, cv::Scalar(2)),
                                       cv::Mat(4, 1, CV_8UC1, cv::Scalar(3)),};

     cv::Mat out;
     cv::hconcat( matrices, out );
     //out:
     //[1, 2, 3;
     // 1, 2, 3;
     // 1, 2, 3;
     // 1, 2, 3]

Parameters:

=over

=item src

input array or vector of matrices. all of the matrices must have the same number of rows and the same depth.

=item dst

output array. It has the same number of rows and depth as the src, and the sum of cols of the src.
same depth.

=back


=for bad

hconcat ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3015 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::hconcat {
  barf "Usage: PDL::OpenCV::hconcat(\$src)\n" if @_ < 1;
  my ($src) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::_hconcat_int($dst,$src);
  !wantarray ? $dst : ($dst)
}
#line 3029 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*hconcat = \&PDL::OpenCV::hconcat;
#line 3036 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 vconcat

=for sig

  Signature: ([o,phys] dst(l2,c2,r2); vector_MatWrapper * src)

=for ref

 NO BROADCASTING.

=for example

 $dst = vconcat($src);

@overload

 {.cpp}
     std::vector<cv::Mat> matrices = { cv::Mat(1, 4, CV_8UC1, cv::Scalar(1)),
                                       cv::Mat(1, 4, CV_8UC1, cv::Scalar(2)),
                                       cv::Mat(1, 4, CV_8UC1, cv::Scalar(3)),};

     cv::Mat out;
     cv::vconcat( matrices, out );
     //out:
     //[1,   1,   1,   1;
     // 2,   2,   2,   2;
     // 3,   3,   3,   3]

Parameters:

=over

=item src

input array or vector of matrices. all of the matrices must have the same number of cols and the same depth

=item dst

output array. It has the same number of cols and depth as the src, and the sum of rows of the src.
same depth.

=back


=for bad

vconcat ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3095 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::vconcat {
  barf "Usage: PDL::OpenCV::vconcat(\$src)\n" if @_ < 1;
  my ($src) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::_vconcat_int($dst,$src);
  !wantarray ? $dst : ($dst)
}
#line 3109 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*vconcat = \&PDL::OpenCV::vconcat;
#line 3116 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 bitwise_and

=for sig

  Signature: ([phys] src1(l1,c1,r1); [phys] src2(l2,c2,r2); [o,phys] dst(l3,c3,r3); [phys] mask(l4,c4,r4))

=for ref

computes bitwise conjunction of the two arrays (dst = src1 & src2)
Calculates the per-element bit-wise conjunction of two arrays or an
array and a scalar. NO BROADCASTING.

=for example

 $dst = bitwise_and($src1,$src2); # with defaults
 $dst = bitwise_and($src1,$src2,$mask);

The function cv::bitwise_and calculates the per-element bit-wise logical conjunction for:
*   Two arrays when src1 and src2 have the same size:
\f[\texttt{dst} (I) =  \texttt{src1} (I)  \wedge \texttt{src2} (I) \quad \texttt{if mask} (I) \ne0\f]
*   An array and a scalar when src2 is constructed from Scalar or has
the same number of elements as `src1.channels()`:
\f[\texttt{dst} (I) =  \texttt{src1} (I)  \wedge \texttt{src2} \quad \texttt{if mask} (I) \ne0\f]
*   A scalar and an array when src1 is constructed from Scalar or has
the same number of elements as `src2.channels()`:
\f[\texttt{dst} (I) =  \texttt{src1}  \wedge \texttt{src2} (I) \quad \texttt{if mask} (I) \ne0\f]
In case of floating-point arrays, their machine-specific bit
representations (usually IEEE754-compliant) are used for the operation.
In case of multi-channel arrays, each channel is processed
independently. In the second and third cases above, the scalar is first
converted to the array type.

Parameters:

=over

=item src1

first input array or a scalar.

=item src2

second input array or a scalar.

=item dst

output array that has the same size and type as the input
arrays.

=item mask

optional operation mask, 8-bit single channel array, that
specifies elements of the output array to be changed.

=back


=for bad

bitwise_and ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3188 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::bitwise_and {
  barf "Usage: PDL::OpenCV::bitwise_and(\$src1,\$src2,\$mask)\n" if @_ < 2;
  my ($src1,$src2,$mask) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $mask = PDL->zeroes(sbyte,0,0,0) if !defined $mask;
  PDL::OpenCV::_bitwise_and_int($src1,$src2,$dst,$mask);
  !wantarray ? $dst : ($dst)
}
#line 3203 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*bitwise_and = \&PDL::OpenCV::bitwise_and;
#line 3210 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 bitwise_or

=for sig

  Signature: ([phys] src1(l1,c1,r1); [phys] src2(l2,c2,r2); [o,phys] dst(l3,c3,r3); [phys] mask(l4,c4,r4))

=for ref

Calculates the per-element bit-wise disjunction of two arrays or an
array and a scalar. NO BROADCASTING.

=for example

 $dst = bitwise_or($src1,$src2); # with defaults
 $dst = bitwise_or($src1,$src2,$mask);

The function cv::bitwise_or calculates the per-element bit-wise logical disjunction for:
*   Two arrays when src1 and src2 have the same size:
\f[\texttt{dst} (I) =  \texttt{src1} (I)  \vee \texttt{src2} (I) \quad \texttt{if mask} (I) \ne0\f]
*   An array and a scalar when src2 is constructed from Scalar or has
the same number of elements as `src1.channels()`:
\f[\texttt{dst} (I) =  \texttt{src1} (I)  \vee \texttt{src2} \quad \texttt{if mask} (I) \ne0\f]
*   A scalar and an array when src1 is constructed from Scalar or has
the same number of elements as `src2.channels()`:
\f[\texttt{dst} (I) =  \texttt{src1}  \vee \texttt{src2} (I) \quad \texttt{if mask} (I) \ne0\f]
In case of floating-point arrays, their machine-specific bit
representations (usually IEEE754-compliant) are used for the operation.
In case of multi-channel arrays, each channel is processed
independently. In the second and third cases above, the scalar is first
converted to the array type.

Parameters:

=over

=item src1

first input array or a scalar.

=item src2

second input array or a scalar.

=item dst

output array that has the same size and type as the input
arrays.

=item mask

optional operation mask, 8-bit single channel array, that
specifies elements of the output array to be changed.

=back


=for bad

bitwise_or ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3281 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::bitwise_or {
  barf "Usage: PDL::OpenCV::bitwise_or(\$src1,\$src2,\$mask)\n" if @_ < 2;
  my ($src1,$src2,$mask) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $mask = PDL->zeroes(sbyte,0,0,0) if !defined $mask;
  PDL::OpenCV::_bitwise_or_int($src1,$src2,$dst,$mask);
  !wantarray ? $dst : ($dst)
}
#line 3296 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*bitwise_or = \&PDL::OpenCV::bitwise_or;
#line 3303 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 bitwise_xor

=for sig

  Signature: ([phys] src1(l1,c1,r1); [phys] src2(l2,c2,r2); [o,phys] dst(l3,c3,r3); [phys] mask(l4,c4,r4))

=for ref

Calculates the per-element bit-wise "exclusive or" operation on two
arrays or an array and a scalar. NO BROADCASTING.

=for example

 $dst = bitwise_xor($src1,$src2); # with defaults
 $dst = bitwise_xor($src1,$src2,$mask);

The function cv::bitwise_xor calculates the per-element bit-wise logical "exclusive-or"
operation for:
*   Two arrays when src1 and src2 have the same size:
\f[\texttt{dst} (I) =  \texttt{src1} (I)  \oplus \texttt{src2} (I) \quad \texttt{if mask} (I) \ne0\f]
*   An array and a scalar when src2 is constructed from Scalar or has
the same number of elements as `src1.channels()`:
\f[\texttt{dst} (I) =  \texttt{src1} (I)  \oplus \texttt{src2} \quad \texttt{if mask} (I) \ne0\f]
*   A scalar and an array when src1 is constructed from Scalar or has
the same number of elements as `src2.channels()`:
\f[\texttt{dst} (I) =  \texttt{src1}  \oplus \texttt{src2} (I) \quad \texttt{if mask} (I) \ne0\f]
In case of floating-point arrays, their machine-specific bit
representations (usually IEEE754-compliant) are used for the operation.
In case of multi-channel arrays, each channel is processed
independently. In the 2nd and 3rd cases above, the scalar is first
converted to the array type.

Parameters:

=over

=item src1

first input array or a scalar.

=item src2

second input array or a scalar.

=item dst

output array that has the same size and type as the input
arrays.

=item mask

optional operation mask, 8-bit single channel array, that
specifies elements of the output array to be changed.

=back


=for bad

bitwise_xor ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3375 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::bitwise_xor {
  barf "Usage: PDL::OpenCV::bitwise_xor(\$src1,\$src2,\$mask)\n" if @_ < 2;
  my ($src1,$src2,$mask) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $mask = PDL->zeroes(sbyte,0,0,0) if !defined $mask;
  PDL::OpenCV::_bitwise_xor_int($src1,$src2,$dst,$mask);
  !wantarray ? $dst : ($dst)
}
#line 3390 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*bitwise_xor = \&PDL::OpenCV::bitwise_xor;
#line 3397 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 bitwise_not

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); [phys] mask(l3,c3,r3))

=for ref

Inverts every bit of an array. NO BROADCASTING.

=for example

 $dst = bitwise_not($src); # with defaults
 $dst = bitwise_not($src,$mask);

The function cv::bitwise_not calculates per-element bit-wise inversion of the input
array:
\f[\texttt{dst} (I) =  \neg \texttt{src} (I)\f]
In case of a floating-point input array, its machine-specific bit
representation (usually IEEE754-compliant) is used for the operation. In
case of multi-channel arrays, each channel is processed independently.

Parameters:

=over

=item src

input array.

=item dst

output array that has the same size and type as the input
array.

=item mask

optional operation mask, 8-bit single channel array, that
specifies elements of the output array to be changed.

=back


=for bad

bitwise_not ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3455 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::bitwise_not {
  barf "Usage: PDL::OpenCV::bitwise_not(\$src,\$mask)\n" if @_ < 1;
  my ($src,$mask) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $mask = PDL->zeroes(sbyte,0,0,0) if !defined $mask;
  PDL::OpenCV::_bitwise_not_int($src,$dst,$mask);
  !wantarray ? $dst : ($dst)
}
#line 3470 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*bitwise_not = \&PDL::OpenCV::bitwise_not;
#line 3477 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 absdiff

=for sig

  Signature: ([phys] src1(l1,c1,r1); [phys] src2(l2,c2,r2); [o,phys] dst(l3,c3,r3))

=for ref

Calculates the per-element absolute difference between two arrays or between an array and a scalar. NO BROADCASTING.

=for example

 $dst = absdiff($src1,$src2);

The function cv::absdiff calculates:
*   Absolute difference between two arrays when they have the same
size and type:
\f[\texttt{dst}(I) =  \texttt{saturate} (| \texttt{src1}(I) -  \texttt{src2}(I)|)\f]
*   Absolute difference between an array and a scalar when the second
array is constructed from Scalar or has as many elements as the
number of channels in `src1`:
\f[\texttt{dst}(I) =  \texttt{saturate} (| \texttt{src1}(I) -  \texttt{src2} |)\f]
*   Absolute difference between a scalar and an array when the first
array is constructed from Scalar or has as many elements as the
number of channels in `src2`:
\f[\texttt{dst}(I) =  \texttt{saturate} (| \texttt{src1} -  \texttt{src2}(I) |)\f]
where I is a multi-dimensional index of array elements. In case of
multi-channel arrays, each channel is processed independently.
@note Saturation is not applied when the arrays have the depth CV_32S.
You may even get a negative value in the case of overflow.

Parameters:

=over

=item src1

first input array or a scalar.

=item src2

second input array or a scalar.

=item dst

output array that has the same size and type as input arrays.

=back

See also:
cv::abs(const Mat&)


=for bad

absdiff ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3545 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::absdiff {
  barf "Usage: PDL::OpenCV::absdiff(\$src1,\$src2)\n" if @_ < 2;
  my ($src1,$src2) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::_absdiff_int($src1,$src2,$dst);
  !wantarray ? $dst : ($dst)
}
#line 3559 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*absdiff = \&PDL::OpenCV::absdiff;
#line 3566 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 copyTo

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); [phys] mask(l3,c3,r3))

=for ref

This is an overloaded member function, provided for convenience (python)
Copies the matrix to another one.
When the operation mask is specified, if the Mat::create call shown above reallocates the matrix, the newly allocated matrix is initialized with all zeros before copying the data.
 NO BROADCASTING.

=for example

 $dst = copyTo($src,$mask);

*this. Its non-zero elements indicate which matrix
elements need to be copied. The mask has to be of type CV_8U and can have 1 or multiple channels.

Parameters:

=over

=item src

source matrix.

=item dst

Destination matrix. If it does not have a proper size or type before the operation, it is
reallocated.

=item mask

Operation mask of the same size as

=back


=for bad

copyTo ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3621 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::copyTo {
  barf "Usage: PDL::OpenCV::copyTo(\$src,\$mask)\n" if @_ < 2;
  my ($src,$mask) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::_copyTo_int($src,$dst,$mask);
  !wantarray ? $dst : ($dst)
}
#line 3635 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*copyTo = \&PDL::OpenCV::copyTo;
#line 3642 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 inRange

=for sig

  Signature: ([phys] src(l1,c1,r1); [phys] lowerb(l2,c2,r2); [phys] upperb(l3,c3,r3); [o,phys] dst(l4,c4,r4))

=for ref

Checks if array elements lie between the elements of two other arrays. NO BROADCASTING.

=for example

 $dst = inRange($src,$lowerb,$upperb);

The function checks the range as follows:
=over
=item *
and so forth.
=back
That is, dst (I) is set to 255 (all 1 -bits) if src (I) is within the
specified 1D, 2D, 3D, ... box and 0 otherwise.
When the lower and/or upper boundary parameters are scalars, the indexes
(I) at lowerb and upperb in the above formulas should be omitted.

Parameters:

=over

=item src

first input array.

=item lowerb

inclusive lower boundary array or a scalar.

=item upperb

inclusive upper boundary array or a scalar.

=item dst

output array of the same size as src and CV_8U type.

=back


=for bad

inRange ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3704 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::inRange {
  barf "Usage: PDL::OpenCV::inRange(\$src,\$lowerb,\$upperb)\n" if @_ < 3;
  my ($src,$lowerb,$upperb) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::_inRange_int($src,$lowerb,$upperb,$dst);
  !wantarray ? $dst : ($dst)
}
#line 3718 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*inRange = \&PDL::OpenCV::inRange;
#line 3725 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 compare

=for sig

  Signature: ([phys] src1(l1,c1,r1); [phys] src2(l2,c2,r2); [o,phys] dst(l3,c3,r3); int [phys] cmpop())

=for ref

Performs the per-element comparison of two arrays or an array and scalar value. NO BROADCASTING.

=for example

 $dst = compare($src1,$src2,$cmpop);

The function compares:
*   Elements of two arrays when src1 and src2 have the same size:
\f[\texttt{dst} (I) =  \texttt{src1} (I)  \,\texttt{cmpop}\, \texttt{src2} (I)\f]
*   Elements of src1 with a scalar src2 when src2 is constructed from
Scalar or has a single element:
\f[\texttt{dst} (I) =  \texttt{src1}(I) \,\texttt{cmpop}\,  \texttt{src2}\f]
*   src1 with elements of src2 when src1 is constructed from Scalar or
has a single element:
\f[\texttt{dst} (I) =  \texttt{src1}  \,\texttt{cmpop}\, \texttt{src2} (I)\f]
When the comparison result is true, the corresponding element of output
array is set to 255. The comparison operations can be replaced with the
equivalent matrix expressions:

 {.cpp}
     Mat dst1 = src1 >= src2;
     Mat dst2 = src1 < 8;
     ...

Parameters:

=over

=item src1

first input array or a scalar; when it is an array, it must have a single channel.

=item src2

second input array or a scalar; when it is an array, it must have a single channel.

=item dst

output array of type ref CV_8U that has the same size and the same number of channels as
    the input arrays.

=item cmpop

a flag, that specifies correspondence between the arrays (cv::CmpTypes)

=back

See also:
checkRange, min, max, threshold


=for bad

compare ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3799 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::compare {
  barf "Usage: PDL::OpenCV::compare(\$src1,\$src2,\$cmpop)\n" if @_ < 3;
  my ($src1,$src2,$cmpop) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::_compare_int($src1,$src2,$dst,$cmpop);
  !wantarray ? $dst : ($dst)
}
#line 3813 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*compare = \&PDL::OpenCV::compare;
#line 3820 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 min

=for sig

  Signature: ([phys] src1(l1,c1,r1); [phys] src2(l2,c2,r2); [o,phys] dst(l3,c3,r3))

=for ref

Calculates per-element minimum of two arrays or an array and a scalar. NO BROADCASTING.

=for example

 $dst = min($src1,$src2);

The function cv::min calculates the per-element minimum of two arrays:
\f[\texttt{dst} (I)= \min ( \texttt{src1} (I), \texttt{src2} (I))\f]
or array and a scalar:
\f[\texttt{dst} (I)= \min ( \texttt{src1} (I), \texttt{value} )\f]

Parameters:

=over

=item src1

first input array.

=item src2

second input array of the same size and type as src1.

=item dst

output array of the same size and type as src1.

=back

See also:
max, compare, inRange, minMaxLoc


=for bad

min ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3876 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::min {
  barf "Usage: PDL::OpenCV::min(\$src1,\$src2)\n" if @_ < 2;
  my ($src1,$src2) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::_min_int($src1,$src2,$dst);
  !wantarray ? $dst : ($dst)
}
#line 3890 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*min = \&PDL::OpenCV::min;
#line 3897 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 max

=for sig

  Signature: ([phys] src1(l1,c1,r1); [phys] src2(l2,c2,r2); [o,phys] dst(l3,c3,r3))

=for ref

Calculates per-element maximum of two arrays or an array and a scalar. NO BROADCASTING.

=for example

 $dst = max($src1,$src2);

The function cv::max calculates the per-element maximum of two arrays:
\f[\texttt{dst} (I)= \max ( \texttt{src1} (I), \texttt{src2} (I))\f]
or array and a scalar:
\f[\texttt{dst} (I)= \max ( \texttt{src1} (I), \texttt{value} )\f]
@ref MatrixExpressions

Parameters:

=over

=item src1

first input array.

=item src2

second input array of the same size and type as src1 .

=item dst

output array of the same size and type as src1.

=back

See also:
min, compare, inRange, minMaxLoc,


=for bad

max ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3954 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::max {
  barf "Usage: PDL::OpenCV::max(\$src1,\$src2)\n" if @_ < 2;
  my ($src1,$src2) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::_max_int($src1,$src2,$dst);
  !wantarray ? $dst : ($dst)
}
#line 3968 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*max = \&PDL::OpenCV::max;
#line 3975 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 sqrt

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2))

=for ref

Calculates a square root of array elements. NO BROADCASTING.

=for example

 $dst = sqrt($src);

The function cv::sqrt calculates a square root of each input array element.
In case of multi-channel arrays, each channel is processed
independently. The accuracy is approximately the same as of the built-in
std::sqrt .

Parameters:

=over

=item src

input floating-point array.

=item dst

output array of the same size and type as src.

=back


=for bad

sqrt ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4024 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::sqrt {
  barf "Usage: PDL::OpenCV::sqrt(\$src)\n" if @_ < 1;
  my ($src) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::_sqrt_int($src,$dst);
  !wantarray ? $dst : ($dst)
}
#line 4038 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*sqrt = \&PDL::OpenCV::sqrt;
#line 4045 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 pow

=for sig

  Signature: ([phys] src(l1,c1,r1); double [phys] power(); [o,phys] dst(l3,c3,r3))

=for ref

Raises every array element to a power. NO BROADCASTING.

=for example

 $dst = pow($src,$power);

The function cv::pow raises every element of the input array to power :
\f[\texttt{dst} (I) =  \fork{\texttt{src}(I)^{power}}{if \(\texttt{power}\) is integer}{|\texttt{src}(I)|^{power}}{otherwise}\f]
So, for a non-integer power exponent, the absolute values of input array
elements are used. However, it is possible to get true values for
negative values using some extra operations. In the example below,
computing the 5th root of array src shows:

 {.cpp}
     Mat mask = src < 0;
     pow(src, 1./5, dst);
     subtract(Scalar::all(0), dst, dst, mask);

For some values of power, such as integer values, 0.5 and -0.5,
specialized faster algorithms are used.
Special values (NaN, Inf) are not handled.

Parameters:

=over

=item src

input array.

=item power

exponent of power.

=item dst

output array of the same size and type as src.

=back

See also:
sqrt, exp, log, cartToPolar, polarToCart


=for bad

pow ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4112 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::pow {
  barf "Usage: PDL::OpenCV::pow(\$src,\$power)\n" if @_ < 2;
  my ($src,$power) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::_pow_int($src,$power,$dst);
  !wantarray ? $dst : ($dst)
}
#line 4126 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*pow = \&PDL::OpenCV::pow;
#line 4133 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 exp

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2))

=for ref

Calculates the exponent of every array element. NO BROADCASTING.

=for example

 $dst = exp($src);

The function cv::exp calculates the exponent of every element of the input
array:
\f[\texttt{dst} [I] = e^{ src(I) }\f]
The maximum relative error is about 7e-6 for single-precision input and
less than 1e-10 for double-precision input. Currently, the function
converts denormalized values to zeros on output. Special values (NaN,
Inf) are not handled.

Parameters:

=over

=item src

input array.

=item dst

output array of the same size and type as src.

=back

See also:
log , cartToPolar , polarToCart , phase , pow , sqrt , magnitude


=for bad

exp ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4188 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::exp {
  barf "Usage: PDL::OpenCV::exp(\$src)\n" if @_ < 1;
  my ($src) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::_exp_int($src,$dst);
  !wantarray ? $dst : ($dst)
}
#line 4202 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*exp = \&PDL::OpenCV::exp;
#line 4209 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 log

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2))

=for ref

Calculates the natural logarithm of every array element. NO BROADCASTING.

=for example

 $dst = log($src);

The function cv::log calculates the natural logarithm of every element of the input array:
\f[\texttt{dst} (I) =  \log (\texttt{src}(I)) \f]
Output on zero, negative and special (NaN, Inf) values is undefined.

Parameters:

=over

=item src

input array.

=item dst

output array of the same size and type as src .

=back

See also:
exp, cartToPolar, polarToCart, phase, pow, sqrt, magnitude


=for bad

log ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4260 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::log {
  barf "Usage: PDL::OpenCV::log(\$src)\n" if @_ < 1;
  my ($src) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::_log_int($src,$dst);
  !wantarray ? $dst : ($dst)
}
#line 4274 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*log = \&PDL::OpenCV::log;
#line 4281 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 polarToCart

=for sig

  Signature: ([phys] magnitude(l1,c1,r1); [phys] angle(l2,c2,r2); [o,phys] x(l3,c3,r3); [o,phys] y(l4,c4,r4); byte [phys] angleInDegrees())

=for ref

Calculates x and y coordinates of 2D vectors from their magnitude and angle. NO BROADCASTING.

=for example

 ($x,$y) = polarToCart($magnitude,$angle); # with defaults
 ($x,$y) = polarToCart($magnitude,$angle,$angleInDegrees);

The function cv::polarToCart calculates the Cartesian coordinates of each 2D
vector represented by the corresponding elements of magnitude and angle:
\f[\begin{array}{l} \texttt{x} (I) =  \texttt{magnitude} (I) \cos ( \texttt{angle} (I)) \\ \texttt{y} (I) =  \texttt{magnitude} (I) \sin ( \texttt{angle} (I)) \\ \end{array}\f]
The relative accuracy of the estimated coordinates is about 1e-6.

Parameters:

=over

=item magnitude

input floating-point array of magnitudes of 2D vectors;
it can be an empty matrix (=Mat()), in this case, the function assumes
that all the magnitudes are =1; if it is not empty, it must have the
same size and type as angle.

=item angle

input floating-point array of angles of 2D vectors.

=item x

output array of x-coordinates of 2D vectors; it has the same
size and type as angle.

=item y

output array of y-coordinates of 2D vectors; it has the same
size and type as angle.

=item angleInDegrees

when true, the input angles are measured in
degrees, otherwise, they are measured in radians.

=back

See also:
cartToPolar, magnitude, phase, exp, log, pow, sqrt


=for bad

polarToCart ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4352 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::polarToCart {
  barf "Usage: PDL::OpenCV::polarToCart(\$magnitude,\$angle,\$angleInDegrees)\n" if @_ < 2;
  my ($magnitude,$angle,$angleInDegrees) = @_;
  my ($x,$y);
  $x = PDL->null if !defined $x;
  $y = PDL->null if !defined $y;
  $angleInDegrees = 0 if !defined $angleInDegrees;
  PDL::OpenCV::_polarToCart_int($magnitude,$angle,$x,$y,$angleInDegrees);
  !wantarray ? $y : ($x,$y)
}
#line 4368 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*polarToCart = \&PDL::OpenCV::polarToCart;
#line 4375 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 cartToPolar

=for sig

  Signature: ([phys] x(l1,c1,r1); [phys] y(l2,c2,r2); [o,phys] magnitude(l3,c3,r3); [o,phys] angle(l4,c4,r4); byte [phys] angleInDegrees())

=for ref

Calculates the magnitude and angle of 2D vectors. NO BROADCASTING.

=for example

 ($magnitude,$angle) = cartToPolar($x,$y); # with defaults
 ($magnitude,$angle) = cartToPolar($x,$y,$angleInDegrees);

The function cv::cartToPolar calculates either the magnitude, angle, or both
for every 2D vector (x(I),y(I)):
\f[\begin{array}{l} \texttt{magnitude} (I)= \sqrt{\texttt{x}(I)^2+\texttt{y}(I)^2} , \\ \texttt{angle} (I)= \texttt{atan2} ( \texttt{y} (I), \texttt{x} (I))[ \cdot180 / \pi ] \end{array}\f]
The angles are calculated with accuracy about 0.3 degrees. For the point
(0,0), the angle is set to 0.
*Pi) or in degrees (0 to 360 degrees).

Parameters:

=over

=item x

array of x-coordinates; this must be a single-precision or
double-precision floating-point array.

=item y

array of y-coordinates, that must have the same size and same type as x.

=item magnitude

output array of magnitudes of the same size and type as x.

=item angle

output array of angles that has the same size and type as
x; the angles are measured in radians (from 0 to 2

=item angleInDegrees

a flag, indicating whether the angles are measured
in radians (which is by default), or in degrees.

=back

See also:
Sobel, Scharr


=for bad

cartToPolar ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4445 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::cartToPolar {
  barf "Usage: PDL::OpenCV::cartToPolar(\$x,\$y,\$angleInDegrees)\n" if @_ < 2;
  my ($x,$y,$angleInDegrees) = @_;
  my ($magnitude,$angle);
  $magnitude = PDL->null if !defined $magnitude;
  $angle = PDL->null if !defined $angle;
  $angleInDegrees = 0 if !defined $angleInDegrees;
  PDL::OpenCV::_cartToPolar_int($x,$y,$magnitude,$angle,$angleInDegrees);
  !wantarray ? $angle : ($magnitude,$angle)
}
#line 4461 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*cartToPolar = \&PDL::OpenCV::cartToPolar;
#line 4468 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 phase

=for sig

  Signature: ([phys] x(l1,c1,r1); [phys] y(l2,c2,r2); [o,phys] angle(l3,c3,r3); byte [phys] angleInDegrees())

=for ref

Calculates the rotation angle of 2D vectors. NO BROADCASTING.

=for example

 $angle = phase($x,$y); # with defaults
 $angle = phase($x,$y,$angleInDegrees);

The function cv::phase calculates the rotation angle of each 2D vector that
is formed from the corresponding elements of x and y :
\f[\texttt{angle} (I) =  \texttt{atan2} ( \texttt{y} (I), \texttt{x} (I))\f]
The angle estimation accuracy is about 0.3 degrees. When x(I)=y(I)=0 ,
the corresponding angle(I) is set to 0.

Parameters:

=over

=item x

input floating-point array of x-coordinates of 2D vectors.

=item y

input array of y-coordinates of 2D vectors; it must have the
same size and the same type as x.

=item angle

output array of vector angles; it has the same size and
same type as x .

=item angleInDegrees

when true, the function calculates the angle in
degrees, otherwise, they are measured in radians.

=back


=for bad

phase ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4530 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::phase {
  barf "Usage: PDL::OpenCV::phase(\$x,\$y,\$angleInDegrees)\n" if @_ < 2;
  my ($x,$y,$angleInDegrees) = @_;
  my ($angle);
  $angle = PDL->null if !defined $angle;
  $angleInDegrees = 0 if !defined $angleInDegrees;
  PDL::OpenCV::_phase_int($x,$y,$angle,$angleInDegrees);
  !wantarray ? $angle : ($angle)
}
#line 4545 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*phase = \&PDL::OpenCV::phase;
#line 4552 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 magnitude

=for sig

  Signature: ([phys] x(l1,c1,r1); [phys] y(l2,c2,r2); [o,phys] magnitude(l3,c3,r3))

=for ref

Calculates the magnitude of 2D vectors. NO BROADCASTING.

=for example

 $magnitude = magnitude($x,$y);

The function cv::magnitude calculates the magnitude of 2D vectors formed
from the corresponding elements of x and y arrays:
\f[\texttt{dst} (I) =  \sqrt{\texttt{x}(I)^2 + \texttt{y}(I)^2}\f]

Parameters:

=over

=item x

floating-point array of x-coordinates of the vectors.

=item y

floating-point array of y-coordinates of the vectors; it must
have the same size as x.

=item magnitude

output array of the same size and type as x.

=back

See also:
cartToPolar, polarToCart, phase, sqrt


=for bad

magnitude ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4608 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::magnitude {
  barf "Usage: PDL::OpenCV::magnitude(\$x,\$y)\n" if @_ < 2;
  my ($x,$y) = @_;
  my ($magnitude);
  $magnitude = PDL->null if !defined $magnitude;
  PDL::OpenCV::_magnitude_int($x,$y,$magnitude);
  !wantarray ? $magnitude : ($magnitude)
}
#line 4622 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*magnitude = \&PDL::OpenCV::magnitude;
#line 4629 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 checkRange

=for sig

  Signature: ([phys] a(l1,c1,r1); byte [phys] quiet(); indx [o,phys] pos(n3=2); double [phys] minVal(); double [phys] maxVal(); byte [o,phys] res())

=for ref

Checks every element of an input array for invalid values.

=for example

 ($pos,$res) = checkRange($a); # with defaults
 ($pos,$res) = checkRange($a,$quiet,$minVal,$maxVal);

The function cv::checkRange checks that every array element is neither NaN nor infinite. When minVal \>
-DBL_MAX and maxVal \< DBL_MAX, the function also checks that each value is between minVal and
maxVal. In case of multi-channel arrays, each channel is processed independently. If some values
are out of range, position of the first outlier is stored in pos (when pos != NULL). Then, the
function either returns false (when quiet=true) or throws an exception.

Parameters:

=over

=item a

input array.

=item quiet

a flag, indicating whether the functions quietly return false when the array elements
are out of range or they throw an exception.

=item pos

optional output parameter, when not NULL, must be a pointer to array of src.dims
elements.

=item minVal

inclusive lower boundary of valid values range.

=item maxVal

exclusive upper boundary of valid values range.

=back


=for bad

checkRange ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4694 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::checkRange {
  barf "Usage: PDL::OpenCV::checkRange(\$a,\$quiet,\$minVal,\$maxVal)\n" if @_ < 1;
  my ($a,$quiet,$minVal,$maxVal) = @_;
  my ($pos,$res);
  $quiet = 1 if !defined $quiet;
  $pos = PDL->null if !defined $pos;
  $minVal = -DBL_MAX() if !defined $minVal;
  $maxVal = DBL_MAX() if !defined $maxVal;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::_checkRange_int($a,$quiet,$pos,$minVal,$maxVal,$res);
  !wantarray ? $res : ($pos,$res)
}
#line 4712 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*checkRange = \&PDL::OpenCV::checkRange;
#line 4719 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 patchNaNs

=for sig

  Signature: ([io,phys] a(l1,c1,r1); double [phys] val())

=for ref

converts NaNs to the given number

=for example

 patchNaNs($a); # with defaults
 patchNaNs($a,$val);

Parameters:

=over

=item a

input/output matrix (CV_32F type).

=item val

value to convert the NaNs

=back


=for bad

patchNaNs ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4764 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::patchNaNs {
  barf "Usage: PDL::OpenCV::patchNaNs(\$a,\$val)\n" if @_ < 1;
  my ($a,$val) = @_;
    $val = 0 if !defined $val;
  PDL::OpenCV::_patchNaNs_int($a,$val);
  
}
#line 4777 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*patchNaNs = \&PDL::OpenCV::patchNaNs;
#line 4784 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 gemm

=for sig

  Signature: ([phys] src1(l1,c1,r1); [phys] src2(l2,c2,r2); double [phys] alpha(); [phys] src3(l4,c4,r4); double [phys] beta(); [o,phys] dst(l6,c6,r6); int [phys] flags())

=for ref

Performs generalized matrix multiplication. NO BROADCASTING.

=for example

 $dst = gemm($src1,$src2,$alpha,$src3,$beta); # with defaults
 $dst = gemm($src1,$src2,$alpha,$src3,$beta,$flags);

The function cv::gemm performs generalized matrix multiplication similar to the
gemm functions in BLAS level 3. For example,
`gemm(src1, src2, alpha, src3, beta, dst, GEMM_1_T + GEMM_3_T)`
corresponds to
\f[\texttt{dst} =  \texttt{alpha} \cdot \texttt{src1} ^T  \cdot \texttt{src2} +  \texttt{beta} \cdot \texttt{src3} ^T\f]
In case of complex (two-channel) data, performed a complex matrix
multiplication.
The function can be replaced with a matrix expression. For example, the
above call can be replaced with:

 {.cpp}
     dst = alpha*src1.t()*src2 + beta*src3.t();

Parameters:

=over

=item src1

first multiplied input matrix that could be real(CV_32FC1,
CV_64FC1) or complex(CV_32FC2, CV_64FC2).

=item src2

second multiplied input matrix of the same type as src1.

=item alpha

weight of the matrix product.

=item src3

third optional delta matrix added to the matrix product; it
should have the same type as src1 and src2.

=item beta

weight of src3.

=item dst

output matrix; it has the proper size and the same type as
input matrices.

=item flags

operation flags (cv::GemmFlags)

=back

See also:
mulTransposed , transform


=for bad

gemm ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4868 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::gemm {
  barf "Usage: PDL::OpenCV::gemm(\$src1,\$src2,\$alpha,\$src3,\$beta,\$flags)\n" if @_ < 5;
  my ($src1,$src2,$alpha,$src3,$beta,$flags) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $flags = 0 if !defined $flags;
  PDL::OpenCV::_gemm_int($src1,$src2,$alpha,$src3,$beta,$dst,$flags);
  !wantarray ? $dst : ($dst)
}
#line 4883 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*gemm = \&PDL::OpenCV::gemm;
#line 4890 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 mulTransposed

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); byte [phys] aTa(); [phys] delta(l4,c4,r4); double [phys] scale(); int [phys] dtype())

=for ref

Calculates the product of a matrix and its transposition. NO BROADCASTING.

=for example

 $dst = mulTransposed($src,$aTa); # with defaults
 $dst = mulTransposed($src,$aTa,$delta,$scale,$dtype);

The function cv::mulTransposed calculates the product of src and its
transposition:
\f[\texttt{dst} = \texttt{scale} ( \texttt{src} - \texttt{delta} )^T ( \texttt{src} - \texttt{delta} )\f]
if aTa=true , and
\f[\texttt{dst} = \texttt{scale} ( \texttt{src} - \texttt{delta} ) ( \texttt{src} - \texttt{delta} )^T\f]
otherwise. The function is used to calculate the covariance matrix. With
zero delta, it can be used as a faster substitute for general matrix
product A*B when B=A'

Parameters:

=over

=item src

input single-channel matrix. Note that unlike gemm, the
function can multiply not only floating-point matrices.

=item dst

output square matrix.

=item aTa

Flag specifying the multiplication ordering. See the
description below.

=item delta

Optional delta matrix subtracted from src before the
multiplication. When the matrix is empty ( delta=noArray() ), it is
assumed to be zero, that is, nothing is subtracted. If it has the same
size as src , it is simply subtracted. Otherwise, it is "repeated" (see
repeat ) to cover the full src and then subtracted. Type of the delta
matrix, when it is not empty, must be the same as the type of created
output matrix. See the dtype parameter description below.

=item scale

Optional scale factor for the matrix product.

=item dtype

Optional type of the output matrix. When it is negative,
the output matrix will have the same type as src . Otherwise, it will be
type=CV_MAT_DEPTH(dtype) that should be either CV_32F or CV_64F .

=back

See also:
calcCovarMatrix, gemm, repeat, reduce


=for bad

mulTransposed ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4973 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::mulTransposed {
  barf "Usage: PDL::OpenCV::mulTransposed(\$src,\$aTa,\$delta,\$scale,\$dtype)\n" if @_ < 2;
  my ($src,$aTa,$delta,$scale,$dtype) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $delta = PDL->zeroes(sbyte,0,0,0) if !defined $delta;
  $scale = 1 if !defined $scale;
  $dtype = -1 if !defined $dtype;
  PDL::OpenCV::_mulTransposed_int($src,$dst,$aTa,$delta,$scale,$dtype);
  !wantarray ? $dst : ($dst)
}
#line 4990 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*mulTransposed = \&PDL::OpenCV::mulTransposed;
#line 4997 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 transpose

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2))

=for ref

Transposes a matrix. NO BROADCASTING.

=for example

 $dst = transpose($src);

The function cv::transpose transposes the matrix src :
\f[\texttt{dst} (i,j) =  \texttt{src} (j,i)\f]
@note No complex conjugation is done in case of a complex matrix. It
should be done separately if needed.

Parameters:

=over

=item src

input array.

=item dst

output array of the same type as src.

=back


=for bad

transpose ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5046 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::transpose {
  barf "Usage: PDL::OpenCV::transpose(\$src)\n" if @_ < 1;
  my ($src) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::_transpose_int($src,$dst);
  !wantarray ? $dst : ($dst)
}
#line 5060 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*transpose = \&PDL::OpenCV::transpose;
#line 5067 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 transform

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); [phys] m(l3,c3,r3))

=for ref

Performs the matrix transformation of every array element. NO BROADCASTING.

=for example

 $dst = transform($src,$m);

The function cv::transform performs the matrix transformation of every
element of the array src and stores the results in dst :
\f[\texttt{dst} (I) =  \texttt{m} \cdot \texttt{src} (I)\f]
(when m.cols=src.channels() ), or
\f[\texttt{dst} (I) =  \texttt{m} \cdot [ \texttt{src} (I); 1]\f]
(when m.cols=src.channels()+1 )
Every element of the N -channel array src is interpreted as N -element
vector that is transformed using the M x N or M x (N+1) matrix m to
M-element vector - the corresponding element of the output array dst .
The function may be used for geometrical transformation of
N -dimensional points, arbitrary linear color space transformation (such
as various kinds of RGB to YUV transforms), shuffling the image
channels, and so forth.

Parameters:

=over

=item src

input array that must have as many channels (1 to 4) as
m.cols or m.cols-1.

=item dst

output array of the same size and depth as src; it has as
many channels as m.rows.

=item m

transformation 2x2 or 2x3 floating-point matrix.

=back

See also:
perspectiveTransform, getAffineTransform, estimateAffine2D, warpAffine, warpPerspective


=for bad

transform ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5134 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::transform {
  barf "Usage: PDL::OpenCV::transform(\$src,\$m)\n" if @_ < 2;
  my ($src,$m) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::_transform_int($src,$dst,$m);
  !wantarray ? $dst : ($dst)
}
#line 5148 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*transform = \&PDL::OpenCV::transform;
#line 5155 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 perspectiveTransform

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); [phys] m(l3,c3,r3))

=for ref

Performs the perspective matrix transformation of vectors. NO BROADCASTING.

=for example

 $dst = perspectiveTransform($src,$m);

The function cv::perspectiveTransform transforms every element of src by
treating it as a 2D or 3D vector, in the following way:
\f[(x, y, z)  \rightarrow (x'/w, y'/w, z'/w)\f]
where
\f[(x', y', z', w') =  \texttt{mat} \cdot \begin{bmatrix} x & y & z & 1  \end{bmatrix}\f]
and
\f[w =  \fork{w'}{if \(w' \ne 0\)}{\infty}{otherwise}\f]
Here a 3D vector transformation is shown. In case of a 2D vector
transformation, the z component is omitted.
@note The function transforms a sparse set of 2D or 3D vectors. If you
want to transform an image using perspective transformation, use
warpPerspective . If you have an inverse problem, that is, you want to
compute the most probable perspective transformation out of several
pairs of corresponding points, you can use getPerspectiveTransform or
findHomography .

Parameters:

=over

=item src

input two-channel or three-channel floating-point array; each
element is a 2D/3D vector to be transformed.

=item dst

output array of the same size and type as src.

=item m

3x3 or 4x4 floating-point transformation matrix.

=back

See also:
transform, warpPerspective, getPerspectiveTransform, findHomography


=for bad

perspectiveTransform ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5223 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::perspectiveTransform {
  barf "Usage: PDL::OpenCV::perspectiveTransform(\$src,\$m)\n" if @_ < 2;
  my ($src,$m) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::_perspectiveTransform_int($src,$dst,$m);
  !wantarray ? $dst : ($dst)
}
#line 5237 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*perspectiveTransform = \&PDL::OpenCV::perspectiveTransform;
#line 5244 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 completeSymm

=for sig

  Signature: ([io,phys] m(l1,c1,r1); byte [phys] lowerToUpper())

=for ref

Copies the lower or the upper half of a square matrix to its another half.

=for example

 completeSymm($m); # with defaults
 completeSymm($m,$lowerToUpper);

The function cv::completeSymm copies the lower or the upper half of a square matrix to
its another half. The matrix diagonal remains unchanged:
- C<<< \texttt{m}_{ij}=\texttt{m}_{ji} >>>for C<<< i > j >>>if
lowerToUpper=false
- C<<< \texttt{m}_{ij}=\texttt{m}_{ji} >>>for C<<< i < j >>>if
lowerToUpper=true

Parameters:

=over

=item m

input-output floating-point square matrix.

=item lowerToUpper

operation flag; if true, the lower half is copied to
the upper half. Otherwise, the upper half is copied to the lower half.

=back

See also:
flip, transpose


=for bad

completeSymm ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5300 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::completeSymm {
  barf "Usage: PDL::OpenCV::completeSymm(\$m,\$lowerToUpper)\n" if @_ < 1;
  my ($m,$lowerToUpper) = @_;
    $lowerToUpper = 0 if !defined $lowerToUpper;
  PDL::OpenCV::_completeSymm_int($m,$lowerToUpper);
  
}
#line 5313 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*completeSymm = \&PDL::OpenCV::completeSymm;
#line 5320 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 setIdentity

=for sig

  Signature: ([io,phys] mtx(l1,c1,r1); double [phys] s(n2=4))

=for ref

Initializes a scaled identity matrix.

=for example

 setIdentity($mtx); # with defaults
 setIdentity($mtx,$s);

The function cv::setIdentity initializes a scaled identity matrix:
\f[\texttt{mtx} (i,j)= \fork{\texttt{value}}{ if \(i=j\)}{0}{otherwise}\f]
The function can also be emulated using the matrix initializers and the
matrix expressions:

     Mat A = Mat::eye(4, 3, CV_32F)*5;
     // A will be set to [[5, 0, 0], [0, 5, 0], [0, 0, 5], [0, 0, 0]]

Parameters:

=over

=item mtx

matrix to initialize (not necessarily square).

=item s

value to assign to diagonal elements.

=back

See also:
Mat::zeros, Mat::ones, Mat::setTo, Mat::operator=


=for bad

setIdentity ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5376 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::setIdentity {
  barf "Usage: PDL::OpenCV::setIdentity(\$mtx,\$s)\n" if @_ < 1;
  my ($mtx,$s) = @_;
    $s = double(1) if !defined $s;
  PDL::OpenCV::_setIdentity_int($mtx,$s);
  
}
#line 5389 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*setIdentity = \&PDL::OpenCV::setIdentity;
#line 5396 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 determinant

=for sig

  Signature: ([phys] mtx(l1,c1,r1); double [o,phys] res())

=for ref

Returns the determinant of a square floating-point matrix.

=for example

 $res = determinant($mtx);

The function cv::determinant calculates and returns the determinant of the
specified matrix. For small matrices ( mtx.cols=mtx.rows\<=3 ), the
direct method is used. For larger matrices, the function uses LU
factorization with partial pivoting.
For symmetric positively-determined matrices, it is also possible to use
eigen decomposition to calculate the determinant.
@ref MatrixExpressions

Parameters:

=over

=item mtx

input matrix that must have CV_32FC1 or CV_64FC1 type and
square size.

=back

See also:
trace, invert, solve, eigen,


=for bad

determinant ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5448 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::determinant {
  barf "Usage: PDL::OpenCV::determinant(\$mtx)\n" if @_ < 1;
  my ($mtx) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::_determinant_int($mtx,$res);
  !wantarray ? $res : ($res)
}
#line 5462 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*determinant = \&PDL::OpenCV::determinant;
#line 5469 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 trace

=for sig

  Signature: ([phys] mtx(l1,c1,r1); double [o,phys] res(n2=4))

=for ref

Returns the trace of a matrix.

=for example

 $res = trace($mtx);

The function cv::trace returns the sum of the diagonal elements of the
matrix mtx .
\f[\mathrm{tr} ( \texttt{mtx} ) =  \sum _i  \texttt{mtx} (i,i)\f]

Parameters:

=over

=item mtx

input matrix.

=back


=for bad

trace ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5513 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::trace {
  barf "Usage: PDL::OpenCV::trace(\$mtx)\n" if @_ < 1;
  my ($mtx) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::_trace_int($mtx,$res);
  !wantarray ? $res : ($res)
}
#line 5527 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*trace = \&PDL::OpenCV::trace;
#line 5534 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 invert

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] flags(); double [o,phys] res())

=for ref

Finds the inverse or pseudo-inverse of a matrix. NO BROADCASTING.

=for example

 ($dst,$res) = invert($src); # with defaults
 ($dst,$res) = invert($src,$flags);

The function cv::invert inverts the matrix src and stores the result in dst
. When the matrix src is singular or non-square, the function calculates
the pseudo-inverse matrix (the dst matrix) so that norm(src*dst - I) is
minimal, where I is an identity matrix.
In case of the #DECOMP_LU method, the function returns non-zero value if
the inverse has been successfully calculated and 0 if src is singular.
In case of the #DECOMP_SVD method, the function returns the inverse
condition number of src (the ratio of the smallest singular value to the
largest singular value) and 0 if src is singular. The SVD method
calculates a pseudo-inverse matrix if src is singular.
Similarly to #DECOMP_LU, the method #DECOMP_CHOLESKY works only with
non-singular square matrices that should also be symmetrical and
positively defined. In this case, the function stores the inverted
matrix in dst and returns non-zero. Otherwise, it returns 0.

Parameters:

=over

=item src

input floating-point M x N matrix.

=item dst

output matrix of N x M size and the same type as src.

=item flags

inversion method (cv::DecompTypes)

=back

See also:
solve, SVD


=for bad

invert ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5601 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::invert {
  barf "Usage: PDL::OpenCV::invert(\$src,\$flags)\n" if @_ < 1;
  my ($src,$flags) = @_;
  my ($dst,$res);
  $dst = PDL->null if !defined $dst;
  $flags = DECOMP_LU() if !defined $flags;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::_invert_int($src,$dst,$flags,$res);
  !wantarray ? $res : ($dst,$res)
}
#line 5617 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*invert = \&PDL::OpenCV::invert;
#line 5624 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 solve

=for sig

  Signature: ([phys] src1(l1,c1,r1); [phys] src2(l2,c2,r2); [o,phys] dst(l3,c3,r3); int [phys] flags(); byte [o,phys] res())

=for ref

Solves one or more linear systems or least-squares problems. NO BROADCASTING.

=for example

 ($dst,$res) = solve($src1,$src2); # with defaults
 ($dst,$res) = solve($src1,$src2,$flags);

The function cv::solve solves a linear system or least-squares problem (the
latter is possible with SVD or QR methods, or by specifying the flag
#DECOMP_NORMAL ):
\f[\texttt{dst} =  \arg \min _X \| \texttt{src1} \cdot \texttt{X} -  \texttt{src2} \|\f]
If #DECOMP_LU or #DECOMP_CHOLESKY method is used, the function returns 1
if src1 (or C<<< \texttt{src1}^T\texttt{src1} >>>) is non-singular. Otherwise,
it returns 0. In the latter case, dst is not valid. Other methods find a
pseudo-solution in case of a singular left-hand side part.
@note If you want to find a unity-norm solution of an under-defined
singular system C<<< \texttt{src1}\cdot\texttt{dst}=0 >>>, the function solve
will not do the work. Use SVD::solveZ instead.

Parameters:

=over

=item src1

input matrix on the left-hand side of the system.

=item src2

input matrix on the right-hand side of the system.

=item dst

output solution.

=item flags

solution (matrix inversion) method (#DecompTypes)

=back

See also:
invert, SVD, eigen


=for bad

solve ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5692 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::solve {
  barf "Usage: PDL::OpenCV::solve(\$src1,\$src2,\$flags)\n" if @_ < 2;
  my ($src1,$src2,$flags) = @_;
  my ($dst,$res);
  $dst = PDL->null if !defined $dst;
  $flags = DECOMP_LU() if !defined $flags;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::_solve_int($src1,$src2,$dst,$flags,$res);
  !wantarray ? $res : ($dst,$res)
}
#line 5708 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*solve = \&PDL::OpenCV::solve;
#line 5715 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 sort

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] flags())

=for ref

Sorts each row or each column of a matrix. NO BROADCASTING.

=for example

 $dst = sort($src,$flags);

The function cv::sort sorts each matrix row or each matrix column in
ascending or descending order. So you should pass two operation flags to
get desired behaviour. If you want to sort matrix rows or columns
lexicographically, you can use STL std::sort generic function with the
proper comparison predicate.

Parameters:

=over

=item src

input single-channel array.

=item dst

output array of the same size and type as src.

=item flags

operation flags, a combination of #SortFlags

=back

See also:
sortIdx, randShuffle


=for bad

sort ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5772 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::sort {
  barf "Usage: PDL::OpenCV::sort(\$src,\$flags)\n" if @_ < 2;
  my ($src,$flags) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::_sort_int($src,$dst,$flags);
  !wantarray ? $dst : ($dst)
}
#line 5786 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*sort = \&PDL::OpenCV::sort;
#line 5793 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 sortIdx

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] flags())

=for ref

Sorts each row or each column of a matrix. NO BROADCASTING.

=for example

 $dst = sortIdx($src,$flags);

The function cv::sortIdx sorts each matrix row or each matrix column in the
ascending or descending order. So you should pass two operation flags to
get desired behaviour. Instead of reordering the elements themselves, it
stores the indices of sorted elements in the output array. For example:

     Mat A = Mat::eye(3,3,CV_32F), B;
     sortIdx(A, B, SORT_EVERY_ROW + SORT_ASCENDING);
     // B will probably contain
     // (because of equal elements in A some permutations are possible):
     // [[1, 2, 0], [0, 2, 1], [0, 1, 2]]

Parameters:

=over

=item src

input single-channel array.

=item dst

output integer array of the same size as src.

=item flags

operation flags that could be a combination of cv::SortFlags

=back

See also:
sort, randShuffle


=for bad

sortIdx ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5855 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::sortIdx {
  barf "Usage: PDL::OpenCV::sortIdx(\$src,\$flags)\n" if @_ < 2;
  my ($src,$flags) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::_sortIdx_int($src,$dst,$flags);
  !wantarray ? $dst : ($dst)
}
#line 5869 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*sortIdx = \&PDL::OpenCV::sortIdx;
#line 5876 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 solveCubic

=for sig

  Signature: ([phys] coeffs(l1,c1,r1); [o,phys] roots(l2,c2,r2); int [o,phys] res())

=for ref

Finds the real roots of a cubic equation. NO BROADCASTING.

=for example

 ($roots,$res) = solveCubic($coeffs);

The function solveCubic finds the real roots of a cubic equation:
=over
=back
The roots are stored in the roots array.

Parameters:

=over

=item coeffs

equation coefficients, an array of 3 or 4 elements.

=item roots

output array of real roots that has 1 or 3 elements.

=back

Returns: number of real roots. It can be 0, 1 or 2.


=for bad

solveCubic ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5927 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::solveCubic {
  barf "Usage: PDL::OpenCV::solveCubic(\$coeffs)\n" if @_ < 1;
  my ($coeffs) = @_;
  my ($roots,$res);
  $roots = PDL->null if !defined $roots;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::_solveCubic_int($coeffs,$roots,$res);
  !wantarray ? $res : ($roots,$res)
}
#line 5942 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*solveCubic = \&PDL::OpenCV::solveCubic;
#line 5949 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 solvePoly

=for sig

  Signature: ([phys] coeffs(l1,c1,r1); [o,phys] roots(l2,c2,r2); int [phys] maxIters(); double [o,phys] res())

=for ref

Finds the real or complex roots of a polynomial equation. NO BROADCASTING.

=for example

 ($roots,$res) = solvePoly($coeffs); # with defaults
 ($roots,$res) = solvePoly($coeffs,$maxIters);

The function cv::solvePoly finds real and complex roots of a polynomial equation:
\f[\texttt{coeffs} [n] x^{n} +  \texttt{coeffs} [n-1] x^{n-1} + ... +  \texttt{coeffs} [1] x +  \texttt{coeffs} [0] = 0\f]

Parameters:

=over

=item coeffs

array of polynomial coefficients.

=item roots

output (complex) array of roots.

=item maxIters

maximum number of iterations the algorithm does.

=back


=for bad

solvePoly ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6001 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::solvePoly {
  barf "Usage: PDL::OpenCV::solvePoly(\$coeffs,\$maxIters)\n" if @_ < 1;
  my ($coeffs,$maxIters) = @_;
  my ($roots,$res);
  $roots = PDL->null if !defined $roots;
  $maxIters = 300 if !defined $maxIters;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::_solvePoly_int($coeffs,$roots,$maxIters,$res);
  !wantarray ? $res : ($roots,$res)
}
#line 6017 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*solvePoly = \&PDL::OpenCV::solvePoly;
#line 6024 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 eigen

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] eigenvalues(l2,c2,r2); [o,phys] eigenvectors(l3,c3,r3); byte [o,phys] res())

=for ref

Calculates eigenvalues and eigenvectors of a symmetric matrix. NO BROADCASTING.

=for example

 ($eigenvalues,$eigenvectors,$res) = eigen($src);

The function cv::eigen calculates just eigenvalues, or eigenvalues and eigenvectors of the symmetric
matrix src:

     src*eigenvectors.row(i).t() = eigenvalues.at<srcType>(i)*eigenvectors.row(i).t()

@note Use cv::eigenNonSymmetric for calculation of real eigenvalues and eigenvectors of non-symmetric matrix.

Parameters:

=over

=item src

input matrix that must have CV_32FC1 or CV_64FC1 type, square size and be symmetrical
(src ^T^ == src).

=item eigenvalues

output vector of eigenvalues of the same type as src; the eigenvalues are stored
in the descending order.

=item eigenvectors

output matrix of eigenvectors; it has the same size and type as src; the
eigenvectors are stored as subsequent matrix rows, in the same order as the corresponding
eigenvalues.

=back

See also:
eigenNonSymmetric, completeSymm , PCA


=for bad

eigen ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6086 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::eigen {
  barf "Usage: PDL::OpenCV::eigen(\$src)\n" if @_ < 1;
  my ($src) = @_;
  my ($eigenvalues,$eigenvectors,$res);
  $eigenvalues = PDL->null if !defined $eigenvalues;
  $eigenvectors = PDL->null if !defined $eigenvectors;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::_eigen_int($src,$eigenvalues,$eigenvectors,$res);
  !wantarray ? $res : ($eigenvalues,$eigenvectors,$res)
}
#line 6102 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*eigen = \&PDL::OpenCV::eigen;
#line 6109 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 eigenNonSymmetric

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] eigenvalues(l2,c2,r2); [o,phys] eigenvectors(l3,c3,r3))

=for ref

Calculates eigenvalues and eigenvectors of a non-symmetric matrix (real eigenvalues only). NO BROADCASTING.

=for example

 ($eigenvalues,$eigenvectors) = eigenNonSymmetric($src);

@note Assumes real eigenvalues.
The function calculates eigenvalues and eigenvectors (optional) of the square matrix src:

     src*eigenvectors.row(i).t() = eigenvalues.at<srcType>(i)*eigenvectors.row(i).t()

Parameters:

=over

=item src

input matrix (CV_32FC1 or CV_64FC1 type).

=item eigenvalues

output vector of eigenvalues (type is the same type as src).

=item eigenvectors

output matrix of eigenvectors (type is the same type as src). The eigenvectors are stored as subsequent matrix rows, in the same order as the corresponding eigenvalues.

=back

See also:
eigen


=for bad

eigenNonSymmetric ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6165 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::eigenNonSymmetric {
  barf "Usage: PDL::OpenCV::eigenNonSymmetric(\$src)\n" if @_ < 1;
  my ($src) = @_;
  my ($eigenvalues,$eigenvectors);
  $eigenvalues = PDL->null if !defined $eigenvalues;
  $eigenvectors = PDL->null if !defined $eigenvectors;
  PDL::OpenCV::_eigenNonSymmetric_int($src,$eigenvalues,$eigenvectors);
  !wantarray ? $eigenvectors : ($eigenvalues,$eigenvectors)
}
#line 6180 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*eigenNonSymmetric = \&PDL::OpenCV::eigenNonSymmetric;
#line 6187 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 calcCovarMatrix

=for sig

  Signature: ([phys] samples(l1,c1,r1); [o,phys] covar(l2,c2,r2); [io,phys] mean(l3,c3,r3); int [phys] flags(); int [phys] ctype())

=for ref

 NO BROADCASTING.

=for example

 $covar = calcCovarMatrix($samples,$mean,$flags); # with defaults
 $covar = calcCovarMatrix($samples,$mean,$flags,$ctype);

@overload
@note use #COVAR_ROWS or #COVAR_COLS flag

Parameters:

=over

=item samples

samples stored as rows/columns of a single matrix.

=item covar

output covariance matrix of the type ctype and square size.

=item mean

input or output (depending on the flags) array as the average value of the input vectors.

=item flags

operation flags as a combination of #CovarFlags

=item ctype

type of the matrixl; it equals 'CV_64F' by default.

=back


=for bad

calcCovarMatrix ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6247 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::calcCovarMatrix {
  barf "Usage: PDL::OpenCV::calcCovarMatrix(\$samples,\$mean,\$flags,\$ctype)\n" if @_ < 3;
  my ($samples,$mean,$flags,$ctype) = @_;
  my ($covar);
  $covar = PDL->null if !defined $covar;
  $ctype = CV_64F() if !defined $ctype;
  PDL::OpenCV::_calcCovarMatrix_int($samples,$covar,$mean,$flags,$ctype);
  !wantarray ? $covar : ($covar)
}
#line 6262 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*calcCovarMatrix = \&PDL::OpenCV::calcCovarMatrix;
#line 6269 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 PCACompute

=for sig

  Signature: ([phys] data(l1,c1,r1); [io,phys] mean(l2,c2,r2); [o,phys] eigenvectors(l3,c3,r3); int [phys] maxComponents())

=for ref

 NO BROADCASTING.

=for example

 $eigenvectors = PCACompute($data,$mean); # with defaults
 $eigenvectors = PCACompute($data,$mean,$maxComponents);

wrap PCA::operator()

=for bad

PCACompute ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6301 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::PCACompute {
  barf "Usage: PDL::OpenCV::PCACompute(\$data,\$mean,\$maxComponents)\n" if @_ < 2;
  my ($data,$mean,$maxComponents) = @_;
  my ($eigenvectors);
  $eigenvectors = PDL->null if !defined $eigenvectors;
  $maxComponents = 0 if !defined $maxComponents;
  PDL::OpenCV::_PCACompute_int($data,$mean,$eigenvectors,$maxComponents);
  !wantarray ? $eigenvectors : ($eigenvectors)
}
#line 6316 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*PCACompute = \&PDL::OpenCV::PCACompute;
#line 6323 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 PCACompute2

=for sig

  Signature: ([phys] data(l1,c1,r1); [io,phys] mean(l2,c2,r2); [o,phys] eigenvectors(l3,c3,r3); [o,phys] eigenvalues(l4,c4,r4); int [phys] maxComponents())

=for ref

 NO BROADCASTING.

=for example

 ($eigenvectors,$eigenvalues) = PCACompute2($data,$mean); # with defaults
 ($eigenvectors,$eigenvalues) = PCACompute2($data,$mean,$maxComponents);

wrap PCA::operator() and add eigenvalues output parameter

=for bad

PCACompute2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6355 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::PCACompute2 {
  barf "Usage: PDL::OpenCV::PCACompute2(\$data,\$mean,\$maxComponents)\n" if @_ < 2;
  my ($data,$mean,$maxComponents) = @_;
  my ($eigenvectors,$eigenvalues);
  $eigenvectors = PDL->null if !defined $eigenvectors;
  $eigenvalues = PDL->null if !defined $eigenvalues;
  $maxComponents = 0 if !defined $maxComponents;
  PDL::OpenCV::_PCACompute2_int($data,$mean,$eigenvectors,$eigenvalues,$maxComponents);
  !wantarray ? $eigenvalues : ($eigenvectors,$eigenvalues)
}
#line 6371 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*PCACompute2 = \&PDL::OpenCV::PCACompute2;
#line 6378 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 PCACompute3

=for sig

  Signature: ([phys] data(l1,c1,r1); [io,phys] mean(l2,c2,r2); [o,phys] eigenvectors(l3,c3,r3); double [phys] retainedVariance())

=for ref

 NO BROADCASTING.

=for example

 $eigenvectors = PCACompute3($data,$mean,$retainedVariance);

wrap PCA::operator()

=for bad

PCACompute3 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6409 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::PCACompute3 {
  barf "Usage: PDL::OpenCV::PCACompute3(\$data,\$mean,\$retainedVariance)\n" if @_ < 3;
  my ($data,$mean,$retainedVariance) = @_;
  my ($eigenvectors);
  $eigenvectors = PDL->null if !defined $eigenvectors;
  PDL::OpenCV::_PCACompute3_int($data,$mean,$eigenvectors,$retainedVariance);
  !wantarray ? $eigenvectors : ($eigenvectors)
}
#line 6423 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*PCACompute3 = \&PDL::OpenCV::PCACompute3;
#line 6430 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 PCACompute4

=for sig

  Signature: ([phys] data(l1,c1,r1); [io,phys] mean(l2,c2,r2); [o,phys] eigenvectors(l3,c3,r3); [o,phys] eigenvalues(l4,c4,r4); double [phys] retainedVariance())

=for ref

 NO BROADCASTING.

=for example

 ($eigenvectors,$eigenvalues) = PCACompute4($data,$mean,$retainedVariance);

wrap PCA::operator() and add eigenvalues output parameter

=for bad

PCACompute4 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6461 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::PCACompute4 {
  barf "Usage: PDL::OpenCV::PCACompute4(\$data,\$mean,\$retainedVariance)\n" if @_ < 3;
  my ($data,$mean,$retainedVariance) = @_;
  my ($eigenvectors,$eigenvalues);
  $eigenvectors = PDL->null if !defined $eigenvectors;
  $eigenvalues = PDL->null if !defined $eigenvalues;
  PDL::OpenCV::_PCACompute4_int($data,$mean,$eigenvectors,$eigenvalues,$retainedVariance);
  !wantarray ? $eigenvalues : ($eigenvectors,$eigenvalues)
}
#line 6476 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*PCACompute4 = \&PDL::OpenCV::PCACompute4;
#line 6483 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 PCAProject

=for sig

  Signature: ([phys] data(l1,c1,r1); [phys] mean(l2,c2,r2); [phys] eigenvectors(l3,c3,r3); [o,phys] result(l4,c4,r4))

=for ref

 NO BROADCASTING.

=for example

 $result = PCAProject($data,$mean,$eigenvectors);

wrap PCA::project

=for bad

PCAProject ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6514 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::PCAProject {
  barf "Usage: PDL::OpenCV::PCAProject(\$data,\$mean,\$eigenvectors)\n" if @_ < 3;
  my ($data,$mean,$eigenvectors) = @_;
  my ($result);
  $result = PDL->null if !defined $result;
  PDL::OpenCV::_PCAProject_int($data,$mean,$eigenvectors,$result);
  !wantarray ? $result : ($result)
}
#line 6528 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*PCAProject = \&PDL::OpenCV::PCAProject;
#line 6535 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 PCABackProject

=for sig

  Signature: ([phys] data(l1,c1,r1); [phys] mean(l2,c2,r2); [phys] eigenvectors(l3,c3,r3); [o,phys] result(l4,c4,r4))

=for ref

 NO BROADCASTING.

=for example

 $result = PCABackProject($data,$mean,$eigenvectors);

wrap PCA::backProject

=for bad

PCABackProject ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6566 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::PCABackProject {
  barf "Usage: PDL::OpenCV::PCABackProject(\$data,\$mean,\$eigenvectors)\n" if @_ < 3;
  my ($data,$mean,$eigenvectors) = @_;
  my ($result);
  $result = PDL->null if !defined $result;
  PDL::OpenCV::_PCABackProject_int($data,$mean,$eigenvectors,$result);
  !wantarray ? $result : ($result)
}
#line 6580 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*PCABackProject = \&PDL::OpenCV::PCABackProject;
#line 6587 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 SVDecomp

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] w(l2,c2,r2); [o,phys] u(l3,c3,r3); [o,phys] vt(l4,c4,r4); int [phys] flags())

=for ref

 NO BROADCASTING.

=for example

 ($w,$u,$vt) = SVDecomp($src); # with defaults
 ($w,$u,$vt) = SVDecomp($src,$flags);

wrap SVD::compute

=for bad

SVDecomp ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6619 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::SVDecomp {
  barf "Usage: PDL::OpenCV::SVDecomp(\$src,\$flags)\n" if @_ < 1;
  my ($src,$flags) = @_;
  my ($w,$u,$vt);
  $w = PDL->null if !defined $w;
  $u = PDL->null if !defined $u;
  $vt = PDL->null if !defined $vt;
  $flags = 0 if !defined $flags;
  PDL::OpenCV::_SVDecomp_int($src,$w,$u,$vt,$flags);
  !wantarray ? $vt : ($w,$u,$vt)
}
#line 6636 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*SVDecomp = \&PDL::OpenCV::SVDecomp;
#line 6643 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 SVBackSubst

=for sig

  Signature: ([phys] w(l1,c1,r1); [phys] u(l2,c2,r2); [phys] vt(l3,c3,r3); [phys] rhs(l4,c4,r4); [o,phys] dst(l5,c5,r5))

=for ref

 NO BROADCASTING.

=for example

 $dst = SVBackSubst($w,$u,$vt,$rhs);

wrap SVD::backSubst

=for bad

SVBackSubst ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6674 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::SVBackSubst {
  barf "Usage: PDL::OpenCV::SVBackSubst(\$w,\$u,\$vt,\$rhs)\n" if @_ < 4;
  my ($w,$u,$vt,$rhs) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::_SVBackSubst_int($w,$u,$vt,$rhs,$dst);
  !wantarray ? $dst : ($dst)
}
#line 6688 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*SVBackSubst = \&PDL::OpenCV::SVBackSubst;
#line 6695 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 Mahalanobis

=for sig

  Signature: ([phys] v1(l1,c1,r1); [phys] v2(l2,c2,r2); [phys] icovar(l3,c3,r3); double [o,phys] res())

=for ref

Calculates the Mahalanobis distance between two vectors.

=for example

 $res = Mahalanobis($v1,$v2,$icovar);

The function cv::Mahalanobis calculates and returns the weighted distance between two vectors:
\f[d( \texttt{vec1} , \texttt{vec2} )= \sqrt{\sum_{i,j}{\texttt{icovar(i,j)}\cdot(\texttt{vec1}(I)-\texttt{vec2}(I))\cdot(\texttt{vec1(j)}-\texttt{vec2(j)})} }\f]
The covariance matrix may be calculated using the #calcCovarMatrix function and then inverted using
the invert function (preferably using the #DECOMP_SVD method, as the most accurate).

Parameters:

=over

=item v1

first 1D input vector.

=item v2

second 1D input vector.

=item icovar

inverse covariance matrix.

=back


=for bad

Mahalanobis ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6748 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Mahalanobis {
  barf "Usage: PDL::OpenCV::Mahalanobis(\$v1,\$v2,\$icovar)\n" if @_ < 3;
  my ($v1,$v2,$icovar) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::_Mahalanobis_int($v1,$v2,$icovar,$res);
  !wantarray ? $res : ($res)
}
#line 6762 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*Mahalanobis = \&PDL::OpenCV::Mahalanobis;
#line 6769 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 dft

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] flags(); int [phys] nonzeroRows())

=for ref

Performs a forward or inverse Discrete Fourier transform of a 1D or 2D floating-point array. NO BROADCASTING.

=for example

 $dst = dft($src); # with defaults
 $dst = dft($src,$flags,$nonzeroRows);

The function cv::dft performs one of the following:
=over
=back
C<<< F^{(N)}_{jk}=\exp(-2\pi i j k/N) >>>and C<<< i=\sqrt{-1} >>>-   Inverse the Fourier transform of a 1D vector of N elements:
\f[\begin{array}{l} X'=  \left (F^{(N)} \right )^{-1}  \cdot Y =  \left (F^{(N)} \right )^*  \cdot y  \\ X = (1/N)  \cdot X, \end{array}\f]
where C<<< F^*=\left(\textrm{Re}(F^{(N)})-\textrm{Im}(F^{(N)})\right)^T >>>-   Forward the 2D Fourier transform of a M x N matrix:
\f[Y = F^{(M)}  \cdot X  \cdot F^{(N)}\f]
-   Inverse the 2D Fourier transform of a M x N matrix:
\f[\begin{array}{l} X'=  \left (F^{(M)} \right )^*  \cdot Y  \cdot \left (F^{(N)} \right )^* \\ X =  \frac{1}{M \cdot N} \cdot X' \end{array}\f]
In case of real (single-channel) data, the output spectrum of the forward Fourier transform or input
spectrum of the inverse Fourier transform can be represented in a packed format called *CCS*
(complex-conjugate-symmetrical). It was borrowed from IPL (Intel* Image Processing Library). Here
is how 2D *CCS* spectrum looks:
\f[\begin{bmatrix} Re Y_{0,0} & Re Y_{0,1} & Im Y_{0,1} & Re Y_{0,2} & Im Y_{0,2} &  \cdots & Re Y_{0,N/2-1} & Im Y_{0,N/2-1} & Re Y_{0,N/2}  \\ Re Y_{1,0} & Re Y_{1,1} & Im Y_{1,1} & Re Y_{1,2} & Im Y_{1,2} &  \cdots & Re Y_{1,N/2-1} & Im Y_{1,N/2-1} & Re Y_{1,N/2}  \\ Im Y_{1,0} & Re Y_{2,1} & Im Y_{2,1} & Re Y_{2,2} & Im Y_{2,2} &  \cdots & Re Y_{2,N/2-1} & Im Y_{2,N/2-1} & Im Y_{1,N/2}  \\ \hdotsfor{9} \\ Re Y_{M/2-1,0} &  Re Y_{M-3,1}  & Im Y_{M-3,1} &  \hdotsfor{3} & Re Y_{M-3,N/2-1} & Im Y_{M-3,N/2-1}& Re Y_{M/2-1,N/2}  \\ Im Y_{M/2-1,0} &  Re Y_{M-2,1}  & Im Y_{M-2,1} &  \hdotsfor{3} & Re Y_{M-2,N/2-1} & Im Y_{M-2,N/2-1}& Im Y_{M/2-1,N/2}  \\ Re Y_{M/2,0}  &  Re Y_{M-1,1} &  Im Y_{M-1,1} &  \hdotsfor{3} & Re Y_{M-1,N/2-1} & Im Y_{M-1,N/2-1}& Re Y_{M/2,N/2} \end{bmatrix}\f]
In case of 1D transform of a real vector, the output looks like the first row of the matrix above.
So, the function chooses an operation mode depending on the flags and size of the input array:
=over
=back
If #DFT_SCALE is set, the scaling is done after the transformation.
Unlike dct , the function supports arrays of arbitrary size. But only those arrays are processed
efficiently, whose sizes can be factorized in a product of small prime numbers (2, 3, and 5 in the
current implementation). Such an efficient DFT size can be calculated using the getOptimalDFTSize
method.
The sample below illustrates how to calculate a DFT-based convolution of two 2D real arrays:

     void convolveDFT(InputArray A, InputArray B, OutputArray C)
     {
         // reallocate the output array if needed
         C.create(abs(A.rows - B.rows)+1, abs(A.cols - B.cols)+1, A.type());
         Size dftSize;
         // calculate the size of DFT transform
         dftSize.width = getOptimalDFTSize(A.cols + B.cols - 1);
         dftSize.height = getOptimalDFTSize(A.rows + B.rows - 1);

         // allocate temporary buffers and initialize them with 0's
         Mat tempA(dftSize, A.type(), Scalar::all(0));
         Mat tempB(dftSize, B.type(), Scalar::all(0));

         // copy A and B to the top-left corners of tempA and tempB, respectively
         Mat roiA(tempA, Rect(0,0,A.cols,A.rows));
         A.copyTo(roiA);
         Mat roiB(tempB, Rect(0,0,B.cols,B.rows));
         B.copyTo(roiB);

         // now transform the padded A & B in-place;
         // use "nonzeroRows" hint for faster processing
         dft(tempA, tempA, 0, A.rows);
         dft(tempB, tempB, 0, B.rows);

         // multiply the spectrums;
         // the function handles packed spectrum representations well
         mulSpectrums(tempA, tempB, tempA);

         // transform the product back from the frequency domain.
         // Even though all the result rows will be non-zero,
         // you need only the first C.rows of them, and thus you
         // pass nonzeroRows == C.rows
         dft(tempA, tempA, DFT_INVERSE + DFT_SCALE, C.rows);

         // now copy the result back to C.
         tempA(Rect(0, 0, C.cols, C.rows)).copyTo(C);

         // all the temporary buffers will be deallocated automatically
     }

To optimize this sample, consider the following approaches:
=over
=back
All of the above improvements have been implemented in #matchTemplate and #filter2D . Therefore, by
using them, you can get the performance even better than with the above theoretically optimal
implementation. Though, those two functions actually calculate cross-correlation, not convolution,
so you need to "flip" the second convolution operand B vertically and horizontally using flip .
@note
-   An example using the discrete fourier transform can be found at
opencv_source_code/samples/cpp/dft.cpp
-   (Python) An example using the dft functionality to perform Wiener deconvolution can be found
at opencv_source/samples/python/deconvolution.py
-   (Python) An example rearranging the quadrants of a Fourier image can be found at
opencv_source/samples/python/dft.py

Parameters:

=over

=item src

input array that could be real or complex.

=item dst

output array whose size and type depends on the flags .

=item flags

transformation flags, representing a combination of the #DftFlags

=item nonzeroRows

when the parameter is not zero, the function assumes that only the first
nonzeroRows rows of the input array (#DFT_INVERSE is not set) or only the first nonzeroRows of the
output array (#DFT_INVERSE is set) contain non-zeros, thus, the function can handle the rest of the
rows more efficiently and save some time; this technique is very useful for calculating array
cross-correlation or convolution using DFT.

=back

See also:
dct , getOptimalDFTSize , mulSpectrums, filter2D , matchTemplate , flip , cartToPolar ,
magnitude , phase


=for bad

dft ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6910 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::dft {
  barf "Usage: PDL::OpenCV::dft(\$src,\$flags,\$nonzeroRows)\n" if @_ < 1;
  my ($src,$flags,$nonzeroRows) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $flags = 0 if !defined $flags;
  $nonzeroRows = 0 if !defined $nonzeroRows;
  PDL::OpenCV::_dft_int($src,$dst,$flags,$nonzeroRows);
  !wantarray ? $dst : ($dst)
}
#line 6926 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*dft = \&PDL::OpenCV::dft;
#line 6933 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 idft

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] flags(); int [phys] nonzeroRows())

=for ref

Calculates the inverse Discrete Fourier Transform of a 1D or 2D array. NO BROADCASTING.

=for example

 $dst = idft($src); # with defaults
 $dst = idft($src,$flags,$nonzeroRows);

idft(src, dst, flags) is equivalent to dft(src, dst, flags | #DFT_INVERSE) .
@note None of dft and idft scales the result by default. So, you should pass #DFT_SCALE to one of
dft or idft explicitly to make these transforms mutually inverse.

Parameters:

=over

=item src

input floating-point real or complex array.

=item dst

output array whose size and type depend on the flags.

=item flags

operation flags (see dft and #DftFlags).

=item nonzeroRows

number of dst rows to process; the rest of the rows have undefined content (see
the convolution sample in dft description.

=back

See also:
dft, dct, idct, mulSpectrums, getOptimalDFTSize


=for bad

idft ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6994 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::idft {
  barf "Usage: PDL::OpenCV::idft(\$src,\$flags,\$nonzeroRows)\n" if @_ < 1;
  my ($src,$flags,$nonzeroRows) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $flags = 0 if !defined $flags;
  $nonzeroRows = 0 if !defined $nonzeroRows;
  PDL::OpenCV::_idft_int($src,$dst,$flags,$nonzeroRows);
  !wantarray ? $dst : ($dst)
}
#line 7010 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*idft = \&PDL::OpenCV::idft;
#line 7017 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 dct

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] flags())

=for ref

Performs a forward or inverse discrete Cosine transform of 1D or 2D array. NO BROADCASTING.

=for example

 $dst = dct($src); # with defaults
 $dst = dct($src,$flags);

The function cv::dct performs a forward or inverse discrete Cosine transform (DCT) of a 1D or 2D
floating-point array:
=over
=back
C<<< \alpha_0=1 >>>, C<<< \alpha_j=2 >>>for *j \> 0*.
-   Inverse Cosine transform of a 1D vector of N elements:
\f[X =  \left (C^{(N)} \right )^{-1}  \cdot Y =  \left (C^{(N)} \right )^T  \cdot Y\f]
(since C<<< C^{(N)} >>>is an orthogonal matrix, C<<< C^{(N)} \cdot \left(C^{(N)}\right)^T = I >>>)
-   Forward 2D Cosine transform of M x N matrix:
\f[Y = C^{(N)}  \cdot X  \cdot \left (C^{(N)} \right )^T\f]
-   Inverse 2D Cosine transform of M x N matrix:
\f[X =  \left (C^{(N)} \right )^T  \cdot X  \cdot C^{(N)}\f]
The function chooses the mode of operation by looking at the flags and size of the input array:
=over
=item *
If (flags & #DCT_ROWS) != 0 , the function performs a 1D transform of each row.
=item *
If the array is a single column or a single row, the function performs a 1D transform.
=item *
If none of the above is true, the function performs a 2D transform.
=back
@note Currently dct supports even-size arrays (2, 4, 6 ...). For data analysis and approximation, you
can pad the array when necessary.
Also, the function performance depends very much, and not monotonically, on the array size (see
getOptimalDFTSize ). In the current implementation DCT of a vector of size N is calculated via DFT
of a vector of size N/2 . Thus, the optimal DCT size N1 \>= N can be calculated as:

     size_t getOptimalDCTSize(size_t N) { return 2*getOptimalDFTSize((N+1)/2); }
     N1 = getOptimalDCTSize(N);

Parameters:

=over

=item src

input floating-point array.

=item dst

output array of the same size and type as src .

=item flags

transformation flags as a combination of cv::DftFlags (DCT_*)

=back

See also:
dft , getOptimalDFTSize , idct


=for bad

dct ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7099 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::dct {
  barf "Usage: PDL::OpenCV::dct(\$src,\$flags)\n" if @_ < 1;
  my ($src,$flags) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $flags = 0 if !defined $flags;
  PDL::OpenCV::_dct_int($src,$dst,$flags);
  !wantarray ? $dst : ($dst)
}
#line 7114 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*dct = \&PDL::OpenCV::dct;
#line 7121 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 idct

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] flags())

=for ref

Calculates the inverse Discrete Cosine Transform of a 1D or 2D array. NO BROADCASTING.

=for example

 $dst = idct($src); # with defaults
 $dst = idct($src,$flags);

idct(src, dst, flags) is equivalent to dct(src, dst, flags | DCT_INVERSE).

Parameters:

=over

=item src

input floating-point single-channel array.

=item dst

output array of the same size and type as src.

=item flags

operation flags.

=back

See also:
dct, dft, idft, getOptimalDFTSize


=for bad

idct ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7175 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::idct {
  barf "Usage: PDL::OpenCV::idct(\$src,\$flags)\n" if @_ < 1;
  my ($src,$flags) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $flags = 0 if !defined $flags;
  PDL::OpenCV::_idct_int($src,$dst,$flags);
  !wantarray ? $dst : ($dst)
}
#line 7190 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*idct = \&PDL::OpenCV::idct;
#line 7197 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 mulSpectrums

=for sig

  Signature: ([phys] a(l1,c1,r1); [phys] b(l2,c2,r2); [o,phys] c(l3,c3,r3); int [phys] flags(); byte [phys] conjB())

=for ref

Performs the per-element multiplication of two Fourier spectrums. NO BROADCASTING.

=for example

 $c = mulSpectrums($a,$b,$flags); # with defaults
 $c = mulSpectrums($a,$b,$flags,$conjB);

The function cv::mulSpectrums performs the per-element multiplication of the two CCS-packed or complex
matrices that are results of a real or complex Fourier transform.
The function, together with dft and idft , may be used to calculate convolution (pass conjB=false )
or correlation (pass conjB=true ) of two arrays rapidly. When the arrays are complex, they are
simply multiplied (per element) with an optional conjugation of the second-array elements. When the
arrays are real, they are assumed to be CCS-packed (see dft for details).

Parameters:

=over

=item a

first input array.

=item b

second input array of the same size and type as src1 .

=item c

output array of the same size and type as src1 .

=item flags

operation flags; currently, the only supported flag is cv::DFT_ROWS, which indicates that
each row of src1 and src2 is an independent 1D Fourier spectrum. If you do not want to use this flag, then simply add a `0` as value.

=item conjB

optional flag that conjugates the second input array before the multiplication (true)
or not (false).

=back


=for bad

mulSpectrums ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7263 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::mulSpectrums {
  barf "Usage: PDL::OpenCV::mulSpectrums(\$a,\$b,\$flags,\$conjB)\n" if @_ < 3;
  my ($a,$b,$flags,$conjB) = @_;
  my ($c);
  $c = PDL->null if !defined $c;
  $conjB = 0 if !defined $conjB;
  PDL::OpenCV::_mulSpectrums_int($a,$b,$c,$flags,$conjB);
  !wantarray ? $c : ($c)
}
#line 7278 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*mulSpectrums = \&PDL::OpenCV::mulSpectrums;
#line 7285 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 getOptimalDFTSize

=for ref

Returns the optimal DFT size for a given vector size.

=for example

 $res = getOptimalDFTSize($vecsize);

DFT performance is not a monotonic function of a vector size. Therefore, when you calculate
convolution of two arrays or perform the spectral analysis of an array, it usually makes sense to
pad the input data with zeros to get a bit larger array that can be transformed much faster than the
original one. Arrays whose size is a power-of-two (2, 4, 8, 16, 32, ...) are the fastest to process.
Though, the arrays whose size is a product of 2's, 3's, and 5's (for example, 300 = 5*5*3*2*2)
are also processed quite efficiently.
The function cv::getOptimalDFTSize returns the minimum number N that is greater than or equal to vecsize
so that the DFT of a vector of size N can be processed efficiently. In the current implementation N
= 2 ^p^ * 3 ^q^ * 5 ^r^ for some integer p, q, r.
The function returns a negative number if vecsize is too large (very close to INT_MAX ).
While the function cannot be used directly to estimate the optimal vector size for DCT transform
(since the current DCT implementation supports only even-size vectors), it can be easily processed
as getOptimalDFTSize((vecsize+1)/2)*2.

Parameters:

=over

=item vecsize

vector size.

=back

See also:
dft , dct , idft , idct , mulSpectrums


=cut
#line 7330 "OpenCV.pm"



#line 275 "./genpp.pl"

*getOptimalDFTSize = \&PDL::OpenCV::getOptimalDFTSize;
#line 7337 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 setRNGSeed

=for ref

Sets state of default random number generator.

=for example

 setRNGSeed($seed);

The function cv::setRNGSeed sets state of default random number generator to custom value.

Parameters:

=over

=item seed

new state for default random number generator

=back

See also:
RNG, randu, randn


=cut
#line 7370 "OpenCV.pm"



#line 275 "./genpp.pl"

*setRNGSeed = \&PDL::OpenCV::setRNGSeed;
#line 7377 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 randu

=for sig

  Signature: ([io,phys] dst(l1,c1,r1); [phys] low(l2,c2,r2); [phys] high(l3,c3,r3))

=for ref

Generates a single uniformly-distributed random number or an array of random numbers.

=for example

 randu($dst,$low,$high);

Non-template variant of the function fills the matrix dst with uniformly-distributed
random numbers from the specified range:
\f[\texttt{low} _c  \leq \texttt{dst} (I)_c <  \texttt{high} _c\f]

Parameters:

=over

=item dst

output array of random numbers; the array must be pre-allocated.

=item low

inclusive lower boundary of the generated random numbers.

=item high

exclusive upper boundary of the generated random numbers.

=back

See also:
RNG, randn, theRNG


=for bad

randu ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7432 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::randu {
  barf "Usage: PDL::OpenCV::randu(\$dst,\$low,\$high)\n" if @_ < 3;
  my ($dst,$low,$high) = @_;
    
  PDL::OpenCV::_randu_int($dst,$low,$high);
  
}
#line 7445 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*randu = \&PDL::OpenCV::randu;
#line 7452 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 randn

=for sig

  Signature: ([io,phys] dst(l1,c1,r1); [phys] mean(l2,c2,r2); [phys] stddev(l3,c3,r3))

=for ref

Fills the array with normally distributed random numbers.

=for example

 randn($dst,$mean,$stddev);

The function cv::randn fills the matrix dst with normally distributed random numbers with the specified
mean vector and the standard deviation matrix. The generated random numbers are clipped to fit the
value range of the output array data type.

Parameters:

=over

=item dst

output array of random numbers; the array must be pre-allocated and have 1 to 4 channels.

=item mean

mean value (expectation) of the generated random numbers.

=item stddev

standard deviation of the generated random numbers; it can be either a vector (in
which case a diagonal standard deviation matrix is assumed) or a square matrix.

=back

See also:
RNG, randu


=for bad

randn ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7508 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::randn {
  barf "Usage: PDL::OpenCV::randn(\$dst,\$mean,\$stddev)\n" if @_ < 3;
  my ($dst,$mean,$stddev) = @_;
    
  PDL::OpenCV::_randn_int($dst,$mean,$stddev);
  
}
#line 7521 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*randn = \&PDL::OpenCV::randn;
#line 7528 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 randShuffle

=for sig

  Signature: ([io,phys] dst(l1,c1,r1); double [phys] iterFactor(); RNGWrapper * rng)

=for ref

Shuffles the array elements randomly.

=for example

 randShuffle($dst); # with defaults
 randShuffle($dst,$iterFactor,$rng);

The function cv::randShuffle shuffles the specified 1D array by randomly choosing pairs of elements and
swapping them. The number of such swap operations will be dst.rows*dst.cols*iterFactor .

Parameters:

=over

=item dst

input/output numerical 1D array.

=item iterFactor

scale factor that determines the number of random swap operations (see the details
below).

=item rng

optional random number generator used for shuffling; if it is zero, theRNG () is used
instead.

=back

See also:
RNG, sort


=for bad

randShuffle ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7585 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::randShuffle {
  barf "Usage: PDL::OpenCV::randShuffle(\$dst,\$iterFactor,\$rng)\n" if @_ < 1;
  my ($dst,$iterFactor,$rng) = @_;
    $iterFactor = 1. if !defined $iterFactor;
  $rng = 0 if !defined $rng;
  PDL::OpenCV::_randShuffle_int($dst,$iterFactor,$rng);
  
}
#line 7599 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*randShuffle = \&PDL::OpenCV::randShuffle;
#line 7606 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 kmeans

=for sig

  Signature: ([phys] data(l1,c1,r1); int [phys] K(); [io,phys] bestLabels(l3,c3,r3); int [phys] attempts(); int [phys] flags(); [o,phys] centers(l7,c7,r7); double [o,phys] res(); TermCriteriaWrapper * criteria)

=for ref

Finds centers of clusters and groups input samples around the clusters. NO BROADCASTING.

=for example

 ($centers,$res) = kmeans($data,$K,$bestLabels,$criteria,$attempts,$flags);

The function kmeans implements a k-means algorithm that finds the centers of cluster_count clusters
and groups the input samples around the clusters. As an output, C<<< \texttt{bestLabels}_i >>>contains a
0-based cluster index for the sample stored in the C<<< i^{th} >>>row of the samples matrix.
@note
-   (Python) An example on K-means clustering can be found at
opencv_source_code/samples/python/kmeans.py
\<cv::Point2f\> points(sampleCount);
\f[\sum _i  \| \texttt{samples} _i -  \texttt{centers} _{ \texttt{labels} _i} \| ^2\f]
after every attempt. The best (minimum) value is chosen and the corresponding labels and the
compactness value are returned by the function. Basically, you can use only the core of the
function, set the number of attempts to 1, initialize labels each time using a custom algorithm,
pass them with the ( flags = #KMEANS_USE_INITIAL_LABELS ) flag, and then choose the best
(most-compact) clustering.

Parameters:

=over

=item data

Data for clustering. An array of N-Dimensional points with float coordinates is needed.
Examples of this array can be:
-   Mat points(count, 2, CV_32F);
-   Mat points(count, 1, CV_32FC2);
-   Mat points(1, count, CV_32FC2);
-   std::vector

=item K

Number of clusters to split the set by.

=item bestLabels

Input/output integer array that stores the cluster indices for every sample.

=item criteria

The algorithm termination criteria, that is, the maximum number of iterations and/or
the desired accuracy. The accuracy is specified as criteria.epsilon. As soon as each of the cluster
centers moves by less than criteria.epsilon on some iteration, the algorithm stops.

=item attempts

Flag to specify the number of times the algorithm is executed using different
initial labellings. The algorithm returns the labels that yield the best compactness (see the last
function parameter).

=item flags

Flag that can take values of cv::KmeansFlags

=item centers

Output matrix of the cluster centers, one row per each cluster center.

=back

Returns: The function returns the compactness measure that is computed as


=for bad

kmeans ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7695 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::kmeans {
  barf "Usage: PDL::OpenCV::kmeans(\$data,\$K,\$bestLabels,\$criteria,\$attempts,\$flags)\n" if @_ < 6;
  my ($data,$K,$bestLabels,$criteria,$attempts,$flags) = @_;
  my ($centers,$res);
  $centers = PDL->null if !defined $centers;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::_kmeans_int($data,$K,$bestLabels,$attempts,$flags,$centers,$res,$criteria);
  !wantarray ? $res : ($centers,$res)
}
#line 7710 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*kmeans = \&PDL::OpenCV::kmeans;
#line 7717 "OpenCV.pm"



#line 394 "./genpp.pl"

=head1 METHODS for PDL::OpenCV::Algorithm


=for ref

This is a base class for all more or less complex algorithms in OpenCV

especially for classes of algorithms, for which there can be multiple implementations. The examples
are stereo correspondence (for which there are algorithms like block matching, semi-global block
matching, graph-cut etc.), background subtraction (which can be done using mixture-of-gaussians
models, codebook-based algorithm etc.), optical flow (block matching, Lucas-Kanade, Horn-Schunck
etc.).
Here is example of SimpleBlobDetector use in your application via Algorithm interface:
@snippet snippets/core_various.cpp Algorithm


=cut

@PDL::OpenCV::Algorithm::ISA = qw();
#line 7742 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 clear

=for ref

Clears the algorithm state

=for example

 $obj->clear;


=cut
#line 7760 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 write

=for ref

simplified API for language bindings
    *

=for example

 $obj->write($fs); # with defaults
 $obj->write($fs,$name);

@overload

=cut
#line 7781 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 read

=for ref

Reads algorithm parameters from a file storage

=for example

 $obj->read($fn);


=cut
#line 7799 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 empty

=for ref

Returns true if the Algorithm is empty (e.g. in the very beginning or after unsuccessful read

=for example

 $res = $obj->empty;


=cut
#line 7817 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 save

=for ref

=for example

 $obj->save($filename);

Saves the algorithm to a file.
In order to make this method work, the derived class must implement Algorithm::write(FileStorage& fs).

=cut
#line 7835 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 getDefaultName

=for ref

=for example

 $res = $obj->getDefaultName;

Returns the algorithm string identifier.
This string is used as top level xml/yml node tag when the object is saved to a file or string.

=cut
#line 7853 "OpenCV.pm"



#line 394 "./genpp.pl"

=head1 METHODS for PDL::OpenCV::DMatch


=for ref

Class for matching keypoint descriptors

query descriptor index, train descriptor index, train image index, and distance between
descriptors.


=cut

@PDL::OpenCV::DMatch::ISA = qw();
#line 7873 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 new

=for ref

=for example

 $obj = PDL::OpenCV::DMatch->new;


=cut
#line 7889 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 new2

=for ref

=for example

 $obj = PDL::OpenCV::DMatch->new2($_queryIdx,$_trainIdx,$_distance);


=cut
#line 7905 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 new3

=for ref

=for example

 $obj = PDL::OpenCV::DMatch->new3($_queryIdx,$_trainIdx,$_imgIdx,$_distance);


=cut
#line 7921 "OpenCV.pm"



#line 394 "./genpp.pl"

=head1 METHODS for PDL::OpenCV::FileNode


=for ref

File Storage Node class.

The node is used to store each and every element of the file storage opened for reading. When
XML/YAML file is read, it is first parsed and stored in the memory as a hierarchical collection of
nodes. Each node can be a "leaf" that is contain a single number or a string, or be a collection of
other nodes. There can be named collections (mappings) where each element has a name and it is
accessed by a name, and ordered collections (sequences) where elements do not have names but rather
accessed by index. Type of the file node can be determined using FileNode::type method.
Note that file nodes are only used for navigating file storages opened for reading. When a file
storage is opened for writing, no data is stored in memory after it is written.


=cut

@PDL::OpenCV::FileNode::ISA = qw();
#line 7947 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 new

=for ref

The constructors.

=for example

 $obj = PDL::OpenCV::FileNode->new;

These constructors are used to create a default file node, construct it from obsolete structures or
from the another file node.

=cut
#line 7967 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 getNode

=for ref

=for example

 $res = $obj->getNode($nodename);

@overload

Parameters:

=over

=item nodename

Name of an element in the mapping node.

=back


=cut
#line 7995 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 at

=for ref

=for example

 $res = $obj->at($i);

@overload

Parameters:

=over

=item i

Index of an element in the sequence node.

=back


=cut
#line 8023 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 FileNode_keys

=for sig

  Signature: (P(); C(); FileNodeWrapper * self; [o] vector_StringWrapper * res)

=for ref

Returns keys of a mapping node.

=for example

 $res = $obj->keys;

Returns: Keys of a mapping node.


=for bad

FileNode_keys ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 8055 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::FileNode::keys {
  barf "Usage: PDL::OpenCV::FileNode::keys(\$self)\n" if @_ < 1;
  my ($self) = @_;
  my ($res);
  
  PDL::OpenCV::FileNode::_FileNode_keys_int($self,$res);
  !wantarray ? $res : ($res)
}
#line 8069 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 8074 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 type

=for ref

Returns type of the node.

=for example

 $res = $obj->type;

Returns: Type of the node. See FileNode::Type


=cut
#line 8094 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 empty

=for ref

=for example

 $res = $obj->empty;


=cut
#line 8110 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 isNone

=for ref

=for example

 $res = $obj->isNone;


=cut
#line 8126 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 isSeq

=for ref

=for example

 $res = $obj->isSeq;


=cut
#line 8142 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 isMap

=for ref

=for example

 $res = $obj->isMap;


=cut
#line 8158 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 isInt

=for ref

=for example

 $res = $obj->isInt;


=cut
#line 8174 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 isReal

=for ref

=for example

 $res = $obj->isReal;


=cut
#line 8190 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 isString

=for ref

=for example

 $res = $obj->isString;


=cut
#line 8206 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 isNamed

=for ref

=for example

 $res = $obj->isNamed;


=cut
#line 8222 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 name

=for ref

=for example

 $res = $obj->name;


=cut
#line 8238 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 size

=for ref

=for example

 $res = $obj->size;


=cut
#line 8254 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 rawSize

=for ref

=for example

 $res = $obj->rawSize;


=cut
#line 8270 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 real

=for ref

=for example

 $res = $obj->real;

Internal method used when reading FileStorage.
Sets the type (int, real or string) and value of the previously created node.

=cut
#line 8288 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 string

=for ref

=for example

 $res = $obj->string;


=cut
#line 8304 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 FileNode_mat

=for sig

  Signature: ([o,phys] res(l2,c2,r2); FileNodeWrapper * self)

=for ref

 NO BROADCASTING.

=for example

 $res = $obj->mat;


=for bad

FileNode_mat ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 8334 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::FileNode::mat {
  barf "Usage: PDL::OpenCV::FileNode::mat(\$self)\n" if @_ < 1;
  my ($self) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::FileNode::_FileNode_mat_int($res,$self);
  !wantarray ? $res : ($res)
}
#line 8348 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 8353 "OpenCV.pm"



#line 394 "./genpp.pl"

=head1 METHODS for PDL::OpenCV::FileStorage


=for ref

XML/YAML/JSON file storage class that encapsulates all the information necessary for writing or
reading data to/from a file.



=cut

@PDL::OpenCV::FileStorage::ISA = qw();
#line 8372 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 new

=for ref

The constructors.

=for example

 $obj = PDL::OpenCV::FileStorage->new;

The full constructor opens the file. Alternatively you can use the default constructor and then
call FileStorage::open.

=cut
#line 8392 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 new2

=for ref

=for example

 $obj = PDL::OpenCV::FileStorage->new2($filename,$flags); # with defaults
 $obj = PDL::OpenCV::FileStorage->new2($filename,$flags,$encoding);

@overload
@copydoc open()

=cut
#line 8411 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 open

=for ref

Opens a file.

=for example

 $res = $obj->open($filename,$flags); # with defaults
 $res = $obj->open($filename,$flags,$encoding);

See description of parameters in FileStorage::FileStorage. The method calls FileStorage::release
before opening the file.

Parameters:

=over

=item filename

Name of the file to open or the text string to read the data from.
     Extension of the file (.xml, .yml/.yaml or .json) determines its format (XML, YAML or JSON
     respectively). Also you can append .gz to work with compressed files, for example myHugeMatrix.xml.gz. If both
     FileStorage::WRITE and FileStorage::MEMORY flags are specified, source is used just to specify
     the output file format (e.g. mydata.xml, .yml etc.). A file name can also contain parameters.
     You can use this format, "*?base64" (e.g. "file.json?base64" (case sensitive)), as an alternative to
     FileStorage::BASE64 flag.

=item flags

Mode of operation. One of FileStorage::Mode

=item encoding

Encoding of the file. Note that UTF-16 XML encoding is not supported currently and
     you should use 8-bit encoding instead of it.

=back


=cut
#line 8458 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 isOpened

=for ref

Checks whether the file is opened.

=for example

 $res = $obj->isOpened;

Returns: true if the object is associated with the current file and false otherwise. It is a
     good practice to call this method after you tried to open a file.


=cut
#line 8479 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 release

=for ref

Closes the file and releases all the memory buffers.

=for example

 $obj->release;

Call this method after all I/O operations with the storage are finished.

=cut
#line 8498 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 releaseAndGetString

=for ref

Closes the file and releases all the memory buffers.

=for example

 $res = $obj->releaseAndGetString;

Call this method after all I/O operations with the storage are finished. If the storage was
opened for writing data and FileStorage::WRITE was specified

=cut
#line 8518 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 getFirstTopLevelNode

=for ref

Returns the first element of the top-level mapping.

=for example

 $res = $obj->getFirstTopLevelNode;

Returns: The first element of the top-level mapping.


=cut
#line 8538 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 root

=for ref

Returns the top-level mapping

=for example

 $res = $obj->root; # with defaults
 $res = $obj->root($streamidx);

Parameters:

=over

=item streamidx

Zero-based index of the stream. In most cases there is only one stream in the file.
     However, YAML supports multiple streams and so there can be several.

=back

Returns: The top-level mapping.


=cut
#line 8570 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 getNode

=for ref

=for example

 $res = $obj->getNode($nodename);

@overload

=cut
#line 8587 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 write

=for ref

Simplified writing API to use with bindings.
     *

=for example

 $obj->write($name,$val);

*

Parameters:

=over

=item name

Name of the written object. When writing to sequences (a.k.a. "arrays"), pass an empty string.
     *

=item val

Value of the written object.

=back


=cut
#line 8623 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 write2

=for ref

=for example

 $obj->write2($name,$val);


=cut
#line 8639 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 write3

=for ref

=for example

 $obj->write3($name,$val);


=cut
#line 8655 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 FileStorage_write4

=for sig

  Signature: ([phys] val(l3,c3,r3); FileStorageWrapper * self; StringWrapper* name)

=for ref

=for example

 $obj->write4($name,$val);


=for bad

FileStorage_write4 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 8683 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::FileStorage::write4 {
  barf "Usage: PDL::OpenCV::FileStorage::write4(\$self,\$name,\$val)\n" if @_ < 3;
  my ($self,$name,$val) = @_;
    
  PDL::OpenCV::FileStorage::_FileStorage_write4_int($val,$self,$name);
  
}
#line 8696 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 8701 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 FileStorage_write5

=for sig

  Signature: (P(); C(); FileStorageWrapper * self; StringWrapper* name; vector_StringWrapper * val)

=for ref

=for example

 $obj->write5($name,$val);


=for bad

FileStorage_write5 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 8729 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::FileStorage::write5 {
  barf "Usage: PDL::OpenCV::FileStorage::write5(\$self,\$name,\$val)\n" if @_ < 3;
  my ($self,$name,$val) = @_;
    
  PDL::OpenCV::FileStorage::_FileStorage_write5_int($self,$name,$val);
  
}
#line 8742 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 8747 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 writeComment

=for ref

Writes a comment.

=for example

 $obj->writeComment($comment); # with defaults
 $obj->writeComment($comment,$append);

The function writes a comment into file storage. The comments are skipped when the storage is read.

Parameters:

=over

=item comment

The written comment, single-line or multi-line

=item append

If true, the function tries to put the comment at the end of current line.
     Else if the comment is multi-line, or if it does not fit at the end of the current
     line, the comment starts a new line.

=back


=cut
#line 8784 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 startWriteStruct

=for ref

Starts to write a nested structure (sequence or a mapping).

=for example

 $obj->startWriteStruct($name,$flags); # with defaults
 $obj->startWriteStruct($name,$flags,$typeName);

Parameters:

=over

=item name

name of the structure. When writing to sequences (a.k.a. "arrays"), pass an empty string.

=item flags

type of the structure (FileNode::MAP or FileNode::SEQ (both with optional FileNode::FLOW)).

=item typeName

optional name of the type you store. The effect of setting this depends on the storage format.
    I.e. if the format has a specification for storing type information, this parameter is used.

=back


=cut
#line 8822 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 endWriteStruct

=for ref

Finishes writing nested structure (should pair startWriteStruct())

=for example

 $obj->endWriteStruct;


=cut
#line 8840 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 getFormat

=for ref

Returns the current format.
     *

=for example

 $res = $obj->getFormat;

Returns: The current format, see FileStorage::Mode


=cut
#line 8861 "OpenCV.pm"



#line 394 "./genpp.pl"

=head1 METHODS for PDL::OpenCV::KeyPoint


=for ref

Data structure for salient point detectors.

The class instance stores a keypoint, i.e. a point feature found by one of many available keypoint
detectors, such as Harris corner detector, #FAST, %StarDetector, %SURF, %SIFT etc.
The keypoint is characterized by the 2D position, scale (proportional to the diameter of the
neighborhood that needs to be taken into account), orientation and some other parameters. The
keypoint neighborhood is then analyzed by another algorithm that builds a descriptor (usually
represented as a feature vector). The keypoints representing the same object in different images
can then be matched using %KDTree or another method.


=cut

@PDL::OpenCV::KeyPoint::ISA = qw();
#line 8886 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 new

=for ref

=for example

 $obj = PDL::OpenCV::KeyPoint->new;


=cut
#line 8902 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 new2

=for ref

=for example

 $obj = PDL::OpenCV::KeyPoint->new2($x,$y,$size); # with defaults
 $obj = PDL::OpenCV::KeyPoint->new2($x,$y,$size,$angle,$response,$octave,$class_id);

Parameters:

=over

=item x

x-coordinate of the keypoint

=item y

y-coordinate of the keypoint

=item size

keypoint diameter

=item angle

keypoint orientation

=item response

keypoint detector response on the keypoint (that is, strength of the keypoint)

=item octave

pyramid octave in which the keypoint has been detected

=item class_id

object id

=back


=cut
#line 8953 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 KeyPoint_convert

=for sig

  Signature: (float [o,phys] points2f(n2=2,n2d0); int [phys] keypointIndexes(n3d0); vector_KeyPointWrapper * keypoints)

=for ref

 NO BROADCASTING.

=for example

 $points2f = PDL::OpenCV::KeyPoint::convert($keypoints); # with defaults
 $points2f = PDL::OpenCV::KeyPoint::convert($keypoints,$keypointIndexes);

This method converts vector of keypoints to vector of points or the reverse, where each keypoint is
assigned the same size and the same orientation.

Parameters:

=over

=item keypoints

Keypoints obtained from any feature detection algorithm like SIFT/SURF/ORB

=item points2f

Array of (x,y) coordinates of each keypoint

=item keypointIndexes

Array of indexes of keypoints to be converted to points. (Acts like a mask to
    convert only specified keypoints)

=back


=for bad

KeyPoint_convert ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 9006 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::KeyPoint::convert {
  barf "Usage: PDL::OpenCV::KeyPoint::convert(\$keypoints,\$keypointIndexes)\n" if @_ < 1;
  my ($keypoints,$keypointIndexes) = @_;
  my ($points2f);
  $points2f = PDL->null if !defined $points2f;
  $keypointIndexes = empty(long) if !defined $keypointIndexes;
  PDL::OpenCV::KeyPoint::_KeyPoint_convert_int($points2f,$keypointIndexes,$keypoints);
  !wantarray ? $points2f : ($points2f)
}
#line 9021 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 9026 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 KeyPoint_convert2

=for sig

  Signature: (float [phys] points2f(n1=2,n1d0); float [phys] size(); float [phys] response(); int [phys] octave(); int [phys] class_id(); [o] vector_KeyPointWrapper * keypoints)

=for ref

=for example

 $keypoints = PDL::OpenCV::KeyPoint::convert2($points2f); # with defaults
 $keypoints = PDL::OpenCV::KeyPoint::convert2($points2f,$size,$response,$octave,$class_id);

@overload

Parameters:

=over

=item points2f

Array of (x,y) coordinates of each keypoint

=item keypoints

Keypoints obtained from any feature detection algorithm like SIFT/SURF/ORB

=item size

keypoint diameter

=item response

keypoint detector response on the keypoint (that is, strength of the keypoint)

=item octave

pyramid octave in which the keypoint has been detected

=item class_id

object id

=back


=for bad

KeyPoint_convert2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 9087 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::KeyPoint::convert2 {
  barf "Usage: PDL::OpenCV::KeyPoint::convert2(\$points2f,\$size,\$response,\$octave,\$class_id)\n" if @_ < 1;
  my ($points2f,$size,$response,$octave,$class_id) = @_;
  my ($keypoints);
  $size = 1 if !defined $size;
  $response = 1 if !defined $response;
  $octave = 0 if !defined $octave;
  $class_id = -1 if !defined $class_id;
  PDL::OpenCV::KeyPoint::_KeyPoint_convert2_int($points2f,$size,$response,$octave,$class_id,$keypoints);
  !wantarray ? $keypoints : ($keypoints)
}
#line 9104 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 9109 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 overlap

=for ref

=for example

 $res = PDL::OpenCV::KeyPoint::overlap($kp1,$kp2);

This method computes overlap for pair of keypoints. Overlap is the ratio between area of keypoint
regions' intersection and area of keypoint regions' union (considering keypoint region as circle).
If they don't overlap, we get zero. If they coincide at same location with same size, we get 1.

Parameters:

=over

=item kp1

First keypoint

=item kp2

Second keypoint

=back


=cut
#line 9143 "OpenCV.pm"



#line 394 "./genpp.pl"

=head1 METHODS for PDL::OpenCV::Moments


=for ref

struct returned by cv::moments

The spatial moments C<<< \texttt{Moments::m}_{ji} >>>are computed as:
\f[\texttt{m} _{ji}= \sum _{x,y}  \left ( \texttt{array} (x,y)  \cdot x^j  \cdot y^i \right )\f]
The central moments C<<< \texttt{Moments::mu}_{ji} >>>are computed as:
\f[\texttt{mu} _{ji}= \sum _{x,y}  \left ( \texttt{array} (x,y)  \cdot (x -  \bar{x} )^j  \cdot (y -  \bar{y} )^i \right )\f]
where C<<< (\bar{x}, \bar{y}) >>>is the mass center:
\f[\bar{x} = \frac{\texttt{m}_{10}}{\texttt{m}_{00}} , \; \bar{y} = \frac{\texttt{m}_{01}}{\texttt{m}_{00}}\f]
The normalized central moments C<<< \texttt{Moments::nu}_{ij} >>>are computed as:
\f[\texttt{nu} _{ji}= \frac{\texttt{mu}_{ji}}{\texttt{m}_{00}^{(i+j)/2+1}} .\f]
@note
C<<< \texttt{mu}_{00}=\texttt{m}_{00} >>>, C<<< \texttt{nu}_{00}=1 >>>C<<< \texttt{nu}_{10}=\texttt{mu}_{10}=\texttt{mu}_{01}=\texttt{mu}_{10}=0 >>>, hence the values are not
stored.
The moments of a contour are defined in the same way but computed using the Green's formula (see
<http://en.wikipedia.org/wiki/Green_theorem>). So, due to a limited raster resolution, the moments
computed for a contour are slightly different from the moments computed for the same rasterized
contour.
@note
Since the contour moments are computed using Green formula, you may get seemingly odd results for
contours with self-intersections, e.g. a zero area (m00) for butterfly-shaped contours.


=cut

@PDL::OpenCV::Moments::ISA = qw();
#line 9179 "OpenCV.pm"



#line 394 "./genpp.pl"

=head1 METHODS for PDL::OpenCV::RNG


=for ref

Random Number Generator

Random number generator. It encapsulates the state (currently, a 64-bit
integer) and has methods to return scalar random values and to fill
arrays with random values. Currently it supports uniform and Gaussian
(normal) distributions. The generator uses Multiply-With-Carry
algorithm, introduced by G. Marsaglia (
<http://en.wikipedia.org/wiki/Multiply-with-carry> ).
Gaussian-distribution random numbers are generated using the Ziggurat
algorithm ( <http://en.wikipedia.org/wiki/Ziggurat_algorithm> ),
introduced by G. Marsaglia and W. W. Tsang.


=cut

@PDL::OpenCV::RNG::ISA = qw();
#line 9206 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 new

=for ref

constructor

=for example

 $obj = PDL::OpenCV::RNG->new;

These are the RNG constructors. The first form sets the state to some
pre-defined value, equal to 2**32-1 in the current implementation. The
second form sets the state to the specified value. If you passed state=0
, the constructor uses the above default value instead to avoid the
singular random number sequence, consisting of all zeros.

=cut
#line 9229 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 new2

=for ref

=for example

 $obj = PDL::OpenCV::RNG->new2($state);

@overload

Parameters:

=over

=item state

64-bit value used to initialize the RNG.

=back


=cut
#line 9257 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 RNG_fill

=for sig

  Signature: ([io,phys] mat(l2,c2,r2); int [phys] distType(); [phys] a(l4,c4,r4); [phys] b(l5,c5,r5); byte [phys] saturateRange(); RNGWrapper * self)

=for ref

Fills arrays with random numbers.

=for example

 $obj->fill($mat,$distType,$a,$b); # with defaults
 $obj->fill($mat,$distType,$a,$b,$saturateRange);

Each of the methods fills the matrix with the random values from the
specified distribution. As the new numbers are generated, the RNG state
is updated accordingly. In case of multiple-channel images, every
channel is filled independently, which means that RNG cannot generate
samples from the multi-dimensional Gaussian distribution with
non-diagonal covariance matrix directly. To do that, the method
generates samples from multi-dimensional standard Gaussian distribution
with zero mean and identity covariation matrix, and then transforms them
using transform to get samples from the specified Gaussian distribution.

Parameters:

=over

=item mat

2D or N-dimensional matrix; currently matrices with more than
    4 channels are not supported by the methods, use Mat::reshape as a
    possible workaround.

=item distType

distribution type, RNG::UNIFORM or RNG::NORMAL.

=item a

first distribution parameter; in case of the uniform
    distribution, this is an inclusive lower boundary, in case of the normal
    distribution, this is a mean value.

=item b

second distribution parameter; in case of the uniform
    distribution, this is a non-inclusive upper boundary, in case of the
    normal distribution, this is a standard deviation (diagonal of the
    standard deviation matrix or the full standard deviation matrix).

=item saturateRange

pre-saturation flag; for uniform distribution only;
    if true, the method will first convert a and b to the acceptable value
    range (according to the mat datatype) and then will generate uniformly
    distributed random numbers within the range [saturate(a), saturate(b)),
    if saturateRange=false, the method will generate uniformly distributed
    random numbers in the original range [a, b) and then will saturate them,
    it means, for example, that
    <tt>theRNG().fill(mat_8u, RNG::UNIFORM, -DBL_MAX, DBL_MAX)</tt> will likely
    produce array mostly filled with 0's and 255's, since the range (0, 255)
    is significantly smaller than [-DBL_MAX, DBL_MAX).

=back


=for bad

RNG_fill ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 9340 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::RNG::fill {
  barf "Usage: PDL::OpenCV::RNG::fill(\$self,\$mat,\$distType,\$a,\$b,\$saturateRange)\n" if @_ < 5;
  my ($self,$mat,$distType,$a,$b,$saturateRange) = @_;
    $saturateRange = 0 if !defined $saturateRange;
  PDL::OpenCV::RNG::_RNG_fill_int($mat,$distType,$a,$b,$saturateRange,$self);
  
}
#line 9353 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 9358 "OpenCV.pm"



#line 394 "./genpp.pl"

=head1 METHODS for PDL::OpenCV::RNG_MT19937


=for ref

Mersenne Twister random number generator

Inspired by http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/MT2002/CODES/mt19937ar.c
@todo document


=cut

@PDL::OpenCV::RNG_MT19937::ISA = qw();
#line 9378 "OpenCV.pm"



#line 394 "./genpp.pl"

=head1 METHODS for PDL::OpenCV::RotatedRect


=for ref

The class represents rotated (i.e. not up-right) rectangles on a plane.

Each rectangle is specified by the center point (mass center), length of each side (represented by
#Size2f structure) and the rotation angle in degrees.
The sample below demonstrates how to use RotatedRect:
@snippet snippets/core_various.cpp RotatedRect_demo
![image](pics/rotatedrect.png)
See also:
CamShift, fitEllipse, minAreaRect, CvBox2D



=cut

@PDL::OpenCV::RotatedRect::ISA = qw();
#line 9404 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 new

=for ref

=for example

 $obj = PDL::OpenCV::RotatedRect->new;


=cut
#line 9420 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 RotatedRect_new2

=for sig

  Signature: (float [phys] center(n2=2); float [phys] size(n3=2); float [phys] angle(); char * klass; [o] RotatedRectWrapper * res)

=for ref

=for example

 $obj = PDL::OpenCV::RotatedRect->new2($center,$size,$angle);

full constructor

Parameters:

=over

=item center

The rectangle mass center.

=item size

Width and height of the rectangle.

=item angle

The rotation angle in a clockwise direction. When the angle is 0, 90, 180, 270 etc.,
    the rectangle becomes an up-right rectangle.

=back


=for bad

RotatedRect_new2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 9469 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::RotatedRect::new2 {
  barf "Usage: PDL::OpenCV::RotatedRect::new2(\$klass,\$center,\$size,\$angle)\n" if @_ < 4;
  my ($klass,$center,$size,$angle) = @_;
  my ($res);
  
  PDL::OpenCV::RotatedRect::_RotatedRect_new2_int($center,$size,$angle,$klass,$res);
  !wantarray ? $res : ($res)
}
#line 9483 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 9488 "OpenCV.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 RotatedRect_boundingRect

=for sig

  Signature: (indx [o,phys] res(n2=4); RotatedRectWrapper * self)

=for ref

=for example

 $res = $obj->boundingRect;

returns 4 vertices of the rectangle

Parameters:

=over

=item pts

The points array for storing rectangle vertices. The order is bottomLeft, topLeft, topRight, bottomRight.

=back


=for bad

RotatedRect_boundingRect ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 9528 "OpenCV.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::RotatedRect::boundingRect {
  barf "Usage: PDL::OpenCV::RotatedRect::boundingRect(\$self)\n" if @_ < 1;
  my ($self) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::RotatedRect::_RotatedRect_boundingRect_int($res,$self);
  !wantarray ? $res : ($res)
}
#line 9542 "OpenCV.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 9547 "OpenCV.pm"



#line 394 "./genpp.pl"

=head1 METHODS for PDL::OpenCV::TermCriteria


=for ref

The class defining termination criteria for iterative algorithms.

You can initialize it by default constructor and then override any parameters, or the structure may
be fully initialized using the advanced variant of the constructor.


=cut

@PDL::OpenCV::TermCriteria::ISA = qw();
#line 9567 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 new

=for ref

=for example

 $obj = PDL::OpenCV::TermCriteria->new;


=cut
#line 9583 "OpenCV.pm"



#line 274 "./genpp.pl"

=head2 new2

=for ref

=for example

 $obj = PDL::OpenCV::TermCriteria->new2($type,$maxCount,$epsilon);

Parameters:

=over

=item type

The type of termination criteria, one of TermCriteria::Type

=item maxCount

The maximum number of iterations or elements to compute.

=item epsilon

The desired accuracy or change in parameters at which the iterative algorithm stops.

=back


=cut
#line 9617 "OpenCV.pm"



#line 441 "./genpp.pl"

=head1 CONSTANTS

=over

=item PDL::OpenCV::DECOMP_LU()

=item PDL::OpenCV::DECOMP_SVD()

=item PDL::OpenCV::DECOMP_EIG()

=item PDL::OpenCV::DECOMP_CHOLESKY()

=item PDL::OpenCV::DECOMP_QR()

=item PDL::OpenCV::DECOMP_NORMAL()

=item PDL::OpenCV::NORM_INF()

=item PDL::OpenCV::NORM_L1()

=item PDL::OpenCV::NORM_L2()

=item PDL::OpenCV::NORM_L2SQR()

=item PDL::OpenCV::NORM_HAMMING()

=item PDL::OpenCV::NORM_HAMMING2()

=item PDL::OpenCV::NORM_TYPE_MASK()

=item PDL::OpenCV::NORM_RELATIVE()

=item PDL::OpenCV::NORM_MINMAX()

=item PDL::OpenCV::CMP_EQ()

=item PDL::OpenCV::CMP_GT()

=item PDL::OpenCV::CMP_GE()

=item PDL::OpenCV::CMP_LT()

=item PDL::OpenCV::CMP_LE()

=item PDL::OpenCV::CMP_NE()

=item PDL::OpenCV::GEMM_1_T()

=item PDL::OpenCV::GEMM_2_T()

=item PDL::OpenCV::GEMM_3_T()

=item PDL::OpenCV::DFT_INVERSE()

=item PDL::OpenCV::DFT_SCALE()

=item PDL::OpenCV::DFT_ROWS()

=item PDL::OpenCV::DFT_COMPLEX_OUTPUT()

=item PDL::OpenCV::DFT_REAL_OUTPUT()

=item PDL::OpenCV::DFT_COMPLEX_INPUT()

=item PDL::OpenCV::DCT_INVERSE()

=item PDL::OpenCV::DCT_ROWS()

=item PDL::OpenCV::BORDER_CONSTANT()

=item PDL::OpenCV::BORDER_REPLICATE()

=item PDL::OpenCV::BORDER_REFLECT()

=item PDL::OpenCV::BORDER_WRAP()

=item PDL::OpenCV::BORDER_REFLECT_101()

=item PDL::OpenCV::BORDER_TRANSPARENT()

=item PDL::OpenCV::BORDER_REFLECT101()

=item PDL::OpenCV::BORDER_DEFAULT()

=item PDL::OpenCV::BORDER_ISOLATED()

=item PDL::OpenCV::ACCESS_READ()

=item PDL::OpenCV::ACCESS_WRITE()

=item PDL::OpenCV::ACCESS_RW()

=item PDL::OpenCV::ACCESS_MASK()

=item PDL::OpenCV::ACCESS_FAST()

=item PDL::OpenCV::USAGE_DEFAULT()

=item PDL::OpenCV::USAGE_ALLOCATE_HOST_MEMORY()

=item PDL::OpenCV::USAGE_ALLOCATE_DEVICE_MEMORY()

=item PDL::OpenCV::USAGE_ALLOCATE_SHARED_MEMORY()

=item PDL::OpenCV::__UMAT_USAGE_FLAGS_32BIT()

=item PDL::OpenCV::SORT_EVERY_ROW()

=item PDL::OpenCV::SORT_EVERY_COLUMN()

=item PDL::OpenCV::SORT_ASCENDING()

=item PDL::OpenCV::SORT_DESCENDING()

=item PDL::OpenCV::COVAR_SCRAMBLED()

=item PDL::OpenCV::COVAR_NORMAL()

=item PDL::OpenCV::COVAR_USE_AVG()

=item PDL::OpenCV::COVAR_SCALE()

=item PDL::OpenCV::COVAR_ROWS()

=item PDL::OpenCV::COVAR_COLS()

=item PDL::OpenCV::KMEANS_RANDOM_CENTERS()

=item PDL::OpenCV::KMEANS_PP_CENTERS()

=item PDL::OpenCV::KMEANS_USE_INITIAL_LABELS()

=item PDL::OpenCV::REDUCE_SUM()

=item PDL::OpenCV::REDUCE_AVG()

=item PDL::OpenCV::REDUCE_MAX()

=item PDL::OpenCV::REDUCE_MIN()

=item PDL::OpenCV::ROTATE_90_CLOCKWISE()

=item PDL::OpenCV::ROTATE_180()

=item PDL::OpenCV::ROTATE_90_COUNTERCLOCKWISE()

=item PDL::OpenCV::CV_8U()

=item PDL::OpenCV::CV_8UC1()

=item PDL::OpenCV::CV_8UC2()

=item PDL::OpenCV::CV_8UC3()

=item PDL::OpenCV::CV_8UC4()

=item PDL::OpenCV::CV_8UC(int n)

=item PDL::OpenCV::CV_8S()

=item PDL::OpenCV::CV_8SC1()

=item PDL::OpenCV::CV_8SC2()

=item PDL::OpenCV::CV_8SC3()

=item PDL::OpenCV::CV_8SC4()

=item PDL::OpenCV::CV_8SC(int n)

=item PDL::OpenCV::CV_16U()

=item PDL::OpenCV::CV_16UC1()

=item PDL::OpenCV::CV_16UC2()

=item PDL::OpenCV::CV_16UC3()

=item PDL::OpenCV::CV_16UC4()

=item PDL::OpenCV::CV_16UC(int n)

=item PDL::OpenCV::CV_16S()

=item PDL::OpenCV::CV_16SC1()

=item PDL::OpenCV::CV_16SC2()

=item PDL::OpenCV::CV_16SC3()

=item PDL::OpenCV::CV_16SC4()

=item PDL::OpenCV::CV_16SC(int n)

=item PDL::OpenCV::CV_32S()

=item PDL::OpenCV::CV_32SC1()

=item PDL::OpenCV::CV_32SC2()

=item PDL::OpenCV::CV_32SC3()

=item PDL::OpenCV::CV_32SC4()

=item PDL::OpenCV::CV_32SC(int n)

=item PDL::OpenCV::CV_32F()

=item PDL::OpenCV::CV_32FC1()

=item PDL::OpenCV::CV_32FC2()

=item PDL::OpenCV::CV_32FC3()

=item PDL::OpenCV::CV_32FC4()

=item PDL::OpenCV::CV_32FC(int n)

=item PDL::OpenCV::CV_64F()

=item PDL::OpenCV::CV_64FC1()

=item PDL::OpenCV::CV_64FC2()

=item PDL::OpenCV::CV_64FC3()

=item PDL::OpenCV::CV_64FC4()

=item PDL::OpenCV::CV_64FC(int n)

=item PDL::OpenCV::CV_PI()

=item PDL::OpenCV::CV_2PI()

=item PDL::OpenCV::CV_LOG2()

=item PDL::OpenCV::INT_MAX()

=item PDL::OpenCV::Error::StsOk()

=item PDL::OpenCV::Error::StsBackTrace()

=item PDL::OpenCV::Error::StsError()

=item PDL::OpenCV::Error::StsInternal()

=item PDL::OpenCV::Error::StsNoMem()

=item PDL::OpenCV::Error::StsBadArg()

=item PDL::OpenCV::Error::StsBadFunc()

=item PDL::OpenCV::Error::StsNoConv()

=item PDL::OpenCV::Error::StsAutoTrace()

=item PDL::OpenCV::Error::HeaderIsNull()

=item PDL::OpenCV::Error::BadImageSize()

=item PDL::OpenCV::Error::BadOffset()

=item PDL::OpenCV::Error::BadDataPtr()

=item PDL::OpenCV::Error::BadStep()

=item PDL::OpenCV::Error::BadModelOrChSeq()

=item PDL::OpenCV::Error::BadNumChannels()

=item PDL::OpenCV::Error::BadNumChannel1U()

=item PDL::OpenCV::Error::BadDepth()

=item PDL::OpenCV::Error::BadAlphaChannel()

=item PDL::OpenCV::Error::BadOrder()

=item PDL::OpenCV::Error::BadOrigin()

=item PDL::OpenCV::Error::BadAlign()

=item PDL::OpenCV::Error::BadCallBack()

=item PDL::OpenCV::Error::BadTileSize()

=item PDL::OpenCV::Error::BadCOI()

=item PDL::OpenCV::Error::BadROISize()

=item PDL::OpenCV::Error::MaskIsTiled()

=item PDL::OpenCV::Error::StsNullPtr()

=item PDL::OpenCV::Error::StsVecLengthErr()

=item PDL::OpenCV::Error::StsFilterStructContentErr()

=item PDL::OpenCV::Error::StsKernelStructContentErr()

=item PDL::OpenCV::Error::StsFilterOffsetErr()

=item PDL::OpenCV::Error::StsBadSize()

=item PDL::OpenCV::Error::StsDivByZero()

=item PDL::OpenCV::Error::StsInplaceNotSupported()

=item PDL::OpenCV::Error::StsObjectNotFound()

=item PDL::OpenCV::Error::StsUnmatchedFormats()

=item PDL::OpenCV::Error::StsBadFlag()

=item PDL::OpenCV::Error::StsBadPoint()

=item PDL::OpenCV::Error::StsBadMask()

=item PDL::OpenCV::Error::StsUnmatchedSizes()

=item PDL::OpenCV::Error::StsUnsupportedFormat()

=item PDL::OpenCV::Error::StsOutOfRange()

=item PDL::OpenCV::Error::StsParseError()

=item PDL::OpenCV::Error::StsNotImplemented()

=item PDL::OpenCV::Error::StsBadMemBlock()

=item PDL::OpenCV::Error::StsAssert()

=item PDL::OpenCV::Error::GpuNotSupported()

=item PDL::OpenCV::Error::GpuApiCallError()

=item PDL::OpenCV::Error::OpenGlNotSupported()

=item PDL::OpenCV::Error::OpenGlApiCallError()

=item PDL::OpenCV::Error::OpenCLApiCallError()

=item PDL::OpenCV::Error::OpenCLDoubleNotSupported()

=item PDL::OpenCV::Error::OpenCLInitError()

=item PDL::OpenCV::Error::OpenCLNoAMDBlasFft()

=item PDL::OpenCV::FileNode::NONE()

=item PDL::OpenCV::FileNode::INT()

=item PDL::OpenCV::FileNode::REAL()

=item PDL::OpenCV::FileNode::FLOAT()

=item PDL::OpenCV::FileNode::STR()

=item PDL::OpenCV::FileNode::STRING()

=item PDL::OpenCV::FileNode::SEQ()

=item PDL::OpenCV::FileNode::MAP()

=item PDL::OpenCV::FileNode::TYPE_MASK()

=item PDL::OpenCV::FileNode::FLOW()

=item PDL::OpenCV::FileNode::UNIFORM()

=item PDL::OpenCV::FileNode::EMPTY()

=item PDL::OpenCV::FileNode::NAMED()

=item PDL::OpenCV::FileStorage::READ()

=item PDL::OpenCV::FileStorage::WRITE()

=item PDL::OpenCV::FileStorage::APPEND()

=item PDL::OpenCV::FileStorage::MEMORY()

=item PDL::OpenCV::FileStorage::FORMAT_MASK()

=item PDL::OpenCV::FileStorage::FORMAT_AUTO()

=item PDL::OpenCV::FileStorage::FORMAT_XML()

=item PDL::OpenCV::FileStorage::FORMAT_YAML()

=item PDL::OpenCV::FileStorage::FORMAT_JSON()

=item PDL::OpenCV::FileStorage::BASE64()

=item PDL::OpenCV::FileStorage::WRITE_BASE64()

=item PDL::OpenCV::FileStorage::UNDEFINED()

=item PDL::OpenCV::FileStorage::VALUE_EXPECTED()

=item PDL::OpenCV::FileStorage::NAME_EXPECTED()

=item PDL::OpenCV::FileStorage::INSIDE_MAP()

=item PDL::OpenCV::Formatter::FMT_DEFAULT()

=item PDL::OpenCV::Formatter::FMT_MATLAB()

=item PDL::OpenCV::Formatter::FMT_CSV()

=item PDL::OpenCV::Formatter::FMT_PYTHON()

=item PDL::OpenCV::Formatter::FMT_NUMPY()

=item PDL::OpenCV::Formatter::FMT_C()

=item PDL::OpenCV::Mat::MAGIC_VAL()

=item PDL::OpenCV::Mat::AUTO_STEP()

=item PDL::OpenCV::Mat::CONTINUOUS_FLAG()

=item PDL::OpenCV::Mat::SUBMATRIX_FLAG()

=item PDL::OpenCV::Mat::MAGIC_MASK()

=item PDL::OpenCV::Mat::TYPE_MASK()

=item PDL::OpenCV::Mat::DEPTH_MASK()

=item PDL::OpenCV::PCA::DATA_AS_ROW()

=item PDL::OpenCV::PCA::DATA_AS_COL()

=item PDL::OpenCV::PCA::USE_AVG()

=item PDL::OpenCV::Param::INT()

=item PDL::OpenCV::Param::BOOLEAN()

=item PDL::OpenCV::Param::REAL()

=item PDL::OpenCV::Param::STRING()

=item PDL::OpenCV::Param::MAT()

=item PDL::OpenCV::Param::MAT_VECTOR()

=item PDL::OpenCV::Param::ALGORITHM()

=item PDL::OpenCV::Param::FLOAT()

=item PDL::OpenCV::Param::UNSIGNED_INT()

=item PDL::OpenCV::Param::UINT64()

=item PDL::OpenCV::Param::UCHAR()

=item PDL::OpenCV::Param::SCALAR()

=item PDL::OpenCV::RNG::UNIFORM()

=item PDL::OpenCV::RNG::NORMAL()

=item PDL::OpenCV::SVD::MODIFY_A()

=item PDL::OpenCV::SVD::NO_UV()

=item PDL::OpenCV::SVD::FULL_UV()

=item PDL::OpenCV::SparseMat::MAGIC_VAL()

=item PDL::OpenCV::SparseMat::MAX_DIM()

=item PDL::OpenCV::SparseMat::HASH_SCALE()

=item PDL::OpenCV::SparseMat::HASH_BIT()

=item PDL::OpenCV::TermCriteria::COUNT()

=item PDL::OpenCV::TermCriteria::MAX_ITER()

=item PDL::OpenCV::TermCriteria::EPS()

=item PDL::OpenCV::UMat::MAGIC_VAL()

=item PDL::OpenCV::UMat::AUTO_STEP()

=item PDL::OpenCV::UMat::CONTINUOUS_FLAG()

=item PDL::OpenCV::UMat::SUBMATRIX_FLAG()

=item PDL::OpenCV::UMat::MAGIC_MASK()

=item PDL::OpenCV::UMat::TYPE_MASK()

=item PDL::OpenCV::UMat::DEPTH_MASK()

=item PDL::OpenCV::UMatData::COPY_ON_MAP()

=item PDL::OpenCV::UMatData::HOST_COPY_OBSOLETE()

=item PDL::OpenCV::UMatData::DEVICE_COPY_OBSOLETE()

=item PDL::OpenCV::UMatData::TEMP_UMAT()

=item PDL::OpenCV::UMatData::TEMP_COPIED_UMAT()

=item PDL::OpenCV::UMatData::USER_ALLOCATED()

=item PDL::OpenCV::UMatData::DEVICE_MEM_MAPPED()

=item PDL::OpenCV::UMatData::ASYNC_CLEANUP()

=item PDL::OpenCV::_InputArray::KIND_SHIFT()

=item PDL::OpenCV::_InputArray::FIXED_TYPE()

=item PDL::OpenCV::_InputArray::FIXED_SIZE()

=item PDL::OpenCV::_InputArray::KIND_MASK()

=item PDL::OpenCV::_InputArray::NONE()

=item PDL::OpenCV::_InputArray::MAT()

=item PDL::OpenCV::_InputArray::MATX()

=item PDL::OpenCV::_InputArray::STD_VECTOR()

=item PDL::OpenCV::_InputArray::STD_VECTOR_VECTOR()

=item PDL::OpenCV::_InputArray::STD_VECTOR_MAT()

=item PDL::OpenCV::_InputArray::EXPR()

=item PDL::OpenCV::_InputArray::OPENGL_BUFFER()

=item PDL::OpenCV::_InputArray::CUDA_HOST_MEM()

=item PDL::OpenCV::_InputArray::CUDA_GPU_MAT()

=item PDL::OpenCV::_InputArray::UMAT()

=item PDL::OpenCV::_InputArray::STD_VECTOR_UMAT()

=item PDL::OpenCV::_InputArray::STD_BOOL_VECTOR()

=item PDL::OpenCV::_InputArray::STD_VECTOR_CUDA_GPU_MAT()

=item PDL::OpenCV::_InputArray::STD_ARRAY()

=item PDL::OpenCV::_InputArray::STD_ARRAY_MAT()

=item PDL::OpenCV::_OutputArray::DEPTH_MASK_8U()

=item PDL::OpenCV::_OutputArray::DEPTH_MASK_8S()

=item PDL::OpenCV::_OutputArray::DEPTH_MASK_16U()

=item PDL::OpenCV::_OutputArray::DEPTH_MASK_16S()

=item PDL::OpenCV::_OutputArray::DEPTH_MASK_32S()

=item PDL::OpenCV::_OutputArray::DEPTH_MASK_32F()

=item PDL::OpenCV::_OutputArray::DEPTH_MASK_64F()

=item PDL::OpenCV::_OutputArray::DEPTH_MASK_16F()

=item PDL::OpenCV::_OutputArray::DEPTH_MASK_ALL()

=item PDL::OpenCV::_OutputArray::DEPTH_MASK_ALL_BUT_8S()

=item PDL::OpenCV::_OutputArray::DEPTH_MASK_ALL_16F()

=item PDL::OpenCV::_OutputArray::DEPTH_MASK_FLT()


=back

=cut
#line 10205 "OpenCV.pm"





#line 129 "opencv.pd"

=head1 BUGS

Please report bugs at L<https://github.com/PDLPorters/PDL-OpenCV/issues>,
or on the mailing list(s) at L<https://pdl.perl.org/?page=mailing-lists>.

=head1 AUTHOR

Ingo Schmid and the PDL Porters. Same terms as PDL itself.

=cut
#line 10223 "OpenCV.pm"




# Exit with OK status

1;
