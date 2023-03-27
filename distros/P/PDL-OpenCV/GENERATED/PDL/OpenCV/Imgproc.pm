#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::OpenCV::Imgproc;

our @EXPORT_OK = qw( getGaussianKernel getDerivKernels getGaborKernel getStructuringElement medianBlur GaussianBlur bilateralFilter boxFilter sqrBoxFilter blur filter2D sepFilter2D Sobel spatialGradient Scharr Laplacian Canny Canny2 cornerMinEigenVal cornerHarris cornerEigenValsAndVecs preCornerDetect cornerSubPix goodFeaturesToTrack goodFeaturesToTrack2 goodFeaturesToTrackWithQuality HoughLines HoughLinesP HoughLinesPointSet HoughCircles erode dilate morphologyEx resize warpAffine warpPerspective remap convertMaps getRotationMatrix2D invertAffineTransform getPerspectiveTransform getAffineTransform getRectSubPix logPolar linearPolar warpPolar integral integral2 integral3 accumulate accumulateSquare accumulateProduct accumulateWeighted phaseCorrelate createHanningWindow divSpectrums threshold adaptiveThreshold pyrDown pyrUp calcHist calcBackProject compareHist equalizeHist EMD watershed pyrMeanShiftFiltering grabCut distanceTransformWithLabels distanceTransform floodFill blendLinear cvtColor cvtColorTwoPlane demosaicing matchTemplate connectedComponentsWithAlgorithm connectedComponents connectedComponentsWithStatsWithAlgorithm connectedComponentsWithStats findContours approxPolyDP arcLength boundingRect contourArea minAreaRect boxPoints minEnclosingCircle minEnclosingTriangle matchShapes convexHull convexityDefects isContourConvex intersectConvexConvex fitEllipse fitEllipseAMS fitEllipseDirect fitLine pointPolygonTest rotatedRectangleIntersection applyColorMap applyColorMap2 line arrowedLine rectangle rectangle2 circle ellipse ellipse2 drawMarker fillConvexPoly fillPoly polylines drawContours clipLine ellipse2Poly putText getTextSize getFontScaleFromHeight FILTER_SCHARR MORPH_ERODE MORPH_DILATE MORPH_OPEN MORPH_CLOSE MORPH_GRADIENT MORPH_TOPHAT MORPH_BLACKHAT MORPH_HITMISS MORPH_RECT MORPH_CROSS MORPH_ELLIPSE INTER_NEAREST INTER_LINEAR INTER_CUBIC INTER_AREA INTER_LANCZOS4 INTER_LINEAR_EXACT INTER_NEAREST_EXACT INTER_MAX WARP_FILL_OUTLIERS WARP_INVERSE_MAP WARP_POLAR_LINEAR WARP_POLAR_LOG INTER_BITS INTER_BITS2 INTER_TAB_SIZE INTER_TAB_SIZE2 DIST_USER DIST_L1 DIST_L2 DIST_C DIST_L12 DIST_FAIR DIST_WELSCH DIST_HUBER DIST_MASK_3 DIST_MASK_5 DIST_MASK_PRECISE THRESH_BINARY THRESH_BINARY_INV THRESH_TRUNC THRESH_TOZERO THRESH_TOZERO_INV THRESH_MASK THRESH_OTSU THRESH_TRIANGLE ADAPTIVE_THRESH_MEAN_C ADAPTIVE_THRESH_GAUSSIAN_C GC_BGD GC_FGD GC_PR_BGD GC_PR_FGD GC_INIT_WITH_RECT GC_INIT_WITH_MASK GC_EVAL GC_EVAL_FREEZE_MODEL DIST_LABEL_CCOMP DIST_LABEL_PIXEL FLOODFILL_FIXED_RANGE FLOODFILL_MASK_ONLY CC_STAT_LEFT CC_STAT_TOP CC_STAT_WIDTH CC_STAT_HEIGHT CC_STAT_AREA CC_STAT_MAX CCL_DEFAULT CCL_WU CCL_GRANA CCL_BOLELLI CCL_SAUF CCL_BBDT CCL_SPAGHETTI RETR_EXTERNAL RETR_LIST RETR_CCOMP RETR_TREE RETR_FLOODFILL CHAIN_APPROX_NONE CHAIN_APPROX_SIMPLE CHAIN_APPROX_TC89_L1 CHAIN_APPROX_TC89_KCOS CONTOURS_MATCH_I1 CONTOURS_MATCH_I2 CONTOURS_MATCH_I3 HOUGH_STANDARD HOUGH_PROBABILISTIC HOUGH_MULTI_SCALE HOUGH_GRADIENT HOUGH_GRADIENT_ALT LSD_REFINE_NONE LSD_REFINE_STD LSD_REFINE_ADV HISTCMP_CORREL HISTCMP_CHISQR HISTCMP_INTERSECT HISTCMP_BHATTACHARYYA HISTCMP_HELLINGER HISTCMP_CHISQR_ALT HISTCMP_KL_DIV COLOR_BGR2BGRA COLOR_RGB2RGBA COLOR_BGRA2BGR COLOR_RGBA2RGB COLOR_BGR2RGBA COLOR_RGB2BGRA COLOR_RGBA2BGR COLOR_BGRA2RGB COLOR_BGR2RGB COLOR_RGB2BGR COLOR_BGRA2RGBA COLOR_RGBA2BGRA COLOR_BGR2GRAY COLOR_RGB2GRAY COLOR_GRAY2BGR COLOR_GRAY2RGB COLOR_GRAY2BGRA COLOR_GRAY2RGBA COLOR_BGRA2GRAY COLOR_RGBA2GRAY COLOR_BGR2BGR565 COLOR_RGB2BGR565 COLOR_BGR5652BGR COLOR_BGR5652RGB COLOR_BGRA2BGR565 COLOR_RGBA2BGR565 COLOR_BGR5652BGRA COLOR_BGR5652RGBA COLOR_GRAY2BGR565 COLOR_BGR5652GRAY COLOR_BGR2BGR555 COLOR_RGB2BGR555 COLOR_BGR5552BGR COLOR_BGR5552RGB COLOR_BGRA2BGR555 COLOR_RGBA2BGR555 COLOR_BGR5552BGRA COLOR_BGR5552RGBA COLOR_GRAY2BGR555 COLOR_BGR5552GRAY COLOR_BGR2XYZ COLOR_RGB2XYZ COLOR_XYZ2BGR COLOR_XYZ2RGB COLOR_BGR2YCrCb COLOR_RGB2YCrCb COLOR_YCrCb2BGR COLOR_YCrCb2RGB COLOR_BGR2HSV COLOR_RGB2HSV COLOR_BGR2Lab COLOR_RGB2Lab COLOR_BGR2Luv COLOR_RGB2Luv COLOR_BGR2HLS COLOR_RGB2HLS COLOR_HSV2BGR COLOR_HSV2RGB COLOR_Lab2BGR COLOR_Lab2RGB COLOR_Luv2BGR COLOR_Luv2RGB COLOR_HLS2BGR COLOR_HLS2RGB COLOR_BGR2HSV_FULL COLOR_RGB2HSV_FULL COLOR_BGR2HLS_FULL COLOR_RGB2HLS_FULL COLOR_HSV2BGR_FULL COLOR_HSV2RGB_FULL COLOR_HLS2BGR_FULL COLOR_HLS2RGB_FULL COLOR_LBGR2Lab COLOR_LRGB2Lab COLOR_LBGR2Luv COLOR_LRGB2Luv COLOR_Lab2LBGR COLOR_Lab2LRGB COLOR_Luv2LBGR COLOR_Luv2LRGB COLOR_BGR2YUV COLOR_RGB2YUV COLOR_YUV2BGR COLOR_YUV2RGB COLOR_YUV2RGB_NV12 COLOR_YUV2BGR_NV12 COLOR_YUV2RGB_NV21 COLOR_YUV2BGR_NV21 COLOR_YUV420sp2RGB COLOR_YUV420sp2BGR COLOR_YUV2RGBA_NV12 COLOR_YUV2BGRA_NV12 COLOR_YUV2RGBA_NV21 COLOR_YUV2BGRA_NV21 COLOR_YUV420sp2RGBA COLOR_YUV420sp2BGRA COLOR_YUV2RGB_YV12 COLOR_YUV2BGR_YV12 COLOR_YUV2RGB_IYUV COLOR_YUV2BGR_IYUV COLOR_YUV2RGB_I420 COLOR_YUV2BGR_I420 COLOR_YUV420p2RGB COLOR_YUV420p2BGR COLOR_YUV2RGBA_YV12 COLOR_YUV2BGRA_YV12 COLOR_YUV2RGBA_IYUV COLOR_YUV2BGRA_IYUV COLOR_YUV2RGBA_I420 COLOR_YUV2BGRA_I420 COLOR_YUV420p2RGBA COLOR_YUV420p2BGRA COLOR_YUV2GRAY_420 COLOR_YUV2GRAY_NV21 COLOR_YUV2GRAY_NV12 COLOR_YUV2GRAY_YV12 COLOR_YUV2GRAY_IYUV COLOR_YUV2GRAY_I420 COLOR_YUV420sp2GRAY COLOR_YUV420p2GRAY COLOR_YUV2RGB_UYVY COLOR_YUV2BGR_UYVY COLOR_YUV2RGB_Y422 COLOR_YUV2BGR_Y422 COLOR_YUV2RGB_UYNV COLOR_YUV2BGR_UYNV COLOR_YUV2RGBA_UYVY COLOR_YUV2BGRA_UYVY COLOR_YUV2RGBA_Y422 COLOR_YUV2BGRA_Y422 COLOR_YUV2RGBA_UYNV COLOR_YUV2BGRA_UYNV COLOR_YUV2RGB_YUY2 COLOR_YUV2BGR_YUY2 COLOR_YUV2RGB_YVYU COLOR_YUV2BGR_YVYU COLOR_YUV2RGB_YUYV COLOR_YUV2BGR_YUYV COLOR_YUV2RGB_YUNV COLOR_YUV2BGR_YUNV COLOR_YUV2RGBA_YUY2 COLOR_YUV2BGRA_YUY2 COLOR_YUV2RGBA_YVYU COLOR_YUV2BGRA_YVYU COLOR_YUV2RGBA_YUYV COLOR_YUV2BGRA_YUYV COLOR_YUV2RGBA_YUNV COLOR_YUV2BGRA_YUNV COLOR_YUV2GRAY_UYVY COLOR_YUV2GRAY_YUY2 COLOR_YUV2GRAY_Y422 COLOR_YUV2GRAY_UYNV COLOR_YUV2GRAY_YVYU COLOR_YUV2GRAY_YUYV COLOR_YUV2GRAY_YUNV COLOR_RGBA2mRGBA COLOR_mRGBA2RGBA COLOR_RGB2YUV_I420 COLOR_BGR2YUV_I420 COLOR_RGB2YUV_IYUV COLOR_BGR2YUV_IYUV COLOR_RGBA2YUV_I420 COLOR_BGRA2YUV_I420 COLOR_RGBA2YUV_IYUV COLOR_BGRA2YUV_IYUV COLOR_RGB2YUV_YV12 COLOR_BGR2YUV_YV12 COLOR_RGBA2YUV_YV12 COLOR_BGRA2YUV_YV12 COLOR_BayerBG2BGR COLOR_BayerGB2BGR COLOR_BayerRG2BGR COLOR_BayerGR2BGR COLOR_BayerBG2RGB COLOR_BayerGB2RGB COLOR_BayerRG2RGB COLOR_BayerGR2RGB COLOR_BayerBG2GRAY COLOR_BayerGB2GRAY COLOR_BayerRG2GRAY COLOR_BayerGR2GRAY COLOR_BayerBG2BGR_VNG COLOR_BayerGB2BGR_VNG COLOR_BayerRG2BGR_VNG COLOR_BayerGR2BGR_VNG COLOR_BayerBG2RGB_VNG COLOR_BayerGB2RGB_VNG COLOR_BayerRG2RGB_VNG COLOR_BayerGR2RGB_VNG COLOR_BayerBG2BGR_EA COLOR_BayerGB2BGR_EA COLOR_BayerRG2BGR_EA COLOR_BayerGR2BGR_EA COLOR_BayerBG2RGB_EA COLOR_BayerGB2RGB_EA COLOR_BayerRG2RGB_EA COLOR_BayerGR2RGB_EA COLOR_BayerBG2BGRA COLOR_BayerGB2BGRA COLOR_BayerRG2BGRA COLOR_BayerGR2BGRA COLOR_BayerBG2RGBA COLOR_BayerGB2RGBA COLOR_BayerRG2RGBA COLOR_BayerGR2RGBA COLOR_COLORCVT_MAX INTERSECT_NONE INTERSECT_PARTIAL INTERSECT_FULL FILLED LINE_4 LINE_8 LINE_AA FONT_HERSHEY_SIMPLEX FONT_HERSHEY_PLAIN FONT_HERSHEY_DUPLEX FONT_HERSHEY_COMPLEX FONT_HERSHEY_TRIPLEX FONT_HERSHEY_COMPLEX_SMALL FONT_HERSHEY_SCRIPT_SIMPLEX FONT_HERSHEY_SCRIPT_COMPLEX FONT_ITALIC MARKER_CROSS MARKER_TILTED_CROSS MARKER_STAR MARKER_DIAMOND MARKER_SQUARE MARKER_TRIANGLE_UP MARKER_TRIANGLE_DOWN TM_SQDIFF TM_SQDIFF_NORMED TM_CCORR TM_CCORR_NORMED TM_CCOEFF TM_CCOEFF_NORMED COLORMAP_AUTUMN COLORMAP_BONE COLORMAP_JET COLORMAP_WINTER COLORMAP_RAINBOW COLORMAP_OCEAN COLORMAP_SUMMER COLORMAP_SPRING COLORMAP_COOL COLORMAP_HSV COLORMAP_PINK COLORMAP_HOT COLORMAP_PARULA COLORMAP_MAGMA COLORMAP_INFERNO COLORMAP_PLASMA COLORMAP_VIRIDIS COLORMAP_CIVIDIS COLORMAP_TWILIGHT COLORMAP_TWILIGHT_SHIFTED COLORMAP_TURBO COLORMAP_DEEPGREEN );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::OpenCV::Imgproc ;






#line 364 "../genpp.pl"

=head1 NAME

PDL::OpenCV::Imgproc - PDL bindings for OpenCV CLAHE, GeneralizedHough, GeneralizedHoughBallard, GeneralizedHoughGuil, LineSegmentDetector, Subdiv2D

=head1 SYNOPSIS

 use PDL::OpenCV::Imgproc;

=cut

use strict;
use warnings;
use PDL::OpenCV; # get constants
#line 40 "Imgproc.pm"






=head1 FUNCTIONS

=cut




#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 getGaussianKernel

=for sig

  Signature: (int [phys] ksize(); double [phys] sigma(); int [phys] ktype(); [o,phys] res(l4,c4,r4))

=for ref

Returns Gaussian filter coefficients. NO BROADCASTING.

=for example

 $res = getGaussianKernel($ksize,$sigma); # with defaults
 $res = getGaussianKernel($ksize,$sigma,$ktype);

The function computes and returns the C<<< \texttt{ksize} \times 1 >>>matrix of Gaussian filter
coefficients:
\f[G_i= \alpha *e^{-(i-( \texttt{ksize} -1)/2)^2/(2* \texttt{sigma}^2)},\f]
where C<<< i=0..\texttt{ksize}-1 >>>and C<<< \alpha >>>is the scale factor chosen so that C<<< \sum_i G_i=1 >>>.
Two of such generated kernels can be passed to sepFilter2D. Those functions automatically recognize
smoothing kernels (a symmetrical kernel with sum of weights equal to 1) and handle them accordingly.
You may also use the higher-level GaussianBlur.
C<<< \texttt{ksize} \mod 2 = 1 >>>) and positive.

Parameters:

=over

=item ksize

Aperture size. It should be odd (

=item sigma

Gaussian standard deviation. If it is non-positive, it is computed from ksize as
`sigma = 0.3*((ksize-1)*0.5 - 1) + 0.8`.

=item ktype

Type of filter coefficients. It can be CV_32F or CV_64F .

=back

See also:
sepFilter2D, getDerivKernels, getStructuringElement, GaussianBlur


=for bad

getGaussianKernel ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 112 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::getGaussianKernel {
  barf "Usage: PDL::OpenCV::Imgproc::getGaussianKernel(\$ksize,\$sigma,\$ktype)\n" if @_ < 2;
  my ($ksize,$sigma,$ktype) = @_;
  my ($res);
  $ktype = CV_64F() if !defined $ktype;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgproc::_getGaussianKernel_int($ksize,$sigma,$ktype,$res);
  !wantarray ? $res : ($res)
}
#line 127 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*getGaussianKernel = \&PDL::OpenCV::Imgproc::getGaussianKernel;
#line 134 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 getDerivKernels

=for sig

  Signature: ([o,phys] kx(l1,c1,r1); [o,phys] ky(l2,c2,r2); int [phys] dx(); int [phys] dy(); int [phys] ksize(); byte [phys] normalize(); int [phys] ktype())

=for ref

Returns filter coefficients for computing spatial image derivatives. NO BROADCASTING.

=for example

 ($kx,$ky) = getDerivKernels($dx,$dy,$ksize); # with defaults
 ($kx,$ky) = getDerivKernels($dx,$dy,$ksize,$normalize,$ktype);

The function computes and returns the filter coefficients for spatial image derivatives. When
`ksize=FILTER_SCHARR`, the Scharr C<<< 3 \times 3 >>>kernels are generated (see #Scharr). Otherwise, Sobel
kernels are generated (see #Sobel). The filters are normally passed to #sepFilter2D or to
C<<< =2^{ksize*2-dx-dy-2} >>>. If you are
going to filter floating-point images, you are likely to use the normalized kernels. But if you
compute derivatives of an 8-bit image, store the results in a 16-bit image, and wish to preserve
all the fractional bits, you may want to set normalize=false .

Parameters:

=over

=item kx

Output matrix of row filter coefficients. It has the type ktype .

=item ky

Output matrix of column filter coefficients. It has the type ktype .

=item dx

Derivative order in respect of x.

=item dy

Derivative order in respect of y.

=item ksize

Aperture size. It can be FILTER_SCHARR, 1, 3, 5, or 7.

=item normalize

Flag indicating whether to normalize (scale down) the filter coefficients or not.
Theoretically, the coefficients should have the denominator

=item ktype

Type of filter coefficients. It can be CV_32f or CV_64F .

=back


=for bad

getDerivKernels ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 208 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::getDerivKernels {
  barf "Usage: PDL::OpenCV::Imgproc::getDerivKernels(\$dx,\$dy,\$ksize,\$normalize,\$ktype)\n" if @_ < 3;
  my ($dx,$dy,$ksize,$normalize,$ktype) = @_;
  my ($kx,$ky);
  $kx = PDL->null if !defined $kx;
  $ky = PDL->null if !defined $ky;
  $normalize = 0 if !defined $normalize;
  $ktype = CV_32F() if !defined $ktype;
  PDL::OpenCV::Imgproc::_getDerivKernels_int($kx,$ky,$dx,$dy,$ksize,$normalize,$ktype);
  !wantarray ? $ky : ($kx,$ky)
}
#line 225 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*getDerivKernels = \&PDL::OpenCV::Imgproc::getDerivKernels;
#line 232 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 getGaborKernel

=for sig

  Signature: (indx [phys] ksize(n1=2); double [phys] sigma(); double [phys] theta(); double [phys] lambd(); double [phys] gamma(); double [phys] psi(); int [phys] ktype(); [o,phys] res(l8,c8,r8))

=for ref

Returns Gabor filter coefficients. NO BROADCASTING.

=for example

 $res = getGaborKernel($ksize,$sigma,$theta,$lambd,$gamma); # with defaults
 $res = getGaborKernel($ksize,$sigma,$theta,$lambd,$gamma,$psi,$ktype);

For more details about gabor filter equations and parameters, see: [Gabor
Filter](http://en.wikipedia.org/wiki/Gabor_filter).

Parameters:

=over

=item ksize

Size of the filter returned.

=item sigma

Standard deviation of the gaussian envelope.

=item theta

Orientation of the normal to the parallel stripes of a Gabor function.

=item lambd

Wavelength of the sinusoidal factor.

=item gamma

Spatial aspect ratio.

=item psi

Phase offset.

=item ktype

Type of filter coefficients. It can be CV_32F or CV_64F .

=back


=for bad

getGaborKernel ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 300 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::getGaborKernel {
  barf "Usage: PDL::OpenCV::Imgproc::getGaborKernel(\$ksize,\$sigma,\$theta,\$lambd,\$gamma,\$psi,\$ktype)\n" if @_ < 5;
  my ($ksize,$sigma,$theta,$lambd,$gamma,$psi,$ktype) = @_;
  my ($res);
  $psi = CV_PI()*0.5 if !defined $psi;
  $ktype = CV_64F() if !defined $ktype;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgproc::_getGaborKernel_int($ksize,$sigma,$theta,$lambd,$gamma,$psi,$ktype,$res);
  !wantarray ? $res : ($res)
}
#line 316 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*getGaborKernel = \&PDL::OpenCV::Imgproc::getGaborKernel;
#line 323 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 getStructuringElement

=for sig

  Signature: (int [phys] shape(); indx [phys] ksize(n2=2); indx [phys] anchor(n3=2); [o,phys] res(l4,c4,r4))

=for ref

Returns a structuring element of the specified size and shape for morphological operations. NO BROADCASTING.

=for example

 $res = getStructuringElement($shape,$ksize); # with defaults
 $res = getStructuringElement($shape,$ksize,$anchor);

The function constructs and returns the structuring element that can be further passed to #erode,
#dilate or #morphologyEx. But you can also construct an arbitrary binary mask yourself and use it as
the structuring element.
C<<< (-1, -1) >>>means that the
anchor is at the center. Note that only the shape of a cross-shaped element depends on the anchor
position. In other cases the anchor just regulates how much the result of the morphological
operation is shifted.

Parameters:

=over

=item shape

Element shape that could be one of #MorphShapes

=item ksize

Size of the structuring element.

=item anchor

Anchor position within the element. The default value

=back


=for bad

getStructuringElement ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 380 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::getStructuringElement {
  barf "Usage: PDL::OpenCV::Imgproc::getStructuringElement(\$shape,\$ksize,\$anchor)\n" if @_ < 2;
  my ($shape,$ksize,$anchor) = @_;
  my ($res);
  $anchor = indx(-1,-1) if !defined $anchor;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgproc::_getStructuringElement_int($shape,$ksize,$anchor,$res);
  !wantarray ? $res : ($res)
}
#line 395 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*getStructuringElement = \&PDL::OpenCV::Imgproc::getStructuringElement;
#line 402 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 medianBlur

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] ksize())

=for ref

Blurs an image using the median filter. NO BROADCASTING.

=for example

 $dst = medianBlur($src,$ksize);

The function smoothes an image using the median filter with the C<<< \texttt{ksize} \times
\texttt{ksize} >>>aperture. Each channel of a multi-channel image is processed independently.
In-place operation is supported.
@note The median filter uses #BORDER_REPLICATE internally to cope with border pixels, see #BorderTypes

Parameters:

=over

=item src

input 1-, 3-, or 4-channel image; when ksize is 3 or 5, the image depth should be
CV_8U, CV_16U, or CV_32F, for larger aperture sizes, it can only be CV_8U.

=item dst

destination array of the same size and type as src.

=item ksize

aperture linear size; it must be odd and greater than 1, for example: 3, 5, 7 ...

=back

See also:
bilateralFilter, blur, boxFilter, GaussianBlur


=for bad

medianBlur ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 459 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::medianBlur {
  barf "Usage: PDL::OpenCV::Imgproc::medianBlur(\$src,\$ksize)\n" if @_ < 2;
  my ($src,$ksize) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::Imgproc::_medianBlur_int($src,$dst,$ksize);
  !wantarray ? $dst : ($dst)
}
#line 473 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*medianBlur = \&PDL::OpenCV::Imgproc::medianBlur;
#line 480 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 GaussianBlur

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); indx [phys] ksize(n3=2); double [phys] sigmaX(); double [phys] sigmaY(); int [phys] borderType())

=for ref

Blurs an image using a Gaussian filter. NO BROADCASTING.

=for example

 $dst = GaussianBlur($src,$ksize,$sigmaX); # with defaults
 $dst = GaussianBlur($src,$ksize,$sigmaX,$sigmaY,$borderType);

The function convolves the source image with the specified Gaussian kernel. In-place filtering is
supported.

Parameters:

=over

=item src

input image; the image can have any number of channels, which are processed
independently, but the depth should be CV_8U, CV_16U, CV_16S, CV_32F or CV_64F.

=item dst

output image of the same size and type as src.

=item ksize

Gaussian kernel size. ksize.width and ksize.height can differ but they both must be
positive and odd. Or, they can be zero's and then they are computed from sigma.

=item sigmaX

Gaussian kernel standard deviation in X direction.

=item sigmaY

Gaussian kernel standard deviation in Y direction; if sigmaY is zero, it is set to be
equal to sigmaX, if both sigmas are zeros, they are computed from ksize.width and ksize.height,
respectively (see #getGaussianKernel for details); to fully control the result regardless of
possible future modifications of all this semantics, it is recommended to specify all of ksize,
sigmaX, and sigmaY.

=item borderType

pixel extrapolation method, see #BorderTypes. #BORDER_WRAP is not supported.

=back

See also:
sepFilter2D, filter2D, blur, boxFilter, bilateralFilter, medianBlur


=for bad

GaussianBlur ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 553 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::GaussianBlur {
  barf "Usage: PDL::OpenCV::Imgproc::GaussianBlur(\$src,\$ksize,\$sigmaX,\$sigmaY,\$borderType)\n" if @_ < 3;
  my ($src,$ksize,$sigmaX,$sigmaY,$borderType) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $sigmaY = 0 if !defined $sigmaY;
  $borderType = BORDER_DEFAULT() if !defined $borderType;
  PDL::OpenCV::Imgproc::_GaussianBlur_int($src,$dst,$ksize,$sigmaX,$sigmaY,$borderType);
  !wantarray ? $dst : ($dst)
}
#line 569 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*GaussianBlur = \&PDL::OpenCV::Imgproc::GaussianBlur;
#line 576 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 bilateralFilter

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] d(); double [phys] sigmaColor(); double [phys] sigmaSpace(); int [phys] borderType())

=for ref

Applies the bilateral filter to an image. NO BROADCASTING.

=for example

 $dst = bilateralFilter($src,$d,$sigmaColor,$sigmaSpace); # with defaults
 $dst = bilateralFilter($src,$d,$sigmaColor,$sigmaSpace,$borderType);

The function applies bilateral filtering to the input image, as described in
http://www.dai.ed.ac.uk/CVonline/LOCAL_COPIES/MANDUCHI1/Bilateral_Filtering.html
bilateralFilter can reduce unwanted noise very well while keeping edges fairly sharp. However, it is
very slow compared to most filters.
_Sigma values_: For simplicity, you can set the 2 sigma values to be the same. If they are small (\<
10), the filter will not have much effect, whereas if they are large (\> 150), they will have a very
strong effect, making the image look "cartoonish".
_Filter size_: Large filters (d \> 5) are very slow, so it is recommended to use d=5 for real-time
applications, and perhaps d=9 for offline applications that need heavy noise filtering.
This filter does not work inplace.
\>0, it specifies the neighborhood size regardless of sigmaSpace. Otherwise, d is
proportional to sigmaSpace.

Parameters:

=over

=item src

Source 8-bit or floating-point, 1-channel or 3-channel image.

=item dst

Destination image of the same size and type as src .

=item d

Diameter of each pixel neighborhood that is used during filtering. If it is non-positive,
it is computed from sigmaSpace.

=item sigmaColor

Filter sigma in the color space. A larger value of the parameter means that
farther colors within the pixel neighborhood (see sigmaSpace) will be mixed together, resulting
in larger areas of semi-equal color.

=item sigmaSpace

Filter sigma in the coordinate space. A larger value of the parameter means that
farther pixels will influence each other as long as their colors are close enough (see sigmaColor
). When d

=item borderType

border mode used to extrapolate pixels outside of the image, see #BorderTypes

=back


=for bad

bilateralFilter ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 655 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::bilateralFilter {
  barf "Usage: PDL::OpenCV::Imgproc::bilateralFilter(\$src,\$d,\$sigmaColor,\$sigmaSpace,\$borderType)\n" if @_ < 4;
  my ($src,$d,$sigmaColor,$sigmaSpace,$borderType) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $borderType = BORDER_DEFAULT() if !defined $borderType;
  PDL::OpenCV::Imgproc::_bilateralFilter_int($src,$dst,$d,$sigmaColor,$sigmaSpace,$borderType);
  !wantarray ? $dst : ($dst)
}
#line 670 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*bilateralFilter = \&PDL::OpenCV::Imgproc::bilateralFilter;
#line 677 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 boxFilter

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] ddepth(); indx [phys] ksize(n4=2); indx [phys] anchor(n5=2); byte [phys] normalize(); int [phys] borderType())

=for ref

Blurs an image using the box filter. NO BROADCASTING.

=for example

 $dst = boxFilter($src,$ddepth,$ksize); # with defaults
 $dst = boxFilter($src,$ddepth,$ksize,$anchor,$normalize,$borderType);

The function smooths an image using the kernel:
\f[\texttt{K} =  \alpha \begin{bmatrix} 1 & 1 & 1 &  \cdots & 1 & 1  \\ 1 & 1 & 1 &  \cdots & 1 & 1  \\ \hdotsfor{6} \\ 1 & 1 & 1 &  \cdots & 1 & 1 \end{bmatrix}\f]
where
\f[\alpha = \begin{cases} \frac{1}{\texttt{ksize.width*ksize.height}} & \texttt{when } \texttt{normalize=true}  \\1 & \texttt{otherwise}\end{cases}\f]
Unnormalized box filter is useful for computing various integral characteristics over each pixel
neighborhood, such as covariance matrices of image derivatives (used in dense optical flow
algorithms, and so on). If you need to compute pixel sums over variable-size windows, use #integral.

Parameters:

=over

=item src

input image.

=item dst

output image of the same size and type as src.

=item ddepth

the output image depth (-1 to use src.depth()).

=item ksize

blurring kernel size.

=item anchor

anchor point; default value Point(-1,-1) means that the anchor is at the kernel
center.

=item normalize

flag, specifying whether the kernel is normalized by its area or not.

=item borderType

border mode used to extrapolate pixels outside of the image, see #BorderTypes. #BORDER_WRAP is not supported.

=back

See also:
blur, bilateralFilter, GaussianBlur, medianBlur, integral


=for bad

boxFilter ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 754 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::boxFilter {
  barf "Usage: PDL::OpenCV::Imgproc::boxFilter(\$src,\$ddepth,\$ksize,\$anchor,\$normalize,\$borderType)\n" if @_ < 3;
  my ($src,$ddepth,$ksize,$anchor,$normalize,$borderType) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $anchor = indx(-1,-1) if !defined $anchor;
  $normalize = 1 if !defined $normalize;
  $borderType = BORDER_DEFAULT() if !defined $borderType;
  PDL::OpenCV::Imgproc::_boxFilter_int($src,$dst,$ddepth,$ksize,$anchor,$normalize,$borderType);
  !wantarray ? $dst : ($dst)
}
#line 771 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*boxFilter = \&PDL::OpenCV::Imgproc::boxFilter;
#line 778 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 sqrBoxFilter

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] ddepth(); indx [phys] ksize(n4=2); indx [phys] anchor(n5=2); byte [phys] normalize(); int [phys] borderType())

=for ref

Calculates the normalized sum of squares of the pixel values overlapping the filter. NO BROADCASTING.

=for example

 $dst = sqrBoxFilter($src,$ddepth,$ksize); # with defaults
 $dst = sqrBoxFilter($src,$ddepth,$ksize,$anchor,$normalize,$borderType);

For every pixel C<<<  (x, y)  >>>in the source image, the function calculates the sum of squares of those neighboring
pixel values which overlap the filter placed over the pixel C<<<  (x, y)  >>>.
The unnormalized square box filter can be useful in computing local image statistics such as the the local
variance and standard deviation around the neighborhood of a pixel.

Parameters:

=over

=item src

input image

=item dst

output image of the same size and type as src

=item ddepth

the output image depth (-1 to use src.depth())

=item ksize

kernel size

=item anchor

kernel anchor point. The default value of Point(-1, -1) denotes that the anchor is at the kernel
center.

=item normalize

flag, specifying whether the kernel is to be normalized by it's area or not.

=item borderType

border mode used to extrapolate pixels outside of the image, see #BorderTypes. #BORDER_WRAP is not supported.

=back

See also:
boxFilter


=for bad

sqrBoxFilter ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 852 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::sqrBoxFilter {
  barf "Usage: PDL::OpenCV::Imgproc::sqrBoxFilter(\$src,\$ddepth,\$ksize,\$anchor,\$normalize,\$borderType)\n" if @_ < 3;
  my ($src,$ddepth,$ksize,$anchor,$normalize,$borderType) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $anchor = indx(-1, -1) if !defined $anchor;
  $normalize = 1 if !defined $normalize;
  $borderType = BORDER_DEFAULT() if !defined $borderType;
  PDL::OpenCV::Imgproc::_sqrBoxFilter_int($src,$dst,$ddepth,$ksize,$anchor,$normalize,$borderType);
  !wantarray ? $dst : ($dst)
}
#line 869 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*sqrBoxFilter = \&PDL::OpenCV::Imgproc::sqrBoxFilter;
#line 876 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 blur

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); indx [phys] ksize(n3=2); indx [phys] anchor(n4=2); int [phys] borderType())

=for ref

Blurs an image using the normalized box filter. NO BROADCASTING.

=for example

 $dst = blur($src,$ksize); # with defaults
 $dst = blur($src,$ksize,$anchor,$borderType);

The function smooths an image using the kernel:
\f[\texttt{K} =  \frac{1}{\texttt{ksize.width*ksize.height}} \begin{bmatrix} 1 & 1 & 1 &  \cdots & 1 & 1  \\ 1 & 1 & 1 &  \cdots & 1 & 1  \\ \hdotsfor{6} \\ 1 & 1 & 1 &  \cdots & 1 & 1  \\ \end{bmatrix}\f]
The call `blur(src, dst, ksize, anchor, borderType)` is equivalent to `boxFilter(src, dst, src.type(), ksize,
anchor, true, borderType)`.

Parameters:

=over

=item src

input image; it can have any number of channels, which are processed independently, but
the depth should be CV_8U, CV_16U, CV_16S, CV_32F or CV_64F.

=item dst

output image of the same size and type as src.

=item ksize

blurring kernel size.

=item anchor

anchor point; default value Point(-1,-1) means that the anchor is at the kernel
center.

=item borderType

border mode used to extrapolate pixels outside of the image, see #BorderTypes. #BORDER_WRAP is not supported.

=back

See also:
boxFilter, bilateralFilter, GaussianBlur, medianBlur


=for bad

blur ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 943 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::blur {
  barf "Usage: PDL::OpenCV::Imgproc::blur(\$src,\$ksize,\$anchor,\$borderType)\n" if @_ < 2;
  my ($src,$ksize,$anchor,$borderType) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $anchor = indx(-1,-1) if !defined $anchor;
  $borderType = BORDER_DEFAULT() if !defined $borderType;
  PDL::OpenCV::Imgproc::_blur_int($src,$dst,$ksize,$anchor,$borderType);
  !wantarray ? $dst : ($dst)
}
#line 959 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*blur = \&PDL::OpenCV::Imgproc::blur;
#line 966 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 filter2D

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] ddepth(); [phys] kernel(l4,c4,r4); indx [phys] anchor(n5=2); double [phys] delta(); int [phys] borderType())

=for ref

Convolves an image with the kernel. NO BROADCASTING.

=for example

 $dst = filter2D($src,$ddepth,$kernel); # with defaults
 $dst = filter2D($src,$ddepth,$kernel,$anchor,$delta,$borderType);

The function applies an arbitrary linear filter to an image. In-place operation is supported. When
the aperture is partially outside the image, the function interpolates outlier pixel values
according to the specified border mode.
The function does actually compute correlation, not the convolution:
\f[\texttt{dst} (x,y) =  \sum _{ \substack{0\leq x' < \texttt{kernel.cols}\\{0\leq y' < \texttt{kernel.rows}}}}  \texttt{kernel} (x',y')* \texttt{src} (x+x'- \texttt{anchor.x} ,y+y'- \texttt{anchor.y} )\f]
That is, the kernel is not mirrored around the anchor point. If you need a real convolution, flip
the kernel using #flip and set the new anchor to `(kernel.cols - anchor.x - 1, kernel.rows -
anchor.y - 1)`.
The function uses the DFT-based algorithm in case of sufficiently large kernels (~`11 x 11` or
larger) and the direct algorithm for small kernels.
@ref filter_depths "combinations"

Parameters:

=over

=item src

input image.

=item dst

output image of the same size and the same number of channels as src.

=item ddepth

desired depth of the destination image, see

=item kernel

convolution kernel (or rather a correlation kernel), a single-channel floating point
matrix; if you want to apply different kernels to different channels, split the image into
separate color planes using split and process them individually.

=item anchor

anchor of the kernel that indicates the relative position of a filtered point within
the kernel; the anchor should lie within the kernel; default value (-1,-1) means that the anchor
is at the kernel center.

=item delta

optional value added to the filtered pixels before storing them in dst.

=item borderType

pixel extrapolation method, see #BorderTypes. #BORDER_WRAP is not supported.

=back

See also:
sepFilter2D, dft, matchTemplate


=for bad

filter2D ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1050 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::filter2D {
  barf "Usage: PDL::OpenCV::Imgproc::filter2D(\$src,\$ddepth,\$kernel,\$anchor,\$delta,\$borderType)\n" if @_ < 3;
  my ($src,$ddepth,$kernel,$anchor,$delta,$borderType) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $anchor = indx(-1,-1) if !defined $anchor;
  $delta = 0 if !defined $delta;
  $borderType = BORDER_DEFAULT() if !defined $borderType;
  PDL::OpenCV::Imgproc::_filter2D_int($src,$dst,$ddepth,$kernel,$anchor,$delta,$borderType);
  !wantarray ? $dst : ($dst)
}
#line 1067 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*filter2D = \&PDL::OpenCV::Imgproc::filter2D;
#line 1074 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 sepFilter2D

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] ddepth(); [phys] kernelX(l4,c4,r4); [phys] kernelY(l5,c5,r5); indx [phys] anchor(n6=2); double [phys] delta(); int [phys] borderType())

=for ref

Applies a separable linear filter to an image. NO BROADCASTING.

=for example

 $dst = sepFilter2D($src,$ddepth,$kernelX,$kernelY); # with defaults
 $dst = sepFilter2D($src,$ddepth,$kernelX,$kernelY,$anchor,$delta,$borderType);

The function applies a separable linear filter to the image. That is, first, every row of src is
filtered with the 1D kernel kernelX. Then, every column of the result is filtered with the 1D
kernel kernelY. The final result shifted by delta is stored in dst .
@ref filter_depths "combinations"
C<<< (-1,-1) >>>means that the anchor
is at the kernel center.

Parameters:

=over

=item src

Source image.

=item dst

Destination image of the same size and the same number of channels as src .

=item ddepth

Destination image depth, see

=item kernelX

Coefficients for filtering each row.

=item kernelY

Coefficients for filtering each column.

=item anchor

Anchor position within the kernel. The default value

=item delta

Value added to the filtered results before storing them.

=item borderType

Pixel extrapolation method, see #BorderTypes. #BORDER_WRAP is not supported.

=back

See also:
filter2D, Sobel, GaussianBlur, boxFilter, blur


=for bad

sepFilter2D ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1153 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::sepFilter2D {
  barf "Usage: PDL::OpenCV::Imgproc::sepFilter2D(\$src,\$ddepth,\$kernelX,\$kernelY,\$anchor,\$delta,\$borderType)\n" if @_ < 4;
  my ($src,$ddepth,$kernelX,$kernelY,$anchor,$delta,$borderType) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $anchor = indx(-1,-1) if !defined $anchor;
  $delta = 0 if !defined $delta;
  $borderType = BORDER_DEFAULT() if !defined $borderType;
  PDL::OpenCV::Imgproc::_sepFilter2D_int($src,$dst,$ddepth,$kernelX,$kernelY,$anchor,$delta,$borderType);
  !wantarray ? $dst : ($dst)
}
#line 1170 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*sepFilter2D = \&PDL::OpenCV::Imgproc::sepFilter2D;
#line 1177 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 Sobel

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] ddepth(); int [phys] dx(); int [phys] dy(); int [phys] ksize(); double [phys] scale(); double [phys] delta(); int [phys] borderType())

=for ref

Calculates the first, second, third, or mixed image derivatives using an extended Sobel operator. NO BROADCASTING.

=for example

 $dst = Sobel($src,$ddepth,$dx,$dy); # with defaults
 $dst = Sobel($src,$ddepth,$dx,$dy,$ksize,$scale,$delta,$borderType);

In all cases except one, the C<<< \texttt{ksize} \times \texttt{ksize} >>>separable kernel is used to
calculate the derivative. When C<<< \texttt{ksize = 1} >>>, the C<<< 3 \times 1 >>>or C<<< 1 \times 3 >>>kernel is used (that is, no Gaussian smoothing is done). `ksize = 1` can only be used for the first
or the second x- or y- derivatives.
There is also the special value `ksize = #FILTER_SCHARR (-1)` that corresponds to the C<<< 3\times3 >>>Scharr
filter that may give more accurate results than the C<<< 3\times3 >>>Sobel. The Scharr aperture is
\f[\vecthreethree{-3}{0}{3}{-10}{0}{10}{-3}{0}{3}\f]
for the x-derivative, or transposed for the y-derivative.
The function calculates an image derivative by convolving the image with the appropriate kernel:
\f[\texttt{dst} =  \frac{\partial^{xorder+yorder} \texttt{src}}{\partial x^{xorder} \partial y^{yorder}}\f]
The Sobel operators combine Gaussian smoothing and differentiation, so the result is more or less
resistant to the noise. Most often, the function is called with ( xorder = 1, yorder = 0, ksize = 3)
or ( xorder = 0, yorder = 1, ksize = 3) to calculate the first x- or y- image derivative. The first
case corresponds to a kernel of:
\f[\vecthreethree{-1}{0}{1}{-2}{0}{2}{-1}{0}{1}\f]
The second case corresponds to a kernel of:
\f[\vecthreethree{-1}{-2}{-1}{0}{0}{0}{1}{2}{1}\f]
@ref filter_depths "combinations"; in the case of
8-bit input images it will result in truncated derivatives.

Parameters:

=over

=item src

input image.

=item dst

output image of the same size and the same number of channels as src .

=item ddepth

output image depth, see

=item dx

order of the derivative x.

=item dy

order of the derivative y.

=item ksize

size of the extended Sobel kernel; it must be 1, 3, 5, or 7.

=item scale

optional scale factor for the computed derivative values; by default, no scaling is
applied (see #getDerivKernels for details).

=item delta

optional delta value that is added to the results prior to storing them in dst.

=item borderType

pixel extrapolation method, see #BorderTypes. #BORDER_WRAP is not supported.

=back

See also:
Scharr, Laplacian, sepFilter2D, filter2D, GaussianBlur, cartToPolar


=for bad

Sobel ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1273 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::Sobel {
  barf "Usage: PDL::OpenCV::Imgproc::Sobel(\$src,\$ddepth,\$dx,\$dy,\$ksize,\$scale,\$delta,\$borderType)\n" if @_ < 4;
  my ($src,$ddepth,$dx,$dy,$ksize,$scale,$delta,$borderType) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $ksize = 3 if !defined $ksize;
  $scale = 1 if !defined $scale;
  $delta = 0 if !defined $delta;
  $borderType = BORDER_DEFAULT() if !defined $borderType;
  PDL::OpenCV::Imgproc::_Sobel_int($src,$dst,$ddepth,$dx,$dy,$ksize,$scale,$delta,$borderType);
  !wantarray ? $dst : ($dst)
}
#line 1291 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*Sobel = \&PDL::OpenCV::Imgproc::Sobel;
#line 1298 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 spatialGradient

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dx(l2,c2,r2); [o,phys] dy(l3,c3,r3); int [phys] ksize(); int [phys] borderType())

=for ref

Calculates the first order image derivative in both x and y using a Sobel operator NO BROADCASTING.

=for example

 ($dx,$dy) = spatialGradient($src); # with defaults
 ($dx,$dy) = spatialGradient($src,$ksize,$borderType);

Equivalent to calling:

 Sobel( src, dx, CV_16SC1, 1, 0, 3 );
 Sobel( src, dy, CV_16SC1, 0, 1, 3 );

Parameters:

=over

=item src

input image.

=item dx

output image with first-order derivative in x.

=item dy

output image with first-order derivative in y.

=item ksize

size of Sobel kernel. It must be 3.

=item borderType

pixel extrapolation method, see #BorderTypes.
                  Only #BORDER_DEFAULT=#BORDER_REFLECT_101 and #BORDER_REPLICATE are supported.

=back

See also:
Sobel


=for bad

spatialGradient ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1364 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::spatialGradient {
  barf "Usage: PDL::OpenCV::Imgproc::spatialGradient(\$src,\$ksize,\$borderType)\n" if @_ < 1;
  my ($src,$ksize,$borderType) = @_;
  my ($dx,$dy);
  $dx = PDL->null if !defined $dx;
  $dy = PDL->null if !defined $dy;
  $ksize = 3 if !defined $ksize;
  $borderType = BORDER_DEFAULT() if !defined $borderType;
  PDL::OpenCV::Imgproc::_spatialGradient_int($src,$dx,$dy,$ksize,$borderType);
  !wantarray ? $dy : ($dx,$dy)
}
#line 1381 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*spatialGradient = \&PDL::OpenCV::Imgproc::spatialGradient;
#line 1388 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 Scharr

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] ddepth(); int [phys] dx(); int [phys] dy(); double [phys] scale(); double [phys] delta(); int [phys] borderType())

=for ref

Calculates the first x- or y- image derivative using Scharr operator. NO BROADCASTING.

=for example

 $dst = Scharr($src,$ddepth,$dx,$dy); # with defaults
 $dst = Scharr($src,$ddepth,$dx,$dy,$scale,$delta,$borderType);

The function computes the first x- or y- spatial image derivative using the Scharr operator. The
call
\f[\texttt{Scharr(src, dst, ddepth, dx, dy, scale, delta, borderType)}\f]
is equivalent to
\f[\texttt{Sobel(src, dst, ddepth, dx, dy, FILTER_SCHARR, scale, delta, borderType)} .\f]
@ref filter_depths "combinations"

Parameters:

=over

=item src

input image.

=item dst

output image of the same size and the same number of channels as src.

=item ddepth

output image depth, see

=item dx

order of the derivative x.

=item dy

order of the derivative y.

=item scale

optional scale factor for the computed derivative values; by default, no scaling is
applied (see #getDerivKernels for details).

=item delta

optional delta value that is added to the results prior to storing them in dst.

=item borderType

pixel extrapolation method, see #BorderTypes. #BORDER_WRAP is not supported.

=back

See also:
cartToPolar


=for bad

Scharr ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1468 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::Scharr {
  barf "Usage: PDL::OpenCV::Imgproc::Scharr(\$src,\$ddepth,\$dx,\$dy,\$scale,\$delta,\$borderType)\n" if @_ < 4;
  my ($src,$ddepth,$dx,$dy,$scale,$delta,$borderType) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $scale = 1 if !defined $scale;
  $delta = 0 if !defined $delta;
  $borderType = BORDER_DEFAULT() if !defined $borderType;
  PDL::OpenCV::Imgproc::_Scharr_int($src,$dst,$ddepth,$dx,$dy,$scale,$delta,$borderType);
  !wantarray ? $dst : ($dst)
}
#line 1485 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*Scharr = \&PDL::OpenCV::Imgproc::Scharr;
#line 1492 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 Laplacian

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] ddepth(); int [phys] ksize(); double [phys] scale(); double [phys] delta(); int [phys] borderType())

=for ref

Calculates the Laplacian of an image. NO BROADCASTING.

=for example

 $dst = Laplacian($src,$ddepth); # with defaults
 $dst = Laplacian($src,$ddepth,$ksize,$scale,$delta,$borderType);

The function calculates the Laplacian of the source image by adding up the second x and y
derivatives calculated using the Sobel operator:
\f[\texttt{dst} =  \Delta \texttt{src} =  \frac{\partial^2 \texttt{src}}{\partial x^2} +  \frac{\partial^2 \texttt{src}}{\partial y^2}\f]
This is done when `ksize > 1`. When `ksize == 1`, the Laplacian is computed by filtering the image
with the following C<<< 3 \times 3 >>>aperture:
\f[\vecthreethree {0}{1}{0}{1}{-4}{1}{0}{1}{0}\f]

Parameters:

=over

=item src

Source image.

=item dst

Destination image of the same size and the same number of channels as src .

=item ddepth

Desired depth of the destination image.

=item ksize

Aperture size used to compute the second-derivative filters. See #getDerivKernels for
details. The size must be positive and odd.

=item scale

Optional scale factor for the computed Laplacian values. By default, no scaling is
applied. See #getDerivKernels for details.

=item delta

Optional delta value that is added to the results prior to storing them in dst .

=item borderType

Pixel extrapolation method, see #BorderTypes. #BORDER_WRAP is not supported.

=back

See also:
Sobel, Scharr


=for bad

Laplacian ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1569 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::Laplacian {
  barf "Usage: PDL::OpenCV::Imgproc::Laplacian(\$src,\$ddepth,\$ksize,\$scale,\$delta,\$borderType)\n" if @_ < 2;
  my ($src,$ddepth,$ksize,$scale,$delta,$borderType) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $ksize = 1 if !defined $ksize;
  $scale = 1 if !defined $scale;
  $delta = 0 if !defined $delta;
  $borderType = BORDER_DEFAULT() if !defined $borderType;
  PDL::OpenCV::Imgproc::_Laplacian_int($src,$dst,$ddepth,$ksize,$scale,$delta,$borderType);
  !wantarray ? $dst : ($dst)
}
#line 1587 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*Laplacian = \&PDL::OpenCV::Imgproc::Laplacian;
#line 1594 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 Canny

=for sig

  Signature: ([phys] image(l1,c1,r1); [o,phys] edges(l2,c2,r2); double [phys] threshold1(); double [phys] threshold2(); int [phys] apertureSize(); byte [phys] L2gradient())

=for ref

Finds edges in an image using the Canny algorithm  NO BROADCASTING.

=for example

 $edges = Canny($image,$threshold1,$threshold2); # with defaults
 $edges = Canny($image,$threshold1,$threshold2,$apertureSize,$L2gradient);

@cite Canny86 .
The function finds edges in the input image and marks them in the output map edges using the
Canny algorithm. The smallest value between threshold1 and threshold2 is used for edge linking. The
largest value is used to find initial segments of strong edges. See
<http://en.wikipedia.org/wiki/Canny_edge_detector>
C<<< L_2 >>>norm
C<<< =\sqrt{(dI/dx)^2 + (dI/dy)^2} >>>should be used to calculate the image gradient magnitude (
L2gradient=true ), or whether the default C<<< L_1 >>>norm C<<< =|dI/dx|+|dI/dy| >>>is enough (
L2gradient=false ).

Parameters:

=over

=item image

8-bit input image.

=item edges

output edge map; single channels 8-bit image, which has the same size as image .

=item threshold1

first threshold for the hysteresis procedure.

=item threshold2

second threshold for the hysteresis procedure.

=item apertureSize

aperture size for the Sobel operator.

=item L2gradient

a flag, indicating whether a more accurate

=back


=for bad

Canny ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1665 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::Canny {
  barf "Usage: PDL::OpenCV::Imgproc::Canny(\$image,\$threshold1,\$threshold2,\$apertureSize,\$L2gradient)\n" if @_ < 3;
  my ($image,$threshold1,$threshold2,$apertureSize,$L2gradient) = @_;
  my ($edges);
  $edges = PDL->null if !defined $edges;
  $apertureSize = 3 if !defined $apertureSize;
  $L2gradient = 0 if !defined $L2gradient;
  PDL::OpenCV::Imgproc::_Canny_int($image,$edges,$threshold1,$threshold2,$apertureSize,$L2gradient);
  !wantarray ? $edges : ($edges)
}
#line 1681 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*Canny = \&PDL::OpenCV::Imgproc::Canny;
#line 1688 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 Canny2

=for sig

  Signature: ([phys] dx(l1,c1,r1); [phys] dy(l2,c2,r2); [o,phys] edges(l3,c3,r3); double [phys] threshold1(); double [phys] threshold2(); byte [phys] L2gradient())

=for ref

 NO BROADCASTING.

=for example

 $edges = Canny2($dx,$dy,$threshold1,$threshold2); # with defaults
 $edges = Canny2($dx,$dy,$threshold1,$threshold2,$L2gradient);

\overload
Finds edges in an image using the Canny algorithm with custom image gradient.
C<<< L_2 >>>norm
C<<< =\sqrt{(dI/dx)^2 + (dI/dy)^2} >>>should be used to calculate the image gradient magnitude (
L2gradient=true ), or whether the default C<<< L_1 >>>norm C<<< =|dI/dx|+|dI/dy| >>>is enough (
L2gradient=false ).

Parameters:

=over

=item dx

16-bit x derivative of input image (CV_16SC1 or CV_16SC3).

=item dy

16-bit y derivative of input image (same type as dx).

=item edges

output edge map; single channels 8-bit image, which has the same size as image .

=item threshold1

first threshold for the hysteresis procedure.

=item threshold2

second threshold for the hysteresis procedure.

=item L2gradient

a flag, indicating whether a more accurate

=back


=for bad

Canny2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1756 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::Canny2 {
  barf "Usage: PDL::OpenCV::Imgproc::Canny2(\$dx,\$dy,\$threshold1,\$threshold2,\$L2gradient)\n" if @_ < 4;
  my ($dx,$dy,$threshold1,$threshold2,$L2gradient) = @_;
  my ($edges);
  $edges = PDL->null if !defined $edges;
  $L2gradient = 0 if !defined $L2gradient;
  PDL::OpenCV::Imgproc::_Canny2_int($dx,$dy,$edges,$threshold1,$threshold2,$L2gradient);
  !wantarray ? $edges : ($edges)
}
#line 1771 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*Canny2 = \&PDL::OpenCV::Imgproc::Canny2;
#line 1778 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 cornerMinEigenVal

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] blockSize(); int [phys] ksize(); int [phys] borderType())

=for ref

Calculates the minimal eigenvalue of gradient matrices for corner detection. NO BROADCASTING.

=for example

 $dst = cornerMinEigenVal($src,$blockSize); # with defaults
 $dst = cornerMinEigenVal($src,$blockSize,$ksize,$borderType);

The function is similar to cornerEigenValsAndVecs but it calculates and stores only the minimal
eigenvalue of the covariance matrix of derivatives, that is, C<<< \min(\lambda_1, \lambda_2) >>>in terms
of the formulae in the cornerEigenValsAndVecs description.

Parameters:

=over

=item src

Input single-channel 8-bit or floating-point image.

=item dst

Image to store the minimal eigenvalues. It has the type CV_32FC1 and the same size as
src .

=item blockSize

Neighborhood size (see the details on #cornerEigenValsAndVecs ).

=item ksize

Aperture parameter for the Sobel operator.

=item borderType

Pixel extrapolation method. See #BorderTypes. #BORDER_WRAP is not supported.

=back


=for bad

cornerMinEigenVal ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1840 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::cornerMinEigenVal {
  barf "Usage: PDL::OpenCV::Imgproc::cornerMinEigenVal(\$src,\$blockSize,\$ksize,\$borderType)\n" if @_ < 2;
  my ($src,$blockSize,$ksize,$borderType) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $ksize = 3 if !defined $ksize;
  $borderType = BORDER_DEFAULT() if !defined $borderType;
  PDL::OpenCV::Imgproc::_cornerMinEigenVal_int($src,$dst,$blockSize,$ksize,$borderType);
  !wantarray ? $dst : ($dst)
}
#line 1856 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*cornerMinEigenVal = \&PDL::OpenCV::Imgproc::cornerMinEigenVal;
#line 1863 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 cornerHarris

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] blockSize(); int [phys] ksize(); double [phys] k(); int [phys] borderType())

=for ref

Harris corner detector. NO BROADCASTING.

=for example

 $dst = cornerHarris($src,$blockSize,$ksize,$k); # with defaults
 $dst = cornerHarris($src,$blockSize,$ksize,$k,$borderType);

The function runs the Harris corner detector on the image. Similarly to cornerMinEigenVal and
cornerEigenValsAndVecs , for each pixel C<<< (x, y) >>>it calculates a C<<< 2\times2 >>>gradient covariance
matrix C<<< M^{(x,y)} >>>over a C<<< \texttt{blockSize} \times \texttt{blockSize} >>>neighborhood. Then, it
computes the following characteristic:
\f[\texttt{dst} (x,y) =  \mathrm{det} M^{(x,y)} - k  \cdot \left ( \mathrm{tr} M^{(x,y)} \right )^2\f]
Corners in the image can be found as the local maxima of this response map.

Parameters:

=over

=item src

Input single-channel 8-bit or floating-point image.

=item dst

Image to store the Harris detector responses. It has the type CV_32FC1 and the same
size as src .

=item blockSize

Neighborhood size (see the details on #cornerEigenValsAndVecs ).

=item ksize

Aperture parameter for the Sobel operator.

=item k

Harris detector free parameter. See the formula above.

=item borderType

Pixel extrapolation method. See #BorderTypes. #BORDER_WRAP is not supported.

=back


=for bad

cornerHarris ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1932 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::cornerHarris {
  barf "Usage: PDL::OpenCV::Imgproc::cornerHarris(\$src,\$blockSize,\$ksize,\$k,\$borderType)\n" if @_ < 4;
  my ($src,$blockSize,$ksize,$k,$borderType) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $borderType = BORDER_DEFAULT() if !defined $borderType;
  PDL::OpenCV::Imgproc::_cornerHarris_int($src,$dst,$blockSize,$ksize,$k,$borderType);
  !wantarray ? $dst : ($dst)
}
#line 1947 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*cornerHarris = \&PDL::OpenCV::Imgproc::cornerHarris;
#line 1954 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 cornerEigenValsAndVecs

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] blockSize(); int [phys] ksize(); int [phys] borderType())

=for ref

Calculates eigenvalues and eigenvectors of image blocks for corner detection. NO BROADCASTING.

=for example

 $dst = cornerEigenValsAndVecs($src,$blockSize,$ksize); # with defaults
 $dst = cornerEigenValsAndVecs($src,$blockSize,$ksize,$borderType);

For every pixel C<<< p >>>, the function cornerEigenValsAndVecs considers a blockSize C<<< \times >>>blockSize
neighborhood C<<< S(p) >>>. It calculates the covariation matrix of derivatives over the neighborhood as:
\f[M =  \begin{bmatrix} \sum _{S(p)}(dI/dx)^2 &  \sum _{S(p)}dI/dx dI/dy  \\ \sum _{S(p)}dI/dx dI/dy &  \sum _{S(p)}(dI/dy)^2 \end{bmatrix}\f]
where the derivatives are computed using the Sobel operator.
After that, it finds eigenvectors and eigenvalues of C<<< M >>>and stores them in the destination image as
C<<< (\lambda_1, \lambda_2, x_1, y_1, x_2, y_2) >>>where
-   C<<< \lambda_1, \lambda_2 >>>are the non-sorted eigenvalues of C<<< M >>>-   C<<< x_1, y_1 >>>are the eigenvectors corresponding to C<<< \lambda_1 >>>-   C<<< x_2, y_2 >>>are the eigenvectors corresponding to C<<< \lambda_2 >>>The output of the function can be used for robust edge or corner detection.

Parameters:

=over

=item src

Input single-channel 8-bit or floating-point image.

=item dst

Image to store the results. It has the same size as src and the type CV_32FC(6) .

=item blockSize

Neighborhood size (see details below).

=item ksize

Aperture parameter for the Sobel operator.

=item borderType

Pixel extrapolation method. See #BorderTypes. #BORDER_WRAP is not supported.

=back

See also:
cornerMinEigenVal, cornerHarris, preCornerDetect


=for bad

cornerEigenValsAndVecs ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2022 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::cornerEigenValsAndVecs {
  barf "Usage: PDL::OpenCV::Imgproc::cornerEigenValsAndVecs(\$src,\$blockSize,\$ksize,\$borderType)\n" if @_ < 3;
  my ($src,$blockSize,$ksize,$borderType) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $borderType = BORDER_DEFAULT() if !defined $borderType;
  PDL::OpenCV::Imgproc::_cornerEigenValsAndVecs_int($src,$dst,$blockSize,$ksize,$borderType);
  !wantarray ? $dst : ($dst)
}
#line 2037 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*cornerEigenValsAndVecs = \&PDL::OpenCV::Imgproc::cornerEigenValsAndVecs;
#line 2044 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 preCornerDetect

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] ksize(); int [phys] borderType())

=for ref

Calculates a feature map for corner detection. NO BROADCASTING.

=for example

 $dst = preCornerDetect($src,$ksize); # with defaults
 $dst = preCornerDetect($src,$ksize,$borderType);

The function calculates the complex spatial derivative-based function of the source image
\f[\texttt{dst} = (D_x  \texttt{src} )^2  \cdot D_{yy}  \texttt{src} + (D_y  \texttt{src} )^2  \cdot D_{xx}  \texttt{src} - 2 D_x  \texttt{src} \cdot D_y  \texttt{src} \cdot D_{xy}  \texttt{src}\f]
where C<<< D_x >>>,C<<< D_y >>>are the first image derivatives, C<<< D_{xx} >>>,C<<< D_{yy} >>>are the second image
derivatives, and C<<< D_{xy} >>>is the mixed derivative.
The corners can be found as local maximums of the functions, as shown below:

     Mat corners, dilated_corners;
     preCornerDetect(image, corners, 3);
     // dilation with 3x3 rectangular structuring element
     dilate(corners, dilated_corners, Mat(), 1);
     Mat corner_mask = corners == dilated_corners;

Parameters:

=over

=item src

Source single-channel 8-bit of floating-point image.

=item dst

Output image that has the type CV_32F and the same size as src .

=item ksize

%Aperture size of the Sobel .

=item borderType

Pixel extrapolation method. See #BorderTypes. #BORDER_WRAP is not supported.

=back


=for bad

preCornerDetect ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2109 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::preCornerDetect {
  barf "Usage: PDL::OpenCV::Imgproc::preCornerDetect(\$src,\$ksize,\$borderType)\n" if @_ < 2;
  my ($src,$ksize,$borderType) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $borderType = BORDER_DEFAULT() if !defined $borderType;
  PDL::OpenCV::Imgproc::_preCornerDetect_int($src,$dst,$ksize,$borderType);
  !wantarray ? $dst : ($dst)
}
#line 2124 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*preCornerDetect = \&PDL::OpenCV::Imgproc::preCornerDetect;
#line 2131 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 cornerSubPix

=for sig

  Signature: ([phys] image(l1,c1,r1); [io,phys] corners(l2,c2,r2); indx [phys] winSize(n3=2); indx [phys] zeroZone(n4=2); TermCriteriaWrapper * criteria)

=for ref

Refines the corner locations.

=for example

 cornerSubPix($image,$corners,$winSize,$zeroZone,$criteria);

The function iterates to find the sub-pixel accurate location of corners or radial saddle
points as described in @cite forstner1987fast, and as shown on the figure below.
![image](pics/cornersubpix.png)
Sub-pixel accurate corner locator is based on the observation that every vector from the center C<<< q >>>to a point C<<< p >>>located within a neighborhood of C<<< q >>>is orthogonal to the image gradient at C<<< p >>>subject to image and measurement noise. Consider the expression:
\f[\epsilon _i = {DI_{p_i}}^T  \cdot (q - p_i)\f]
where C<<< {DI_{p_i}} >>>is an image gradient at one of the points C<<< p_i >>>in a neighborhood of C<<< q >>>. The
value of C<<< q >>>is to be found so that C<<< \epsilon_i >>>is minimized. A system of equations may be set up
with C<<< \epsilon_i >>>set to zero:
\f[\sum _i(DI_{p_i}  \cdot {DI_{p_i}}^T) \cdot q -  \sum _i(DI_{p_i}  \cdot {DI_{p_i}}^T  \cdot p_i)\f]
where the gradients are summed within a neighborhood ("search window") of C<<< q >>>. Calling the first
gradient term C<<< G >>>and the second gradient term C<<< b >>>gives:
\f[q = G^{-1}  \cdot b\f]
The algorithm sets the center of the neighborhood window at this new center C<<< q >>>and then iterates
until the center stays within a set threshold.
C<<< (5*2+1) \times (5*2+1) = 11 \times 11 >>>search window is used.

Parameters:

=over

=item image

Input single-channel, 8-bit or float image.

=item corners

Initial coordinates of the input corners and refined coordinates provided for
output.

=item winSize

Half of the side length of the search window. For example, if winSize=Size(5,5) ,
then a

=item zeroZone

Half of the size of the dead region in the middle of the search zone over which
the summation in the formula below is not done. It is used sometimes to avoid possible
singularities of the autocorrelation matrix. The value of (-1,-1) indicates that there is no such
a size.

=item criteria

Criteria for termination of the iterative process of corner refinement. That is,
the process of corner position refinement stops either after criteria.maxCount iterations or when
the corner position moves by less than criteria.epsilon on some iteration.

=back


=for bad

cornerSubPix ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2210 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::cornerSubPix {
  barf "Usage: PDL::OpenCV::Imgproc::cornerSubPix(\$image,\$corners,\$winSize,\$zeroZone,\$criteria)\n" if @_ < 5;
  my ($image,$corners,$winSize,$zeroZone,$criteria) = @_;
    
  PDL::OpenCV::Imgproc::_cornerSubPix_int($image,$corners,$winSize,$zeroZone,$criteria);
  
}
#line 2223 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*cornerSubPix = \&PDL::OpenCV::Imgproc::cornerSubPix;
#line 2230 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 goodFeaturesToTrack

=for sig

  Signature: ([phys] image(l1,c1,r1); [o,phys] corners(l2,c2,r2); int [phys] maxCorners(); double [phys] qualityLevel(); double [phys] minDistance(); [phys] mask(l6,c6,r6); int [phys] blockSize(); byte [phys] useHarrisDetector(); double [phys] k())

=for ref

Determines strong corners on an image. NO BROADCASTING.

=for example

 $corners = goodFeaturesToTrack($image,$maxCorners,$qualityLevel,$minDistance); # with defaults
 $corners = goodFeaturesToTrack($image,$maxCorners,$qualityLevel,$minDistance,$mask,$blockSize,$useHarrisDetector,$k);

The function finds the most prominent corners in the image or in the specified image region, as
described in @cite Shi94
-   Function calculates the corner quality measure at every source image pixel using the
#cornerMinEigenVal or #cornerHarris .
-   Function performs a non-maximum suppression (the local maximums in *3 x 3* neighborhood are
retained).
-   The corners with the minimal eigenvalue less than
C<<< \texttt{qualityLevel} \cdot \max_{x,y} qualityMeasureMap(x,y) >>>are rejected.
-   The remaining corners are sorted by the quality measure in the descending order.
-   Function throws away each corner for which there is a stronger corner at a distance less than
maxDistance.
The function can be used to initialize a point-based tracker of an object.
@note If the function is called with different values A and B of the parameter qualityLevel , and
A \> B, the vector of returned corners with qualityLevel=A will be the prefix of the output vector
with qualityLevel=B .

Parameters:

=over

=item image

Input 8-bit or floating-point 32-bit, single-channel image.

=item corners

Output vector of detected corners.

=item maxCorners

Maximum number of corners to return. If there are more corners than are found,
the strongest of them is returned. `maxCorners <= 0` implies that no limit on the maximum is set
and all detected corners are returned.

=item qualityLevel

Parameter characterizing the minimal accepted quality of image corners. The
parameter value is multiplied by the best corner quality measure, which is the minimal eigenvalue
(see #cornerMinEigenVal ) or the Harris function response (see #cornerHarris ). The corners with the
quality measure less than the product are rejected. For example, if the best corner has the
quality measure = 1500, and the qualityLevel=0.01 , then all the corners with the quality measure
less than 15 are rejected.

=item minDistance

Minimum possible Euclidean distance between the returned corners.

=item mask

Optional region of interest. If the image is not empty (it needs to have the type
CV_8UC1 and the same size as image ), it specifies the region in which the corners are detected.

=item blockSize

Size of an average block for computing a derivative covariation matrix over each
pixel neighborhood. See cornerEigenValsAndVecs .

=item useHarrisDetector

Parameter indicating whether to use a Harris detector (see #cornerHarris)
or #cornerMinEigenVal.

=item k

Free parameter of the Harris detector.

=back

See also:
cornerMinEigenVal, cornerHarris, calcOpticalFlowPyrLK, estimateRigidTransform,


=for bad

goodFeaturesToTrack ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2332 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::goodFeaturesToTrack {
  barf "Usage: PDL::OpenCV::Imgproc::goodFeaturesToTrack(\$image,\$maxCorners,\$qualityLevel,\$minDistance,\$mask,\$blockSize,\$useHarrisDetector,\$k)\n" if @_ < 4;
  my ($image,$maxCorners,$qualityLevel,$minDistance,$mask,$blockSize,$useHarrisDetector,$k) = @_;
  my ($corners);
  $corners = PDL->null if !defined $corners;
  $mask = PDL->zeroes(sbyte,0,0,0) if !defined $mask;
  $blockSize = 3 if !defined $blockSize;
  $useHarrisDetector = 0 if !defined $useHarrisDetector;
  $k = 0.04 if !defined $k;
  PDL::OpenCV::Imgproc::_goodFeaturesToTrack_int($image,$corners,$maxCorners,$qualityLevel,$minDistance,$mask,$blockSize,$useHarrisDetector,$k);
  !wantarray ? $corners : ($corners)
}
#line 2350 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*goodFeaturesToTrack = \&PDL::OpenCV::Imgproc::goodFeaturesToTrack;
#line 2357 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 goodFeaturesToTrack2

=for sig

  Signature: ([phys] image(l1,c1,r1); [o,phys] corners(l2,c2,r2); int [phys] maxCorners(); double [phys] qualityLevel(); double [phys] minDistance(); [phys] mask(l6,c6,r6); int [phys] blockSize(); int [phys] gradientSize(); byte [phys] useHarrisDetector(); double [phys] k())

=for ref

 NO BROADCASTING.

=for example

 $corners = goodFeaturesToTrack2($image,$maxCorners,$qualityLevel,$minDistance,$mask,$blockSize,$gradientSize); # with defaults
 $corners = goodFeaturesToTrack2($image,$maxCorners,$qualityLevel,$minDistance,$mask,$blockSize,$gradientSize,$useHarrisDetector,$k);


=for bad

goodFeaturesToTrack2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2388 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::goodFeaturesToTrack2 {
  barf "Usage: PDL::OpenCV::Imgproc::goodFeaturesToTrack2(\$image,\$maxCorners,\$qualityLevel,\$minDistance,\$mask,\$blockSize,\$gradientSize,\$useHarrisDetector,\$k)\n" if @_ < 7;
  my ($image,$maxCorners,$qualityLevel,$minDistance,$mask,$blockSize,$gradientSize,$useHarrisDetector,$k) = @_;
  my ($corners);
  $corners = PDL->null if !defined $corners;
  $useHarrisDetector = 0 if !defined $useHarrisDetector;
  $k = 0.04 if !defined $k;
  PDL::OpenCV::Imgproc::_goodFeaturesToTrack2_int($image,$corners,$maxCorners,$qualityLevel,$minDistance,$mask,$blockSize,$gradientSize,$useHarrisDetector,$k);
  !wantarray ? $corners : ($corners)
}
#line 2404 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*goodFeaturesToTrack2 = \&PDL::OpenCV::Imgproc::goodFeaturesToTrack2;
#line 2411 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 goodFeaturesToTrackWithQuality

=for sig

  Signature: ([phys] image(l1,c1,r1); [o,phys] corners(l2,c2,r2); int [phys] maxCorners(); double [phys] qualityLevel(); double [phys] minDistance(); [phys] mask(l6,c6,r6); [o,phys] cornersQuality(l7,c7,r7); int [phys] blockSize(); int [phys] gradientSize(); byte [phys] useHarrisDetector(); double [phys] k())

=for ref

Same as above, but returns also quality measure of the detected corners. NO BROADCASTING.

=for example

 ($corners,$cornersQuality) = goodFeaturesToTrackWithQuality($image,$maxCorners,$qualityLevel,$minDistance,$mask); # with defaults
 ($corners,$cornersQuality) = goodFeaturesToTrackWithQuality($image,$maxCorners,$qualityLevel,$minDistance,$mask,$blockSize,$gradientSize,$useHarrisDetector,$k);

Parameters:

=over

=item image

Input 8-bit or floating-point 32-bit, single-channel image.

=item corners

Output vector of detected corners.

=item maxCorners

Maximum number of corners to return. If there are more corners than are found,
the strongest of them is returned. `maxCorners <= 0` implies that no limit on the maximum is set
and all detected corners are returned.

=item qualityLevel

Parameter characterizing the minimal accepted quality of image corners. The
parameter value is multiplied by the best corner quality measure, which is the minimal eigenvalue
(see #cornerMinEigenVal ) or the Harris function response (see #cornerHarris ). The corners with the
quality measure less than the product are rejected. For example, if the best corner has the
quality measure = 1500, and the qualityLevel=0.01 , then all the corners with the quality measure
less than 15 are rejected.

=item minDistance

Minimum possible Euclidean distance between the returned corners.

=item mask

Region of interest. If the image is not empty (it needs to have the type
CV_8UC1 and the same size as image ), it specifies the region in which the corners are detected.

=item cornersQuality

Output vector of quality measure of the detected corners.

=item blockSize

Size of an average block for computing a derivative covariation matrix over each
pixel neighborhood. See cornerEigenValsAndVecs .

=item gradientSize

Aperture parameter for the Sobel operator used for derivatives computation.
See cornerEigenValsAndVecs .

=item useHarrisDetector

Parameter indicating whether to use a Harris detector (see #cornerHarris)
or #cornerMinEigenVal.

=item k

Free parameter of the Harris detector.

=back


=for bad

goodFeaturesToTrackWithQuality ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2503 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::goodFeaturesToTrackWithQuality {
  barf "Usage: PDL::OpenCV::Imgproc::goodFeaturesToTrackWithQuality(\$image,\$maxCorners,\$qualityLevel,\$minDistance,\$mask,\$blockSize,\$gradientSize,\$useHarrisDetector,\$k)\n" if @_ < 5;
  my ($image,$maxCorners,$qualityLevel,$minDistance,$mask,$blockSize,$gradientSize,$useHarrisDetector,$k) = @_;
  my ($corners,$cornersQuality);
  $corners = PDL->null if !defined $corners;
  $cornersQuality = PDL->null if !defined $cornersQuality;
  $blockSize = 3 if !defined $blockSize;
  $gradientSize = 3 if !defined $gradientSize;
  $useHarrisDetector = 0 if !defined $useHarrisDetector;
  $k = 0.04 if !defined $k;
  PDL::OpenCV::Imgproc::_goodFeaturesToTrackWithQuality_int($image,$corners,$maxCorners,$qualityLevel,$minDistance,$mask,$cornersQuality,$blockSize,$gradientSize,$useHarrisDetector,$k);
  !wantarray ? $cornersQuality : ($corners,$cornersQuality)
}
#line 2522 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*goodFeaturesToTrackWithQuality = \&PDL::OpenCV::Imgproc::goodFeaturesToTrackWithQuality;
#line 2529 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 HoughLines

=for sig

  Signature: ([phys] image(l1,c1,r1); [o,phys] lines(l2,c2,r2); double [phys] rho(); double [phys] theta(); int [phys] threshold(); double [phys] srn(); double [phys] stn(); double [phys] min_theta(); double [phys] max_theta())

=for ref

Finds lines in a binary image using the standard Hough transform. NO BROADCASTING.

=for example

 $lines = HoughLines($image,$rho,$theta,$threshold); # with defaults
 $lines = HoughLines($image,$rho,$theta,$threshold,$srn,$stn,$min_theta,$max_theta);

The function implements the standard or standard multi-scale Hough transform algorithm for line
detection. See <http://homepages.inf.ed.ac.uk/rbf/HIPR2/hough.htm> for a good explanation of Hough
transform.
C<<< (\rho, \theta) >>>or C<<< (\rho, \theta, \textrm{votes}) >>>. C<<< \rho >>>is the distance from the coordinate origin C<<< (0,0) >>>(top-left corner of
the image). C<<< \theta >>>is the line rotation angle in radians (
C<<< 0 \sim \textrm{vertical line}, \pi/2 \sim \textrm{horizontal line} >>>).
C<<< \textrm{votes} >>>is the value of accumulator.
C<<< >\texttt{threshold} >>>).

Parameters:

=over

=item image

8-bit, single-channel binary source image. The image may be modified by the function.

=item lines

Output vector of lines. Each line is represented by a 2 or 3 element vector

=item rho

Distance resolution of the accumulator in pixels.

=item theta

Angle resolution of the accumulator in radians.

=item threshold

Accumulator threshold parameter. Only those lines are returned that get enough
votes (

=item srn

For the multi-scale Hough transform, it is a divisor for the distance resolution rho .
The coarse accumulator distance resolution is rho and the accurate accumulator resolution is
rho/srn . If both srn=0 and stn=0 , the classical Hough transform is used. Otherwise, both these
parameters should be positive.

=item stn

For the multi-scale Hough transform, it is a divisor for the distance resolution theta.

=item min_theta

For standard and multi-scale Hough transform, minimum angle to check for lines.
Must fall between 0 and max_theta.

=item max_theta

For standard and multi-scale Hough transform, maximum angle to check for lines.
Must fall between min_theta and CV_PI.

=back


=for bad

HoughLines ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2617 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::HoughLines {
  barf "Usage: PDL::OpenCV::Imgproc::HoughLines(\$image,\$rho,\$theta,\$threshold,\$srn,\$stn,\$min_theta,\$max_theta)\n" if @_ < 4;
  my ($image,$rho,$theta,$threshold,$srn,$stn,$min_theta,$max_theta) = @_;
  my ($lines);
  $lines = PDL->null if !defined $lines;
  $srn = 0 if !defined $srn;
  $stn = 0 if !defined $stn;
  $min_theta = 0 if !defined $min_theta;
  $max_theta = CV_PI() if !defined $max_theta;
  PDL::OpenCV::Imgproc::_HoughLines_int($image,$lines,$rho,$theta,$threshold,$srn,$stn,$min_theta,$max_theta);
  !wantarray ? $lines : ($lines)
}
#line 2635 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*HoughLines = \&PDL::OpenCV::Imgproc::HoughLines;
#line 2642 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 HoughLinesP

=for sig

  Signature: ([phys] image(l1,c1,r1); [o,phys] lines(l2,c2,r2); double [phys] rho(); double [phys] theta(); int [phys] threshold(); double [phys] minLineLength(); double [phys] maxLineGap())

=for ref

Finds line segments in a binary image using the probabilistic Hough transform. NO BROADCASTING.

=for example

 $lines = HoughLinesP($image,$rho,$theta,$threshold); # with defaults
 $lines = HoughLinesP($image,$rho,$theta,$threshold,$minLineLength,$maxLineGap);

The function implements the probabilistic Hough transform algorithm for line detection, described
in @cite Matas00
See the line detection example below:
@include snippets/imgproc_HoughLinesP.cpp
This is a sample picture the function parameters have been tuned for:
![image](pics/building.jpg)
And this is the output of the above program in case of the probabilistic Hough transform:
![image](pics/houghp.png)
C<<< (x_1, y_1, x_2, y_2) >>>, where C<<< (x_1,y_1) >>>and C<<< (x_2, y_2) >>>are the ending points of each detected
line segment.
C<<< >\texttt{threshold} >>>).

Parameters:

=over

=item image

8-bit, single-channel binary source image. The image may be modified by the function.

=item lines

Output vector of lines. Each line is represented by a 4-element vector

=item rho

Distance resolution of the accumulator in pixels.

=item theta

Angle resolution of the accumulator in radians.

=item threshold

Accumulator threshold parameter. Only those lines are returned that get enough
votes (

=item minLineLength

Minimum line length. Line segments shorter than that are rejected.

=item maxLineGap

Maximum allowed gap between points on the same line to link them.

=back

See also:
LineSegmentDetector


=for bad

HoughLinesP ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2723 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::HoughLinesP {
  barf "Usage: PDL::OpenCV::Imgproc::HoughLinesP(\$image,\$rho,\$theta,\$threshold,\$minLineLength,\$maxLineGap)\n" if @_ < 4;
  my ($image,$rho,$theta,$threshold,$minLineLength,$maxLineGap) = @_;
  my ($lines);
  $lines = PDL->null if !defined $lines;
  $minLineLength = 0 if !defined $minLineLength;
  $maxLineGap = 0 if !defined $maxLineGap;
  PDL::OpenCV::Imgproc::_HoughLinesP_int($image,$lines,$rho,$theta,$threshold,$minLineLength,$maxLineGap);
  !wantarray ? $lines : ($lines)
}
#line 2739 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*HoughLinesP = \&PDL::OpenCV::Imgproc::HoughLinesP;
#line 2746 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 HoughLinesPointSet

=for sig

  Signature: ([phys] point(l1,c1,r1); [o,phys] lines(l2,c2,r2); int [phys] lines_max(); int [phys] threshold(); double [phys] min_rho(); double [phys] max_rho(); double [phys] rho_step(); double [phys] min_theta(); double [phys] max_theta(); double [phys] theta_step())

=for ref

Finds lines in a set of points using the standard Hough transform. NO BROADCASTING.

=for example

 $lines = HoughLinesPointSet($point,$lines_max,$threshold,$min_rho,$max_rho,$rho_step,$min_theta,$max_theta,$theta_step);

The function finds lines in a set of points using a modification of the Hough transform.
@include snippets/imgproc_HoughLinesPointSet.cpp
C<<< (x,y) >>>. Type must be CV_32FC2 or CV_32SC2.
C<<< (votes, rho, theta) >>>.
The larger the value of 'votes', the higher the reliability of the Hough line.
C<<< >\texttt{threshold} >>>)

Parameters:

=over

=item point

Input vector of points. Each vector must be encoded as a Point vector

=item lines

Output vector of found lines. Each vector is encoded as a vector<Vec3d>

=item lines_max

Max count of hough lines.

=item threshold

Accumulator threshold parameter. Only those lines are returned that get enough
votes (

=item min_rho

Minimum Distance value of the accumulator in pixels.

=item max_rho

Maximum Distance value of the accumulator in pixels.

=item rho_step

Distance resolution of the accumulator in pixels.

=item min_theta

Minimum angle value of the accumulator in radians.

=item max_theta

Maximum angle value of the accumulator in radians.

=item theta_step

Angle resolution of the accumulator in radians.

=back


=for bad

HoughLinesPointSet ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2830 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::HoughLinesPointSet {
  barf "Usage: PDL::OpenCV::Imgproc::HoughLinesPointSet(\$point,\$lines_max,\$threshold,\$min_rho,\$max_rho,\$rho_step,\$min_theta,\$max_theta,\$theta_step)\n" if @_ < 9;
  my ($point,$lines_max,$threshold,$min_rho,$max_rho,$rho_step,$min_theta,$max_theta,$theta_step) = @_;
  my ($lines);
  $lines = PDL->null if !defined $lines;
  PDL::OpenCV::Imgproc::_HoughLinesPointSet_int($point,$lines,$lines_max,$threshold,$min_rho,$max_rho,$rho_step,$min_theta,$max_theta,$theta_step);
  !wantarray ? $lines : ($lines)
}
#line 2844 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*HoughLinesPointSet = \&PDL::OpenCV::Imgproc::HoughLinesPointSet;
#line 2851 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 HoughCircles

=for sig

  Signature: ([phys] image(l1,c1,r1); [o,phys] circles(l2,c2,r2); int [phys] method(); double [phys] dp(); double [phys] minDist(); double [phys] param1(); double [phys] param2(); int [phys] minRadius(); int [phys] maxRadius())

=for ref

Finds circles in a grayscale image using the Hough transform. NO BROADCASTING.

=for example

 $circles = HoughCircles($image,$method,$dp,$minDist); # with defaults
 $circles = HoughCircles($image,$method,$dp,$minDist,$param1,$param2,$minRadius,$maxRadius);

The function finds circles in a grayscale image using a modification of the Hough transform.
Example: :
@include snippets/imgproc_HoughLinesCircles.cpp
@note Usually the function detects the centers of circles well. However, it may fail to find correct
radii. You can assist to the function by specifying the radius range ( minRadius and maxRadius ) if
you know it. Or, in the case of #HOUGH_GRADIENT method you may set maxRadius to a negative number
to return centers only without radius search, and find the correct radius using an additional procedure.
It also helps to smooth image a bit unless it's already soft. For example,
GaussianBlur() with 7x7 kernel and 1.5x1.5 sigma or similar blurring may help.
C<<< (x, y, radius) >>>or C<<< (x, y, radius, votes) >>>.

Parameters:

=over

=item image

8-bit, single-channel, grayscale input image.

=item circles

Output vector of found circles. Each vector is encoded as  3 or 4 element
floating-point vector

=item method

Detection method, see #HoughModes. The available methods are #HOUGH_GRADIENT and #HOUGH_GRADIENT_ALT.

=item dp

Inverse ratio of the accumulator resolution to the image resolution. For example, if
dp=1 , the accumulator has the same resolution as the input image. If dp=2 , the accumulator has
half as big width and height. For #HOUGH_GRADIENT_ALT the recommended value is dp=1.5,
unless some small very circles need to be detected.

=item minDist

Minimum distance between the centers of the detected circles. If the parameter is
too small, multiple neighbor circles may be falsely detected in addition to a true one. If it is
too large, some circles may be missed.

=item param1

First method-specific parameter. In case of #HOUGH_GRADIENT and #HOUGH_GRADIENT_ALT,
it is the higher threshold of the two passed to the Canny edge detector (the lower one is twice smaller).
Note that #HOUGH_GRADIENT_ALT uses #Scharr algorithm to compute image derivatives, so the threshold value
shough normally be higher, such as 300 or normally exposed and contrasty images.

=item param2

Second method-specific parameter. In case of #HOUGH_GRADIENT, it is the
accumulator threshold for the circle centers at the detection stage. The smaller it is, the more
false circles may be detected. Circles, corresponding to the larger accumulator values, will be
returned first. In the case of #HOUGH_GRADIENT_ALT algorithm, this is the circle "perfectness" measure.
The closer it to 1, the better shaped circles algorithm selects. In most cases 0.9 should be fine.
If you want get better detection of small circles, you may decrease it to 0.85, 0.8 or even less.
But then also try to limit the search range [minRadius, maxRadius] to avoid many false circles.

=item minRadius

Minimum circle radius.

=item maxRadius

Maximum circle radius. If <= 0, uses the maximum image dimension. If < 0, #HOUGH_GRADIENT returns
centers without finding the radius. #HOUGH_GRADIENT_ALT always computes circle radiuses.

=back

See also:
fitEllipse, minEnclosingCircle


=for bad

HoughCircles ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2954 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::HoughCircles {
  barf "Usage: PDL::OpenCV::Imgproc::HoughCircles(\$image,\$method,\$dp,\$minDist,\$param1,\$param2,\$minRadius,\$maxRadius)\n" if @_ < 4;
  my ($image,$method,$dp,$minDist,$param1,$param2,$minRadius,$maxRadius) = @_;
  my ($circles);
  $circles = PDL->null if !defined $circles;
  $param1 = 100 if !defined $param1;
  $param2 = 100 if !defined $param2;
  $minRadius = 0 if !defined $minRadius;
  $maxRadius = 0 if !defined $maxRadius;
  PDL::OpenCV::Imgproc::_HoughCircles_int($image,$circles,$method,$dp,$minDist,$param1,$param2,$minRadius,$maxRadius);
  !wantarray ? $circles : ($circles)
}
#line 2972 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*HoughCircles = \&PDL::OpenCV::Imgproc::HoughCircles;
#line 2979 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 erode

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); [phys] kernel(l3,c3,r3); indx [phys] anchor(n4=2); int [phys] iterations(); int [phys] borderType(); double [phys] borderValue(n7=4))

=for ref

Erodes an image by using a specific structuring element. NO BROADCASTING.

=for example

 $dst = erode($src,$kernel); # with defaults
 $dst = erode($src,$kernel,$anchor,$iterations,$borderType,$borderValue);

The function erodes the source image using the specified structuring element that determines the
shape of a pixel neighborhood over which the minimum is taken:
\f[\texttt{dst} (x,y) =  \min _{(x',y'):  \, \texttt{element} (x',y') \ne0 } \texttt{src} (x+x',y+y')\f]
The function supports the in-place mode. Erosion can be applied several ( iterations ) times. In
case of multi-channel images, each channel is processed independently.

Parameters:

=over

=item src

input image; the number of channels can be arbitrary, but the depth should be one of
CV_8U, CV_16U, CV_16S, CV_32F or CV_64F.

=item dst

output image of the same size and type as src.

=item kernel

structuring element used for erosion; if `element=Mat()`, a `3 x 3` rectangular
structuring element is used. Kernel can be created using #getStructuringElement.

=item anchor

position of the anchor within the element; default value (-1, -1) means that the
anchor is at the element center.

=item iterations

number of times erosion is applied.

=item borderType

pixel extrapolation method, see #BorderTypes. #BORDER_WRAP is not supported.

=item borderValue

border value in case of a constant border

=back

See also:
dilate, morphologyEx, getStructuringElement


=for bad

erode ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3056 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::erode {
  barf "Usage: PDL::OpenCV::Imgproc::erode(\$src,\$kernel,\$anchor,\$iterations,\$borderType,\$borderValue)\n" if @_ < 2;
  my ($src,$kernel,$anchor,$iterations,$borderType,$borderValue) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $anchor = indx(-1,-1) if !defined $anchor;
  $iterations = 1 if !defined $iterations;
  $borderType = BORDER_CONSTANT() if !defined $borderType;
  $borderValue = morphologyDefaultBorderValue() if !defined $borderValue;
  PDL::OpenCV::Imgproc::_erode_int($src,$dst,$kernel,$anchor,$iterations,$borderType,$borderValue);
  !wantarray ? $dst : ($dst)
}
#line 3074 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*erode = \&PDL::OpenCV::Imgproc::erode;
#line 3081 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 dilate

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); [phys] kernel(l3,c3,r3); indx [phys] anchor(n4=2); int [phys] iterations(); int [phys] borderType(); double [phys] borderValue(n7=4))

=for ref

Dilates an image by using a specific structuring element. NO BROADCASTING.

=for example

 $dst = dilate($src,$kernel); # with defaults
 $dst = dilate($src,$kernel,$anchor,$iterations,$borderType,$borderValue);

The function dilates the source image using the specified structuring element that determines the
shape of a pixel neighborhood over which the maximum is taken:
\f[\texttt{dst} (x,y) =  \max _{(x',y'):  \, \texttt{element} (x',y') \ne0 } \texttt{src} (x+x',y+y')\f]
The function supports the in-place mode. Dilation can be applied several ( iterations ) times. In
case of multi-channel images, each channel is processed independently.

Parameters:

=over

=item src

input image; the number of channels can be arbitrary, but the depth should be one of
CV_8U, CV_16U, CV_16S, CV_32F or CV_64F.

=item dst

output image of the same size and type as src.

=item kernel

structuring element used for dilation; if elemenat=Mat(), a 3 x 3 rectangular
structuring element is used. Kernel can be created using #getStructuringElement

=item anchor

position of the anchor within the element; default value (-1, -1) means that the
anchor is at the element center.

=item iterations

number of times dilation is applied.

=item borderType

pixel extrapolation method, see #BorderTypes. #BORDER_WRAP is not suported.

=item borderValue

border value in case of a constant border

=back

See also:
erode, morphologyEx, getStructuringElement


=for bad

dilate ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3158 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::dilate {
  barf "Usage: PDL::OpenCV::Imgproc::dilate(\$src,\$kernel,\$anchor,\$iterations,\$borderType,\$borderValue)\n" if @_ < 2;
  my ($src,$kernel,$anchor,$iterations,$borderType,$borderValue) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $anchor = indx(-1,-1) if !defined $anchor;
  $iterations = 1 if !defined $iterations;
  $borderType = BORDER_CONSTANT() if !defined $borderType;
  $borderValue = morphologyDefaultBorderValue() if !defined $borderValue;
  PDL::OpenCV::Imgproc::_dilate_int($src,$dst,$kernel,$anchor,$iterations,$borderType,$borderValue);
  !wantarray ? $dst : ($dst)
}
#line 3176 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*dilate = \&PDL::OpenCV::Imgproc::dilate;
#line 3183 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 morphologyEx

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] op(); [phys] kernel(l4,c4,r4); indx [phys] anchor(n5=2); int [phys] iterations(); int [phys] borderType(); double [phys] borderValue(n8=4))

=for ref

Performs advanced morphological transformations. NO BROADCASTING.

=for example

 $dst = morphologyEx($src,$op,$kernel); # with defaults
 $dst = morphologyEx($src,$op,$kernel,$anchor,$iterations,$borderType,$borderValue);

The function cv::morphologyEx can perform advanced morphological transformations using an erosion and dilation as
basic operations.
Any of the operations can be done in-place. In case of multi-channel images, each channel is
processed independently.
@note The number of iterations is the number of times erosion or dilatation operation will be applied.
For instance, an opening operation (#MORPH_OPEN) with two iterations is equivalent to apply
successively: erode -> erode -> dilate -> dilate (and not erode -> dilate -> erode -> dilate).

Parameters:

=over

=item src

Source image. The number of channels can be arbitrary. The depth should be one of
CV_8U, CV_16U, CV_16S, CV_32F or CV_64F.

=item dst

Destination image of the same size and type as source image.

=item op

Type of a morphological operation, see #MorphTypes

=item kernel

Structuring element. It can be created using #getStructuringElement.

=item anchor

Anchor position with the kernel. Negative values mean that the anchor is at the
kernel center.

=item iterations

Number of times erosion and dilation are applied.

=item borderType

Pixel extrapolation method, see #BorderTypes. #BORDER_WRAP is not supported.

=item borderValue

Border value in case of a constant border. The default value has a special
meaning.

=back

See also:
dilate, erode, getStructuringElement


=for bad

morphologyEx ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3266 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::morphologyEx {
  barf "Usage: PDL::OpenCV::Imgproc::morphologyEx(\$src,\$op,\$kernel,\$anchor,\$iterations,\$borderType,\$borderValue)\n" if @_ < 3;
  my ($src,$op,$kernel,$anchor,$iterations,$borderType,$borderValue) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $anchor = indx(-1,-1) if !defined $anchor;
  $iterations = 1 if !defined $iterations;
  $borderType = BORDER_CONSTANT() if !defined $borderType;
  $borderValue = morphologyDefaultBorderValue() if !defined $borderValue;
  PDL::OpenCV::Imgproc::_morphologyEx_int($src,$dst,$op,$kernel,$anchor,$iterations,$borderType,$borderValue);
  !wantarray ? $dst : ($dst)
}
#line 3284 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*morphologyEx = \&PDL::OpenCV::Imgproc::morphologyEx;
#line 3291 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 resize

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); indx [phys] dsize(n3=2); double [phys] fx(); double [phys] fy(); int [phys] interpolation())

=for ref

Resizes an image. NO BROADCASTING.

=for example

 $dst = resize($src,$dsize); # with defaults
 $dst = resize($src,$dsize,$fx,$fy,$interpolation);

The function resize resizes the image src down to or up to the specified size. Note that the
initial dst type or size are not taken into account. Instead, the size and type are derived from
the `src`,`dsize`,`fx`, and `fy`. If you want to resize src so that it fits the pre-created dst,
you may call the function as follows:

     // explicitly specify dsize=dst.size(); fx and fy will be computed from that.
     resize(src, dst, dst.size(), 0, 0, interpolation);

If you want to decimate the image by factor of 2 in each direction, you can call the function this
way:

     // specify fx and fy and let the function compute the destination image size.
     resize(src, dst, Size(), 0.5, 0.5, interpolation);

To shrink an image, it will generally look best with #INTER_AREA interpolation, whereas to
enlarge an image, it will generally look best with c#INTER_CUBIC (slow) or #INTER_LINEAR
(faster but still looks OK).
\f[\texttt{dsize = Size(round(fx*src.cols), round(fy*src.rows))}\f]
Either dsize or both fx and fy must be non-zero.
\f[\texttt{(double)dsize.width/src.cols}\f]
\f[\texttt{(double)dsize.height/src.rows}\f]

Parameters:

=over

=item src

input image.

=item dst

output image; it has the size dsize (when it is non-zero) or the size computed from
src.size(), fx, and fy; the type of dst is the same as of src.

=item dsize

output image size; if it equals zero (`None` in Python), it is computed as:

=item fx

scale factor along the horizontal axis; when it equals 0, it is computed as

=item fy

scale factor along the vertical axis; when it equals 0, it is computed as

=item interpolation

interpolation method, see #InterpolationFlags

=back

See also:
warpAffine, warpPerspective, remap


=for bad

resize ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3378 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::resize {
  barf "Usage: PDL::OpenCV::Imgproc::resize(\$src,\$dsize,\$fx,\$fy,\$interpolation)\n" if @_ < 2;
  my ($src,$dsize,$fx,$fy,$interpolation) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $fx = 0 if !defined $fx;
  $fy = 0 if !defined $fy;
  $interpolation = INTER_LINEAR() if !defined $interpolation;
  PDL::OpenCV::Imgproc::_resize_int($src,$dst,$dsize,$fx,$fy,$interpolation);
  !wantarray ? $dst : ($dst)
}
#line 3395 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*resize = \&PDL::OpenCV::Imgproc::resize;
#line 3402 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 warpAffine

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); [phys] M(l3,c3,r3); indx [phys] dsize(n4=2); int [phys] flags(); int [phys] borderMode(); double [phys] borderValue(n7))

=for ref

Applies an affine transformation to an image. NO BROADCASTING.

=for example

 $dst = warpAffine($src,$M,$dsize); # with defaults
 $dst = warpAffine($src,$M,$dsize,$flags,$borderMode,$borderValue);

The function warpAffine transforms the source image using the specified matrix:
\f[\texttt{dst} (x,y) =  \texttt{src} ( \texttt{M} _{11} x +  \texttt{M} _{12} y +  \texttt{M} _{13}, \texttt{M} _{21} x +  \texttt{M} _{22} y +  \texttt{M} _{23})\f]
when the flag #WARP_INVERSE_MAP is set. Otherwise, the transformation is first inverted
with #invertAffineTransform and then put in the formula above instead of M. The function cannot
operate in-place.
C<<< 2\times 3 >>>transformation matrix.
C<<< \texttt{dst}\rightarrow\texttt{src} >>>).

Parameters:

=over

=item src

input image.

=item dst

output image that has the size dsize and the same type as src .

=item M

=item dsize

size of the output image.

=item flags

combination of interpolation methods (see #InterpolationFlags) and the optional
flag #WARP_INVERSE_MAP that means that M is the inverse transformation (

=item borderMode

pixel extrapolation method (see #BorderTypes); when
borderMode=#BORDER_TRANSPARENT, it means that the pixels in the destination image corresponding to
the "outliers" in the source image are not modified by the function.

=item borderValue

value used in case of a constant border; by default, it is 0.

=back

See also:
warpPerspective, resize, remap, getRectSubPix, transform


=for bad

warpAffine ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3479 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::warpAffine {
  barf "Usage: PDL::OpenCV::Imgproc::warpAffine(\$src,\$M,\$dsize,\$flags,\$borderMode,\$borderValue)\n" if @_ < 3;
  my ($src,$M,$dsize,$flags,$borderMode,$borderValue) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $flags = INTER_LINEAR() if !defined $flags;
  $borderMode = BORDER_CONSTANT() if !defined $borderMode;
  $borderValue = empty(double) if !defined $borderValue;
  PDL::OpenCV::Imgproc::_warpAffine_int($src,$dst,$M,$dsize,$flags,$borderMode,$borderValue);
  !wantarray ? $dst : ($dst)
}
#line 3496 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*warpAffine = \&PDL::OpenCV::Imgproc::warpAffine;
#line 3503 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 warpPerspective

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); [phys] M(l3,c3,r3); indx [phys] dsize(n4=2); int [phys] flags(); int [phys] borderMode(); double [phys] borderValue(n7))

=for ref

Applies a perspective transformation to an image. NO BROADCASTING.

=for example

 $dst = warpPerspective($src,$M,$dsize); # with defaults
 $dst = warpPerspective($src,$M,$dsize,$flags,$borderMode,$borderValue);

The function warpPerspective transforms the source image using the specified matrix:
\f[\texttt{dst} (x,y) =  \texttt{src} \left ( \frac{M_{11} x + M_{12} y + M_{13}}{M_{31} x + M_{32} y + M_{33}} ,
\frac{M_{21} x + M_{22} y + M_{23}}{M_{31} x + M_{32} y + M_{33}} \right )\f]
when the flag #WARP_INVERSE_MAP is set. Otherwise, the transformation is first inverted with invert
and then put in the formula above instead of M. The function cannot operate in-place.
C<<< 3\times 3 >>>transformation matrix.
C<<< \texttt{dst}\rightarrow\texttt{src} >>>).

Parameters:

=over

=item src

input image.

=item dst

output image that has the size dsize and the same type as src .

=item M

=item dsize

size of the output image.

=item flags

combination of interpolation methods (#INTER_LINEAR or #INTER_NEAREST) and the
optional flag #WARP_INVERSE_MAP, that sets M as the inverse transformation (

=item borderMode

pixel extrapolation method (#BORDER_CONSTANT or #BORDER_REPLICATE).

=item borderValue

value used in case of a constant border; by default, it equals 0.

=back

See also:
warpAffine, resize, remap, getRectSubPix, perspectiveTransform


=for bad

warpPerspective ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3578 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::warpPerspective {
  barf "Usage: PDL::OpenCV::Imgproc::warpPerspective(\$src,\$M,\$dsize,\$flags,\$borderMode,\$borderValue)\n" if @_ < 3;
  my ($src,$M,$dsize,$flags,$borderMode,$borderValue) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $flags = INTER_LINEAR() if !defined $flags;
  $borderMode = BORDER_CONSTANT() if !defined $borderMode;
  $borderValue = empty(double) if !defined $borderValue;
  PDL::OpenCV::Imgproc::_warpPerspective_int($src,$dst,$M,$dsize,$flags,$borderMode,$borderValue);
  !wantarray ? $dst : ($dst)
}
#line 3595 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*warpPerspective = \&PDL::OpenCV::Imgproc::warpPerspective;
#line 3602 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 remap

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); [phys] map1(l3,c3,r3); [phys] map2(l4,c4,r4); int [phys] interpolation(); int [phys] borderMode(); double [phys] borderValue(n7))

=for ref

Applies a generic geometrical transformation to an image. NO BROADCASTING.

=for example

 $dst = remap($src,$map1,$map2,$interpolation); # with defaults
 $dst = remap($src,$map1,$map2,$interpolation,$borderMode,$borderValue);

The function remap transforms the source image using the specified map:
\f[\texttt{dst} (x,y) =  \texttt{src} (map_x(x,y),map_y(x,y))\f]
where values of pixels with non-integer coordinates are computed using one of available
interpolation methods. C<<< map_x >>>and C<<< map_y >>>can be encoded as separate floating-point maps
in C<<< map_1 >>>and C<<< map_2 >>>respectively, or interleaved floating-point maps of C<<< (x,y) >>>in
C<<< map_1 >>>, or fixed-point maps created by using convertMaps. The reason you might want to
convert from floating to fixed-point representations of a map is that they can yield much faster
(\~2x) remapping operations. In the converted case, C<<< map_1 >>>contains pairs (cvFloor(x),
cvFloor(y)) and C<<< map_2 >>>contains indices in a table of interpolation coefficients.
This function cannot operate in-place.
@note
Due to current implementation limitations the size of an input and output images should be less than 32767x32767.

Parameters:

=over

=item src

Source image.

=item dst

Destination image. It has the same size as map1 and the same type as src .

=item map1

The first map of either (x,y) points or just x values having the type CV_16SC2 ,
CV_32FC1, or CV_32FC2. See convertMaps for details on converting a floating point
representation to fixed-point for speed.

=item map2

The second map of y values having the type CV_16UC1, CV_32FC1, or none (empty map
if map1 is (x,y) points), respectively.

=item interpolation

Interpolation method (see #InterpolationFlags). The methods #INTER_AREA
and #INTER_LINEAR_EXACT are not supported by this function.

=item borderMode

Pixel extrapolation method (see #BorderTypes). When
borderMode=#BORDER_TRANSPARENT, it means that the pixels in the destination image that
corresponds to the "outliers" in the source image are not modified by the function.

=item borderValue

Value used in case of a constant border. By default, it is 0.

=back


=for bad

remap ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3686 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::remap {
  barf "Usage: PDL::OpenCV::Imgproc::remap(\$src,\$map1,\$map2,\$interpolation,\$borderMode,\$borderValue)\n" if @_ < 4;
  my ($src,$map1,$map2,$interpolation,$borderMode,$borderValue) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $borderMode = BORDER_CONSTANT() if !defined $borderMode;
  $borderValue = empty(double) if !defined $borderValue;
  PDL::OpenCV::Imgproc::_remap_int($src,$dst,$map1,$map2,$interpolation,$borderMode,$borderValue);
  !wantarray ? $dst : ($dst)
}
#line 3702 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*remap = \&PDL::OpenCV::Imgproc::remap;
#line 3709 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 convertMaps

=for sig

  Signature: ([phys] map1(l1,c1,r1); [phys] map2(l2,c2,r2); [o,phys] dstmap1(l3,c3,r3); [o,phys] dstmap2(l4,c4,r4); int [phys] dstmap1type(); byte [phys] nninterpolation())

=for ref

Converts image transformation maps from one representation to another. NO BROADCASTING.

=for example

 ($dstmap1,$dstmap2) = convertMaps($map1,$map2,$dstmap1type); # with defaults
 ($dstmap1,$dstmap2) = convertMaps($map1,$map2,$dstmap1type,$nninterpolation);

The function converts a pair of maps for remap from one representation to another. The following
options ( (map1.type(), map2.type()) C<<< \rightarrow >>>(dstmap1.type(), dstmap2.type()) ) are
supported:
- C<<< \texttt{(CV_32FC1, CV_32FC1)} \rightarrow \texttt{(CV_16SC2, CV_16UC1)} >>>. This is the
most frequently used conversion operation, in which the original floating-point maps (see remap )
are converted to a more compact and much faster fixed-point representation. The first output array
contains the rounded coordinates and the second array (created only when nninterpolation=false )
contains indices in the interpolation tables.
- C<<< \texttt{(CV_32FC2)} \rightarrow \texttt{(CV_16SC2, CV_16UC1)} >>>. The same as above but
the original maps are stored in one 2-channel matrix.
- Reverse conversion. Obviously, the reconstructed floating-point maps will not be exactly the same
as the originals.

Parameters:

=over

=item map1

The first input map of type CV_16SC2, CV_32FC1, or CV_32FC2 .

=item map2

The second input map of type CV_16UC1, CV_32FC1, or none (empty matrix),
respectively.

=item dstmap1

The first output map that has the type dstmap1type and the same size as src .

=item dstmap2

The second output map.

=item dstmap1type

Type of the first output map that should be CV_16SC2, CV_32FC1, or
CV_32FC2 .

=item nninterpolation

Flag indicating whether the fixed-point maps are used for the
nearest-neighbor or for a more complex interpolation.

=back

See also:
remap, undistort, initUndistortRectifyMap


=for bad

convertMaps ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3789 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::convertMaps {
  barf "Usage: PDL::OpenCV::Imgproc::convertMaps(\$map1,\$map2,\$dstmap1type,\$nninterpolation)\n" if @_ < 3;
  my ($map1,$map2,$dstmap1type,$nninterpolation) = @_;
  my ($dstmap1,$dstmap2);
  $dstmap1 = PDL->null if !defined $dstmap1;
  $dstmap2 = PDL->null if !defined $dstmap2;
  $nninterpolation = 0 if !defined $nninterpolation;
  PDL::OpenCV::Imgproc::_convertMaps_int($map1,$map2,$dstmap1,$dstmap2,$dstmap1type,$nninterpolation);
  !wantarray ? $dstmap2 : ($dstmap1,$dstmap2)
}
#line 3805 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*convertMaps = \&PDL::OpenCV::Imgproc::convertMaps;
#line 3812 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 getRotationMatrix2D

=for sig

  Signature: (float [phys] center(n1=2); double [phys] angle(); double [phys] scale(); [o,phys] res(l4,c4,r4))

=for ref

Calculates an affine matrix of 2D rotation. NO BROADCASTING.

=for example

 $res = getRotationMatrix2D($center,$angle,$scale);

The function calculates the following matrix:
\f[\begin{bmatrix} \alpha &  \beta & (1- \alpha )  \cdot \texttt{center.x} -  \beta \cdot \texttt{center.y} \\ - \beta &  \alpha &  \beta \cdot \texttt{center.x} + (1- \alpha )  \cdot \texttt{center.y} \end{bmatrix}\f]
where
\f[\begin{array}{l} \alpha =  \texttt{scale} \cdot \cos \texttt{angle} , \\ \beta =  \texttt{scale} \cdot \sin \texttt{angle} \end{array}\f]
The transformation maps the rotation center to itself. If this is not the target, adjust the shift.

Parameters:

=over

=item center

Center of the rotation in the source image.

=item angle

Rotation angle in degrees. Positive values mean counter-clockwise rotation (the
coordinate origin is assumed to be the top-left corner).

=item scale

Isotropic scale factor.

=back

See also:
getAffineTransform, warpAffine, transform


=for bad

getRotationMatrix2D ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3870 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::getRotationMatrix2D {
  barf "Usage: PDL::OpenCV::Imgproc::getRotationMatrix2D(\$center,\$angle,\$scale)\n" if @_ < 3;
  my ($center,$angle,$scale) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgproc::_getRotationMatrix2D_int($center,$angle,$scale,$res);
  !wantarray ? $res : ($res)
}
#line 3884 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*getRotationMatrix2D = \&PDL::OpenCV::Imgproc::getRotationMatrix2D;
#line 3891 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 invertAffineTransform

=for sig

  Signature: ([phys] M(l1,c1,r1); [o,phys] iM(l2,c2,r2))

=for ref

Inverts an affine transformation. NO BROADCASTING.

=for example

 $iM = invertAffineTransform($M);

The function computes an inverse affine transformation represented by C<<< 2 \times 3 >>>matrix M:
\f[\begin{bmatrix} a_{11} & a_{12} & b_1  \\ a_{21} & a_{22} & b_2 \end{bmatrix}\f]
The result is also a C<<< 2 \times 3 >>>matrix of the same type as M.

Parameters:

=over

=item M

Original affine transformation.

=item iM

Output reverse affine transformation.

=back


=for bad

invertAffineTransform ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3939 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::invertAffineTransform {
  barf "Usage: PDL::OpenCV::Imgproc::invertAffineTransform(\$M)\n" if @_ < 1;
  my ($M) = @_;
  my ($iM);
  $iM = PDL->null if !defined $iM;
  PDL::OpenCV::Imgproc::_invertAffineTransform_int($M,$iM);
  !wantarray ? $iM : ($iM)
}
#line 3953 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*invertAffineTransform = \&PDL::OpenCV::Imgproc::invertAffineTransform;
#line 3960 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 getPerspectiveTransform

=for sig

  Signature: ([phys] src(l1,c1,r1); [phys] dst(l2,c2,r2); int [phys] solveMethod(); [o,phys] res(l4,c4,r4))

=for ref

Calculates a perspective transform from four pairs of the corresponding points. NO BROADCASTING.

=for example

 $res = getPerspectiveTransform($src,$dst); # with defaults
 $res = getPerspectiveTransform($src,$dst,$solveMethod);

The function calculates the C<<< 3 \times 3 >>>matrix of a perspective transform so that:
\f[\begin{bmatrix} t_i x'_i \\ t_i y'_i \\ t_i \end{bmatrix} = \texttt{map_matrix} \cdot \begin{bmatrix} x_i \\ y_i \\ 1 \end{bmatrix}\f]
where
\f[dst(i)=(x'_i,y'_i), src(i)=(x_i, y_i), i=0,1,2,3\f]

Parameters:

=over

=item src

Coordinates of quadrangle vertices in the source image.

=item dst

Coordinates of the corresponding quadrangle vertices in the destination image.

=item solveMethod

method passed to cv::solve (#DecompTypes)

=back

See also:
findHomography, warpPerspective, perspectiveTransform


=for bad

getPerspectiveTransform ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4017 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::getPerspectiveTransform {
  barf "Usage: PDL::OpenCV::Imgproc::getPerspectiveTransform(\$src,\$dst,\$solveMethod)\n" if @_ < 2;
  my ($src,$dst,$solveMethod) = @_;
  my ($res);
  $solveMethod = DECOMP_LU() if !defined $solveMethod;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgproc::_getPerspectiveTransform_int($src,$dst,$solveMethod,$res);
  !wantarray ? $res : ($res)
}
#line 4032 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*getPerspectiveTransform = \&PDL::OpenCV::Imgproc::getPerspectiveTransform;
#line 4039 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 getAffineTransform

=for sig

  Signature: ([phys] src(l1,c1,r1); [phys] dst(l2,c2,r2); [o,phys] res(l3,c3,r3))

=for ref

 NO BROADCASTING.

=for example

 $res = getAffineTransform($src,$dst);

@overload

=for bad

getAffineTransform ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4070 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::getAffineTransform {
  barf "Usage: PDL::OpenCV::Imgproc::getAffineTransform(\$src,\$dst)\n" if @_ < 2;
  my ($src,$dst) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgproc::_getAffineTransform_int($src,$dst,$res);
  !wantarray ? $res : ($res)
}
#line 4084 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*getAffineTransform = \&PDL::OpenCV::Imgproc::getAffineTransform;
#line 4091 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 getRectSubPix

=for sig

  Signature: ([phys] image(l1,c1,r1); indx [phys] patchSize(n2=2); float [phys] center(n3=2); [o,phys] patch(l4,c4,r4); int [phys] patchType())

=for ref

Retrieves a pixel rectangle from an image with sub-pixel accuracy. NO BROADCASTING.

=for example

 $patch = getRectSubPix($image,$patchSize,$center); # with defaults
 $patch = getRectSubPix($image,$patchSize,$center,$patchType);

The function getRectSubPix extracts pixels from src:
\f[patch(x, y) = src(x +  \texttt{center.x} - ( \texttt{dst.cols} -1)*0.5, y +  \texttt{center.y} - ( \texttt{dst.rows} -1)*0.5)\f]
where the values of the pixels at non-integer coordinates are retrieved using bilinear
interpolation. Every channel of multi-channel images is processed independently. Also
the image should be a single channel or three channel image. While the center of the
rectangle must be inside the image, parts of the rectangle may be outside.

Parameters:

=over

=item image

Source image.

=item patchSize

Size of the extracted patch.

=item center

Floating point coordinates of the center of the extracted rectangle within the
source image. The center must be inside the image.

=item patch

Extracted patch that has the size patchSize and the same number of channels as src .

=item patchType

Depth of the extracted pixels. By default, they have the same depth as src .

=back

See also:
warpAffine, warpPerspective


=for bad

getRectSubPix ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4159 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::getRectSubPix {
  barf "Usage: PDL::OpenCV::Imgproc::getRectSubPix(\$image,\$patchSize,\$center,\$patchType)\n" if @_ < 3;
  my ($image,$patchSize,$center,$patchType) = @_;
  my ($patch);
  $patch = PDL->null if !defined $patch;
  $patchType = -1 if !defined $patchType;
  PDL::OpenCV::Imgproc::_getRectSubPix_int($image,$patchSize,$center,$patch,$patchType);
  !wantarray ? $patch : ($patch)
}
#line 4174 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*getRectSubPix = \&PDL::OpenCV::Imgproc::getRectSubPix;
#line 4181 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 logPolar

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); float [phys] center(n3=2); double [phys] M(); int [phys] flags())

=for ref

Remaps an image to semilog-polar coordinates space. NO BROADCASTING.

=for example

 $dst = logPolar($src,$center,$M,$flags);

@deprecated This function produces same result as cv::warpPolar(src, dst, src.size(), center, maxRadius, flags+WARP_POLAR_LOG);
@internal
Transform the source image using the following transformation (See @ref polar_remaps_reference_image "Polar remaps reference image d)"):
\f[\begin{array}{l}
dst( \rho , \phi ) = src(x,y) \\
dst.size() \leftarrow src.size()
\end{array}\f]
where
\f[\begin{array}{l}
I = (dx,dy) = (x - center.x,y - center.y) \\
\rho = M \cdot log_e(\texttt{magnitude} (I)) ,\\
\phi = Kangle \cdot \texttt{angle} (I) \\
\end{array}\f]
and
\f[\begin{array}{l}
M = src.cols / log_e(maxRadius) \\
Kangle = src.rows / 2\Pi \\
\end{array}\f]
The function emulates the human "foveal" vision and can be used for fast scale and
rotation-invariant template matching, for object tracking and so forth.
@note
-   The function can not operate in-place.
-   To calculate magnitude and angle in degrees #cartToPolar is used internally thus angles are measured from 0 to 360 with accuracy about 0.3 degrees.
@endinternal

Parameters:

=over

=item src

Source image

=item dst

Destination image. It will have same size and type as src.

=item center

The transformation center; where the output precision is maximal

=item M

Magnitude scale parameter. It determines the radius of the bounding circle to transform too.

=item flags

A combination of interpolation methods, see #InterpolationFlags

=back

See also:
cv::linearPolar


=for bad

logPolar ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4265 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::logPolar {
  barf "Usage: PDL::OpenCV::Imgproc::logPolar(\$src,\$center,\$M,\$flags)\n" if @_ < 4;
  my ($src,$center,$M,$flags) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::Imgproc::_logPolar_int($src,$dst,$center,$M,$flags);
  !wantarray ? $dst : ($dst)
}
#line 4279 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*logPolar = \&PDL::OpenCV::Imgproc::logPolar;
#line 4286 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 linearPolar

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); float [phys] center(n3=2); double [phys] maxRadius(); int [phys] flags())

=for ref

Remaps an image to polar coordinates space. NO BROADCASTING.

=for example

 $dst = linearPolar($src,$center,$maxRadius,$flags);

@deprecated This function produces same result as cv::warpPolar(src, dst, src.size(), center, maxRadius, flags)
@internal
Transform the source image using the following transformation (See @ref polar_remaps_reference_image "Polar remaps reference image c)"):
\f[\begin{array}{l}
dst( \rho , \phi ) = src(x,y) \\
dst.size() \leftarrow src.size()
\end{array}\f]
where
\f[\begin{array}{l}
I = (dx,dy) = (x - center.x,y - center.y) \\
\rho = Kmag \cdot \texttt{magnitude} (I) ,\\
\phi = angle \cdot \texttt{angle} (I)
\end{array}\f]
and
\f[\begin{array}{l}
Kx = src.cols / maxRadius \\
Ky = src.rows / 2\Pi
\end{array}\f]
@note
-   The function can not operate in-place.
-   To calculate magnitude and angle in degrees #cartToPolar is used internally thus angles are measured from 0 to 360 with accuracy about 0.3 degrees.
@endinternal

Parameters:

=over

=item src

Source image

=item dst

Destination image. It will have same size and type as src.

=item center

The transformation center;

=item maxRadius

The radius of the bounding circle to transform. It determines the inverse magnitude scale parameter too.

=item flags

A combination of interpolation methods, see #InterpolationFlags

=back

See also:
cv::logPolar


=for bad

linearPolar ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4368 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::linearPolar {
  barf "Usage: PDL::OpenCV::Imgproc::linearPolar(\$src,\$center,\$maxRadius,\$flags)\n" if @_ < 4;
  my ($src,$center,$maxRadius,$flags) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::Imgproc::_linearPolar_int($src,$dst,$center,$maxRadius,$flags);
  !wantarray ? $dst : ($dst)
}
#line 4382 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*linearPolar = \&PDL::OpenCV::Imgproc::linearPolar;
#line 4389 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 warpPolar

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); indx [phys] dsize(n3=2); float [phys] center(n4=2); double [phys] maxRadius(); int [phys] flags())

=for ref

Remaps an image to polar or semilog-polar coordinates space NO BROADCASTING.

=for example

 $dst = warpPolar($src,$dsize,$center,$maxRadius,$flags);

@anchor polar_remaps_reference_image
![Polar remaps reference](pics/polar_remap_doc.png)
Transform the source image using the following transformation:
\f[
dst(\rho , \phi ) = src(x,y)
\f]
where
\f[
\begin{array}{l}
\vec{I} = (x - center.x, \;y - center.y) \\
\phi = Kangle \cdot \texttt{angle} (\vec{I}) \\
\rho = \left\{\begin{matrix}
Klin \cdot \texttt{magnitude} (\vec{I}) & default \\
Klog \cdot log_e(\texttt{magnitude} (\vec{I})) & if \; semilog \\
\end{matrix}\right.
\end{array}
\f]
and
\f[
\begin{array}{l}
Kangle = dsize.height / 2\Pi \\
Klin = dsize.width / maxRadius \\
Klog = dsize.width / log_e(maxRadius) \\
\end{array}
\f]
\par Linear vs semilog mapping
Polar mapping can be linear or semi-log. Add one of #WarpPolarMode to `flags` to specify the polar mapping mode.
Linear is the default mode.
The semilog mapping emulates the human "foveal" vision that permit very high acuity on the line of sight (central vision)
in contrast to peripheral vision where acuity is minor.
\par Option on `dsize`:
- if both values in `dsize <=0 ` (default),
the destination image will have (almost) same area of source bounding circle:
\f[\begin{array}{l}
dsize.area  \leftarrow (maxRadius^2 \cdot \Pi) \\
dsize.width = \texttt{cvRound}(maxRadius) \\
dsize.height = \texttt{cvRound}(maxRadius \cdot \Pi) \\
\end{array}\f]
- if only `dsize.height <= 0`,
the destination image area will be proportional to the bounding circle area but scaled by `Kx * Kx`:
\f[\begin{array}{l}
dsize.height = \texttt{cvRound}(dsize.width \cdot \Pi) \\
\end{array}
\f]
- if both values in `dsize > 0 `,
the destination image will have the given size therefore the area of the bounding circle will be scaled to `dsize`.
\par Reverse mapping
You can get reverse mapping adding #WARP_INVERSE_MAP to `flags`
\snippet polar_transforms.cpp InverseMap
In addiction, to calculate the original coordinate from a polar mapped coordinate C<<< (rho, phi)->(x, y) >>>:
\snippet polar_transforms.cpp InverseCoordinate
@note
-  The function can not operate in-place.
-  To calculate magnitude and angle in degrees #cartToPolar is used internally thus angles are measured from 0 to 360 with accuracy about 0.3 degrees.
-  This function uses #remap. Due to current implementation limitations the size of an input and output images should be less than 32767x32767.

Parameters:

=over

=item src

Source image.

=item dst

Destination image. It will have same type as src.

=item dsize

The destination image size (see description for valid options).

=item center

The transformation center.

=item maxRadius

The radius of the bounding circle to transform. It determines the inverse magnitude scale parameter too.

=item flags

A combination of interpolation methods, #InterpolationFlags + #WarpPolarMode.
            - Add #WARP_POLAR_LINEAR to select linear polar mapping (default)
            - Add #WARP_POLAR_LOG to select semilog polar mapping
            - Add #WARP_INVERSE_MAP for reverse mapping.

=back

See also:
cv::remap


=for bad

warpPolar ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4511 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::warpPolar {
  barf "Usage: PDL::OpenCV::Imgproc::warpPolar(\$src,\$dsize,\$center,\$maxRadius,\$flags)\n" if @_ < 5;
  my ($src,$dsize,$center,$maxRadius,$flags) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::Imgproc::_warpPolar_int($src,$dst,$dsize,$center,$maxRadius,$flags);
  !wantarray ? $dst : ($dst)
}
#line 4525 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*warpPolar = \&PDL::OpenCV::Imgproc::warpPolar;
#line 4532 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 integral

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] sum(l2,c2,r2); [o,phys] sqsum(l3,c3,r3); [o,phys] tilted(l4,c4,r4); int [phys] sdepth(); int [phys] sqdepth())

=for ref

Calculates the integral of an image. NO BROADCASTING.

=for example

 ($sum,$sqsum,$tilted) = integral($src); # with defaults
 ($sum,$sqsum,$tilted) = integral($src,$sdepth,$sqdepth);

The function calculates one or more integral images for the source image as follows:
\f[\texttt{sum} (X,Y) =  \sum _{x<X,y<Y}  \texttt{image} (x,y)\f]
\f[\texttt{sqsum} (X,Y) =  \sum _{x<X,y<Y}  \texttt{image} (x,y)^2\f]
\f[\texttt{tilted} (X,Y) =  \sum _{y<Y,abs(x-X+1) \leq Y-y-1}  \texttt{image} (x,y)\f]
Using these integral images, you can calculate sum, mean, and standard deviation over a specific
up-right or rotated rectangular region of the image in a constant time, for example:
\f[\sum _{x_1 \leq x < x_2,  \, y_1  \leq y < y_2}  \texttt{image} (x,y) =  \texttt{sum} (x_2,y_2)- \texttt{sum} (x_1,y_2)- \texttt{sum} (x_2,y_1)+ \texttt{sum} (x_1,y_1)\f]
It makes possible to do a fast blurring or fast block correlation with a variable window size, for
example. In case of multi-channel images, sums for each channel are accumulated independently.
As a practical example, the next figure shows the calculation of the integral of a straight
rectangle Rect(3,3,3,2) and of a tilted rectangle Rect(5,1,2,3) . The selected pixels in the
original image are shown, as well as the relative pixels in the integral images sum and tilted .
![integral calculation example](pics/integral.png)
C<<< W \times H >>>, 8-bit or floating-point (32f or 64f).
C<<< (W+1)\times (H+1) >>>, 32-bit integer or floating-point (32f or 64f).
C<<< (W+1)\times (H+1) >>>, double-precision
floating-point (64f) array.
C<<< (W+1)\times (H+1) >>>array with
the same data type as sum.

Parameters:

=over

=item src

input image as

=item sum

integral image as

=item sqsum

integral image for squared pixel values; it is

=item tilted

integral for the image rotated by 45 degrees; it is

=item sdepth

desired depth of the integral and the tilted integral images, CV_32S, CV_32F, or
CV_64F.

=item sqdepth

desired depth of the integral image of squared pixel values, CV_32F or CV_64F.

=back


=for bad

integral ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4614 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::integral {
  barf "Usage: PDL::OpenCV::Imgproc::integral(\$src,\$sdepth,\$sqdepth)\n" if @_ < 1;
  my ($src,$sdepth,$sqdepth) = @_;
  my ($sum,$sqsum,$tilted);
  $sum = PDL->null if !defined $sum;
  $sqsum = PDL->null if !defined $sqsum;
  $tilted = PDL->null if !defined $tilted;
  $sdepth = -1 if !defined $sdepth;
  $sqdepth = -1 if !defined $sqdepth;
  PDL::OpenCV::Imgproc::_integral_int($src,$sum,$sqsum,$tilted,$sdepth,$sqdepth);
  !wantarray ? $tilted : ($sum,$sqsum,$tilted)
}
#line 4632 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*integral = \&PDL::OpenCV::Imgproc::integral;
#line 4639 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 integral2

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] sum(l2,c2,r2); int [phys] sdepth())

=for ref

 NO BROADCASTING.

=for example

 $sum = integral2($src); # with defaults
 $sum = integral2($src,$sdepth);

@overload

=for bad

integral2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4671 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::integral2 {
  barf "Usage: PDL::OpenCV::Imgproc::integral2(\$src,\$sdepth)\n" if @_ < 1;
  my ($src,$sdepth) = @_;
  my ($sum);
  $sum = PDL->null if !defined $sum;
  $sdepth = -1 if !defined $sdepth;
  PDL::OpenCV::Imgproc::_integral2_int($src,$sum,$sdepth);
  !wantarray ? $sum : ($sum)
}
#line 4686 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*integral2 = \&PDL::OpenCV::Imgproc::integral2;
#line 4693 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 integral3

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] sum(l2,c2,r2); [o,phys] sqsum(l3,c3,r3); int [phys] sdepth(); int [phys] sqdepth())

=for ref

 NO BROADCASTING.

=for example

 ($sum,$sqsum) = integral3($src); # with defaults
 ($sum,$sqsum) = integral3($src,$sdepth,$sqdepth);

@overload

=for bad

integral3 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4725 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::integral3 {
  barf "Usage: PDL::OpenCV::Imgproc::integral3(\$src,\$sdepth,\$sqdepth)\n" if @_ < 1;
  my ($src,$sdepth,$sqdepth) = @_;
  my ($sum,$sqsum);
  $sum = PDL->null if !defined $sum;
  $sqsum = PDL->null if !defined $sqsum;
  $sdepth = -1 if !defined $sdepth;
  $sqdepth = -1 if !defined $sqdepth;
  PDL::OpenCV::Imgproc::_integral3_int($src,$sum,$sqsum,$sdepth,$sqdepth);
  !wantarray ? $sqsum : ($sum,$sqsum)
}
#line 4742 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*integral3 = \&PDL::OpenCV::Imgproc::integral3;
#line 4749 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 accumulate

=for sig

  Signature: ([phys] src(l1,c1,r1); [io,phys] dst(l2,c2,r2); [phys] mask(l3,c3,r3))

=for ref

Adds an image to the accumulator image.

=for example

 accumulate($src,$dst); # with defaults
 accumulate($src,$dst,$mask);

The function adds src or some of its elements to dst :
\f[\texttt{dst} (x,y)  \leftarrow \texttt{dst} (x,y) +  \texttt{src} (x,y)  \quad \text{if} \quad \texttt{mask} (x,y)  \ne 0\f]
The function supports multi-channel images. Each channel is processed independently.
The function cv::accumulate can be used, for example, to collect statistics of a scene background
viewed by a still camera and for the further foreground-background segmentation.

Parameters:

=over

=item src

Input image of type CV_8UC(n), CV_16UC(n), CV_32FC(n) or CV_64FC(n), where n is a positive integer.

=item dst

%Accumulator image with the same number of channels as input image, and a depth of CV_32F or CV_64F.

=item mask

Optional operation mask.

=back

See also:
accumulateSquare, accumulateProduct, accumulateWeighted


=for bad

accumulate ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4807 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::accumulate {
  barf "Usage: PDL::OpenCV::Imgproc::accumulate(\$src,\$dst,\$mask)\n" if @_ < 2;
  my ($src,$dst,$mask) = @_;
    $mask = PDL->zeroes(sbyte,0,0,0) if !defined $mask;
  PDL::OpenCV::Imgproc::_accumulate_int($src,$dst,$mask);
  
}
#line 4820 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*accumulate = \&PDL::OpenCV::Imgproc::accumulate;
#line 4827 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 accumulateSquare

=for sig

  Signature: ([phys] src(l1,c1,r1); [io,phys] dst(l2,c2,r2); [phys] mask(l3,c3,r3))

=for ref

Adds the square of a source image to the accumulator image.

=for example

 accumulateSquare($src,$dst); # with defaults
 accumulateSquare($src,$dst,$mask);

The function adds the input image src or its selected region, raised to a power of 2, to the
accumulator dst :
\f[\texttt{dst} (x,y)  \leftarrow \texttt{dst} (x,y) +  \texttt{src} (x,y)^2  \quad \text{if} \quad \texttt{mask} (x,y)  \ne 0\f]
The function supports multi-channel images. Each channel is processed independently.

Parameters:

=over

=item src

Input image as 1- or 3-channel, 8-bit or 32-bit floating point.

=item dst

%Accumulator image with the same number of channels as input image, 32-bit or 64-bit
floating-point.

=item mask

Optional operation mask.

=back

See also:
accumulateSquare, accumulateProduct, accumulateWeighted


=for bad

accumulateSquare ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4885 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::accumulateSquare {
  barf "Usage: PDL::OpenCV::Imgproc::accumulateSquare(\$src,\$dst,\$mask)\n" if @_ < 2;
  my ($src,$dst,$mask) = @_;
    $mask = PDL->zeroes(sbyte,0,0,0) if !defined $mask;
  PDL::OpenCV::Imgproc::_accumulateSquare_int($src,$dst,$mask);
  
}
#line 4898 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*accumulateSquare = \&PDL::OpenCV::Imgproc::accumulateSquare;
#line 4905 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 accumulateProduct

=for sig

  Signature: ([phys] src1(l1,c1,r1); [phys] src2(l2,c2,r2); [io,phys] dst(l3,c3,r3); [phys] mask(l4,c4,r4))

=for ref

Adds the per-element product of two input images to the accumulator image.

=for example

 accumulateProduct($src1,$src2,$dst); # with defaults
 accumulateProduct($src1,$src2,$dst,$mask);

The function adds the product of two images or their selected regions to the accumulator dst :
\f[\texttt{dst} (x,y)  \leftarrow \texttt{dst} (x,y) +  \texttt{src1} (x,y)  \cdot \texttt{src2} (x,y)  \quad \text{if} \quad \texttt{mask} (x,y)  \ne 0\f]
The function supports multi-channel images. Each channel is processed independently.

Parameters:

=over

=item src1

First input image, 1- or 3-channel, 8-bit or 32-bit floating point.

=item src2

Second input image of the same type and the same size as src1 .

=item dst

%Accumulator image with the same number of channels as input images, 32-bit or 64-bit
floating-point.

=item mask

Optional operation mask.

=back

See also:
accumulate, accumulateSquare, accumulateWeighted


=for bad

accumulateProduct ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4966 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::accumulateProduct {
  barf "Usage: PDL::OpenCV::Imgproc::accumulateProduct(\$src1,\$src2,\$dst,\$mask)\n" if @_ < 3;
  my ($src1,$src2,$dst,$mask) = @_;
    $mask = PDL->zeroes(sbyte,0,0,0) if !defined $mask;
  PDL::OpenCV::Imgproc::_accumulateProduct_int($src1,$src2,$dst,$mask);
  
}
#line 4979 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*accumulateProduct = \&PDL::OpenCV::Imgproc::accumulateProduct;
#line 4986 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 accumulateWeighted

=for sig

  Signature: ([phys] src(l1,c1,r1); [io,phys] dst(l2,c2,r2); double [phys] alpha(); [phys] mask(l4,c4,r4))

=for ref

Updates a running average.

=for example

 accumulateWeighted($src,$dst,$alpha); # with defaults
 accumulateWeighted($src,$dst,$alpha,$mask);

The function calculates the weighted sum of the input image src and the accumulator dst so that dst
becomes a running average of a frame sequence:
\f[\texttt{dst} (x,y)  \leftarrow (1- \texttt{alpha} )  \cdot \texttt{dst} (x,y) +  \texttt{alpha} \cdot \texttt{src} (x,y)  \quad \text{if} \quad \texttt{mask} (x,y)  \ne 0\f]
That is, alpha regulates the update speed (how fast the accumulator "forgets" about earlier images).
The function supports multi-channel images. Each channel is processed independently.

Parameters:

=over

=item src

Input image as 1- or 3-channel, 8-bit or 32-bit floating point.

=item dst

%Accumulator image with the same number of channels as input image, 32-bit or 64-bit
floating-point.

=item alpha

Weight of the input image.

=item mask

Optional operation mask.

=back

See also:
accumulate, accumulateSquare, accumulateProduct


=for bad

accumulateWeighted ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5049 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::accumulateWeighted {
  barf "Usage: PDL::OpenCV::Imgproc::accumulateWeighted(\$src,\$dst,\$alpha,\$mask)\n" if @_ < 3;
  my ($src,$dst,$alpha,$mask) = @_;
    $mask = PDL->zeroes(sbyte,0,0,0) if !defined $mask;
  PDL::OpenCV::Imgproc::_accumulateWeighted_int($src,$dst,$alpha,$mask);
  
}
#line 5062 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*accumulateWeighted = \&PDL::OpenCV::Imgproc::accumulateWeighted;
#line 5069 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 phaseCorrelate

=for sig

  Signature: ([phys] src1(l1,c1,r1); [phys] src2(l2,c2,r2); [phys] window(l3,c3,r3); double [o,phys] response(); double [o,phys] res(n5=2))

=for ref

The function is used to detect translational shifts that occur between two images.

=for example

 ($response,$res) = phaseCorrelate($src1,$src2); # with defaults
 ($response,$res) = phaseCorrelate($src1,$src2,$window);

The operation takes advantage of the Fourier shift theorem for detecting the translational shift in
the frequency domain. It can be used for fast image registration as well as motion estimation. For
more information please see <http://en.wikipedia.org/wiki/Phase_correlation>
Calculates the cross-power spectrum of two supplied source arrays. The arrays are padded if needed
with getOptimalDFTSize.
The function performs the following equations:
=over
=back
C<<< \mathcal{F} >>>is the forward DFT.
- It then computes the cross-power spectrum of each frequency domain array:
\f[R = \frac{ \mathbf{G}_a \mathbf{G}_b^*}{|\mathbf{G}_a \mathbf{G}_b^*|}\f]
- Next the cross-correlation is converted back into the time domain via the inverse DFT:
\f[r = \mathcal{F}^{-1}\{R\}\f]
- Finally, it computes the peak location and computes a 5x5 weighted centroid around the peak to
achieve sub-pixel accuracy.
\f[(\Delta x, \Delta y) = \texttt{weightedCentroid} \{\arg \max_{(x, y)}\{r\}\}\f]
- If non-zero, the response parameter is computed as the sum of the elements of r within the 5x5
centroid around the peak location. It is normalized to a maximum of 1 (meaning there is a single
peak) and will be smaller when there are multiple peaks.

Parameters:

=over

=item src1

Source floating point array (CV_32FC1 or CV_64FC1)

=item src2

Source floating point array (CV_32FC1 or CV_64FC1)

=item window

Floating point array with windowing coefficients to reduce edge effects (optional).

=item response

Signal power within the 5x5 centroid around the peak, between 0 and 1 (optional).

=back

Returns: detected phase shift (sub-pixel) between the two arrays.

See also:
dft, getOptimalDFTSize, idft, mulSpectrums createHanningWindow


=for bad

phaseCorrelate ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5147 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::phaseCorrelate {
  barf "Usage: PDL::OpenCV::Imgproc::phaseCorrelate(\$src1,\$src2,\$window)\n" if @_ < 2;
  my ($src1,$src2,$window) = @_;
  my ($response,$res);
  $window = PDL->zeroes(sbyte,0,0,0) if !defined $window;
  $response = PDL->null if !defined $response;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgproc::_phaseCorrelate_int($src1,$src2,$window,$response,$res);
  !wantarray ? $res : ($response,$res)
}
#line 5163 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*phaseCorrelate = \&PDL::OpenCV::Imgproc::phaseCorrelate;
#line 5170 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 createHanningWindow

=for sig

  Signature: ([o,phys] dst(l1,c1,r1); indx [phys] winSize(n2=2); int [phys] type())

=for ref

This function computes a Hanning window coefficients in two dimensions. NO BROADCASTING.

=for example

 $dst = createHanningWindow($winSize,$type);

See (http://en.wikipedia.org/wiki/Hann_function) and (http://en.wikipedia.org/wiki/Window_function)
for more information.
An example is shown below:

     // create hanning window of size 100x100 and type CV_32F
     Mat hann;
     createHanningWindow(hann, Size(100, 100), CV_32F);

Parameters:

=over

=item dst

Destination array to place Hann coefficients in

=item winSize

The window size specifications (both width and height must be > 1)

=item type

Created array type

=back


=for bad

createHanningWindow ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5226 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::createHanningWindow {
  barf "Usage: PDL::OpenCV::Imgproc::createHanningWindow(\$winSize,\$type)\n" if @_ < 2;
  my ($winSize,$type) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::Imgproc::_createHanningWindow_int($dst,$winSize,$type);
  !wantarray ? $dst : ($dst)
}
#line 5240 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*createHanningWindow = \&PDL::OpenCV::Imgproc::createHanningWindow;
#line 5247 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 divSpectrums

=for sig

  Signature: ([phys] a(l1,c1,r1); [phys] b(l2,c2,r2); [o,phys] c(l3,c3,r3); int [phys] flags(); byte [phys] conjB())

=for ref

Performs the per-element division of the first Fourier spectrum by the second Fourier spectrum. NO BROADCASTING.

=for example

 $c = divSpectrums($a,$b,$flags); # with defaults
 $c = divSpectrums($a,$b,$flags,$conjB);

The function cv::divSpectrums performs the per-element division of the first array by the second array.
The arrays are CCS-packed or complex matrices that are results of a real or complex Fourier transform.

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

divSpectrums ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5309 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::divSpectrums {
  barf "Usage: PDL::OpenCV::Imgproc::divSpectrums(\$a,\$b,\$flags,\$conjB)\n" if @_ < 3;
  my ($a,$b,$flags,$conjB) = @_;
  my ($c);
  $c = PDL->null if !defined $c;
  $conjB = 0 if !defined $conjB;
  PDL::OpenCV::Imgproc::_divSpectrums_int($a,$b,$c,$flags,$conjB);
  !wantarray ? $c : ($c)
}
#line 5324 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*divSpectrums = \&PDL::OpenCV::Imgproc::divSpectrums;
#line 5331 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 threshold

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); double [phys] thresh(); double [phys] maxval(); int [phys] type(); double [o,phys] res())

=for ref

Applies a fixed-level threshold to each array element. NO BROADCASTING.

=for example

 ($dst,$res) = threshold($src,$thresh,$maxval,$type);

The function applies fixed-level thresholding to a multiple-channel array. The function is typically
used to get a bi-level (binary) image out of a grayscale image ( #compare could be also used for
this purpose) or for removing a noise, that is, filtering out pixels with too small or too large
values. There are several types of thresholding supported by the function. They are determined by
type parameter.
Also, the special values #THRESH_OTSU or #THRESH_TRIANGLE may be combined with one of the
above values. In these cases, the function determines the optimal threshold value using the Otsu's
or Triangle algorithm and uses it instead of the specified thresh.
@note Currently, the Otsu's and Triangle methods are implemented only for 8-bit single-channel images.

Parameters:

=over

=item src

input array (multiple-channel, 8-bit or 32-bit floating point).

=item dst

output array of the same size  and type and the same number of channels as src.

=item thresh

threshold value.

=item maxval

maximum value to use with the #THRESH_BINARY and #THRESH_BINARY_INV thresholding
types.

=item type

thresholding type (see #ThresholdTypes).

=back

Returns: the computed threshold value if Otsu's or Triangle methods used.

See also:
adaptiveThreshold, findContours, compare, min, max


=for bad

threshold ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5403 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::threshold {
  barf "Usage: PDL::OpenCV::Imgproc::threshold(\$src,\$thresh,\$maxval,\$type)\n" if @_ < 4;
  my ($src,$thresh,$maxval,$type) = @_;
  my ($dst,$res);
  $dst = PDL->null if !defined $dst;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgproc::_threshold_int($src,$dst,$thresh,$maxval,$type,$res);
  !wantarray ? $res : ($dst,$res)
}
#line 5418 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*threshold = \&PDL::OpenCV::Imgproc::threshold;
#line 5425 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 adaptiveThreshold

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); double [phys] maxValue(); int [phys] adaptiveMethod(); int [phys] thresholdType(); int [phys] blockSize(); double [phys] C())

=for ref

Applies an adaptive threshold to an array. NO BROADCASTING.

=for example

 $dst = adaptiveThreshold($src,$maxValue,$adaptiveMethod,$thresholdType,$blockSize,$C);

The function transforms a grayscale image to a binary image according to the formulae:
=over
=back
C<<< T(x,y) >>>is a threshold calculated individually for each pixel (see adaptiveMethod parameter).
The function can process the image in-place.

Parameters:

=over

=item src

Source 8-bit single-channel image.

=item dst

Destination image of the same size and the same type as src.

=item maxValue

Non-zero value assigned to the pixels for which the condition is satisfied

=item adaptiveMethod

Adaptive thresholding algorithm to use, see #AdaptiveThresholdTypes.
The #BORDER_REPLICATE | #BORDER_ISOLATED is used to process boundaries.

=item thresholdType

Thresholding type that must be either #THRESH_BINARY or #THRESH_BINARY_INV,
see #ThresholdTypes.

=item blockSize

Size of a pixel neighborhood that is used to calculate a threshold value for the
pixel: 3, 5, 7, and so on.

=item C

Constant subtracted from the mean or weighted mean (see the details below). Normally, it
is positive but may be zero or negative as well.

=back

See also:
threshold, blur, GaussianBlur


=for bad

adaptiveThreshold ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5502 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::adaptiveThreshold {
  barf "Usage: PDL::OpenCV::Imgproc::adaptiveThreshold(\$src,\$maxValue,\$adaptiveMethod,\$thresholdType,\$blockSize,\$C)\n" if @_ < 6;
  my ($src,$maxValue,$adaptiveMethod,$thresholdType,$blockSize,$C) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::Imgproc::_adaptiveThreshold_int($src,$dst,$maxValue,$adaptiveMethod,$thresholdType,$blockSize,$C);
  !wantarray ? $dst : ($dst)
}
#line 5516 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*adaptiveThreshold = \&PDL::OpenCV::Imgproc::adaptiveThreshold;
#line 5523 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 pyrDown

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); indx [phys] dstsize(n3); int [phys] borderType())

=for ref

Blurs an image and downsamples it. NO BROADCASTING.

=for example

 $dst = pyrDown($src); # with defaults
 $dst = pyrDown($src,$dstsize,$borderType);

By default, size of the output image is computed as `Size((src.cols+1)/2, (src.rows+1)/2)`, but in
any case, the following conditions should be satisfied:
\f[\begin{array}{l} | \texttt{dstsize.width} *2-src.cols| \leq 2 \\ | \texttt{dstsize.height} *2-src.rows| \leq 2 \end{array}\f]
The function performs the downsampling step of the Gaussian pyramid construction. First, it
convolves the source image with the kernel:
\f[\frac{1}{256} \begin{bmatrix} 1 & 4 & 6 & 4 & 1  \\ 4 & 16 & 24 & 16 & 4  \\ 6 & 24 & 36 & 24 & 6  \\ 4 & 16 & 24 & 16 & 4  \\ 1 & 4 & 6 & 4 & 1 \end{bmatrix}\f]
Then, it downsamples the image by rejecting even rows and columns.

Parameters:

=over

=item src

input image.

=item dst

output image; it has the specified size and the same type as src.

=item dstsize

size of the output image.

=item borderType

Pixel extrapolation method, see #BorderTypes (#BORDER_CONSTANT isn't supported)

=back


=for bad

pyrDown ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5584 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::pyrDown {
  barf "Usage: PDL::OpenCV::Imgproc::pyrDown(\$src,\$dstsize,\$borderType)\n" if @_ < 1;
  my ($src,$dstsize,$borderType) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $dstsize = empty(indx) if !defined $dstsize;
  $borderType = BORDER_DEFAULT() if !defined $borderType;
  PDL::OpenCV::Imgproc::_pyrDown_int($src,$dst,$dstsize,$borderType);
  !wantarray ? $dst : ($dst)
}
#line 5600 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*pyrDown = \&PDL::OpenCV::Imgproc::pyrDown;
#line 5607 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 pyrUp

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); indx [phys] dstsize(n3); int [phys] borderType())

=for ref

Upsamples an image and then blurs it. NO BROADCASTING.

=for example

 $dst = pyrUp($src); # with defaults
 $dst = pyrUp($src,$dstsize,$borderType);

By default, size of the output image is computed as `Size(src.cols*2, (src.rows*2)`, but in any
case, the following conditions should be satisfied:
\f[\begin{array}{l} | \texttt{dstsize.width} -src.cols*2| \leq  ( \texttt{dstsize.width}   \mod  2)  \\ | \texttt{dstsize.height} -src.rows*2| \leq  ( \texttt{dstsize.height}   \mod  2) \end{array}\f]
The function performs the upsampling step of the Gaussian pyramid construction, though it can
actually be used to construct the Laplacian pyramid. First, it upsamples the source image by
injecting even zero rows and columns and then convolves the result with the same kernel as in
pyrDown multiplied by 4.

Parameters:

=over

=item src

input image.

=item dst

output image. It has the specified size and the same type as src .

=item dstsize

size of the output image.

=item borderType

Pixel extrapolation method, see #BorderTypes (only #BORDER_DEFAULT is supported)

=back


=for bad

pyrUp ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5668 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::pyrUp {
  barf "Usage: PDL::OpenCV::Imgproc::pyrUp(\$src,\$dstsize,\$borderType)\n" if @_ < 1;
  my ($src,$dstsize,$borderType) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $dstsize = empty(indx) if !defined $dstsize;
  $borderType = BORDER_DEFAULT() if !defined $borderType;
  PDL::OpenCV::Imgproc::_pyrUp_int($src,$dst,$dstsize,$borderType);
  !wantarray ? $dst : ($dst)
}
#line 5684 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*pyrUp = \&PDL::OpenCV::Imgproc::pyrUp;
#line 5691 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 calcHist

=for sig

  Signature: (int [phys] channels(n2d0); [phys] mask(l3,c3,r3); [o,phys] hist(l4,c4,r4); int [phys] histSize(n5d0); float [phys] ranges(n6d0); byte [phys] accumulate(); vector_MatWrapper * images)

=for ref

 NO BROADCASTING.

=for example

 $hist = calcHist($images,$channels,$mask,$histSize,$ranges); # with defaults
 $hist = calcHist($images,$channels,$mask,$histSize,$ranges,$accumulate);

@overload

=for bad

calcHist ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5723 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::calcHist {
  barf "Usage: PDL::OpenCV::Imgproc::calcHist(\$images,\$channels,\$mask,\$histSize,\$ranges,\$accumulate)\n" if @_ < 5;
  my ($images,$channels,$mask,$histSize,$ranges,$accumulate) = @_;
  my ($hist);
  $hist = PDL->null if !defined $hist;
  $accumulate = 0 if !defined $accumulate;
  PDL::OpenCV::Imgproc::_calcHist_int($channels,$mask,$hist,$histSize,$ranges,$accumulate,$images);
  !wantarray ? $hist : ($hist)
}
#line 5738 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*calcHist = \&PDL::OpenCV::Imgproc::calcHist;
#line 5745 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 calcBackProject

=for sig

  Signature: (int [phys] channels(n2d0); [phys] hist(l3,c3,r3); [o,phys] dst(l4,c4,r4); float [phys] ranges(n5d0); double [phys] scale(); vector_MatWrapper * images)

=for ref

 NO BROADCASTING.

=for example

 $dst = calcBackProject($images,$channels,$hist,$ranges,$scale);

@overload

=for bad

calcBackProject ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5776 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::calcBackProject {
  barf "Usage: PDL::OpenCV::Imgproc::calcBackProject(\$images,\$channels,\$hist,\$ranges,\$scale)\n" if @_ < 5;
  my ($images,$channels,$hist,$ranges,$scale) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::Imgproc::_calcBackProject_int($channels,$hist,$dst,$ranges,$scale,$images);
  !wantarray ? $dst : ($dst)
}
#line 5790 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*calcBackProject = \&PDL::OpenCV::Imgproc::calcBackProject;
#line 5797 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 compareHist

=for sig

  Signature: ([phys] H1(l1,c1,r1); [phys] H2(l2,c2,r2); int [phys] method(); double [o,phys] res())

=for ref

Compares two histograms.

=for example

 $res = compareHist($H1,$H2,$method);

The function cv::compareHist compares two dense or two sparse histograms using the specified method.
The function returns C<<< d(H_1, H_2) >>>.
While the function works well with 1-, 2-, 3-dimensional dense histograms, it may not be suitable
for high-dimensional sparse histograms. In such histograms, because of aliasing and sampling
problems, the coordinates of non-zero histogram bins can slightly shift. To compare such histograms
or more general sparse configurations of weighted points, consider using the #EMD function.

Parameters:

=over

=item H1

First compared histogram.

=item H2

Second compared histogram of the same size as H1 .

=item method

Comparison method, see #HistCompMethods

=back


=for bad

compareHist ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5852 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::compareHist {
  barf "Usage: PDL::OpenCV::Imgproc::compareHist(\$H1,\$H2,\$method)\n" if @_ < 3;
  my ($H1,$H2,$method) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgproc::_compareHist_int($H1,$H2,$method,$res);
  !wantarray ? $res : ($res)
}
#line 5866 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*compareHist = \&PDL::OpenCV::Imgproc::compareHist;
#line 5873 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 equalizeHist

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2))

=for ref

Equalizes the histogram of a grayscale image. NO BROADCASTING.

=for example

 $dst = equalizeHist($src);

The function equalizes the histogram of the input image using the following algorithm:
- Calculate the histogram C<<< H >>>for src .
- Normalize the histogram so that the sum of histogram bins is 255.
- Compute the integral of the histogram:
\f[H'_i =  \sum _{0  \le j < i} H(j)\f]
- Transform the image using C<<< H' >>>as a look-up table: C<<< \texttt{dst}(x,y) = H'(\texttt{src}(x,y)) >>>The algorithm normalizes the brightness and increases the contrast of the image.

Parameters:

=over

=item src

Source 8-bit single channel image.

=item dst

Destination image of the same size and type as src .

=back


=for bad

equalizeHist ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5924 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::equalizeHist {
  barf "Usage: PDL::OpenCV::Imgproc::equalizeHist(\$src)\n" if @_ < 1;
  my ($src) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::Imgproc::_equalizeHist_int($src,$dst);
  !wantarray ? $dst : ($dst)
}
#line 5938 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*equalizeHist = \&PDL::OpenCV::Imgproc::equalizeHist;
#line 5945 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 EMD

=for sig

  Signature: ([phys] signature1(l1,c1,r1); [phys] signature2(l2,c2,r2); int [phys] distType(); [phys] cost(l4,c4,r4); float [io,phys] lowerBound(n5); [o,phys] flow(l6,c6,r6); float [o,phys] res())

=for ref

Computes the "minimal work" distance between two weighted point configurations. NO BROADCASTING.

=for example

 ($flow,$res) = EMD($signature1,$signature2,$distType); # with defaults
 ($flow,$res) = EMD($signature1,$signature2,$distType,$cost,$lowerBound);

The function computes the earth mover distance and/or a lower boundary of the distance between the
two weighted point configurations. One of the applications described in @cite RubnerSept98,
@cite Rubner2000 is multi-dimensional histogram comparison for image retrieval. EMD is a transportation
problem that is solved using some modification of a simplex algorithm, thus the complexity is
exponential in the worst case, though, on average it is much faster. In the case of a real metric
the lower boundary can be calculated even faster (using linear-time algorithm) and it can be used
to determine roughly whether the two signatures are far enough so that they cannot relate to the
same object.
C<<< \texttt{size1}\times \texttt{dims}+1 >>>floating-point matrix.
Each row stores the point weight followed by the point coordinates. The matrix is allowed to have
a single column (weights only) if the user-defined cost matrix is used. The weights must be
non-negative and have at least one non-zero value.
C<<< \texttt{size1}\times \texttt{size2} >>>cost matrix. Also, if a cost matrix
is used, lower boundary lowerBound cannot be calculated because it needs a metric function.
*lowerBound . If the calculated distance between mass centers is greater or
equal to *lowerBound (it means that the signatures are far enough), the function does not
calculate EMD. In any case *lowerBound is set to the calculated distance between mass centers on
return. Thus, if you want to calculate both distance between mass centers and EMD, *lowerBound
should be set to 0.
C<<< \texttt{size1} \times \texttt{size2} >>>flow matrix: C<<< \texttt{flow}_{i,j} >>>is
a flow from C<<< i >>>-th point of signature1 to C<<< j >>>-th point of signature2 .

Parameters:

=over

=item signature1

First signature, a

=item signature2

Second signature of the same format as signature1 , though the number of rows
may be different. The total weights may be different. In this case an extra "dummy" point is added
to either signature1 or signature2. The weights must be non-negative and have at least one non-zero
value.

=item distType

Used metric. See #DistanceTypes.

=item cost

User-defined

=item lowerBound

Optional input/output parameter: lower boundary of a distance between the two
signatures that is a distance between mass centers. The lower boundary may not be calculated if
the user-defined cost matrix is used, the total weights of point configurations are not equal, or
if the signatures consist of weights only (the signature matrices have a single column). You
**must** initialize

=item flow

Resultant

=back


=for bad

EMD ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6035 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::EMD {
  barf "Usage: PDL::OpenCV::Imgproc::EMD(\$signature1,\$signature2,\$distType,\$cost,\$lowerBound)\n" if @_ < 3;
  my ($signature1,$signature2,$distType,$cost,$lowerBound) = @_;
  my ($flow,$res);
  $cost = PDL->zeroes(sbyte,0,0,0) if !defined $cost;
  $lowerBound = empty(float) if !defined $lowerBound;
  $flow = PDL->null if !defined $flow;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgproc::_EMD_int($signature1,$signature2,$distType,$cost,$lowerBound,$flow,$res);
  !wantarray ? $res : ($flow,$res)
}
#line 6052 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*EMD = \&PDL::OpenCV::Imgproc::EMD;
#line 6059 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 watershed

=for sig

  Signature: ([phys] image(l1,c1,r1); [io,phys] markers(l2,c2,r2))

=for ref

Performs a marker-based image segmentation using the watershed algorithm.

=for example

 watershed($image,$markers);

The function implements one of the variants of watershed, non-parametric marker-based segmentation
algorithm, described in @cite Meyer92 .
Before passing the image to the function, you have to roughly outline the desired regions in the
image markers with positive (\>0) indices. So, every region is represented as one or more connected
components with the pixel values 1, 2, 3, and so on. Such markers can be retrieved from a binary
mask using #findContours and #drawContours (see the watershed.cpp demo). The markers are "seeds" of
the future image regions. All the other pixels in markers , whose relation to the outlined regions
is not known and should be defined by the algorithm, should be set to 0's. In the function output,
each pixel in markers is set to a value of the "seed" components or to -1 at boundaries between the
regions.
@note Any two neighbor connected components are not necessarily separated by a watershed boundary
(-1's pixels); for example, they can touch each other in the initial marker image passed to the
function.

Parameters:

=over

=item image

Input 8-bit 3-channel image.

=item markers

Input/output 32-bit single-channel image (map) of markers. It should have the same
size as image .

=back

See also:
findContours


=for bad

watershed ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6121 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::watershed {
  barf "Usage: PDL::OpenCV::Imgproc::watershed(\$image,\$markers)\n" if @_ < 2;
  my ($image,$markers) = @_;
    
  PDL::OpenCV::Imgproc::_watershed_int($image,$markers);
  
}
#line 6134 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*watershed = \&PDL::OpenCV::Imgproc::watershed;
#line 6141 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 pyrMeanShiftFiltering

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); double [phys] sp(); double [phys] sr(); int [phys] maxLevel(); TermCriteriaWrapper * termcrit)

=for ref

Performs initial step of meanshift segmentation of an image. NO BROADCASTING.

=for example

 $dst = pyrMeanShiftFiltering($src,$sp,$sr); # with defaults
 $dst = pyrMeanShiftFiltering($src,$sp,$sr,$maxLevel,$termcrit);

The function implements the filtering stage of meanshift segmentation, that is, the output of the
function is the filtered "posterized" image with color gradients and fine-grain texture flattened.
At every pixel (X,Y) of the input image (or down-sized input image, see below) the function executes
meanshift iterations, that is, the pixel (X,Y) neighborhood in the joint space-color hyperspace is
considered:
\f[(x,y): X- \texttt{sp} \le x  \le X+ \texttt{sp} , Y- \texttt{sp} \le y  \le Y+ \texttt{sp} , ||(R,G,B)-(r,g,b)||   \le \texttt{sr}\f]
where (R,G,B) and (r,g,b) are the vectors of color components at (X,Y) and (x,y), respectively
(though, the algorithm does not depend on the color space used, so any 3-component color space can
be used instead). Over the neighborhood the average spatial value (X',Y') and average color vector
(R',G',B') are found and they act as the neighborhood center on the next iteration:
\f[(X,Y)~(X',Y'), (R,G,B)~(R',G',B').\f]
After the iterations over, the color components of the initial pixel (that is, the pixel from where
the iterations started) are set to the final value (average color at the last iteration):
\f[I(X,Y) <- (R*,G*,B*)\f]
When maxLevel \> 0, the gaussian pyramid of maxLevel+1 levels is built, and the above procedure is
run on the smallest layer first. After that, the results are propagated to the larger layer and the
iterations are run again only on those pixels where the layer colors differ by more than sr from the
lower-resolution layer of the pyramid. That makes boundaries of color regions sharper. Note that the
results will be actually different from the ones obtained by running the meanshift procedure on the
whole original image (i.e. when maxLevel==0).

Parameters:

=over

=item src

The source 8-bit, 3-channel image.

=item dst

The destination image of the same format and the same size as the source.

=item sp

The spatial window radius.

=item sr

The color window radius.

=item maxLevel

Maximum level of the pyramid for the segmentation.

=item termcrit

Termination criteria: when to stop meanshift iterations.

=back


=for bad

pyrMeanShiftFiltering ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6223 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::pyrMeanShiftFiltering {
  barf "Usage: PDL::OpenCV::Imgproc::pyrMeanShiftFiltering(\$src,\$sp,\$sr,\$maxLevel,\$termcrit)\n" if @_ < 3;
  my ($src,$sp,$sr,$maxLevel,$termcrit) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $maxLevel = 1 if !defined $maxLevel;
  $termcrit = PDL::OpenCV::TermCriteria->new2(PDL::OpenCV::TermCriteria::MAX_ITER()+PDL::OpenCV::TermCriteria::EPS(),5,1) if !defined $termcrit;
  PDL::OpenCV::Imgproc::_pyrMeanShiftFiltering_int($src,$dst,$sp,$sr,$maxLevel,$termcrit);
  !wantarray ? $dst : ($dst)
}
#line 6239 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*pyrMeanShiftFiltering = \&PDL::OpenCV::Imgproc::pyrMeanShiftFiltering;
#line 6246 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 grabCut

=for sig

  Signature: ([phys] img(l1,c1,r1); [io,phys] mask(l2,c2,r2); indx [phys] rect(n3=4); [io,phys] bgdModel(l4,c4,r4); [io,phys] fgdModel(l5,c5,r5); int [phys] iterCount(); int [phys] mode())

=for ref

Runs the GrabCut algorithm.

=for example

 grabCut($img,$mask,$rect,$bgdModel,$fgdModel,$iterCount); # with defaults
 grabCut($img,$mask,$rect,$bgdModel,$fgdModel,$iterCount,$mode);

The function implements the [GrabCut image segmentation algorithm](http://en.wikipedia.org/wiki/GrabCut).

Parameters:

=over

=item img

Input 8-bit 3-channel image.

=item mask

Input/output 8-bit single-channel mask. The mask is initialized by the function when
mode is set to #GC_INIT_WITH_RECT. Its elements may have one of the #GrabCutClasses.

=item rect

ROI containing a segmented object. The pixels outside of the ROI are marked as
"obvious background". The parameter is only used when mode==#GC_INIT_WITH_RECT .

=item bgdModel

Temporary array for the background model. Do not modify it while you are
processing the same image.

=item fgdModel

Temporary arrays for the foreground model. Do not modify it while you are
processing the same image.

=item iterCount

Number of iterations the algorithm should make before returning the result. Note
that the result can be refined with further calls with mode==#GC_INIT_WITH_MASK or
mode==GC_EVAL .

=item mode

Operation mode that could be one of the #GrabCutModes

=back


=for bad

grabCut ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6319 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::grabCut {
  barf "Usage: PDL::OpenCV::Imgproc::grabCut(\$img,\$mask,\$rect,\$bgdModel,\$fgdModel,\$iterCount,\$mode)\n" if @_ < 6;
  my ($img,$mask,$rect,$bgdModel,$fgdModel,$iterCount,$mode) = @_;
    $mode = GC_EVAL() if !defined $mode;
  PDL::OpenCV::Imgproc::_grabCut_int($img,$mask,$rect,$bgdModel,$fgdModel,$iterCount,$mode);
  
}
#line 6332 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*grabCut = \&PDL::OpenCV::Imgproc::grabCut;
#line 6339 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 distanceTransformWithLabels

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); [o,phys] labels(l3,c3,r3); int [phys] distanceType(); int [phys] maskSize(); int [phys] labelType())

=for ref

Calculates the distance to the closest zero pixel for each pixel of the source image. NO BROADCASTING.

=for example

 ($dst,$labels) = distanceTransformWithLabels($src,$distanceType,$maskSize); # with defaults
 ($dst,$labels) = distanceTransformWithLabels($src,$distanceType,$maskSize,$labelType);

The function cv::distanceTransform calculates the approximate or precise distance from every binary
image pixel to the nearest zero pixel. For zero image pixels, the distance will obviously be zero.
When maskSize == #DIST_MASK_PRECISE and distanceType == #DIST_L2 , the function runs the
algorithm described in @cite Felzenszwalb04 . This algorithm is parallelized with the TBB library.
In other cases, the algorithm @cite Borgefors86 is used. This means that for a pixel the function
finds the shortest path to the nearest zero pixel consisting of basic shifts: horizontal, vertical,
diagonal, or knight's move (the latest is available for a C<<< 5\times 5 >>>mask). The overall
distance is calculated as a sum of these basic distances. Since the distance function should be
symmetric, all of the horizontal and vertical shifts must have the same cost (denoted as a ), all
the diagonal shifts must have the same cost (denoted as `b`), and all knight's moves must have the
same cost (denoted as `c`). For the #DIST_C and #DIST_L1 types, the distance is calculated
precisely, whereas for #DIST_L2 (Euclidean distance) the distance can be calculated only with a
relative error (a C<<< 5\times 5 >>>mask gives more accurate results). For `a`,`b`, and `c`, OpenCV
uses the values suggested in the original paper:
=over
=item *
DIST_L1: `a = 1, b = 2`
=item *
DIST_C: `a = 1, b = 1`
=back
Typically, for a fast, coarse distance estimation #DIST_L2, a C<<< 3\times 3 >>>mask is used. For a
more accurate distance estimation #DIST_L2, a C<<< 5\times 5 >>>mask or the precise algorithm is used.
Note that both the precise and the approximate algorithms are linear on the number of pixels.
This variant of the function does not only compute the minimum distance for each pixel C<<< (x, y) >>>but also identifies the nearest connected component consisting of zero pixels
(labelType==#DIST_LABEL_CCOMP) or the nearest zero pixel (labelType==#DIST_LABEL_PIXEL). Index of the
component/pixel is stored in `labels(x, y)`. When labelType==#DIST_LABEL_CCOMP, the function
automatically finds connected components of zero pixels in the input image and marks them with
distinct labels. When labelType==#DIST_LABEL_PIXEL, the function scans through the input image and
marks all the zero pixels with distinct labels.
In this mode, the complexity is still linear. That is, the function provides a very fast way to
compute the Voronoi diagram for a binary image. Currently, the second variant can use only the
approximate distance transform algorithm, i.e. maskSize=#DIST_MASK_PRECISE is not supported
yet.
C<<< 3\times 3 >>>mask gives the same result as C<<< 5\times
5 >>>or any larger aperture.

Parameters:

=over

=item src

8-bit, single-channel (binary) source image.

=item dst

Output image with calculated distances. It is a 8-bit or 32-bit floating-point,
single-channel image of the same size as src.

=item labels

Output 2D array of labels (the discrete Voronoi diagram). It has the type
CV_32SC1 and the same size as src.

=item distanceType

Type of distance, see #DistanceTypes

=item maskSize

Size of the distance transform mask, see #DistanceTransformMasks.
#DIST_MASK_PRECISE is not supported by this variant. In case of the #DIST_L1 or #DIST_C distance type,
the parameter is forced to 3 because a

=item labelType

Type of the label array to build, see #DistanceTransformLabelTypes.

=back


=for bad

distanceTransformWithLabels ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6440 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::distanceTransformWithLabels {
  barf "Usage: PDL::OpenCV::Imgproc::distanceTransformWithLabels(\$src,\$distanceType,\$maskSize,\$labelType)\n" if @_ < 3;
  my ($src,$distanceType,$maskSize,$labelType) = @_;
  my ($dst,$labels);
  $dst = PDL->null if !defined $dst;
  $labels = PDL->null if !defined $labels;
  $labelType = DIST_LABEL_CCOMP() if !defined $labelType;
  PDL::OpenCV::Imgproc::_distanceTransformWithLabels_int($src,$dst,$labels,$distanceType,$maskSize,$labelType);
  !wantarray ? $labels : ($dst,$labels)
}
#line 6456 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*distanceTransformWithLabels = \&PDL::OpenCV::Imgproc::distanceTransformWithLabels;
#line 6463 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 distanceTransform

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] distanceType(); int [phys] maskSize(); int [phys] dstType())

=for ref

 NO BROADCASTING.

=for example

 $dst = distanceTransform($src,$distanceType,$maskSize); # with defaults
 $dst = distanceTransform($src,$distanceType,$maskSize,$dstType);

@overload
C<<< 3\times 3 >>>mask gives
the same result as C<<< 5\times 5 >>>or any larger aperture.

Parameters:

=over

=item src

8-bit, single-channel (binary) source image.

=item dst

Output image with calculated distances. It is a 8-bit or 32-bit floating-point,
single-channel image of the same size as src .

=item distanceType

Type of distance, see #DistanceTypes

=item maskSize

Size of the distance transform mask, see #DistanceTransformMasks. In case of the
#DIST_L1 or #DIST_C distance type, the parameter is forced to 3 because a

=item dstType

Type of output image. It can be CV_8U or CV_32F. Type CV_8U can be used only for
the first variant of the function and distanceType == #DIST_L1.

=back


=for bad

distanceTransform ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6527 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::distanceTransform {
  barf "Usage: PDL::OpenCV::Imgproc::distanceTransform(\$src,\$distanceType,\$maskSize,\$dstType)\n" if @_ < 3;
  my ($src,$distanceType,$maskSize,$dstType) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $dstType = CV_32F() if !defined $dstType;
  PDL::OpenCV::Imgproc::_distanceTransform_int($src,$dst,$distanceType,$maskSize,$dstType);
  !wantarray ? $dst : ($dst)
}
#line 6542 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*distanceTransform = \&PDL::OpenCV::Imgproc::distanceTransform;
#line 6549 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 floodFill

=for sig

  Signature: ([io,phys] image(l1,c1,r1); [io,phys] mask(l2,c2,r2); indx [phys] seedPoint(n3=2); double [phys] newVal(n4=4); indx [o,phys] rect(n5=4); double [phys] loDiff(n6); double [phys] upDiff(n7); int [phys] flags(); int [o,phys] res())

=for ref

Fills a connected component with the given color.

=for example

 ($rect,$res) = floodFill($image,$mask,$seedPoint,$newVal); # with defaults
 ($rect,$res) = floodFill($image,$mask,$seedPoint,$newVal,$loDiff,$upDiff,$flags);

The function cv::floodFill fills a connected component starting from the seed point with the specified
color. The connectivity is determined by the color/brightness closeness of the neighbor pixels. The
pixel at C<<< (x,y) >>>is considered to belong to the repainted domain if:
- in case of a grayscale image and floating range
\f[\texttt{src} (x',y')- \texttt{loDiff} \leq \texttt{src} (x,y)  \leq \texttt{src} (x',y')+ \texttt{upDiff}\f]
- in case of a grayscale image and fixed range
\f[\texttt{src} ( \texttt{seedPoint} .x, \texttt{seedPoint} .y)- \texttt{loDiff} \leq \texttt{src} (x,y)  \leq \texttt{src} ( \texttt{seedPoint} .x, \texttt{seedPoint} .y)+ \texttt{upDiff}\f]
- in case of a color image and floating range
\f[\texttt{src} (x',y')_r- \texttt{loDiff} _r \leq \texttt{src} (x,y)_r \leq \texttt{src} (x',y')_r+ \texttt{upDiff} _r,\f]
\f[\texttt{src} (x',y')_g- \texttt{loDiff} _g \leq \texttt{src} (x,y)_g \leq \texttt{src} (x',y')_g+ \texttt{upDiff} _g\f]
and
\f[\texttt{src} (x',y')_b- \texttt{loDiff} _b \leq \texttt{src} (x,y)_b \leq \texttt{src} (x',y')_b+ \texttt{upDiff} _b\f]
- in case of a color image and fixed range
\f[\texttt{src} ( \texttt{seedPoint} .x, \texttt{seedPoint} .y)_r- \texttt{loDiff} _r \leq \texttt{src} (x,y)_r \leq \texttt{src} ( \texttt{seedPoint} .x, \texttt{seedPoint} .y)_r+ \texttt{upDiff} _r,\f]
\f[\texttt{src} ( \texttt{seedPoint} .x, \texttt{seedPoint} .y)_g- \texttt{loDiff} _g \leq \texttt{src} (x,y)_g \leq \texttt{src} ( \texttt{seedPoint} .x, \texttt{seedPoint} .y)_g+ \texttt{upDiff} _g\f]
and
\f[\texttt{src} ( \texttt{seedPoint} .x, \texttt{seedPoint} .y)_b- \texttt{loDiff} _b \leq \texttt{src} (x,y)_b \leq \texttt{src} ( \texttt{seedPoint} .x, \texttt{seedPoint} .y)_b+ \texttt{upDiff} _b\f]
where C<<< src(x',y') >>>is the value of one of pixel neighbors that is already known to belong to the
component. That is, to be added to the connected component, a color/brightness of the pixel should
be close enough to:
=over
=item *
Color/brightness of the seed point in case of a fixed range.
=back
Use these functions to either mark a connected component with the specified color in-place, or build
a mask and then extract the contour, or copy the region to another image, and so on.
\<\< 8 ) will consider 4 nearest
neighbours and fill the mask with a value of 255. The following additional options occupy higher
bits and therefore may be further combined with the connectivity and mask fill values using
bit-wise or (|), see #FloodFillFlags.
@note Since the mask is larger than the filled image, a pixel C<<< (x, y) >>>in image corresponds to the
pixel C<<< (x+1, y+1) >>>in the mask .

Parameters:

=over

=item image

Input/output 1- or 3-channel, 8-bit, or floating-point image. It is modified by the
function unless the #FLOODFILL_MASK_ONLY flag is set in the second variant of the function. See
the details below.

=item mask

Operation mask that should be a single-channel 8-bit image, 2 pixels wider and 2 pixels
taller than image. Since this is both an input and output parameter, you must take responsibility
of initializing it. Flood-filling cannot go across non-zero pixels in the input mask. For example,
an edge detector output can be used as a mask to stop filling at edges. On output, pixels in the
mask corresponding to filled pixels in the image are set to 1 or to the a value specified in flags
as described below. Additionally, the function fills the border of the mask with ones to simplify
internal processing. It is therefore possible to use the same mask in multiple calls to the function
to make sure the filled areas do not overlap.

=item seedPoint

Starting point.

=item newVal

New value of the repainted domain pixels.

=item loDiff

Maximal lower brightness/color difference between the currently observed pixel and
one of its neighbors belonging to the component, or a seed pixel being added to the component.

=item upDiff

Maximal upper brightness/color difference between the currently observed pixel and
one of its neighbors belonging to the component, or a seed pixel being added to the component.

=item rect

Optional output parameter set by the function to the minimum bounding rectangle of the
repainted domain.

=item flags

Operation flags. The first 8 bits contain a connectivity value. The default value of
4 means that only the four nearest neighbor pixels (those that share an edge) are considered. A
connectivity value of 8 means that the eight nearest neighbor pixels (those that share a corner)
will be considered. The next 8 bits (8-16) contain a value between 1 and 255 with which to fill
the mask (the default value is 1). For example, 4 | ( 255

=back

See also:
findContours


=for bad

floodFill ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6670 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::floodFill {
  barf "Usage: PDL::OpenCV::Imgproc::floodFill(\$image,\$mask,\$seedPoint,\$newVal,\$loDiff,\$upDiff,\$flags)\n" if @_ < 4;
  my ($image,$mask,$seedPoint,$newVal,$loDiff,$upDiff,$flags) = @_;
  my ($rect,$res);
  $rect = PDL->null if !defined $rect;
  $loDiff = empty(double) if !defined $loDiff;
  $upDiff = empty(double) if !defined $upDiff;
  $flags = 4 if !defined $flags;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgproc::_floodFill_int($image,$mask,$seedPoint,$newVal,$rect,$loDiff,$upDiff,$flags,$res);
  !wantarray ? $res : ($rect,$res)
}
#line 6688 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*floodFill = \&PDL::OpenCV::Imgproc::floodFill;
#line 6695 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 blendLinear

=for sig

  Signature: ([phys] src1(l1,c1,r1); [phys] src2(l2,c2,r2); [phys] weights1(l3,c3,r3); [phys] weights2(l4,c4,r4); [o,phys] dst(l5,c5,r5))

=for ref

 NO BROADCASTING.

=for example

 $dst = blendLinear($src1,$src2,$weights1,$weights2);

@overload
variant without `mask` parameter

=for bad

blendLinear ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6727 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::blendLinear {
  barf "Usage: PDL::OpenCV::Imgproc::blendLinear(\$src1,\$src2,\$weights1,\$weights2)\n" if @_ < 4;
  my ($src1,$src2,$weights1,$weights2) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::Imgproc::_blendLinear_int($src1,$src2,$weights1,$weights2,$dst);
  !wantarray ? $dst : ($dst)
}
#line 6741 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*blendLinear = \&PDL::OpenCV::Imgproc::blendLinear;
#line 6748 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 cvtColor

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] code(); int [phys] dstCn())

=for ref

Converts an image from one color space to another. NO BROADCASTING.

=for example

 $dst = cvtColor($src,$code); # with defaults
 $dst = cvtColor($src,$code,$dstCn);

The function converts an input image from one color space to another. In case of a transformation
to-from RGB color space, the order of the channels should be specified explicitly (RGB or BGR). Note
that the default color format in OpenCV is often referred to as RGB but it is actually BGR (the
bytes are reversed). So the first byte in a standard (24-bit) color image will be an 8-bit Blue
component, the second byte will be Green, and the third byte will be Red. The fourth, fifth, and
sixth bytes would then be the second pixel (Blue, then Green, then Red), and so on.
The conventional ranges for R, G, and B channel values are:
=over
=item *
0 to 255 for CV_8U images
=item *
0 to 65535 for CV_16U images
=item *
0 to 1 for CV_32F images
=back
In case of linear transformations, the range does not matter. But in case of a non-linear
transformation, an input RGB image should be normalized to the proper value range to get the correct
results, for example, for RGB C<<< \rightarrow >>>L*u*v* transformation. For example, if you have a
32-bit floating-point image directly converted from an 8-bit image without any scaling, then it will
have the 0..255 value range instead of 0..1 assumed by the function. So, before calling #cvtColor ,
you need first to scale the image down:

     img *= 1./255;
     cvtColor(img, img, COLOR_BGR2Luv);

If you use #cvtColor with 8-bit images, the conversion will have some information lost. For many
applications, this will not be noticeable but it is recommended to use 32-bit images in applications
that need the full range of colors or that convert an image before an operation and then convert
back.
If conversion adds the alpha channel, its value will set to the maximum of corresponding channel
range: 255 for CV_8U, 65535 for CV_16U, 1 for CV_32F.
@ref imgproc_color_conversions

Parameters:

=over

=item src

input image: 8-bit unsigned, 16-bit unsigned ( CV_16UC... ), or single-precision
floating-point.

=item dst

output image of the same size and depth as src.

=item code

color space conversion code (see #ColorConversionCodes).

=item dstCn

number of channels in the destination image; if the parameter is 0, the number of the
channels is derived automatically from src and code.

=back

See also:


=for bad

cvtColor ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6838 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::cvtColor {
  barf "Usage: PDL::OpenCV::Imgproc::cvtColor(\$src,\$code,\$dstCn)\n" if @_ < 2;
  my ($src,$code,$dstCn) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $dstCn = 0 if !defined $dstCn;
  PDL::OpenCV::Imgproc::_cvtColor_int($src,$dst,$code,$dstCn);
  !wantarray ? $dst : ($dst)
}
#line 6853 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*cvtColor = \&PDL::OpenCV::Imgproc::cvtColor;
#line 6860 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 cvtColorTwoPlane

=for sig

  Signature: ([phys] src1(l1,c1,r1); [phys] src2(l2,c2,r2); [o,phys] dst(l3,c3,r3); int [phys] code())

=for ref

Converts an image from one color space to another where the source image is
stored in two planes. NO BROADCASTING.

=for example

 $dst = cvtColorTwoPlane($src1,$src2,$code);

This function only supports YUV420 to RGB conversion as of now.

Parameters:

=over

=item src1

8-bit image (#CV_8U) of the Y plane.

=item src2

image containing interleaved U/V plane.

=item dst

output image.

=item code

Specifies the type of conversion. It can take any of the following values:
- #COLOR_YUV2BGR_NV12
- #COLOR_YUV2RGB_NV12
- #COLOR_YUV2BGRA_NV12
- #COLOR_YUV2RGBA_NV12
- #COLOR_YUV2BGR_NV21
- #COLOR_YUV2RGB_NV21
- #COLOR_YUV2BGRA_NV21
- #COLOR_YUV2RGBA_NV21

=back


=for bad

cvtColorTwoPlane ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6923 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::cvtColorTwoPlane {
  barf "Usage: PDL::OpenCV::Imgproc::cvtColorTwoPlane(\$src1,\$src2,\$code)\n" if @_ < 3;
  my ($src1,$src2,$code) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::Imgproc::_cvtColorTwoPlane_int($src1,$src2,$dst,$code);
  !wantarray ? $dst : ($dst)
}
#line 6937 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*cvtColorTwoPlane = \&PDL::OpenCV::Imgproc::cvtColorTwoPlane;
#line 6944 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 demosaicing

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] code(); int [phys] dstCn())

=for ref

main function for all demosaicing processes NO BROADCASTING.

=for example

 $dst = demosaicing($src,$code); # with defaults
 $dst = demosaicing($src,$code,$dstCn);

The function can do the following transformations:
-   Demosaicing using bilinear interpolation
#COLOR_BayerBG2BGR , #COLOR_BayerGB2BGR , #COLOR_BayerRG2BGR , #COLOR_BayerGR2BGR
#COLOR_BayerBG2GRAY , #COLOR_BayerGB2GRAY , #COLOR_BayerRG2GRAY , #COLOR_BayerGR2GRAY
-   Demosaicing using Variable Number of Gradients.
#COLOR_BayerBG2BGR_VNG , #COLOR_BayerGB2BGR_VNG , #COLOR_BayerRG2BGR_VNG , #COLOR_BayerGR2BGR_VNG
-   Edge-Aware Demosaicing.
#COLOR_BayerBG2BGR_EA , #COLOR_BayerGB2BGR_EA , #COLOR_BayerRG2BGR_EA , #COLOR_BayerGR2BGR_EA
-   Demosaicing with alpha channel
#COLOR_BayerBG2BGRA , #COLOR_BayerGB2BGRA , #COLOR_BayerRG2BGRA , #COLOR_BayerGR2BGRA

Parameters:

=over

=item src

input image: 8-bit unsigned or 16-bit unsigned.

=item dst

output image of the same size and depth as src.

=item code

Color space conversion code (see the description below).

=item dstCn

number of channels in the destination image; if the parameter is 0, the number of the
channels is derived automatically from src and code.

=back

See also:
cvtColor


=for bad

demosaicing ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7012 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::demosaicing {
  barf "Usage: PDL::OpenCV::Imgproc::demosaicing(\$src,\$code,\$dstCn)\n" if @_ < 2;
  my ($src,$code,$dstCn) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  $dstCn = 0 if !defined $dstCn;
  PDL::OpenCV::Imgproc::_demosaicing_int($src,$dst,$code,$dstCn);
  !wantarray ? $dst : ($dst)
}
#line 7027 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*demosaicing = \&PDL::OpenCV::Imgproc::demosaicing;
#line 7034 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 matchTemplate

=for sig

  Signature: ([phys] image(l1,c1,r1); [phys] templ(l2,c2,r2); [o,phys] result(l3,c3,r3); int [phys] method(); [phys] mask(l5,c5,r5))

=for ref

Compares a template against overlapped image regions. NO BROADCASTING.

=for example

 $result = matchTemplate($image,$templ,$method); # with defaults
 $result = matchTemplate($image,$templ,$method,$mask);

The function slides through image , compares the overlapped patches of size C<<< w \times h >>>against
templ using the specified method and stores the comparison results in result . #TemplateMatchModes
describes the formulae for the available comparison methods ( C<<< I >>>denotes image, C<<< T >>>template, C<<< R >>>result, C<<< M >>>the optional mask ). The summation is done over template and/or
the image patch: C<<< x' = 0...w-1, y' = 0...h-1 >>>After the function finishes the comparison, the best matches can be found as global minimums (when
#TM_SQDIFF was used) or maximums (when #TM_CCORR or #TM_CCOEFF was used) using the
#minMaxLoc function. In case of a color image, template summation in the numerator and each sum in
the denominator is done over all of the channels and separate mean values are used for each channel.
That is, the function can take a color template and a color image. The result will still be a
single-channel image, which is easier to analyze.
C<<< W \times H >>>and templ is C<<< w \times h >>>, then result is C<<< (W-w+1) \times (H-h+1) >>>.

Parameters:

=over

=item image

Image where the search is running. It must be 8-bit or 32-bit floating-point.

=item templ

Searched template. It must be not greater than the source image and have the same
data type.

=item result

Map of comparison results. It must be single-channel 32-bit floating-point. If image
is

=item method

Parameter specifying the comparison method, see #TemplateMatchModes

=item mask

Optional mask. It must have the same size as templ. It must either have the same number
            of channels as template or only one channel, which is then used for all template and
            image channels. If the data type is #CV_8U, the mask is interpreted as a binary mask,
            meaning only elements where mask is nonzero are used and are kept unchanged independent
            of the actual mask value (weight equals 1). For data tpye #CV_32F, the mask values are
            used as weights. The exact formulas are documented in #TemplateMatchModes.

=back


=for bad

matchTemplate ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7109 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::matchTemplate {
  barf "Usage: PDL::OpenCV::Imgproc::matchTemplate(\$image,\$templ,\$method,\$mask)\n" if @_ < 3;
  my ($image,$templ,$method,$mask) = @_;
  my ($result);
  $result = PDL->null if !defined $result;
  $mask = PDL->zeroes(sbyte,0,0,0) if !defined $mask;
  PDL::OpenCV::Imgproc::_matchTemplate_int($image,$templ,$result,$method,$mask);
  !wantarray ? $result : ($result)
}
#line 7124 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*matchTemplate = \&PDL::OpenCV::Imgproc::matchTemplate;
#line 7131 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 connectedComponentsWithAlgorithm

=for sig

  Signature: ([phys] image(l1,c1,r1); [o,phys] labels(l2,c2,r2); int [phys] connectivity(); int [phys] ltype(); int [phys] ccltype(); int [o,phys] res())

=for ref

computes the connected components labeled image of boolean image NO BROADCASTING.

=for example

 ($labels,$res) = connectedComponentsWithAlgorithm($image,$connectivity,$ltype,$ccltype);

image with 4 or 8 way connectivity - returns N, the total number of labels [0, N-1] where 0
represents the background label. ltype specifies the output label image type, an important
consideration based on the total number of labels or alternatively the total number of pixels in
the source image. ccltype specifies the connected components labeling algorithm to use, currently
Grana (BBDT) and Wu's (SAUF) @cite Wu2009 algorithms are supported, see the #ConnectedComponentsAlgorithmsTypes
for details. Note that SAUF algorithm forces a row major ordering of labels while BBDT does not.
This function uses parallel version of both Grana and Wu's algorithms if at least one allowed
parallel framework is enabled and if the rows of the image are at least twice the number returned by #getNumberOfCPUs.

Parameters:

=over

=item image

the 8-bit single-channel image to be labeled

=item labels

destination labeled image

=item connectivity

8 or 4 for 8-way or 4-way connectivity respectively

=item ltype

output image label type. Currently CV_32S and CV_16U are supported.

=item ccltype

connected components algorithm type (see the #ConnectedComponentsAlgorithmsTypes).

=back


=for bad

connectedComponentsWithAlgorithm ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7196 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::connectedComponentsWithAlgorithm {
  barf "Usage: PDL::OpenCV::Imgproc::connectedComponentsWithAlgorithm(\$image,\$connectivity,\$ltype,\$ccltype)\n" if @_ < 4;
  my ($image,$connectivity,$ltype,$ccltype) = @_;
  my ($labels,$res);
  $labels = PDL->null if !defined $labels;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgproc::_connectedComponentsWithAlgorithm_int($image,$labels,$connectivity,$ltype,$ccltype,$res);
  !wantarray ? $res : ($labels,$res)
}
#line 7211 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*connectedComponentsWithAlgorithm = \&PDL::OpenCV::Imgproc::connectedComponentsWithAlgorithm;
#line 7218 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 connectedComponents

=for sig

  Signature: ([phys] image(l1,c1,r1); [o,phys] labels(l2,c2,r2); int [phys] connectivity(); int [phys] ltype(); int [o,phys] res())

=for ref

 NO BROADCASTING.

=for example

 ($labels,$res) = connectedComponents($image); # with defaults
 ($labels,$res) = connectedComponents($image,$connectivity,$ltype);

@overload

Parameters:

=over

=item image

the 8-bit single-channel image to be labeled

=item labels

destination labeled image

=item connectivity

8 or 4 for 8-way or 4-way connectivity respectively

=item ltype

output image label type. Currently CV_32S and CV_16U are supported.

=back


=for bad

connectedComponents ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7273 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::connectedComponents {
  barf "Usage: PDL::OpenCV::Imgproc::connectedComponents(\$image,\$connectivity,\$ltype)\n" if @_ < 1;
  my ($image,$connectivity,$ltype) = @_;
  my ($labels,$res);
  $labels = PDL->null if !defined $labels;
  $connectivity = 8 if !defined $connectivity;
  $ltype = CV_32S() if !defined $ltype;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgproc::_connectedComponents_int($image,$labels,$connectivity,$ltype,$res);
  !wantarray ? $res : ($labels,$res)
}
#line 7290 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*connectedComponents = \&PDL::OpenCV::Imgproc::connectedComponents;
#line 7297 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 connectedComponentsWithStatsWithAlgorithm

=for sig

  Signature: ([phys] image(l1,c1,r1); [o,phys] labels(l2,c2,r2); [o,phys] stats(l3,c3,r3); [o,phys] centroids(l4,c4,r4); int [phys] connectivity(); int [phys] ltype(); int [phys] ccltype(); int [o,phys] res())

=for ref

computes the connected components labeled image of boolean image and also produces a statistics output for each label NO BROADCASTING.

=for example

 ($labels,$stats,$centroids,$res) = connectedComponentsWithStatsWithAlgorithm($image,$connectivity,$ltype,$ccltype);

image with 4 or 8 way connectivity - returns N, the total number of labels [0, N-1] where 0
represents the background label. ltype specifies the output label image type, an important
consideration based on the total number of labels or alternatively the total number of pixels in
the source image. ccltype specifies the connected components labeling algorithm to use, currently
Grana's (BBDT) and Wu's (SAUF) @cite Wu2009 algorithms are supported, see the #ConnectedComponentsAlgorithmsTypes
for details. Note that SAUF algorithm forces a row major ordering of labels while BBDT does not.
This function uses parallel version of both Grana and Wu's algorithms (statistics included) if at least one allowed
parallel framework is enabled and if the rows of the image are at least twice the number returned by #getNumberOfCPUs.

Parameters:

=over

=item image

the 8-bit single-channel image to be labeled

=item labels

destination labeled image

=item stats

statistics output for each label, including the background label.
Statistics are accessed via stats(label, COLUMN) where COLUMN is one of
#ConnectedComponentsTypes, selecting the statistic. The data type is CV_32S.

=item centroids

centroid output for each label, including the background label. Centroids are
accessed via centroids(label, 0) for x and centroids(label, 1) for y. The data type CV_64F.

=item connectivity

8 or 4 for 8-way or 4-way connectivity respectively

=item ltype

output image label type. Currently CV_32S and CV_16U are supported.

=item ccltype

connected components algorithm type (see #ConnectedComponentsAlgorithmsTypes).

=back


=for bad

connectedComponentsWithStatsWithAlgorithm ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7373 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::connectedComponentsWithStatsWithAlgorithm {
  barf "Usage: PDL::OpenCV::Imgproc::connectedComponentsWithStatsWithAlgorithm(\$image,\$connectivity,\$ltype,\$ccltype)\n" if @_ < 4;
  my ($image,$connectivity,$ltype,$ccltype) = @_;
  my ($labels,$stats,$centroids,$res);
  $labels = PDL->null if !defined $labels;
  $stats = PDL->null if !defined $stats;
  $centroids = PDL->null if !defined $centroids;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgproc::_connectedComponentsWithStatsWithAlgorithm_int($image,$labels,$stats,$centroids,$connectivity,$ltype,$ccltype,$res);
  !wantarray ? $res : ($labels,$stats,$centroids,$res)
}
#line 7390 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*connectedComponentsWithStatsWithAlgorithm = \&PDL::OpenCV::Imgproc::connectedComponentsWithStatsWithAlgorithm;
#line 7397 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 connectedComponentsWithStats

=for sig

  Signature: ([phys] image(l1,c1,r1); [o,phys] labels(l2,c2,r2); [o,phys] stats(l3,c3,r3); [o,phys] centroids(l4,c4,r4); int [phys] connectivity(); int [phys] ltype(); int [o,phys] res())

=for ref

 NO BROADCASTING.

=for example

 ($labels,$stats,$centroids,$res) = connectedComponentsWithStats($image); # with defaults
 ($labels,$stats,$centroids,$res) = connectedComponentsWithStats($image,$connectivity,$ltype);

@overload

Parameters:

=over

=item image

the 8-bit single-channel image to be labeled

=item labels

destination labeled image

=item stats

statistics output for each label, including the background label.
Statistics are accessed via stats(label, COLUMN) where COLUMN is one of
#ConnectedComponentsTypes, selecting the statistic. The data type is CV_32S.

=item centroids

centroid output for each label, including the background label. Centroids are
accessed via centroids(label, 0) for x and centroids(label, 1) for y. The data type CV_64F.

=item connectivity

8 or 4 for 8-way or 4-way connectivity respectively

=item ltype

output image label type. Currently CV_32S and CV_16U are supported.

=back


=for bad

connectedComponentsWithStats ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7463 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::connectedComponentsWithStats {
  barf "Usage: PDL::OpenCV::Imgproc::connectedComponentsWithStats(\$image,\$connectivity,\$ltype)\n" if @_ < 1;
  my ($image,$connectivity,$ltype) = @_;
  my ($labels,$stats,$centroids,$res);
  $labels = PDL->null if !defined $labels;
  $stats = PDL->null if !defined $stats;
  $centroids = PDL->null if !defined $centroids;
  $connectivity = 8 if !defined $connectivity;
  $ltype = CV_32S() if !defined $ltype;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgproc::_connectedComponentsWithStats_int($image,$labels,$stats,$centroids,$connectivity,$ltype,$res);
  !wantarray ? $res : ($labels,$stats,$centroids,$res)
}
#line 7482 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*connectedComponentsWithStats = \&PDL::OpenCV::Imgproc::connectedComponentsWithStats;
#line 7489 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 findContours

=for sig

  Signature: ([phys] image(l1,c1,r1); [o,phys] hierarchy(l3,c3,r3); int [phys] mode(); int [phys] method(); indx [phys] offset(n6); [o] vector_MatWrapper * contours)

=for ref

Finds contours in a binary image. NO BROADCASTING.

=for example

 ($contours,$hierarchy) = findContours($image,$mode,$method); # with defaults
 ($contours,$hierarchy) = findContours($image,$mode,$method,$offset);

The function retrieves contours from the binary image using the algorithm @cite Suzuki85 . The contours
are a useful tool for shape analysis and object detection and recognition. See squares.cpp in the
OpenCV sample directory.
@note Since opencv 3.2 source image is not modified by this function.
@note In Python, hierarchy is nested inside a top level array. Use hierarchy[0][i] to access hierarchical elements of i-th contour.

Parameters:

=over

=item image

Source, an 8-bit single-channel image. Non-zero pixels are treated as 1's. Zero
pixels remain 0's, so the image is treated as binary . You can use #compare, #inRange, #threshold ,
#adaptiveThreshold, #Canny, and others to create a binary image out of a grayscale or color one.
If mode equals to #RETR_CCOMP or #RETR_FLOODFILL, the input can also be a 32-bit integer image of labels (CV_32SC1).

=item contours

Detected contours. Each contour is stored as a vector of points (e.g.
std::vector<std::vector<cv::Point> >).

=item hierarchy

Optional output vector (e.g. std::vector<cv::Vec4i>), containing information about the image topology. It has
as many elements as the number of contours. For each i-th contour contours[i], the elements
hierarchy[i][0] , hierarchy[i][1] , hierarchy[i][2] , and hierarchy[i][3] are set to 0-based indices
in contours of the next and previous contours at the same hierarchical level, the first child
contour and the parent contour, respectively. If for the contour i there are no next, previous,
parent, or nested contours, the corresponding elements of hierarchy[i] will be negative.

=item mode

Contour retrieval mode, see #RetrievalModes

=item method

Contour approximation method, see #ContourApproximationModes

=item offset

Optional offset by which every contour point is shifted. This is useful if the
contours are extracted from the image ROI and then they should be analyzed in the whole image
context.

=back


=for bad

findContours ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7567 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::findContours {
  barf "Usage: PDL::OpenCV::Imgproc::findContours(\$image,\$mode,\$method,\$offset)\n" if @_ < 3;
  my ($image,$mode,$method,$offset) = @_;
  my ($contours,$hierarchy);
  $hierarchy = PDL->null if !defined $hierarchy;
  $offset = empty(indx) if !defined $offset;
  PDL::OpenCV::Imgproc::_findContours_int($image,$hierarchy,$mode,$method,$offset,$contours);
  !wantarray ? $hierarchy : ($contours,$hierarchy)
}
#line 7582 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*findContours = \&PDL::OpenCV::Imgproc::findContours;
#line 7589 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 approxPolyDP

=for sig

  Signature: ([phys] curve(l1,c1,r1); [o,phys] approxCurve(l2,c2,r2); double [phys] epsilon(); byte [phys] closed())

=for ref

Approximates a polygonal curve(s) with the specified precision. NO BROADCASTING.

=for example

 $approxCurve = approxPolyDP($curve,$epsilon,$closed);

The function cv::approxPolyDP approximates a curve or a polygon with another curve/polygon with less
vertices so that the distance between them is less or equal to the specified precision. It uses the
Douglas-Peucker algorithm <http://en.wikipedia.org/wiki/Ramer-Douglas-Peucker_algorithm>

Parameters:

=over

=item curve

Input vector of a 2D point stored in std::vector or Mat

=item approxCurve

Result of the approximation. The type should match the type of the input curve.

=item epsilon

Parameter specifying the approximation accuracy. This is the maximum distance
between the original curve and its approximation.

=item closed

If true, the approximated curve is closed (its first and last vertices are
connected). Otherwise, it is not closed.

=back


=for bad

approxPolyDP ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7647 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::approxPolyDP {
  barf "Usage: PDL::OpenCV::Imgproc::approxPolyDP(\$curve,\$epsilon,\$closed)\n" if @_ < 3;
  my ($curve,$epsilon,$closed) = @_;
  my ($approxCurve);
  $approxCurve = PDL->null if !defined $approxCurve;
  PDL::OpenCV::Imgproc::_approxPolyDP_int($curve,$approxCurve,$epsilon,$closed);
  !wantarray ? $approxCurve : ($approxCurve)
}
#line 7661 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*approxPolyDP = \&PDL::OpenCV::Imgproc::approxPolyDP;
#line 7668 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 arcLength

=for sig

  Signature: ([phys] curve(l1,c1,r1); byte [phys] closed(); double [o,phys] res())

=for ref

Calculates a contour perimeter or a curve length.

=for example

 $res = arcLength($curve,$closed);

The function computes a curve length or a closed contour perimeter.

Parameters:

=over

=item curve

Input vector of 2D points, stored in std::vector or Mat.

=item closed

Flag indicating whether the curve is closed or not.

=back


=for bad

arcLength ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7714 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::arcLength {
  barf "Usage: PDL::OpenCV::Imgproc::arcLength(\$curve,\$closed)\n" if @_ < 2;
  my ($curve,$closed) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgproc::_arcLength_int($curve,$closed,$res);
  !wantarray ? $res : ($res)
}
#line 7728 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*arcLength = \&PDL::OpenCV::Imgproc::arcLength;
#line 7735 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 boundingRect

=for sig

  Signature: ([phys] array(l1,c1,r1); indx [o,phys] res(n2=4))

=for ref

Calculates the up-right bounding rectangle of a point set or non-zero pixels of gray-scale image.

=for example

 $res = boundingRect($array);

The function calculates and returns the minimal up-right bounding rectangle for the specified point set or
non-zero pixels of gray-scale image.

Parameters:

=over

=item array

Input gray-scale image or 2D point set, stored in std::vector or Mat.

=back


=for bad

boundingRect ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7778 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::boundingRect {
  barf "Usage: PDL::OpenCV::Imgproc::boundingRect(\$array)\n" if @_ < 1;
  my ($array) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgproc::_boundingRect_int($array,$res);
  !wantarray ? $res : ($res)
}
#line 7792 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*boundingRect = \&PDL::OpenCV::Imgproc::boundingRect;
#line 7799 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 contourArea

=for sig

  Signature: ([phys] contour(l1,c1,r1); byte [phys] oriented(); double [o,phys] res())

=for ref

Calculates a contour area.

=for example

 $res = contourArea($contour); # with defaults
 $res = contourArea($contour,$oriented);

The function computes a contour area. Similarly to moments , the area is computed using the Green
formula. Thus, the returned area and the number of non-zero pixels, if you draw the contour using
#drawContours or #fillPoly , can be different. Also, the function will most certainly give a wrong
results for contours with self-intersections.
Example:

     vector<Point> contour;
     contour.push_back(Point2f(0, 0));
     contour.push_back(Point2f(10, 0));
     contour.push_back(Point2f(10, 10));
     contour.push_back(Point2f(5, 4));

     double area0 = contourArea(contour);
     vector<Point> approx;
     approxPolyDP(contour, approx, 5, true);
     double area1 = contourArea(approx);

     cout << "area0 =" << area0 << endl <<
             "area1 =" << area1 << endl <<
             "approx poly vertices" << approx.size() << endl;

Parameters:

=over

=item contour

Input vector of 2D points (contour vertices), stored in std::vector or Mat.

=item oriented

Oriented area flag. If it is true, the function returns a signed area value,
depending on the contour orientation (clockwise or counter-clockwise). Using this feature you can
determine orientation of a contour by taking the sign of an area. By default, the parameter is
false, which means that the absolute value is returned.

=back


=for bad

contourArea ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7868 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::contourArea {
  barf "Usage: PDL::OpenCV::Imgproc::contourArea(\$contour,\$oriented)\n" if @_ < 1;
  my ($contour,$oriented) = @_;
  my ($res);
  $oriented = 0 if !defined $oriented;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgproc::_contourArea_int($contour,$oriented,$res);
  !wantarray ? $res : ($res)
}
#line 7883 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*contourArea = \&PDL::OpenCV::Imgproc::contourArea;
#line 7890 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 minAreaRect

=for sig

  Signature: ([phys] points(l1,c1,r1); [o] RotatedRectWrapper * res)

=for ref

Finds a rotated rectangle of the minimum area enclosing the input 2D point set.

=for example

 $res = minAreaRect($points);

The function calculates and returns the minimum-area bounding rectangle (possibly rotated) for a
specified point set. Developer should keep in mind that the returned RotatedRect can contain negative
indices when data is close to the containing Mat element boundary.
\<\> or Mat

Parameters:

=over

=item points

Input vector of 2D points, stored in std::vector

=back


=for bad

minAreaRect ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7935 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::minAreaRect {
  barf "Usage: PDL::OpenCV::Imgproc::minAreaRect(\$points)\n" if @_ < 1;
  my ($points) = @_;
  my ($res);
  
  PDL::OpenCV::Imgproc::_minAreaRect_int($points,$res);
  !wantarray ? $res : ($res)
}
#line 7949 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*minAreaRect = \&PDL::OpenCV::Imgproc::minAreaRect;
#line 7956 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 boxPoints

=for sig

  Signature: ([o,phys] points(l2,c2,r2); RotatedRectWrapper * box)

=for ref

Finds the four vertices of a rotated rect. Useful to draw the rotated rectangle. NO BROADCASTING.

=for example

 $points = boxPoints($box);

The function finds the four vertices of a rotated rectangle. This function is useful to draw the
rectangle. In C++, instead of using this function, you can directly use RotatedRect::points method. Please
visit the @ref tutorial_bounding_rotated_ellipses "tutorial on Creating Bounding rotated boxes and ellipses for contours" for more information.

Parameters:

=over

=item box

The input rotated rectangle. It may be the output of

=item points

The output array of four vertices of rectangles.

=back


=for bad

boxPoints ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 8004 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::boxPoints {
  barf "Usage: PDL::OpenCV::Imgproc::boxPoints(\$box)\n" if @_ < 1;
  my ($box) = @_;
  my ($points);
  $points = PDL->null if !defined $points;
  PDL::OpenCV::Imgproc::_boxPoints_int($points,$box);
  !wantarray ? $points : ($points)
}
#line 8018 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*boxPoints = \&PDL::OpenCV::Imgproc::boxPoints;
#line 8025 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 minEnclosingCircle

=for sig

  Signature: ([phys] points(l1,c1,r1); float [o,phys] center(n2=2); float [o,phys] radius())

=for ref

Finds a circle of the minimum area enclosing a 2D point set.

=for example

 ($center,$radius) = minEnclosingCircle($points);

The function finds the minimal enclosing circle of a 2D point set using an iterative algorithm.
\<\> or Mat

Parameters:

=over

=item points

Input vector of 2D points, stored in std::vector

=item center

Output center of the circle.

=item radius

Output radius of the circle.

=back


=for bad

minEnclosingCircle ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 8076 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::minEnclosingCircle {
  barf "Usage: PDL::OpenCV::Imgproc::minEnclosingCircle(\$points)\n" if @_ < 1;
  my ($points) = @_;
  my ($center,$radius);
  $center = PDL->null if !defined $center;
  $radius = PDL->null if !defined $radius;
  PDL::OpenCV::Imgproc::_minEnclosingCircle_int($points,$center,$radius);
  !wantarray ? $radius : ($center,$radius)
}
#line 8091 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*minEnclosingCircle = \&PDL::OpenCV::Imgproc::minEnclosingCircle;
#line 8098 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 minEnclosingTriangle

=for sig

  Signature: ([phys] points(l1,c1,r1); [o,phys] triangle(l2,c2,r2); double [o,phys] res())

=for ref

Finds a triangle of minimum area enclosing a 2D point set and returns its area. NO BROADCASTING.

=for example

 ($triangle,$res) = minEnclosingTriangle($points);

The function finds a triangle of minimum area enclosing the given set of 2D points and returns its
area. The output for a given 2D point set is shown in the image below. 2D points are depicted in
*red* and the enclosing triangle in *yellow*.
![Sample output of the minimum enclosing triangle function](pics/minenclosingtriangle.png)
The implementation of the algorithm is based on O'Rourke's @cite ORourke86 and Klee and Laskowski's
@cite KleeLaskowski85 papers. O'Rourke provides a C<<< \theta(n) >>>algorithm for finding the minimal
enclosing triangle of a 2D convex polygon with n vertices. Since the #minEnclosingTriangle function
takes a 2D point set as input an additional preprocessing step of computing the convex hull of the
2D point set is required. The complexity of the #convexHull function is C<<< O(n log(n)) >>>which is higher
than C<<< \theta(n) >>>. Thus the overall complexity of the function is C<<< O(n log(n)) >>>.
\<\> or Mat

Parameters:

=over

=item points

Input vector of 2D points with depth CV_32S or CV_32F, stored in std::vector

=item triangle

Output vector of three 2D points defining the vertices of the triangle. The depth
of the OutputArray must be CV_32F.

=back


=for bad

minEnclosingTriangle ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 8155 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::minEnclosingTriangle {
  barf "Usage: PDL::OpenCV::Imgproc::minEnclosingTriangle(\$points)\n" if @_ < 1;
  my ($points) = @_;
  my ($triangle,$res);
  $triangle = PDL->null if !defined $triangle;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgproc::_minEnclosingTriangle_int($points,$triangle,$res);
  !wantarray ? $res : ($triangle,$res)
}
#line 8170 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*minEnclosingTriangle = \&PDL::OpenCV::Imgproc::minEnclosingTriangle;
#line 8177 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 matchShapes

=for sig

  Signature: ([phys] contour1(l1,c1,r1); [phys] contour2(l2,c2,r2); int [phys] method(); double [phys] parameter(); double [o,phys] res())

=for ref

Compares two shapes.

=for example

 $res = matchShapes($contour1,$contour2,$method,$parameter);

The function compares two shapes. All three implemented methods use the Hu invariants (see #HuMoments)

Parameters:

=over

=item contour1

First contour or grayscale image.

=item contour2

Second contour or grayscale image.

=item method

Comparison method, see #ShapeMatchModes

=item parameter

Method-specific parameter (not supported now).

=back


=for bad

matchShapes ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 8231 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::matchShapes {
  barf "Usage: PDL::OpenCV::Imgproc::matchShapes(\$contour1,\$contour2,\$method,\$parameter)\n" if @_ < 4;
  my ($contour1,$contour2,$method,$parameter) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgproc::_matchShapes_int($contour1,$contour2,$method,$parameter,$res);
  !wantarray ? $res : ($res)
}
#line 8245 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*matchShapes = \&PDL::OpenCV::Imgproc::matchShapes;
#line 8252 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 convexHull

=for sig

  Signature: ([phys] points(l1,c1,r1); [o,phys] hull(l2,c2,r2); byte [phys] clockwise(); byte [phys] returnPoints())

=for ref

Finds the convex hull of a point set. NO BROADCASTING.

=for example

 $hull = convexHull($points); # with defaults
 $hull = convexHull($points,$clockwise,$returnPoints);

The function cv::convexHull finds the convex hull of a 2D point set using the Sklansky's algorithm @cite Sklansky82
that has *O(N logN)* complexity in the current implementation.
\<int\> implies returnPoints=false, std::vector\<Point\> implies
returnPoints=true.
@note `points` and `hull` should be different arrays, inplace processing isn't supported.
Check @ref tutorial_hull "the corresponding tutorial" for more details.
useful links:
https://www.learnopencv.com/convex-hull-using-opencv-in-python-and-c/

Parameters:

=over

=item points

Input 2D point set, stored in std::vector or Mat.

=item hull

Output convex hull. It is either an integer vector of indices or vector of points. In
the first case, the hull elements are 0-based indices of the convex hull points in the original
array (since the set of convex hull points is a subset of the original point set). In the second
case, hull elements are the convex hull points themselves.

=item clockwise

Orientation flag. If it is true, the output convex hull is oriented clockwise.
Otherwise, it is oriented counter-clockwise. The assumed coordinate system has its X axis pointing
to the right, and its Y axis pointing upwards.

=item returnPoints

Operation flag. In case of a matrix, when the flag is true, the function
returns convex hull points. Otherwise, it returns indices of the convex hull points. When the
output array is std::vector, the flag is ignored, and the output depends on the type of the
vector: std::vector

=back


=for bad

convexHull ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 8322 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::convexHull {
  barf "Usage: PDL::OpenCV::Imgproc::convexHull(\$points,\$clockwise,\$returnPoints)\n" if @_ < 1;
  my ($points,$clockwise,$returnPoints) = @_;
  my ($hull);
  $hull = PDL->null if !defined $hull;
  $clockwise = 0 if !defined $clockwise;
  $returnPoints = 1 if !defined $returnPoints;
  PDL::OpenCV::Imgproc::_convexHull_int($points,$hull,$clockwise,$returnPoints);
  !wantarray ? $hull : ($hull)
}
#line 8338 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*convexHull = \&PDL::OpenCV::Imgproc::convexHull;
#line 8345 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 convexityDefects

=for sig

  Signature: ([phys] contour(l1,c1,r1); [phys] convexhull(l2,c2,r2); [o,phys] convexityDefects(l3,c3,r3))

=for ref

Finds the convexity defects of a contour. NO BROADCASTING.

=for example

 $convexityDefects = convexityDefects($contour,$convexhull);

The figure below displays convexity defects of a hand contour:
![image](pics/defects.png)

Parameters:

=over

=item contour

Input contour.

=item convexhull

Convex hull obtained using convexHull that should contain indices of the contour
points that make the hull.

=item convexityDefects

The output vector of convexity defects. In C++ and the new Python/Java
interface each convexity defect is represented as 4-element integer vector (a.k.a. #Vec4i):
(start_index, end_index, farthest_pt_index, fixpt_depth), where indices are 0-based indices
in the original contour of the convexity defect beginning, end and the farthest point, and
fixpt_depth is fixed-point approximation (with 8 fractional bits) of the distance between the
farthest contour point and the hull. That is, to get the floating-point value of the depth will be
fixpt_depth/256.0.

=back


=for bad

convexityDefects ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 8403 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::convexityDefects {
  barf "Usage: PDL::OpenCV::Imgproc::convexityDefects(\$contour,\$convexhull)\n" if @_ < 2;
  my ($contour,$convexhull) = @_;
  my ($convexityDefects);
  $convexityDefects = PDL->null if !defined $convexityDefects;
  PDL::OpenCV::Imgproc::_convexityDefects_int($contour,$convexhull,$convexityDefects);
  !wantarray ? $convexityDefects : ($convexityDefects)
}
#line 8417 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*convexityDefects = \&PDL::OpenCV::Imgproc::convexityDefects;
#line 8424 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 isContourConvex

=for sig

  Signature: ([phys] contour(l1,c1,r1); byte [o,phys] res())

=for ref

Tests a contour convexity.

=for example

 $res = isContourConvex($contour);

The function tests whether the input contour is convex or not. The contour must be simple, that is,
without self-intersections. Otherwise, the function output is undefined.
\<\> or Mat

Parameters:

=over

=item contour

Input vector of 2D points, stored in std::vector

=back


=for bad

isContourConvex ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 8468 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::isContourConvex {
  barf "Usage: PDL::OpenCV::Imgproc::isContourConvex(\$contour)\n" if @_ < 1;
  my ($contour) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgproc::_isContourConvex_int($contour,$res);
  !wantarray ? $res : ($res)
}
#line 8482 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*isContourConvex = \&PDL::OpenCV::Imgproc::isContourConvex;
#line 8489 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 intersectConvexConvex

=for sig

  Signature: ([phys] p1(l1,c1,r1); [phys] p2(l2,c2,r2); [o,phys] p12(l3,c3,r3); byte [phys] handleNested(); float [o,phys] res())

=for ref

Finds intersection of two convex polygons NO BROADCASTING.

=for example

 ($p12,$res) = intersectConvexConvex($p1,$p2); # with defaults
 ($p12,$res) = intersectConvexConvex($p1,$p2,$handleNested);

@note intersectConvexConvex doesn't confirm that both polygons are convex and will return invalid results if they aren't.

Parameters:

=over

=item p1

First polygon

=item p2

Second polygon

=item p12

Output polygon describing the intersecting area

=item handleNested

When true, an intersection is found if one of the polygons is fully enclosed in the other.
When false, no intersection is found. If the polygons share a side or the vertex of one polygon lies on an edge
of the other, they are not considered nested and an intersection will be found regardless of the value of handleNested.

=back

Returns: Absolute value of area of intersecting polygon


=for bad

intersectConvexConvex ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 8548 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::intersectConvexConvex {
  barf "Usage: PDL::OpenCV::Imgproc::intersectConvexConvex(\$p1,\$p2,\$handleNested)\n" if @_ < 2;
  my ($p1,$p2,$handleNested) = @_;
  my ($p12,$res);
  $p12 = PDL->null if !defined $p12;
  $handleNested = 1 if !defined $handleNested;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgproc::_intersectConvexConvex_int($p1,$p2,$p12,$handleNested,$res);
  !wantarray ? $res : ($p12,$res)
}
#line 8564 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*intersectConvexConvex = \&PDL::OpenCV::Imgproc::intersectConvexConvex;
#line 8571 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 fitEllipse

=for sig

  Signature: ([phys] points(l1,c1,r1); [o] RotatedRectWrapper * res)

=for ref

Fits an ellipse around a set of 2D points.

=for example

 $res = fitEllipse($points);

The function calculates the ellipse that fits (in a least-squares sense) a set of 2D points best of
all. It returns the rotated rectangle in which the ellipse is inscribed. The first algorithm described by @cite Fitzgibbon95
is used. Developer should keep in mind that it is possible that the returned
ellipse/rotatedRect data contains negative indices, due to the data points being close to the
border of the containing Mat element.
\<\> or Mat

Parameters:

=over

=item points

Input 2D point set, stored in std::vector

=back


=for bad

fitEllipse ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 8618 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::fitEllipse {
  barf "Usage: PDL::OpenCV::Imgproc::fitEllipse(\$points)\n" if @_ < 1;
  my ($points) = @_;
  my ($res);
  
  PDL::OpenCV::Imgproc::_fitEllipse_int($points,$res);
  !wantarray ? $res : ($res)
}
#line 8632 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*fitEllipse = \&PDL::OpenCV::Imgproc::fitEllipse;
#line 8639 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 fitEllipseAMS

=for sig

  Signature: ([phys] points(l1,c1,r1); [o] RotatedRectWrapper * res)

=for ref

Fits an ellipse around a set of 2D points.

=for example

 $res = fitEllipseAMS($points);

The function calculates the ellipse that fits a set of 2D points.
It returns the rotated rectangle in which the ellipse is inscribed.
The Approximate Mean Square (AMS) proposed by @cite Taubin1991 is used.
For an ellipse, this basis set is C<<<  \chi= \left(x^2, x y, y^2, x, y, 1\right)  >>>,
which is a set of six free coefficients C<<<  A^T=\left\{A_{\text{xx}},A_{\text{xy}},A_{\text{yy}},A_x,A_y,A_0\right\}  >>>.
However, to specify an ellipse, all that is needed is five numbers; the major and minor axes lengths C<<<  (a,b)  >>>,
the position C<<<  (x_0,y_0)  >>>, and the orientation C<<<  \theta  >>>. This is because the basis set includes lines,
quadratics, parabolic and hyperbolic functions as well as elliptical functions as possible fits.
If the fit is found to be a parabolic or hyperbolic function then the standard #fitEllipse method is used.
The AMS method restricts the fit to parabolic, hyperbolic and elliptical curves
by imposing the condition that C<<<  A^T ( D_x^T D_x  +   D_y^T D_y) A = 1  >>>where
the matrices C<<<  Dx  >>>and C<<<  Dy  >>>are the partial derivatives of the design matrix C<<<  D  >>>with
respect to x and y. The matrices are formed row by row applying the following to
each of the points in the set:
\f{align*}{
D(i,:)&=\left\{x_i^2, x_i y_i, y_i^2, x_i, y_i, 1\right\} &
D_x(i,:)&=\left\{2 x_i,y_i,0,1,0,0\right\} &
D_y(i,:)&=\left\{0,x_i,2 y_i,0,1,0\right\}
\f}
The AMS method minimizes the cost function
\f{equation*}{
\epsilon ^2=\frac{ A^T D^T D A }{ A^T (D_x^T D_x +  D_y^T D_y) A^T }
\f}
The minimum cost is found by solving the generalized eigenvalue problem.
\f{equation*}{
D^T D A = \lambda  \left( D_x^T D_x +  D_y^T D_y\right) A
\f}
\<\> or Mat

Parameters:

=over

=item points

Input 2D point set, stored in std::vector

=back


=for bad

fitEllipseAMS ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 8708 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::fitEllipseAMS {
  barf "Usage: PDL::OpenCV::Imgproc::fitEllipseAMS(\$points)\n" if @_ < 1;
  my ($points) = @_;
  my ($res);
  
  PDL::OpenCV::Imgproc::_fitEllipseAMS_int($points,$res);
  !wantarray ? $res : ($res)
}
#line 8722 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*fitEllipseAMS = \&PDL::OpenCV::Imgproc::fitEllipseAMS;
#line 8729 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 fitEllipseDirect

=for sig

  Signature: ([phys] points(l1,c1,r1); [o] RotatedRectWrapper * res)

=for ref

Fits an ellipse around a set of 2D points.

=for example

 $res = fitEllipseDirect($points);

The function calculates the ellipse that fits a set of 2D points.
It returns the rotated rectangle in which the ellipse is inscribed.
The Direct least square (Direct) method by @cite Fitzgibbon1999 is used.
For an ellipse, this basis set is C<<<  \chi= \left(x^2, x y, y^2, x, y, 1\right)  >>>,
which is a set of six free coefficients C<<<  A^T=\left\{A_{\text{xx}},A_{\text{xy}},A_{\text{yy}},A_x,A_y,A_0\right\}  >>>.
However, to specify an ellipse, all that is needed is five numbers; the major and minor axes lengths C<<<  (a,b)  >>>,
the position C<<<  (x_0,y_0)  >>>, and the orientation C<<<  \theta  >>>. This is because the basis set includes lines,
quadratics, parabolic and hyperbolic functions as well as elliptical functions as possible fits.
The Direct method confines the fit to ellipses by ensuring that C<<<  4 A_{xx} A_{yy}- A_{xy}^2 > 0  >>>.
The condition imposed is that C<<<  4 A_{xx} A_{yy}- A_{xy}^2=1  >>>which satisfies the inequality
and as the coefficients can be arbitrarily scaled is not overly restrictive.
\f{equation*}{
\epsilon ^2= A^T D^T D A \quad \text{with} \quad A^T C A =1 \quad \text{and} \quad C=\left(\begin{matrix}
0 & 0  & 2  & 0  & 0  &  0  \\
0 & -1  & 0  & 0  & 0  &  0 \\
2 & 0  & 0  & 0  & 0  &  0 \\
0 & 0  & 0  & 0  & 0  &  0 \\
0 & 0  & 0  & 0  & 0  &  0 \\
0 & 0  & 0  & 0  & 0  &  0
\end{matrix} \right)
\f}
The minimum cost is found by solving the generalized eigenvalue problem.
\f{equation*}{
D^T D A = \lambda  \left( C\right) A
\f}
The system produces only one positive eigenvalue C<<<  \lambda >>>which is chosen as the solution
with its eigenvector C<<< \mathbf{u} >>>. These are used to find the coefficients
\f{equation*}{
A = \sqrt{\frac{1}{\mathbf{u}^T C \mathbf{u}}}  \mathbf{u}
\f}
The scaling factor guarantees that  C<<< A^T C A =1 >>>.
\<\> or Mat

Parameters:

=over

=item points

Input 2D point set, stored in std::vector

=back


=for bad

fitEllipseDirect ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 8802 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::fitEllipseDirect {
  barf "Usage: PDL::OpenCV::Imgproc::fitEllipseDirect(\$points)\n" if @_ < 1;
  my ($points) = @_;
  my ($res);
  
  PDL::OpenCV::Imgproc::_fitEllipseDirect_int($points,$res);
  !wantarray ? $res : ($res)
}
#line 8816 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*fitEllipseDirect = \&PDL::OpenCV::Imgproc::fitEllipseDirect;
#line 8823 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 fitLine

=for sig

  Signature: ([phys] points(l1,c1,r1); [o,phys] line(l2,c2,r2); int [phys] distType(); double [phys] param(); double [phys] reps(); double [phys] aeps())

=for ref

Fits a line to a 2D or 3D point set. NO BROADCASTING.

=for example

 $line = fitLine($points,$distType,$param,$reps,$aeps);

The function fitLine fits a line to a 2D or 3D point set by minimizing C<<< \sum_i \rho(r_i) >>>where
C<<< r_i >>>is a distance between the C<<< i^{th} >>>point, the line and C<<< \rho(r) >>>is a distance function, one
of the following:
=over
=back
The algorithm is based on the M-estimator ( <http://en.wikipedia.org/wiki/M-estimator> ) technique
that iteratively fits the line using the weighted least-squares algorithm. After each iteration the
weights C<<< w_i >>>are adjusted to be inversely proportional to C<<< \rho(r_i) >>>.
\<\> or Mat.

Parameters:

=over

=item points

Input vector of 2D or 3D points, stored in std::vector

=item line

Output line parameters. In case of 2D fitting, it should be a vector of 4 elements
(like Vec4f) - (vx, vy, x0, y0), where (vx, vy) is a normalized vector collinear to the line and
(x0, y0) is a point on the line. In case of 3D fitting, it should be a vector of 6 elements (like
Vec6f) - (vx, vy, vz, x0, y0, z0), where (vx, vy, vz) is a normalized vector collinear to the line
and (x0, y0, z0) is a point on the line.

=item distType

Distance used by the M-estimator, see #DistanceTypes

=item param

Numerical parameter ( C ) for some types of distances. If it is 0, an optimal value
is chosen.

=item reps

Sufficient accuracy for the radius (distance between the coordinate origin and the line).

=item aeps

Sufficient accuracy for the angle. 0.01 would be a good default value for reps and aeps.

=back


=for bad

fitLine ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 8898 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::fitLine {
  barf "Usage: PDL::OpenCV::Imgproc::fitLine(\$points,\$distType,\$param,\$reps,\$aeps)\n" if @_ < 5;
  my ($points,$distType,$param,$reps,$aeps) = @_;
  my ($line);
  $line = PDL->null if !defined $line;
  PDL::OpenCV::Imgproc::_fitLine_int($points,$line,$distType,$param,$reps,$aeps);
  !wantarray ? $line : ($line)
}
#line 8912 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*fitLine = \&PDL::OpenCV::Imgproc::fitLine;
#line 8919 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 pointPolygonTest

=for sig

  Signature: ([phys] contour(l1,c1,r1); float [phys] pt(n2=2); byte [phys] measureDist(); double [o,phys] res())

=for ref

Performs a point-in-contour test.

=for example

 $res = pointPolygonTest($contour,$pt,$measureDist);

The function determines whether the point is inside a contour, outside, or lies on an edge (or
coincides with a vertex). It returns positive (inside), negative (outside), or zero (on an edge)
value, correspondingly. When measureDist=false , the return value is +1, -1, and 0, respectively.
Otherwise, the return value is a signed distance between the point and the nearest contour edge.
See below a sample output of the function where each image pixel is tested against the contour:
![sample output](pics/pointpolygon.png)

Parameters:

=over

=item contour

Input contour.

=item pt

Point tested against the contour.

=item measureDist

If true, the function estimates the signed distance from the point to the
nearest contour edge. Otherwise, the function only checks if the point is inside a contour or not.

=back


=for bad

pointPolygonTest ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 8975 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::pointPolygonTest {
  barf "Usage: PDL::OpenCV::Imgproc::pointPolygonTest(\$contour,\$pt,\$measureDist)\n" if @_ < 3;
  my ($contour,$pt,$measureDist) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgproc::_pointPolygonTest_int($contour,$pt,$measureDist,$res);
  !wantarray ? $res : ($res)
}
#line 8989 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*pointPolygonTest = \&PDL::OpenCV::Imgproc::pointPolygonTest;
#line 8996 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 rotatedRectangleIntersection

=for sig

  Signature: ([o,phys] intersectingRegion(l3,c3,r3); int [o,phys] res(); RotatedRectWrapper * rect1; RotatedRectWrapper * rect2)

=for ref

Finds out if there is any intersection between two rotated rectangles. NO BROADCASTING.

=for example

 ($intersectingRegion,$res) = rotatedRectangleIntersection($rect1,$rect2);

If there is then the vertices of the intersecting region are returned as well.
Below are some examples of intersection configurations. The hatched pattern indicates the
intersecting region and the red vertices are returned by the function.
![intersection examples](pics/intersection.png)
\<cv::Point2f\> or cv::Mat as Mx1 of type CV_32FC2.

Parameters:

=over

=item rect1

First rectangle

=item rect2

Second rectangle

=item intersectingRegion

The output array of the vertices of the intersecting region. It returns
at most 8 vertices. Stored as std::vector

=back

Returns: One of #RectanglesIntersectTypes


=for bad

rotatedRectangleIntersection ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 9053 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::rotatedRectangleIntersection {
  barf "Usage: PDL::OpenCV::Imgproc::rotatedRectangleIntersection(\$rect1,\$rect2)\n" if @_ < 2;
  my ($rect1,$rect2) = @_;
  my ($intersectingRegion,$res);
  $intersectingRegion = PDL->null if !defined $intersectingRegion;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgproc::_rotatedRectangleIntersection_int($intersectingRegion,$res,$rect1,$rect2);
  !wantarray ? $res : ($intersectingRegion,$res)
}
#line 9068 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*rotatedRectangleIntersection = \&PDL::OpenCV::Imgproc::rotatedRectangleIntersection;
#line 9075 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 applyColorMap

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); int [phys] colormap())

=for ref

Applies a GNU Octave/MATLAB equivalent colormap on a given image. NO BROADCASTING.

=for example

 $dst = applyColorMap($src,$colormap);

Parameters:

=over

=item src

The source image, grayscale or colored of type CV_8UC1 or CV_8UC3.

=item dst

The result is the colormapped source image. Note: Mat::create is called on dst.

=item colormap

The colormap to apply, see #ColormapTypes

=back


=for bad

applyColorMap ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 9123 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::applyColorMap {
  barf "Usage: PDL::OpenCV::Imgproc::applyColorMap(\$src,\$colormap)\n" if @_ < 2;
  my ($src,$colormap) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::Imgproc::_applyColorMap_int($src,$dst,$colormap);
  !wantarray ? $dst : ($dst)
}
#line 9137 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*applyColorMap = \&PDL::OpenCV::Imgproc::applyColorMap;
#line 9144 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 applyColorMap2

=for sig

  Signature: ([phys] src(l1,c1,r1); [o,phys] dst(l2,c2,r2); [phys] userColor(l3,c3,r3))

=for ref

Applies a user colormap on a given image. NO BROADCASTING.

=for example

 $dst = applyColorMap2($src,$userColor);

Parameters:

=over

=item src

The source image, grayscale or colored of type CV_8UC1 or CV_8UC3.

=item dst

The result is the colormapped source image. Note: Mat::create is called on dst.

=item userColor

The colormap to apply of type CV_8UC1 or CV_8UC3 and size 256

=back


=for bad

applyColorMap2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 9192 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::applyColorMap2 {
  barf "Usage: PDL::OpenCV::Imgproc::applyColorMap2(\$src,\$userColor)\n" if @_ < 2;
  my ($src,$userColor) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::Imgproc::_applyColorMap2_int($src,$dst,$userColor);
  !wantarray ? $dst : ($dst)
}
#line 9206 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*applyColorMap2 = \&PDL::OpenCV::Imgproc::applyColorMap2;
#line 9213 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 line

=for sig

  Signature: ([io,phys] img(l1,c1,r1); indx [phys] pt1(n2=2); indx [phys] pt2(n3=2); double [phys] color(n4=4); int [phys] thickness(); int [phys] lineType(); int [phys] shift())

=for ref

Draws a line segment connecting two points.

=for example

 line($img,$pt1,$pt2,$color); # with defaults
 line($img,$pt1,$pt2,$color,$thickness,$lineType,$shift);

The function line draws the line segment between pt1 and pt2 points in the image. The line is
clipped by the image boundaries. For non-antialiased lines with integer coordinates, the 8-connected
or 4-connected Bresenham algorithm is used. Thick lines are drawn with rounding endings. Antialiased
lines are drawn using Gaussian filtering.

Parameters:

=over

=item img

Image.

=item pt1

First point of the line segment.

=item pt2

Second point of the line segment.

=item color

Line color.

=item thickness

Line thickness.

=item lineType

Type of the line. See #LineTypes.

=item shift

Number of fractional bits in the point coordinates.

=back


=for bad

line ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 9283 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::line {
  barf "Usage: PDL::OpenCV::Imgproc::line(\$img,\$pt1,\$pt2,\$color,\$thickness,\$lineType,\$shift)\n" if @_ < 4;
  my ($img,$pt1,$pt2,$color,$thickness,$lineType,$shift) = @_;
    $thickness = 1 if !defined $thickness;
  $lineType = LINE_8() if !defined $lineType;
  $shift = 0 if !defined $shift;
  PDL::OpenCV::Imgproc::_line_int($img,$pt1,$pt2,$color,$thickness,$lineType,$shift);
  
}
#line 9298 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*line = \&PDL::OpenCV::Imgproc::line;
#line 9305 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 arrowedLine

=for sig

  Signature: ([io,phys] img(l1,c1,r1); indx [phys] pt1(n2=2); indx [phys] pt2(n3=2); double [phys] color(n4=4); int [phys] thickness(); int [phys] line_type(); int [phys] shift(); double [phys] tipLength())

=for ref

Draws an arrow segment pointing from the first point to the second one.

=for example

 arrowedLine($img,$pt1,$pt2,$color); # with defaults
 arrowedLine($img,$pt1,$pt2,$color,$thickness,$line_type,$shift,$tipLength);

The function cv::arrowedLine draws an arrow between pt1 and pt2 points in the image. See also #line.

Parameters:

=over

=item img

Image.

=item pt1

The point the arrow starts from.

=item pt2

The point the arrow points to.

=item color

Line color.

=item thickness

Line thickness.

=item line_type

Type of the line. See #LineTypes

=item shift

Number of fractional bits in the point coordinates.

=item tipLength

The length of the arrow tip in relation to the arrow length

=back


=for bad

arrowedLine ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 9376 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::arrowedLine {
  barf "Usage: PDL::OpenCV::Imgproc::arrowedLine(\$img,\$pt1,\$pt2,\$color,\$thickness,\$line_type,\$shift,\$tipLength)\n" if @_ < 4;
  my ($img,$pt1,$pt2,$color,$thickness,$line_type,$shift,$tipLength) = @_;
    $thickness = 1 if !defined $thickness;
  $line_type = 8 if !defined $line_type;
  $shift = 0 if !defined $shift;
  $tipLength = 0.1 if !defined $tipLength;
  PDL::OpenCV::Imgproc::_arrowedLine_int($img,$pt1,$pt2,$color,$thickness,$line_type,$shift,$tipLength);
  
}
#line 9392 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*arrowedLine = \&PDL::OpenCV::Imgproc::arrowedLine;
#line 9399 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 rectangle

=for sig

  Signature: ([io,phys] img(l1,c1,r1); indx [phys] pt1(n2=2); indx [phys] pt2(n3=2); double [phys] color(n4=4); int [phys] thickness(); int [phys] lineType(); int [phys] shift())

=for ref

Draws a simple, thick, or filled up-right rectangle.

=for example

 rectangle($img,$pt1,$pt2,$color); # with defaults
 rectangle($img,$pt1,$pt2,$color,$thickness,$lineType,$shift);

The function cv::rectangle draws a rectangle outline or a filled rectangle whose two opposite corners
are pt1 and pt2.

Parameters:

=over

=item img

Image.

=item pt1

Vertex of the rectangle.

=item pt2

Vertex of the rectangle opposite to pt1 .

=item color

Rectangle color or brightness (grayscale image).

=item thickness

Thickness of lines that make up the rectangle. Negative values, like #FILLED,
mean that the function has to draw a filled rectangle.

=item lineType

Type of the line. See #LineTypes

=item shift

Number of fractional bits in the point coordinates.

=back


=for bad

rectangle ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 9468 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::rectangle {
  barf "Usage: PDL::OpenCV::Imgproc::rectangle(\$img,\$pt1,\$pt2,\$color,\$thickness,\$lineType,\$shift)\n" if @_ < 4;
  my ($img,$pt1,$pt2,$color,$thickness,$lineType,$shift) = @_;
    $thickness = 1 if !defined $thickness;
  $lineType = LINE_8() if !defined $lineType;
  $shift = 0 if !defined $shift;
  PDL::OpenCV::Imgproc::_rectangle_int($img,$pt1,$pt2,$color,$thickness,$lineType,$shift);
  
}
#line 9483 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*rectangle = \&PDL::OpenCV::Imgproc::rectangle;
#line 9490 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 rectangle2

=for sig

  Signature: ([io,phys] img(l1,c1,r1); indx [phys] rec(n2=4); double [phys] color(n3=4); int [phys] thickness(); int [phys] lineType(); int [phys] shift())

=for ref

=for example

 rectangle2($img,$rec,$color); # with defaults
 rectangle2($img,$rec,$color,$thickness,$lineType,$shift);

@overload
use `rec` parameter as alternative specification of the drawn rectangle: `r.tl() and
r.br()-Point(1,1)` are opposite corners

=for bad

rectangle2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 9522 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::rectangle2 {
  barf "Usage: PDL::OpenCV::Imgproc::rectangle2(\$img,\$rec,\$color,\$thickness,\$lineType,\$shift)\n" if @_ < 3;
  my ($img,$rec,$color,$thickness,$lineType,$shift) = @_;
    $thickness = 1 if !defined $thickness;
  $lineType = LINE_8() if !defined $lineType;
  $shift = 0 if !defined $shift;
  PDL::OpenCV::Imgproc::_rectangle2_int($img,$rec,$color,$thickness,$lineType,$shift);
  
}
#line 9537 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*rectangle2 = \&PDL::OpenCV::Imgproc::rectangle2;
#line 9544 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 circle

=for sig

  Signature: ([io,phys] img(l1,c1,r1); indx [phys] center(n2=2); int [phys] radius(); double [phys] color(n4=4); int [phys] thickness(); int [phys] lineType(); int [phys] shift())

=for ref

Draws a circle.

=for example

 circle($img,$center,$radius,$color); # with defaults
 circle($img,$center,$radius,$color,$thickness,$lineType,$shift);

The function cv::circle draws a simple or filled circle with a given center and radius.

Parameters:

=over

=item img

Image where the circle is drawn.

=item center

Center of the circle.

=item radius

Radius of the circle.

=item color

Circle color.

=item thickness

Thickness of the circle outline, if positive. Negative values, like #FILLED,
mean that a filled circle is to be drawn.

=item lineType

Type of the circle boundary. See #LineTypes

=item shift

Number of fractional bits in the coordinates of the center and in the radius value.

=back


=for bad

circle ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 9612 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::circle {
  barf "Usage: PDL::OpenCV::Imgproc::circle(\$img,\$center,\$radius,\$color,\$thickness,\$lineType,\$shift)\n" if @_ < 4;
  my ($img,$center,$radius,$color,$thickness,$lineType,$shift) = @_;
    $thickness = 1 if !defined $thickness;
  $lineType = LINE_8() if !defined $lineType;
  $shift = 0 if !defined $shift;
  PDL::OpenCV::Imgproc::_circle_int($img,$center,$radius,$color,$thickness,$lineType,$shift);
  
}
#line 9627 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*circle = \&PDL::OpenCV::Imgproc::circle;
#line 9634 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 ellipse

=for sig

  Signature: ([io,phys] img(l1,c1,r1); indx [phys] center(n2=2); indx [phys] axes(n3=2); double [phys] angle(); double [phys] startAngle(); double [phys] endAngle(); double [phys] color(n7=4); int [phys] thickness(); int [phys] lineType(); int [phys] shift())

=for ref

Draws a simple or thick elliptic arc or fills an ellipse sector.

=for example

 ellipse($img,$center,$axes,$angle,$startAngle,$endAngle,$color); # with defaults
 ellipse($img,$center,$axes,$angle,$startAngle,$endAngle,$color,$thickness,$lineType,$shift);

The function cv::ellipse with more parameters draws an ellipse outline, a filled ellipse, an elliptic
arc, or a filled ellipse sector. The drawing code uses general parametric form.
A piecewise-linear curve is used to approximate the elliptic arc
boundary. If you need more control of the ellipse rendering, you can retrieve the curve using
#ellipse2Poly and then render it with #polylines or fill it with #fillPoly. If you use the first
variant of the function and want to draw the whole ellipse, not an arc, pass `startAngle=0` and
`endAngle=360`. If `startAngle` is greater than `endAngle`, they are swapped. The figure below explains
the meaning of the parameters to draw the blue arc.
![Parameters of Elliptic Arc](pics/ellipse.svg)

Parameters:

=over

=item img

Image.

=item center

Center of the ellipse.

=item axes

Half of the size of the ellipse main axes.

=item angle

Ellipse rotation angle in degrees.

=item startAngle

Starting angle of the elliptic arc in degrees.

=item endAngle

Ending angle of the elliptic arc in degrees.

=item color

Ellipse color.

=item thickness

Thickness of the ellipse arc outline, if positive. Otherwise, this indicates that
a filled ellipse sector is to be drawn.

=item lineType

Type of the ellipse boundary. See #LineTypes

=item shift

Number of fractional bits in the coordinates of the center and values of axes.

=back


=for bad

ellipse ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 9722 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::ellipse {
  barf "Usage: PDL::OpenCV::Imgproc::ellipse(\$img,\$center,\$axes,\$angle,\$startAngle,\$endAngle,\$color,\$thickness,\$lineType,\$shift)\n" if @_ < 7;
  my ($img,$center,$axes,$angle,$startAngle,$endAngle,$color,$thickness,$lineType,$shift) = @_;
    $thickness = 1 if !defined $thickness;
  $lineType = LINE_8() if !defined $lineType;
  $shift = 0 if !defined $shift;
  PDL::OpenCV::Imgproc::_ellipse_int($img,$center,$axes,$angle,$startAngle,$endAngle,$color,$thickness,$lineType,$shift);
  
}
#line 9737 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*ellipse = \&PDL::OpenCV::Imgproc::ellipse;
#line 9744 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 ellipse2

=for sig

  Signature: ([io,phys] img(l1,c1,r1); double [phys] color(n3=4); int [phys] thickness(); int [phys] lineType(); RotatedRectWrapper * box)

=for ref

=for example

 ellipse2($img,$box,$color); # with defaults
 ellipse2($img,$box,$color,$thickness,$lineType);

@overload

Parameters:

=over

=item img

Image.

=item box

Alternative ellipse representation via RotatedRect. This means that the function draws
an ellipse inscribed in the rotated rectangle.

=item color

Ellipse color.

=item thickness

Thickness of the ellipse arc outline, if positive. Otherwise, this indicates that
a filled ellipse sector is to be drawn.

=item lineType

Type of the ellipse boundary. See #LineTypes

=back


=for bad

ellipse2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 9803 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::ellipse2 {
  barf "Usage: PDL::OpenCV::Imgproc::ellipse2(\$img,\$box,\$color,\$thickness,\$lineType)\n" if @_ < 3;
  my ($img,$box,$color,$thickness,$lineType) = @_;
    $thickness = 1 if !defined $thickness;
  $lineType = LINE_8() if !defined $lineType;
  PDL::OpenCV::Imgproc::_ellipse2_int($img,$color,$thickness,$lineType,$box);
  
}
#line 9817 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*ellipse2 = \&PDL::OpenCV::Imgproc::ellipse2;
#line 9824 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 drawMarker

=for sig

  Signature: ([io,phys] img(l1,c1,r1); indx [phys] position(n2=2); double [phys] color(n3=4); int [phys] markerType(); int [phys] markerSize(); int [phys] thickness(); int [phys] line_type())

=for ref

Draws a marker on a predefined position in an image.

=for example

 drawMarker($img,$position,$color); # with defaults
 drawMarker($img,$position,$color,$markerType,$markerSize,$thickness,$line_type);

The function cv::drawMarker draws a marker on a given position in the image. For the moment several
marker types are supported, see #MarkerTypes for more information.

Parameters:

=over

=item img

Image.

=item position

The point where the crosshair is positioned.

=item color

Line color.

=item markerType

The specific type of marker you want to use, see #MarkerTypes

=item thickness

Line thickness.

=item line_type

Type of the line, See #LineTypes

=item markerSize

The length of the marker axis [default = 20 pixels]

=back


=for bad

drawMarker ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 9892 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::drawMarker {
  barf "Usage: PDL::OpenCV::Imgproc::drawMarker(\$img,\$position,\$color,\$markerType,\$markerSize,\$thickness,\$line_type)\n" if @_ < 3;
  my ($img,$position,$color,$markerType,$markerSize,$thickness,$line_type) = @_;
    $markerType = MARKER_CROSS() if !defined $markerType;
  $markerSize = 20 if !defined $markerSize;
  $thickness = 1 if !defined $thickness;
  $line_type = 8 if !defined $line_type;
  PDL::OpenCV::Imgproc::_drawMarker_int($img,$position,$color,$markerType,$markerSize,$thickness,$line_type);
  
}
#line 9908 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*drawMarker = \&PDL::OpenCV::Imgproc::drawMarker;
#line 9915 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 fillConvexPoly

=for sig

  Signature: ([io,phys] img(l1,c1,r1); [phys] points(l2,c2,r2); double [phys] color(n3=4); int [phys] lineType(); int [phys] shift())

=for ref

Fills a convex polygon.

=for example

 fillConvexPoly($img,$points,$color); # with defaults
 fillConvexPoly($img,$points,$color,$lineType,$shift);

The function cv::fillConvexPoly draws a filled convex polygon. This function is much faster than the
function #fillPoly . It can fill not only convex polygons but any monotonic polygon without
self-intersections, that is, a polygon whose contour intersects every horizontal line (scan line)
twice at the most (though, its top-most and/or the bottom edge could be horizontal).

Parameters:

=over

=item img

Image.

=item points

Polygon vertices.

=item color

Polygon color.

=item lineType

Type of the polygon boundaries. See #LineTypes

=item shift

Number of fractional bits in the vertex coordinates.

=back


=for bad

fillConvexPoly ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 9977 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::fillConvexPoly {
  barf "Usage: PDL::OpenCV::Imgproc::fillConvexPoly(\$img,\$points,\$color,\$lineType,\$shift)\n" if @_ < 3;
  my ($img,$points,$color,$lineType,$shift) = @_;
    $lineType = LINE_8() if !defined $lineType;
  $shift = 0 if !defined $shift;
  PDL::OpenCV::Imgproc::_fillConvexPoly_int($img,$points,$color,$lineType,$shift);
  
}
#line 9991 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*fillConvexPoly = \&PDL::OpenCV::Imgproc::fillConvexPoly;
#line 9998 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 fillPoly

=for sig

  Signature: ([io,phys] img(l1,c1,r1); double [phys] color(n3=4); int [phys] lineType(); int [phys] shift(); indx [phys] offset(n6); vector_MatWrapper * pts)

=for ref

Fills the area bounded by one or more polygons.

=for example

 fillPoly($img,$pts,$color); # with defaults
 fillPoly($img,$pts,$color,$lineType,$shift,$offset);

The function cv::fillPoly fills an area bounded by several polygonal contours. The function can fill
complex areas, for example, areas with holes, contours with self-intersections (some of their
parts), and so forth.

Parameters:

=over

=item img

Image.

=item pts

Array of polygons where each polygon is represented as an array of points.

=item color

Polygon color.

=item lineType

Type of the polygon boundaries. See #LineTypes

=item shift

Number of fractional bits in the vertex coordinates.

=item offset

Optional offset of all points of the contours.

=back


=for bad

fillPoly ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 10063 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::fillPoly {
  barf "Usage: PDL::OpenCV::Imgproc::fillPoly(\$img,\$pts,\$color,\$lineType,\$shift,\$offset)\n" if @_ < 3;
  my ($img,$pts,$color,$lineType,$shift,$offset) = @_;
    $lineType = LINE_8() if !defined $lineType;
  $shift = 0 if !defined $shift;
  $offset = empty(indx) if !defined $offset;
  PDL::OpenCV::Imgproc::_fillPoly_int($img,$color,$lineType,$shift,$offset,$pts);
  
}
#line 10078 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*fillPoly = \&PDL::OpenCV::Imgproc::fillPoly;
#line 10085 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 polylines

=for sig

  Signature: ([io,phys] img(l1,c1,r1); byte [phys] isClosed(); double [phys] color(n4=4); int [phys] thickness(); int [phys] lineType(); int [phys] shift(); vector_MatWrapper * pts)

=for ref

Draws several polygonal curves.

=for example

 polylines($img,$pts,$isClosed,$color); # with defaults
 polylines($img,$pts,$isClosed,$color,$thickness,$lineType,$shift);

The function cv::polylines draws one or more polygonal curves.

Parameters:

=over

=item img

Image.

=item pts

Array of polygonal curves.

=item isClosed

Flag indicating whether the drawn polylines are closed or not. If they are closed,
the function draws a line from the last vertex of each curve to its first vertex.

=item color

Polyline color.

=item thickness

Thickness of the polyline edges.

=item lineType

Type of the line segments. See #LineTypes

=item shift

Number of fractional bits in the vertex coordinates.

=back


=for bad

polylines ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 10153 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::polylines {
  barf "Usage: PDL::OpenCV::Imgproc::polylines(\$img,\$pts,\$isClosed,\$color,\$thickness,\$lineType,\$shift)\n" if @_ < 4;
  my ($img,$pts,$isClosed,$color,$thickness,$lineType,$shift) = @_;
    $thickness = 1 if !defined $thickness;
  $lineType = LINE_8() if !defined $lineType;
  $shift = 0 if !defined $shift;
  PDL::OpenCV::Imgproc::_polylines_int($img,$isClosed,$color,$thickness,$lineType,$shift,$pts);
  
}
#line 10168 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*polylines = \&PDL::OpenCV::Imgproc::polylines;
#line 10175 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 drawContours

=for sig

  Signature: ([io,phys] image(l1,c1,r1); int [phys] contourIdx(); double [phys] color(n4=4); int [phys] thickness(); int [phys] lineType(); [phys] hierarchy(l7,c7,r7); int [phys] maxLevel(); indx [phys] offset(n9); vector_MatWrapper * contours)

=for ref

Draws contours outlines or filled contours.

=for example

 drawContours($image,$contours,$contourIdx,$color); # with defaults
 drawContours($image,$contours,$contourIdx,$color,$thickness,$lineType,$hierarchy,$maxLevel,$offset);

The function draws contour outlines in the image if C<<< \texttt{thickness} \ge 0 >>>or fills the area
bounded by the contours if C<<< \texttt{thickness}<0 >>>. The example below shows how to retrieve
connected components from the binary image and label them: :
@include snippets/imgproc_drawContours.cpp
C<<< \texttt{offset}=(dx,dy) >>>.
@note When thickness=#FILLED, the function is designed to handle connected components with holes correctly
even when no hierarchy data is provided. This is done by analyzing all the outlines together
using even-odd rule. This may give incorrect results if you have a joint collection of separately retrieved
contours. In order to solve this problem, you need to call #drawContours separately for each sub-group
of contours, or iterate over the collection using contourIdx parameter.

Parameters:

=over

=item image

Destination image.

=item contours

All the input contours. Each contour is stored as a point vector.

=item contourIdx

Parameter indicating a contour to draw. If it is negative, all the contours are drawn.

=item color

Color of the contours.

=item thickness

Thickness of lines the contours are drawn with. If it is negative (for example,
thickness=#FILLED ), the contour interiors are drawn.

=item lineType

Line connectivity. See #LineTypes

=item hierarchy

Optional information about hierarchy. It is only needed if you want to draw only
some of the contours (see maxLevel ).

=item maxLevel

Maximal level for drawn contours. If it is 0, only the specified contour is drawn.
If it is 1, the function draws the contour(s) and all the nested contours. If it is 2, the function
draws the contours, all the nested contours, all the nested-to-nested contours, and so on. This
parameter is only taken into account when there is hierarchy available.

=item offset

Optional contour shift parameter. Shift all the drawn contours by the specified

=back


=for bad

drawContours ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 10264 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::drawContours {
  barf "Usage: PDL::OpenCV::Imgproc::drawContours(\$image,\$contours,\$contourIdx,\$color,\$thickness,\$lineType,\$hierarchy,\$maxLevel,\$offset)\n" if @_ < 4;
  my ($image,$contours,$contourIdx,$color,$thickness,$lineType,$hierarchy,$maxLevel,$offset) = @_;
    $thickness = 1 if !defined $thickness;
  $lineType = LINE_8() if !defined $lineType;
  $hierarchy = PDL->zeroes(sbyte,0,0,0) if !defined $hierarchy;
  $maxLevel = INT_MAX() if !defined $maxLevel;
  $offset = empty(indx) if !defined $offset;
  PDL::OpenCV::Imgproc::_drawContours_int($image,$contourIdx,$color,$thickness,$lineType,$hierarchy,$maxLevel,$offset,$contours);
  
}
#line 10281 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*drawContours = \&PDL::OpenCV::Imgproc::drawContours;
#line 10288 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 clipLine

=for sig

  Signature: (indx [phys] imgRect(n1=4); indx [o,phys] pt1(n2=2); indx [o,phys] pt2(n3=2); byte [o,phys] res())

=for ref

=for example

 ($pt1,$pt2,$res) = clipLine($imgRect);

@overload

Parameters:

=over

=item imgRect

Image rectangle.

=item pt1

First line point.

=item pt2

Second line point.

=back


=for bad

clipLine ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 10336 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::clipLine {
  barf "Usage: PDL::OpenCV::Imgproc::clipLine(\$imgRect)\n" if @_ < 1;
  my ($imgRect) = @_;
  my ($pt1,$pt2,$res);
  $pt1 = PDL->null if !defined $pt1;
  $pt2 = PDL->null if !defined $pt2;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgproc::_clipLine_int($imgRect,$pt1,$pt2,$res);
  !wantarray ? $res : ($pt1,$pt2,$res)
}
#line 10352 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*clipLine = \&PDL::OpenCV::Imgproc::clipLine;
#line 10359 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 ellipse2Poly

=for sig

  Signature: (indx [phys] center(n1=2); indx [phys] axes(n2=2); int [phys] angle(); int [phys] arcStart(); int [phys] arcEnd(); int [phys] delta(); indx [o,phys] pts(n7=2,n7d0))

=for ref

Approximates an elliptic arc with a polyline. NO BROADCASTING.

=for example

 $pts = ellipse2Poly($center,$axes,$angle,$arcStart,$arcEnd,$delta);

The function ellipse2Poly computes the vertices of a polyline that approximates the specified
elliptic arc. It is used by #ellipse. If `arcStart` is greater than `arcEnd`, they are swapped.

Parameters:

=over

=item center

Center of the arc.

=item axes

Half of the size of the ellipse main axes. See #ellipse for details.

=item angle

Rotation angle of the ellipse in degrees. See #ellipse for details.

=item arcStart

Starting angle of the elliptic arc in degrees.

=item arcEnd

Ending angle of the elliptic arc in degrees.

=item delta

Angle between the subsequent polyline vertices. It defines the approximation
accuracy.

=item pts

Output vector of polyline vertices.

=back


=for bad

ellipse2Poly ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 10427 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::ellipse2Poly {
  barf "Usage: PDL::OpenCV::Imgproc::ellipse2Poly(\$center,\$axes,\$angle,\$arcStart,\$arcEnd,\$delta)\n" if @_ < 6;
  my ($center,$axes,$angle,$arcStart,$arcEnd,$delta) = @_;
  my ($pts);
  $pts = PDL->null if !defined $pts;
  PDL::OpenCV::Imgproc::_ellipse2Poly_int($center,$axes,$angle,$arcStart,$arcEnd,$delta,$pts);
  !wantarray ? $pts : ($pts)
}
#line 10441 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*ellipse2Poly = \&PDL::OpenCV::Imgproc::ellipse2Poly;
#line 10448 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 putText

=for sig

  Signature: ([io,phys] img(l1,c1,r1); indx [phys] org(n3=2); int [phys] fontFace(); double [phys] fontScale(); double [phys] color(n6=4); int [phys] thickness(); int [phys] lineType(); byte [phys] bottomLeftOrigin(); StringWrapper* text)

=for ref

Draws a text string.

=for example

 putText($img,$text,$org,$fontFace,$fontScale,$color); # with defaults
 putText($img,$text,$org,$fontFace,$fontScale,$color,$thickness,$lineType,$bottomLeftOrigin);

The function cv::putText renders the specified text string in the image. Symbols that cannot be rendered
using the specified font are replaced by question marks. See #getTextSize for a text rendering code
example.

Parameters:

=over

=item img

Image.

=item text

Text string to be drawn.

=item org

Bottom-left corner of the text string in the image.

=item fontFace

Font type, see #HersheyFonts.

=item fontScale

Font scale factor that is multiplied by the font-specific base size.

=item color

Text color.

=item thickness

Thickness of the lines used to draw a text.

=item lineType

Line type. See #LineTypes

=item bottomLeftOrigin

When true, the image data origin is at the bottom-left corner. Otherwise,
it is at the top-left corner.

=back


=for bad

putText ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 10526 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::putText {
  barf "Usage: PDL::OpenCV::Imgproc::putText(\$img,\$text,\$org,\$fontFace,\$fontScale,\$color,\$thickness,\$lineType,\$bottomLeftOrigin)\n" if @_ < 6;
  my ($img,$text,$org,$fontFace,$fontScale,$color,$thickness,$lineType,$bottomLeftOrigin) = @_;
    $thickness = 1 if !defined $thickness;
  $lineType = LINE_8() if !defined $lineType;
  $bottomLeftOrigin = 0 if !defined $bottomLeftOrigin;
  PDL::OpenCV::Imgproc::_putText_int($img,$org,$fontFace,$fontScale,$color,$thickness,$lineType,$bottomLeftOrigin,$text);
  
}
#line 10541 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*putText = \&PDL::OpenCV::Imgproc::putText;
#line 10548 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 getTextSize

=for sig

  Signature: (int [phys] fontFace(); double [phys] fontScale(); int [phys] thickness(); int [o,phys] baseLine(); indx [o,phys] res(n6=2); StringWrapper* text)

=for ref

Calculates the width and height of a text string.

=for example

 ($baseLine,$res) = getTextSize($text,$fontFace,$fontScale,$thickness);

The function cv::getTextSize calculates and returns the size of a box that contains the specified text.
That is, the following code renders some text, the tight box surrounding it, and the baseline: :

     String text = "Funny text inside the box";
     int fontFace = FONT_HERSHEY_SCRIPT_SIMPLEX;
     double fontScale = 2;
     int thickness = 3;

     Mat img(600, 800, CV_8UC3, Scalar::all(0));

     int baseline=0;
     Size textSize = getTextSize(text, fontFace,
                                 fontScale, thickness, &baseline);
     baseline += thickness;

     // center the text
     Point textOrg((img.cols - textSize.width)/2,
                   (img.rows + textSize.height)/2);

     // draw the box
     rectangle(img, textOrg + Point(0, baseline),
               textOrg + Point(textSize.width, -textSize.height),
               Scalar(0,0,255));
     // ... and the baseline first
     line(img, textOrg + Point(0, thickness),
          textOrg + Point(textSize.width, thickness),
          Scalar(0, 0, 255));

     // then put the text itself
     putText(img, text, textOrg, fontFace, fontScale,
             Scalar::all(255), thickness, 8);

@param[out] baseLine y-coordinate of the baseline relative to the bottom-most text
point.

Parameters:

=over

=item text

Input text string.

=item fontFace

Font to use, see #HersheyFonts.

=item fontScale

Font scale factor that is multiplied by the font-specific base size.

=item thickness

Thickness of lines used to render the text. See #putText for details.

=back

Returns: The size of a box that contains the specified text.

See also:
putText


=for bad

getTextSize ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 10640 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgproc::getTextSize {
  barf "Usage: PDL::OpenCV::Imgproc::getTextSize(\$text,\$fontFace,\$fontScale,\$thickness)\n" if @_ < 4;
  my ($text,$fontFace,$fontScale,$thickness) = @_;
  my ($baseLine,$res);
  $baseLine = PDL->null if !defined $baseLine;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgproc::_getTextSize_int($fontFace,$fontScale,$thickness,$baseLine,$res,$text);
  !wantarray ? $res : ($baseLine,$res)
}
#line 10655 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*getTextSize = \&PDL::OpenCV::Imgproc::getTextSize;
#line 10662 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 getFontScaleFromHeight

=for ref

Calculates the font-specific size to use to achieve a given height in pixels.

=for example

 $res = getFontScaleFromHeight($fontFace,$pixelHeight); # with defaults
 $res = getFontScaleFromHeight($fontFace,$pixelHeight,$thickness);

Parameters:

=over

=item fontFace

Font to use, see cv::HersheyFonts.

=item pixelHeight

Pixel height to compute the fontScale for

=item thickness

Thickness of lines used to render the text.See putText for details.

=back

Returns: The fontSize to use for cv::putText

See also:
cv::putText


=cut
#line 10704 "Imgproc.pm"



#line 275 "../genpp.pl"

*getFontScaleFromHeight = \&PDL::OpenCV::Imgproc::getFontScaleFromHeight;
#line 10711 "Imgproc.pm"



#line 394 "../genpp.pl"

=head1 METHODS for PDL::OpenCV::CLAHE


=for ref

Base class for Contrast Limited Adaptive Histogram Equalization.


Subclass of PDL::OpenCV::Algorithm


=cut

@PDL::OpenCV::CLAHE::ISA = qw(PDL::OpenCV::Algorithm);
#line 10731 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 CLAHE_new

=for sig

  Signature: (double [phys] clipLimit(); indx [phys] tileGridSize(n3=2); char * klass; [o] CLAHEWrapper * res)

=for ref

Creates a smart pointer to a cv::CLAHE class and initializes it.

=for example

 $obj = PDL::OpenCV::CLAHE->new; # with defaults
 $obj = PDL::OpenCV::CLAHE->new($clipLimit,$tileGridSize);

Parameters:

=over

=item clipLimit

Threshold for contrast limiting.

=item tileGridSize

Size of grid for histogram equalization. Input image will be divided into
equally sized rectangular tiles. tileGridSize defines the number of tiles in row and column.

=back


=for bad

CLAHE_new ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 10777 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::CLAHE::new {
  barf "Usage: PDL::OpenCV::CLAHE::new(\$klass,\$clipLimit,\$tileGridSize)\n" if @_ < 1;
  my ($klass,$clipLimit,$tileGridSize) = @_;
  my ($res);
  $clipLimit = 40.0 if !defined $clipLimit;
  $tileGridSize = indx(8, 8) if !defined $tileGridSize;
  PDL::OpenCV::CLAHE::_CLAHE_new_int($clipLimit,$tileGridSize,$klass,$res);
  !wantarray ? $res : ($res)
}
#line 10792 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 10797 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 CLAHE_apply

=for sig

  Signature: ([phys] src(l2,c2,r2); [o,phys] dst(l3,c3,r3); CLAHEWrapper * self)

=for ref

Equalizes the histogram of a grayscale image using Contrast Limited Adaptive Histogram Equalization. NO BROADCASTING.

=for example

 $dst = $obj->apply($src);

Parameters:

=over

=item src

Source image of type CV_8UC1 or CV_16UC1.

=item dst

Destination image.

=back


=for bad

CLAHE_apply ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 10841 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::CLAHE::apply {
  barf "Usage: PDL::OpenCV::CLAHE::apply(\$self,\$src)\n" if @_ < 2;
  my ($self,$src) = @_;
  my ($dst);
  $dst = PDL->null if !defined $dst;
  PDL::OpenCV::CLAHE::_CLAHE_apply_int($src,$dst,$self);
  !wantarray ? $dst : ($dst)
}
#line 10855 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 10860 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 setClipLimit

=for ref

Sets threshold for contrast limiting.

=for example

 $obj->setClipLimit($clipLimit);

Parameters:

=over

=item clipLimit

threshold value.

=back


=cut
#line 10888 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 getClipLimit

=for ref

=for example

 $res = $obj->getClipLimit;


=cut
#line 10904 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 CLAHE_setTilesGridSize

=for sig

  Signature: (indx [phys] tileGridSize(n2=2); CLAHEWrapper * self)

=for ref

Sets size of grid for histogram equalization. Input image will be divided into
    equally sized rectangular tiles.

=for example

 $obj->setTilesGridSize($tileGridSize);

Parameters:

=over

=item tileGridSize

defines the number of tiles in row and column.

=back


=for bad

CLAHE_setTilesGridSize ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 10945 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::CLAHE::setTilesGridSize {
  barf "Usage: PDL::OpenCV::CLAHE::setTilesGridSize(\$self,\$tileGridSize)\n" if @_ < 2;
  my ($self,$tileGridSize) = @_;
    
  PDL::OpenCV::CLAHE::_CLAHE_setTilesGridSize_int($tileGridSize,$self);
  
}
#line 10958 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 10963 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 CLAHE_getTilesGridSize

=for sig

  Signature: (indx [o,phys] res(n2=2); CLAHEWrapper * self)

=for ref

=for example

 $res = $obj->getTilesGridSize;


=for bad

CLAHE_getTilesGridSize ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 10991 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::CLAHE::getTilesGridSize {
  barf "Usage: PDL::OpenCV::CLAHE::getTilesGridSize(\$self)\n" if @_ < 1;
  my ($self) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::CLAHE::_CLAHE_getTilesGridSize_int($res,$self);
  !wantarray ? $res : ($res)
}
#line 11005 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 11010 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 collectGarbage

=for ref

=for example

 $obj->collectGarbage;


=cut
#line 11026 "Imgproc.pm"



#line 394 "../genpp.pl"

=head1 METHODS for PDL::OpenCV::GeneralizedHough


=for ref

finds arbitrary template in the grayscale image using Generalized Hough Transform


Subclass of PDL::OpenCV::Algorithm


=cut

@PDL::OpenCV::GeneralizedHough::ISA = qw(PDL::OpenCV::Algorithm);
#line 11046 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 GeneralizedHough_setTemplate

=for sig

  Signature: ([phys] templ(l2,c2,r2); indx [phys] templCenter(n3=2); GeneralizedHoughWrapper * self)

=for ref

=for example

 $obj->setTemplate($templ); # with defaults
 $obj->setTemplate($templ,$templCenter);


=for bad

GeneralizedHough_setTemplate ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 11075 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::GeneralizedHough::setTemplate {
  barf "Usage: PDL::OpenCV::GeneralizedHough::setTemplate(\$self,\$templ,\$templCenter)\n" if @_ < 2;
  my ($self,$templ,$templCenter) = @_;
    $templCenter = indx(-1, -1) if !defined $templCenter;
  PDL::OpenCV::GeneralizedHough::_GeneralizedHough_setTemplate_int($templ,$templCenter,$self);
  
}
#line 11088 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 11093 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 GeneralizedHough_setTemplate2

=for sig

  Signature: ([phys] edges(l2,c2,r2); [phys] dx(l3,c3,r3); [phys] dy(l4,c4,r4); indx [phys] templCenter(n5=2); GeneralizedHoughWrapper * self)

=for ref

=for example

 $obj->setTemplate2($edges,$dx,$dy); # with defaults
 $obj->setTemplate2($edges,$dx,$dy,$templCenter);


=for bad

GeneralizedHough_setTemplate2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 11122 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::GeneralizedHough::setTemplate2 {
  barf "Usage: PDL::OpenCV::GeneralizedHough::setTemplate2(\$self,\$edges,\$dx,\$dy,\$templCenter)\n" if @_ < 4;
  my ($self,$edges,$dx,$dy,$templCenter) = @_;
    $templCenter = indx(-1, -1) if !defined $templCenter;
  PDL::OpenCV::GeneralizedHough::_GeneralizedHough_setTemplate2_int($edges,$dx,$dy,$templCenter,$self);
  
}
#line 11135 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 11140 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 GeneralizedHough_detect

=for sig

  Signature: ([phys] image(l2,c2,r2); [o,phys] positions(l3,c3,r3); [o,phys] votes(l4,c4,r4); GeneralizedHoughWrapper * self)

=for ref

 NO BROADCASTING.

=for example

 ($positions,$votes) = $obj->detect($image);


=for bad

GeneralizedHough_detect ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 11170 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::GeneralizedHough::detect {
  barf "Usage: PDL::OpenCV::GeneralizedHough::detect(\$self,\$image)\n" if @_ < 2;
  my ($self,$image) = @_;
  my ($positions,$votes);
  $positions = PDL->null if !defined $positions;
  $votes = PDL->null if !defined $votes;
  PDL::OpenCV::GeneralizedHough::_GeneralizedHough_detect_int($image,$positions,$votes,$self);
  !wantarray ? $votes : ($positions,$votes)
}
#line 11185 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 11190 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 GeneralizedHough_detect2

=for sig

  Signature: ([phys] edges(l2,c2,r2); [phys] dx(l3,c3,r3); [phys] dy(l4,c4,r4); [o,phys] positions(l5,c5,r5); [o,phys] votes(l6,c6,r6); GeneralizedHoughWrapper * self)

=for ref

 NO BROADCASTING.

=for example

 ($positions,$votes) = $obj->detect2($edges,$dx,$dy);


=for bad

GeneralizedHough_detect2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 11220 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::GeneralizedHough::detect2 {
  barf "Usage: PDL::OpenCV::GeneralizedHough::detect2(\$self,\$edges,\$dx,\$dy)\n" if @_ < 4;
  my ($self,$edges,$dx,$dy) = @_;
  my ($positions,$votes);
  $positions = PDL->null if !defined $positions;
  $votes = PDL->null if !defined $votes;
  PDL::OpenCV::GeneralizedHough::_GeneralizedHough_detect2_int($edges,$dx,$dy,$positions,$votes,$self);
  !wantarray ? $votes : ($positions,$votes)
}
#line 11235 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 11240 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 setCannyLowThresh

=for ref

=for example

 $obj->setCannyLowThresh($cannyLowThresh);


=cut
#line 11256 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 getCannyLowThresh

=for ref

=for example

 $res = $obj->getCannyLowThresh;


=cut
#line 11272 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 setCannyHighThresh

=for ref

=for example

 $obj->setCannyHighThresh($cannyHighThresh);


=cut
#line 11288 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 getCannyHighThresh

=for ref

=for example

 $res = $obj->getCannyHighThresh;


=cut
#line 11304 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 setMinDist

=for ref

=for example

 $obj->setMinDist($minDist);


=cut
#line 11320 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 getMinDist

=for ref

=for example

 $res = $obj->getMinDist;


=cut
#line 11336 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 setDp

=for ref

=for example

 $obj->setDp($dp);


=cut
#line 11352 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 getDp

=for ref

=for example

 $res = $obj->getDp;


=cut
#line 11368 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 setMaxBufferSize

=for ref

=for example

 $obj->setMaxBufferSize($maxBufferSize);


=cut
#line 11384 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 getMaxBufferSize

=for ref

=for example

 $res = $obj->getMaxBufferSize;


=cut
#line 11400 "Imgproc.pm"



#line 394 "../genpp.pl"

=head1 METHODS for PDL::OpenCV::GeneralizedHoughBallard


=for ref

finds arbitrary template in the grayscale image using Generalized Hough Transform

Detects position only without translation and rotation @cite Ballard1981 .

Subclass of PDL::OpenCV::GeneralizedHough


=cut

@PDL::OpenCV::GeneralizedHoughBallard::ISA = qw(PDL::OpenCV::GeneralizedHough);
#line 11421 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 new

=for ref

Creates a smart pointer to a cv::GeneralizedHoughBallard class and initializes it.

=for example

 $obj = PDL::OpenCV::GeneralizedHoughBallard->new;


=cut
#line 11439 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 setLevels

=for ref

=for example

 $obj->setLevels($levels);


=cut
#line 11455 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 getLevels

=for ref

=for example

 $res = $obj->getLevels;


=cut
#line 11471 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 setVotesThreshold

=for ref

=for example

 $obj->setVotesThreshold($votesThreshold);


=cut
#line 11487 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 getVotesThreshold

=for ref

=for example

 $res = $obj->getVotesThreshold;


=cut
#line 11503 "Imgproc.pm"



#line 394 "../genpp.pl"

=head1 METHODS for PDL::OpenCV::GeneralizedHoughGuil


=for ref

finds arbitrary template in the grayscale image using Generalized Hough Transform

Detects position, translation and rotation @cite Guil1999 .

Subclass of PDL::OpenCV::GeneralizedHough


=cut

@PDL::OpenCV::GeneralizedHoughGuil::ISA = qw(PDL::OpenCV::GeneralizedHough);
#line 11524 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 new

=for ref

Creates a smart pointer to a cv::GeneralizedHoughGuil class and initializes it.

=for example

 $obj = PDL::OpenCV::GeneralizedHoughGuil->new;


=cut
#line 11542 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 setXi

=for ref

=for example

 $obj->setXi($xi);


=cut
#line 11558 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 getXi

=for ref

=for example

 $res = $obj->getXi;


=cut
#line 11574 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 setLevels

=for ref

=for example

 $obj->setLevels($levels);


=cut
#line 11590 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 getLevels

=for ref

=for example

 $res = $obj->getLevels;


=cut
#line 11606 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 setAngleEpsilon

=for ref

=for example

 $obj->setAngleEpsilon($angleEpsilon);


=cut
#line 11622 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 getAngleEpsilon

=for ref

=for example

 $res = $obj->getAngleEpsilon;


=cut
#line 11638 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 setMinAngle

=for ref

=for example

 $obj->setMinAngle($minAngle);


=cut
#line 11654 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 getMinAngle

=for ref

=for example

 $res = $obj->getMinAngle;


=cut
#line 11670 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 setMaxAngle

=for ref

=for example

 $obj->setMaxAngle($maxAngle);


=cut
#line 11686 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 getMaxAngle

=for ref

=for example

 $res = $obj->getMaxAngle;


=cut
#line 11702 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 setAngleStep

=for ref

=for example

 $obj->setAngleStep($angleStep);


=cut
#line 11718 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 getAngleStep

=for ref

=for example

 $res = $obj->getAngleStep;


=cut
#line 11734 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 setAngleThresh

=for ref

=for example

 $obj->setAngleThresh($angleThresh);


=cut
#line 11750 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 getAngleThresh

=for ref

=for example

 $res = $obj->getAngleThresh;


=cut
#line 11766 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 setMinScale

=for ref

=for example

 $obj->setMinScale($minScale);


=cut
#line 11782 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 getMinScale

=for ref

=for example

 $res = $obj->getMinScale;


=cut
#line 11798 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 setMaxScale

=for ref

=for example

 $obj->setMaxScale($maxScale);


=cut
#line 11814 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 getMaxScale

=for ref

=for example

 $res = $obj->getMaxScale;


=cut
#line 11830 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 setScaleStep

=for ref

=for example

 $obj->setScaleStep($scaleStep);


=cut
#line 11846 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 getScaleStep

=for ref

=for example

 $res = $obj->getScaleStep;


=cut
#line 11862 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 setScaleThresh

=for ref

=for example

 $obj->setScaleThresh($scaleThresh);


=cut
#line 11878 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 getScaleThresh

=for ref

=for example

 $res = $obj->getScaleThresh;


=cut
#line 11894 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 setPosThresh

=for ref

=for example

 $obj->setPosThresh($posThresh);


=cut
#line 11910 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 getPosThresh

=for ref

=for example

 $res = $obj->getPosThresh;


=cut
#line 11926 "Imgproc.pm"



#line 394 "../genpp.pl"

=head1 METHODS for PDL::OpenCV::LineSegmentDetector


=for ref

Line segment detector class

following the algorithm described at @cite Rafael12 .
@note Implementation has been removed from OpenCV version 3.4.6 to 3.4.15 and version 4.1.0 to 4.5.3 due original code license conflict.
restored again after [Computation of a NFA](https://github.com/rafael-grompone-von-gioi/binomial_nfa) code published under the MIT license.

Subclass of PDL::OpenCV::Algorithm


=cut

@PDL::OpenCV::LineSegmentDetector::ISA = qw(PDL::OpenCV::Algorithm);
#line 11949 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 new

=for ref

Creates a smart pointer to a LineSegmentDetector object and initializes it.

=for example

 $obj = PDL::OpenCV::LineSegmentDetector->new; # with defaults
 $obj = PDL::OpenCV::LineSegmentDetector->new($refine,$scale,$sigma_scale,$quant,$ang_th,$log_eps,$density_th,$n_bins);

The LineSegmentDetector algorithm is defined using the standard values. Only advanced users may want
to edit those, as to tailor it for their own application.
\> log_eps. Used only when advance refinement is chosen.

Parameters:

=over

=item refine

The way found lines will be refined, see #LineSegmentDetectorModes

=item scale

The scale of the image that will be used to find the lines. Range (0..1].

=item sigma_scale

Sigma for Gaussian filter. It is computed as sigma = sigma_scale/scale.

=item quant

Bound to the quantization error on the gradient norm.

=item ang_th

Gradient angle tolerance in degrees.

=item log_eps

Detection threshold: -log10(NFA)

=item density_th

Minimal density of aligned region points in the enclosing rectangle.

=item n_bins

Number of bins in pseudo-ordering of gradient modulus.

=back


=cut
#line 12010 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 LineSegmentDetector_detect

=for sig

  Signature: ([phys] image(l2,c2,r2); [o,phys] lines(l3,c3,r3); [o,phys] width(l4,c4,r4); [o,phys] prec(l5,c5,r5); [o,phys] nfa(l6,c6,r6); LineSegmentDetectorWrapper * self)

=for ref

Finds lines in the input image. NO BROADCASTING.

=for example

 ($lines,$width,$prec,$nfa) = $obj->detect($image);

This is the output of the default parameters of the algorithm on the above shown image.
![image](pics/building_lsd.png)
\>detect(image(roi), lines, ...); lines += Scalar(roi.x, roi.y, roi.x, roi.y);`

Parameters:

=over

=item image

A grayscale (CV_8UC1) input image. If only a roi needs to be selected, use:
    `lsd_ptr-

=item lines

A vector of Vec4f elements specifying the beginning and ending point of a line. Where
    Vec4f is (x1, y1, x2, y2), point 1 is the start, point 2 - end. Returned lines are strictly
    oriented depending on the gradient.

=item width

Vector of widths of the regions, where the lines are found. E.g. Width of line.

=item prec

Vector of precisions with which the lines are found.

=item nfa

Vector containing number of false alarms in the line region, with precision of 10%. The
    bigger the value, logarithmically better the detection.
    - -1 corresponds to 10 mean false alarms
    - 0 corresponds to 1 mean false alarm
    - 1 corresponds to 0.1 mean false alarms
    This vector will be calculated only when the objects type is #LSD_REFINE_ADV.

=back


=for bad

LineSegmentDetector_detect ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 12078 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::LineSegmentDetector::detect {
  barf "Usage: PDL::OpenCV::LineSegmentDetector::detect(\$self,\$image)\n" if @_ < 2;
  my ($self,$image) = @_;
  my ($lines,$width,$prec,$nfa);
  $lines = PDL->null if !defined $lines;
  $width = PDL->null if !defined $width;
  $prec = PDL->null if !defined $prec;
  $nfa = PDL->null if !defined $nfa;
  PDL::OpenCV::LineSegmentDetector::_LineSegmentDetector_detect_int($image,$lines,$width,$prec,$nfa,$self);
  !wantarray ? $nfa : ($lines,$width,$prec,$nfa)
}
#line 12095 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 12100 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 LineSegmentDetector_drawSegments

=for sig

  Signature: ([io,phys] image(l2,c2,r2); [phys] lines(l3,c3,r3); LineSegmentDetectorWrapper * self)

=for ref

Draws the line segments on a given image.

=for example

 $obj->drawSegments($image,$lines);

Parameters:

=over

=item image

The image, where the lines will be drawn. Should be bigger or equal to the image,
    where the lines were found.

=item lines

A vector of the lines that needed to be drawn.

=back


=for bad

LineSegmentDetector_drawSegments ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 12145 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::LineSegmentDetector::drawSegments {
  barf "Usage: PDL::OpenCV::LineSegmentDetector::drawSegments(\$self,\$image,\$lines)\n" if @_ < 3;
  my ($self,$image,$lines) = @_;
    
  PDL::OpenCV::LineSegmentDetector::_LineSegmentDetector_drawSegments_int($image,$lines,$self);
  
}
#line 12158 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 12163 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 LineSegmentDetector_compareSegments

=for sig

  Signature: (indx [phys] size(n2=2); [phys] lines1(l3,c3,r3); [phys] lines2(l4,c4,r4); [io,phys] image(l5,c5,r5); int [o,phys] res(); LineSegmentDetectorWrapper * self)

=for ref

Draws two groups of lines in blue and red, counting the non overlapping (mismatching) pixels.

=for example

 $res = $obj->compareSegments($size,$lines1,$lines2); # with defaults
 $res = $obj->compareSegments($size,$lines1,$lines2,$image);

Parameters:

=over

=item size

The size of the image, where lines1 and lines2 were found.

=item lines1

The first group of lines that needs to be drawn. It is visualized in blue color.

=item lines2

The second group of lines. They visualized in red color.

=item image

Optional image, where the lines will be drawn. The image should be color(3-channel)
    in order for lines1 and lines2 to be drawn in the above mentioned colors.

=back


=for bad

LineSegmentDetector_compareSegments ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 12217 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::LineSegmentDetector::compareSegments {
  barf "Usage: PDL::OpenCV::LineSegmentDetector::compareSegments(\$self,\$size,\$lines1,\$lines2,\$image)\n" if @_ < 4;
  my ($self,$size,$lines1,$lines2,$image) = @_;
  my ($res);
  $image = PDL->zeroes(sbyte,0,0,0) if !defined $image;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::LineSegmentDetector::_LineSegmentDetector_compareSegments_int($size,$lines1,$lines2,$image,$res,$self);
  !wantarray ? $res : ($res)
}
#line 12232 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 12237 "Imgproc.pm"



#line 394 "../genpp.pl"

=head1 METHODS for PDL::OpenCV::Subdiv2D





=cut

@PDL::OpenCV::Subdiv2D::ISA = qw();
#line 12252 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 new

=for ref

=for example

 $obj = PDL::OpenCV::Subdiv2D->new;

creates an empty Subdiv2D object.
To create a new empty Delaunay subdivision you need to use the #initDelaunay function.

=cut
#line 12270 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 Subdiv2D_new2

=for sig

  Signature: (indx [phys] rect(n2=4); char * klass; [o] Subdiv2DWrapper * res)

=for ref

=for example

 $obj = PDL::OpenCV::Subdiv2D->new2($rect);

@overload
The function creates an empty Delaunay subdivision where 2D points can be added using the function
insert() . All of the points to be added must be within the specified rectangle, otherwise a runtime
error is raised.

Parameters:

=over

=item rect

Rectangle that includes all of the 2D points that are to be added to the subdivision.

=back


=for bad

Subdiv2D_new2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 12313 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Subdiv2D::new2 {
  barf "Usage: PDL::OpenCV::Subdiv2D::new2(\$klass,\$rect)\n" if @_ < 2;
  my ($klass,$rect) = @_;
  my ($res);
  
  PDL::OpenCV::Subdiv2D::_Subdiv2D_new2_int($rect,$klass,$res);
  !wantarray ? $res : ($res)
}
#line 12327 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 12332 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 Subdiv2D_initDelaunay

=for sig

  Signature: (indx [phys] rect(n2=4); Subdiv2DWrapper * self)

=for ref

Creates a new empty Delaunay subdivision

=for example

 $obj->initDelaunay($rect);

Parameters:

=over

=item rect

Rectangle that includes all of the 2D points that are to be added to the subdivision.

=back


=for bad

Subdiv2D_initDelaunay ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 12372 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Subdiv2D::initDelaunay {
  barf "Usage: PDL::OpenCV::Subdiv2D::initDelaunay(\$self,\$rect)\n" if @_ < 2;
  my ($self,$rect) = @_;
    
  PDL::OpenCV::Subdiv2D::_Subdiv2D_initDelaunay_int($rect,$self);
  
}
#line 12385 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 12390 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 Subdiv2D_insert

=for sig

  Signature: (float [phys] pt(n2=2); int [o,phys] res(); Subdiv2DWrapper * self)

=for ref

Insert a single point into a Delaunay triangulation.

=for example

 $res = $obj->insert($pt);

The function inserts a single point into a subdivision and modifies the subdivision topology
appropriately. If a point with the same coordinates exists already, no new point is added.
@note If the point is outside of the triangulation specified rect a runtime error is raised.

Parameters:

=over

=item pt

Point to insert.

=back

Returns: the ID of the point.


=for bad

Subdiv2D_insert ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 12436 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Subdiv2D::insert {
  barf "Usage: PDL::OpenCV::Subdiv2D::insert(\$self,\$pt)\n" if @_ < 2;
  my ($self,$pt) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Subdiv2D::_Subdiv2D_insert_int($pt,$res,$self);
  !wantarray ? $res : ($res)
}
#line 12450 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 12455 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 Subdiv2D_insert2

=for sig

  Signature: (float [phys] ptvec(n2=2,n2d0); Subdiv2DWrapper * self)

=for ref

Insert multiple points into a Delaunay triangulation.

=for example

 $obj->insert2($ptvec);

The function inserts a vector of points into a subdivision and modifies the subdivision topology
appropriately.

Parameters:

=over

=item ptvec

Points to insert.

=back


=for bad

Subdiv2D_insert2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 12498 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Subdiv2D::insert2 {
  barf "Usage: PDL::OpenCV::Subdiv2D::insert2(\$self,\$ptvec)\n" if @_ < 2;
  my ($self,$ptvec) = @_;
    
  PDL::OpenCV::Subdiv2D::_Subdiv2D_insert2_int($ptvec,$self);
  
}
#line 12511 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 12516 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 Subdiv2D_locate

=for sig

  Signature: (float [phys] pt(n2=2); int [o,phys] edge(); int [o,phys] vertex(); int [o,phys] res(); Subdiv2DWrapper * self)

=for ref

Returns the location of a point within a Delaunay triangulation.

=for example

 ($edge,$vertex,$res) = $obj->locate($pt);

The function locates the input point within the subdivision and gives one of the triangle edges
or vertices.

Parameters:

=over

=item pt

Point to locate.

=item edge

Output edge that the point belongs to or is located to the right of it.

=item vertex

Optional output vertex the input point coincides with.

=back

Returns: an integer which specify one of the following five cases for point location:
    -  The point falls into some facet. The function returns #PTLOC_INSIDE and edge will contain one of
       edges of the facet.
    -  The point falls onto the edge. The function returns #PTLOC_ON_EDGE and edge will contain this edge.
    -  The point coincides with one of the subdivision vertices. The function returns #PTLOC_VERTEX and
       vertex will contain a pointer to the vertex.
    -  The point is outside the subdivision reference rectangle. The function returns #PTLOC_OUTSIDE_RECT
       and no pointers are filled.
    -  One of input arguments is invalid. A runtime error is raised or, if silent or "parent" error
       processing mode is selected, #PTLOC_ERROR is returned.


=for bad

Subdiv2D_locate ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 12578 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Subdiv2D::locate {
  barf "Usage: PDL::OpenCV::Subdiv2D::locate(\$self,\$pt)\n" if @_ < 2;
  my ($self,$pt) = @_;
  my ($edge,$vertex,$res);
  $edge = PDL->null if !defined $edge;
  $vertex = PDL->null if !defined $vertex;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Subdiv2D::_Subdiv2D_locate_int($pt,$edge,$vertex,$res,$self);
  !wantarray ? $res : ($edge,$vertex,$res)
}
#line 12594 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 12599 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 Subdiv2D_findNearest

=for sig

  Signature: (float [phys] pt(n2=2); float [o,phys] nearestPt(n3=2); int [o,phys] res(); Subdiv2DWrapper * self)

=for ref

Finds the subdivision vertex closest to the given point.

=for example

 ($nearestPt,$res) = $obj->findNearest($pt);

The function is another function that locates the input point within the subdivision. It finds the
subdivision vertex that is the closest to the input point. It is not necessarily one of vertices
of the facet containing the input point, though the facet (located using locate() ) is used as a
starting point.

Parameters:

=over

=item pt

Input point.

=item nearestPt

Output subdivision vertex point.

=back

Returns: vertex ID.


=for bad

Subdiv2D_findNearest ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 12650 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Subdiv2D::findNearest {
  barf "Usage: PDL::OpenCV::Subdiv2D::findNearest(\$self,\$pt)\n" if @_ < 2;
  my ($self,$pt) = @_;
  my ($nearestPt,$res);
  $nearestPt = PDL->null if !defined $nearestPt;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Subdiv2D::_Subdiv2D_findNearest_int($pt,$nearestPt,$res,$self);
  !wantarray ? $res : ($nearestPt,$res)
}
#line 12665 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 12670 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 Subdiv2D_getEdgeList

=for sig

  Signature: (float [o,phys] edgeList(n2=4,n2d0); Subdiv2DWrapper * self)

=for ref

Returns a list of all edges. NO BROADCASTING.

=for example

 $edgeList = $obj->getEdgeList;

The function gives each edge as a 4 numbers vector, where each two are one of the edge
vertices. i.e. org_x = v[0], org_y = v[1], dst_x = v[2], dst_y = v[3].

Parameters:

=over

=item edgeList

Output vector.

=back


=for bad

Subdiv2D_getEdgeList ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 12713 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Subdiv2D::getEdgeList {
  barf "Usage: PDL::OpenCV::Subdiv2D::getEdgeList(\$self)\n" if @_ < 1;
  my ($self) = @_;
  my ($edgeList);
  $edgeList = PDL->null if !defined $edgeList;
  PDL::OpenCV::Subdiv2D::_Subdiv2D_getEdgeList_int($edgeList,$self);
  !wantarray ? $edgeList : ($edgeList)
}
#line 12727 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 12732 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 Subdiv2D_getLeadingEdgeList

=for sig

  Signature: (int [o,phys] leadingEdgeList(n2d0); Subdiv2DWrapper * self)

=for ref

Returns a list of the leading edge ID connected to each triangle. NO BROADCASTING.

=for example

 $leadingEdgeList = $obj->getLeadingEdgeList;

The function gives one edge ID for each triangle.

Parameters:

=over

=item leadingEdgeList

Output vector.

=back


=for bad

Subdiv2D_getLeadingEdgeList ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 12774 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Subdiv2D::getLeadingEdgeList {
  barf "Usage: PDL::OpenCV::Subdiv2D::getLeadingEdgeList(\$self)\n" if @_ < 1;
  my ($self) = @_;
  my ($leadingEdgeList);
  $leadingEdgeList = PDL->null if !defined $leadingEdgeList;
  PDL::OpenCV::Subdiv2D::_Subdiv2D_getLeadingEdgeList_int($leadingEdgeList,$self);
  !wantarray ? $leadingEdgeList : ($leadingEdgeList)
}
#line 12788 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 12793 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 Subdiv2D_getTriangleList

=for sig

  Signature: (float [o,phys] triangleList(n2=6,n2d0); Subdiv2DWrapper * self)

=for ref

Returns a list of all triangles. NO BROADCASTING.

=for example

 $triangleList = $obj->getTriangleList;

The function gives each triangle as a 6 numbers vector, where each two are one of the triangle
vertices. i.e. p1_x = v[0], p1_y = v[1], p2_x = v[2], p2_y = v[3], p3_x = v[4], p3_y = v[5].

Parameters:

=over

=item triangleList

Output vector.

=back


=for bad

Subdiv2D_getTriangleList ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 12836 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Subdiv2D::getTriangleList {
  barf "Usage: PDL::OpenCV::Subdiv2D::getTriangleList(\$self)\n" if @_ < 1;
  my ($self) = @_;
  my ($triangleList);
  $triangleList = PDL->null if !defined $triangleList;
  PDL::OpenCV::Subdiv2D::_Subdiv2D_getTriangleList_int($triangleList,$self);
  !wantarray ? $triangleList : ($triangleList)
}
#line 12850 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 12855 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 Subdiv2D_getVoronoiFacetList

=for sig

  Signature: (int [phys] idx(n2d0); float [o,phys] facetCenters(n4=2,n4d0); Subdiv2DWrapper * self; [o] vector_vector_Point2fWrapper * facetList)

=for ref

Returns a list of all Voronoi facets. NO BROADCASTING.

=for example

 ($facetList,$facetCenters) = $obj->getVoronoiFacetList($idx);

Parameters:

=over

=item idx

Vector of vertices IDs to consider. For all vertices you can pass empty vector.

=item facetList

Output vector of the Voronoi facets.

=item facetCenters

Output vector of the Voronoi facets center points.

=back


=for bad

Subdiv2D_getVoronoiFacetList ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 12903 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Subdiv2D::getVoronoiFacetList {
  barf "Usage: PDL::OpenCV::Subdiv2D::getVoronoiFacetList(\$self,\$idx)\n" if @_ < 2;
  my ($self,$idx) = @_;
  my ($facetList,$facetCenters);
  $facetCenters = PDL->null if !defined $facetCenters;
  PDL::OpenCV::Subdiv2D::_Subdiv2D_getVoronoiFacetList_int($idx,$facetCenters,$self,$facetList);
  !wantarray ? $facetCenters : ($facetList,$facetCenters)
}
#line 12917 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 12922 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 Subdiv2D_getVertex

=for sig

  Signature: (int [phys] vertex(); int [o,phys] firstEdge(); float [o,phys] res(n4=2); Subdiv2DWrapper * self)

=for ref

Returns vertex location from vertex ID.

=for example

 ($firstEdge,$res) = $obj->getVertex($vertex);

Parameters:

=over

=item vertex

vertex ID.

=item firstEdge

Optional. The first edge ID which is connected to the vertex.

=back

Returns: vertex (x,y)


=for bad

Subdiv2D_getVertex ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 12968 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Subdiv2D::getVertex {
  barf "Usage: PDL::OpenCV::Subdiv2D::getVertex(\$self,\$vertex)\n" if @_ < 2;
  my ($self,$vertex) = @_;
  my ($firstEdge,$res);
  $firstEdge = PDL->null if !defined $firstEdge;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Subdiv2D::_Subdiv2D_getVertex_int($vertex,$firstEdge,$res,$self);
  !wantarray ? $res : ($firstEdge,$res)
}
#line 12983 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 12988 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 getEdge

=for ref

Returns one of the edges related to the given edge.

=for example

 $res = $obj->getEdge($edge,$nextEdgeType);

![sample output](pics/quadedge.png)

Parameters:

=over

=item edge

Subdivision edge ID.

=item nextEdgeType

Parameter specifying which of the related edges to return.
    The following values are possible:
    -   NEXT_AROUND_ORG next around the edge origin ( eOnext on the picture below if e is the input edge)
    -   NEXT_AROUND_DST next around the edge vertex ( eDnext )
    -   PREV_AROUND_ORG previous around the edge origin (reversed eRnext )
    -   PREV_AROUND_DST previous around the edge destination (reversed eLnext )
    -   NEXT_AROUND_LEFT next around the left facet ( eLnext )
    -   NEXT_AROUND_RIGHT next around the right facet ( eRnext )
    -   PREV_AROUND_LEFT previous around the left facet (reversed eOnext )
    -   PREV_AROUND_RIGHT previous around the right facet (reversed eDnext )

=back

Returns: edge ID related to the input edge.


=cut
#line 13033 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 nextEdge

=for ref

Returns next edge around the edge origin.

=for example

 $res = $obj->nextEdge($edge);

Parameters:

=over

=item edge

Subdivision edge ID.

=back

Returns: an integer which is next edge ID around the edge origin: eOnext on the
    picture above if e is the input edge).


=cut
#line 13064 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 rotateEdge

=for ref

Returns another edge of the same quad-edge.

=for example

 $res = $obj->rotateEdge($edge,$rotate);

Parameters:

=over

=item edge

Subdivision edge ID.

=item rotate

Parameter specifying which of the edges of the same quad-edge as the input
    one to return. The following values are possible:
    -   0 - the input edge ( e on the picture below if e is the input edge)
    -   1 - the rotated edge ( eRot )
    -   2 - the reversed edge (reversed e (in green))
    -   3 - the reversed rotated edge (reversed eRot (in green))

=back

Returns: one of the edges ID of the same quad-edge as the input edge.


=cut
#line 13103 "Imgproc.pm"



#line 274 "../genpp.pl"

=head2 symEdge

=for ref

=for example

 $res = $obj->symEdge($edge);


=cut
#line 13119 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 Subdiv2D_edgeOrg

=for sig

  Signature: (int [phys] edge(); float [o,phys] orgpt(n3=2); int [o,phys] res(); Subdiv2DWrapper * self)

=for ref

Returns the edge origin.

=for example

 ($orgpt,$res) = $obj->edgeOrg($edge);

Parameters:

=over

=item edge

Subdivision edge ID.

=item orgpt

Output vertex location.

=back

Returns: vertex ID.


=for bad

Subdiv2D_edgeOrg ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 13165 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Subdiv2D::edgeOrg {
  barf "Usage: PDL::OpenCV::Subdiv2D::edgeOrg(\$self,\$edge)\n" if @_ < 2;
  my ($self,$edge) = @_;
  my ($orgpt,$res);
  $orgpt = PDL->null if !defined $orgpt;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Subdiv2D::_Subdiv2D_edgeOrg_int($edge,$orgpt,$res,$self);
  !wantarray ? $res : ($orgpt,$res)
}
#line 13180 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 13185 "Imgproc.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 Subdiv2D_edgeDst

=for sig

  Signature: (int [phys] edge(); float [o,phys] dstpt(n3=2); int [o,phys] res(); Subdiv2DWrapper * self)

=for ref

Returns the edge destination.

=for example

 ($dstpt,$res) = $obj->edgeDst($edge);

Parameters:

=over

=item edge

Subdivision edge ID.

=item dstpt

Output vertex location.

=back

Returns: vertex ID.


=for bad

Subdiv2D_edgeDst ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 13231 "Imgproc.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Subdiv2D::edgeDst {
  barf "Usage: PDL::OpenCV::Subdiv2D::edgeDst(\$self,\$edge)\n" if @_ < 2;
  my ($self,$edge) = @_;
  my ($dstpt,$res);
  $dstpt = PDL->null if !defined $dstpt;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Subdiv2D::_Subdiv2D_edgeDst_int($edge,$dstpt,$res,$self);
  !wantarray ? $res : ($dstpt,$res)
}
#line 13246 "Imgproc.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 13251 "Imgproc.pm"



#line 441 "../genpp.pl"

=head1 CONSTANTS

=over

=item PDL::OpenCV::Imgproc::FILTER_SCHARR()

=item PDL::OpenCV::Imgproc::MORPH_ERODE()

=item PDL::OpenCV::Imgproc::MORPH_DILATE()

=item PDL::OpenCV::Imgproc::MORPH_OPEN()

=item PDL::OpenCV::Imgproc::MORPH_CLOSE()

=item PDL::OpenCV::Imgproc::MORPH_GRADIENT()

=item PDL::OpenCV::Imgproc::MORPH_TOPHAT()

=item PDL::OpenCV::Imgproc::MORPH_BLACKHAT()

=item PDL::OpenCV::Imgproc::MORPH_HITMISS()

=item PDL::OpenCV::Imgproc::MORPH_RECT()

=item PDL::OpenCV::Imgproc::MORPH_CROSS()

=item PDL::OpenCV::Imgproc::MORPH_ELLIPSE()

=item PDL::OpenCV::Imgproc::INTER_NEAREST()

=item PDL::OpenCV::Imgproc::INTER_LINEAR()

=item PDL::OpenCV::Imgproc::INTER_CUBIC()

=item PDL::OpenCV::Imgproc::INTER_AREA()

=item PDL::OpenCV::Imgproc::INTER_LANCZOS4()

=item PDL::OpenCV::Imgproc::INTER_LINEAR_EXACT()

=item PDL::OpenCV::Imgproc::INTER_NEAREST_EXACT()

=item PDL::OpenCV::Imgproc::INTER_MAX()

=item PDL::OpenCV::Imgproc::WARP_FILL_OUTLIERS()

=item PDL::OpenCV::Imgproc::WARP_INVERSE_MAP()

=item PDL::OpenCV::Imgproc::WARP_POLAR_LINEAR()

=item PDL::OpenCV::Imgproc::WARP_POLAR_LOG()

=item PDL::OpenCV::Imgproc::INTER_BITS()

=item PDL::OpenCV::Imgproc::INTER_BITS2()

=item PDL::OpenCV::Imgproc::INTER_TAB_SIZE()

=item PDL::OpenCV::Imgproc::INTER_TAB_SIZE2()

=item PDL::OpenCV::Imgproc::DIST_USER()

=item PDL::OpenCV::Imgproc::DIST_L1()

=item PDL::OpenCV::Imgproc::DIST_L2()

=item PDL::OpenCV::Imgproc::DIST_C()

=item PDL::OpenCV::Imgproc::DIST_L12()

=item PDL::OpenCV::Imgproc::DIST_FAIR()

=item PDL::OpenCV::Imgproc::DIST_WELSCH()

=item PDL::OpenCV::Imgproc::DIST_HUBER()

=item PDL::OpenCV::Imgproc::DIST_MASK_3()

=item PDL::OpenCV::Imgproc::DIST_MASK_5()

=item PDL::OpenCV::Imgproc::DIST_MASK_PRECISE()

=item PDL::OpenCV::Imgproc::THRESH_BINARY()

=item PDL::OpenCV::Imgproc::THRESH_BINARY_INV()

=item PDL::OpenCV::Imgproc::THRESH_TRUNC()

=item PDL::OpenCV::Imgproc::THRESH_TOZERO()

=item PDL::OpenCV::Imgproc::THRESH_TOZERO_INV()

=item PDL::OpenCV::Imgproc::THRESH_MASK()

=item PDL::OpenCV::Imgproc::THRESH_OTSU()

=item PDL::OpenCV::Imgproc::THRESH_TRIANGLE()

=item PDL::OpenCV::Imgproc::ADAPTIVE_THRESH_MEAN_C()

=item PDL::OpenCV::Imgproc::ADAPTIVE_THRESH_GAUSSIAN_C()

=item PDL::OpenCV::Imgproc::GC_BGD()

=item PDL::OpenCV::Imgproc::GC_FGD()

=item PDL::OpenCV::Imgproc::GC_PR_BGD()

=item PDL::OpenCV::Imgproc::GC_PR_FGD()

=item PDL::OpenCV::Imgproc::GC_INIT_WITH_RECT()

=item PDL::OpenCV::Imgproc::GC_INIT_WITH_MASK()

=item PDL::OpenCV::Imgproc::GC_EVAL()

=item PDL::OpenCV::Imgproc::GC_EVAL_FREEZE_MODEL()

=item PDL::OpenCV::Imgproc::DIST_LABEL_CCOMP()

=item PDL::OpenCV::Imgproc::DIST_LABEL_PIXEL()

=item PDL::OpenCV::Imgproc::FLOODFILL_FIXED_RANGE()

=item PDL::OpenCV::Imgproc::FLOODFILL_MASK_ONLY()

=item PDL::OpenCV::Imgproc::CC_STAT_LEFT()

=item PDL::OpenCV::Imgproc::CC_STAT_TOP()

=item PDL::OpenCV::Imgproc::CC_STAT_WIDTH()

=item PDL::OpenCV::Imgproc::CC_STAT_HEIGHT()

=item PDL::OpenCV::Imgproc::CC_STAT_AREA()

=item PDL::OpenCV::Imgproc::CC_STAT_MAX()

=item PDL::OpenCV::Imgproc::CCL_DEFAULT()

=item PDL::OpenCV::Imgproc::CCL_WU()

=item PDL::OpenCV::Imgproc::CCL_GRANA()

=item PDL::OpenCV::Imgproc::CCL_BOLELLI()

=item PDL::OpenCV::Imgproc::CCL_SAUF()

=item PDL::OpenCV::Imgproc::CCL_BBDT()

=item PDL::OpenCV::Imgproc::CCL_SPAGHETTI()

=item PDL::OpenCV::Imgproc::RETR_EXTERNAL()

=item PDL::OpenCV::Imgproc::RETR_LIST()

=item PDL::OpenCV::Imgproc::RETR_CCOMP()

=item PDL::OpenCV::Imgproc::RETR_TREE()

=item PDL::OpenCV::Imgproc::RETR_FLOODFILL()

=item PDL::OpenCV::Imgproc::CHAIN_APPROX_NONE()

=item PDL::OpenCV::Imgproc::CHAIN_APPROX_SIMPLE()

=item PDL::OpenCV::Imgproc::CHAIN_APPROX_TC89_L1()

=item PDL::OpenCV::Imgproc::CHAIN_APPROX_TC89_KCOS()

=item PDL::OpenCV::Imgproc::CONTOURS_MATCH_I1()

=item PDL::OpenCV::Imgproc::CONTOURS_MATCH_I2()

=item PDL::OpenCV::Imgproc::CONTOURS_MATCH_I3()

=item PDL::OpenCV::Imgproc::HOUGH_STANDARD()

=item PDL::OpenCV::Imgproc::HOUGH_PROBABILISTIC()

=item PDL::OpenCV::Imgproc::HOUGH_MULTI_SCALE()

=item PDL::OpenCV::Imgproc::HOUGH_GRADIENT()

=item PDL::OpenCV::Imgproc::HOUGH_GRADIENT_ALT()

=item PDL::OpenCV::Imgproc::LSD_REFINE_NONE()

=item PDL::OpenCV::Imgproc::LSD_REFINE_STD()

=item PDL::OpenCV::Imgproc::LSD_REFINE_ADV()

=item PDL::OpenCV::Imgproc::HISTCMP_CORREL()

=item PDL::OpenCV::Imgproc::HISTCMP_CHISQR()

=item PDL::OpenCV::Imgproc::HISTCMP_INTERSECT()

=item PDL::OpenCV::Imgproc::HISTCMP_BHATTACHARYYA()

=item PDL::OpenCV::Imgproc::HISTCMP_HELLINGER()

=item PDL::OpenCV::Imgproc::HISTCMP_CHISQR_ALT()

=item PDL::OpenCV::Imgproc::HISTCMP_KL_DIV()

=item PDL::OpenCV::Imgproc::COLOR_BGR2BGRA()

=item PDL::OpenCV::Imgproc::COLOR_RGB2RGBA()

=item PDL::OpenCV::Imgproc::COLOR_BGRA2BGR()

=item PDL::OpenCV::Imgproc::COLOR_RGBA2RGB()

=item PDL::OpenCV::Imgproc::COLOR_BGR2RGBA()

=item PDL::OpenCV::Imgproc::COLOR_RGB2BGRA()

=item PDL::OpenCV::Imgproc::COLOR_RGBA2BGR()

=item PDL::OpenCV::Imgproc::COLOR_BGRA2RGB()

=item PDL::OpenCV::Imgproc::COLOR_BGR2RGB()

=item PDL::OpenCV::Imgproc::COLOR_RGB2BGR()

=item PDL::OpenCV::Imgproc::COLOR_BGRA2RGBA()

=item PDL::OpenCV::Imgproc::COLOR_RGBA2BGRA()

=item PDL::OpenCV::Imgproc::COLOR_BGR2GRAY()

=item PDL::OpenCV::Imgproc::COLOR_RGB2GRAY()

=item PDL::OpenCV::Imgproc::COLOR_GRAY2BGR()

=item PDL::OpenCV::Imgproc::COLOR_GRAY2RGB()

=item PDL::OpenCV::Imgproc::COLOR_GRAY2BGRA()

=item PDL::OpenCV::Imgproc::COLOR_GRAY2RGBA()

=item PDL::OpenCV::Imgproc::COLOR_BGRA2GRAY()

=item PDL::OpenCV::Imgproc::COLOR_RGBA2GRAY()

=item PDL::OpenCV::Imgproc::COLOR_BGR2BGR565()

=item PDL::OpenCV::Imgproc::COLOR_RGB2BGR565()

=item PDL::OpenCV::Imgproc::COLOR_BGR5652BGR()

=item PDL::OpenCV::Imgproc::COLOR_BGR5652RGB()

=item PDL::OpenCV::Imgproc::COLOR_BGRA2BGR565()

=item PDL::OpenCV::Imgproc::COLOR_RGBA2BGR565()

=item PDL::OpenCV::Imgproc::COLOR_BGR5652BGRA()

=item PDL::OpenCV::Imgproc::COLOR_BGR5652RGBA()

=item PDL::OpenCV::Imgproc::COLOR_GRAY2BGR565()

=item PDL::OpenCV::Imgproc::COLOR_BGR5652GRAY()

=item PDL::OpenCV::Imgproc::COLOR_BGR2BGR555()

=item PDL::OpenCV::Imgproc::COLOR_RGB2BGR555()

=item PDL::OpenCV::Imgproc::COLOR_BGR5552BGR()

=item PDL::OpenCV::Imgproc::COLOR_BGR5552RGB()

=item PDL::OpenCV::Imgproc::COLOR_BGRA2BGR555()

=item PDL::OpenCV::Imgproc::COLOR_RGBA2BGR555()

=item PDL::OpenCV::Imgproc::COLOR_BGR5552BGRA()

=item PDL::OpenCV::Imgproc::COLOR_BGR5552RGBA()

=item PDL::OpenCV::Imgproc::COLOR_GRAY2BGR555()

=item PDL::OpenCV::Imgproc::COLOR_BGR5552GRAY()

=item PDL::OpenCV::Imgproc::COLOR_BGR2XYZ()

=item PDL::OpenCV::Imgproc::COLOR_RGB2XYZ()

=item PDL::OpenCV::Imgproc::COLOR_XYZ2BGR()

=item PDL::OpenCV::Imgproc::COLOR_XYZ2RGB()

=item PDL::OpenCV::Imgproc::COLOR_BGR2YCrCb()

=item PDL::OpenCV::Imgproc::COLOR_RGB2YCrCb()

=item PDL::OpenCV::Imgproc::COLOR_YCrCb2BGR()

=item PDL::OpenCV::Imgproc::COLOR_YCrCb2RGB()

=item PDL::OpenCV::Imgproc::COLOR_BGR2HSV()

=item PDL::OpenCV::Imgproc::COLOR_RGB2HSV()

=item PDL::OpenCV::Imgproc::COLOR_BGR2Lab()

=item PDL::OpenCV::Imgproc::COLOR_RGB2Lab()

=item PDL::OpenCV::Imgproc::COLOR_BGR2Luv()

=item PDL::OpenCV::Imgproc::COLOR_RGB2Luv()

=item PDL::OpenCV::Imgproc::COLOR_BGR2HLS()

=item PDL::OpenCV::Imgproc::COLOR_RGB2HLS()

=item PDL::OpenCV::Imgproc::COLOR_HSV2BGR()

=item PDL::OpenCV::Imgproc::COLOR_HSV2RGB()

=item PDL::OpenCV::Imgproc::COLOR_Lab2BGR()

=item PDL::OpenCV::Imgproc::COLOR_Lab2RGB()

=item PDL::OpenCV::Imgproc::COLOR_Luv2BGR()

=item PDL::OpenCV::Imgproc::COLOR_Luv2RGB()

=item PDL::OpenCV::Imgproc::COLOR_HLS2BGR()

=item PDL::OpenCV::Imgproc::COLOR_HLS2RGB()

=item PDL::OpenCV::Imgproc::COLOR_BGR2HSV_FULL()

=item PDL::OpenCV::Imgproc::COLOR_RGB2HSV_FULL()

=item PDL::OpenCV::Imgproc::COLOR_BGR2HLS_FULL()

=item PDL::OpenCV::Imgproc::COLOR_RGB2HLS_FULL()

=item PDL::OpenCV::Imgproc::COLOR_HSV2BGR_FULL()

=item PDL::OpenCV::Imgproc::COLOR_HSV2RGB_FULL()

=item PDL::OpenCV::Imgproc::COLOR_HLS2BGR_FULL()

=item PDL::OpenCV::Imgproc::COLOR_HLS2RGB_FULL()

=item PDL::OpenCV::Imgproc::COLOR_LBGR2Lab()

=item PDL::OpenCV::Imgproc::COLOR_LRGB2Lab()

=item PDL::OpenCV::Imgproc::COLOR_LBGR2Luv()

=item PDL::OpenCV::Imgproc::COLOR_LRGB2Luv()

=item PDL::OpenCV::Imgproc::COLOR_Lab2LBGR()

=item PDL::OpenCV::Imgproc::COLOR_Lab2LRGB()

=item PDL::OpenCV::Imgproc::COLOR_Luv2LBGR()

=item PDL::OpenCV::Imgproc::COLOR_Luv2LRGB()

=item PDL::OpenCV::Imgproc::COLOR_BGR2YUV()

=item PDL::OpenCV::Imgproc::COLOR_RGB2YUV()

=item PDL::OpenCV::Imgproc::COLOR_YUV2BGR()

=item PDL::OpenCV::Imgproc::COLOR_YUV2RGB()

=item PDL::OpenCV::Imgproc::COLOR_YUV2RGB_NV12()

=item PDL::OpenCV::Imgproc::COLOR_YUV2BGR_NV12()

=item PDL::OpenCV::Imgproc::COLOR_YUV2RGB_NV21()

=item PDL::OpenCV::Imgproc::COLOR_YUV2BGR_NV21()

=item PDL::OpenCV::Imgproc::COLOR_YUV420sp2RGB()

=item PDL::OpenCV::Imgproc::COLOR_YUV420sp2BGR()

=item PDL::OpenCV::Imgproc::COLOR_YUV2RGBA_NV12()

=item PDL::OpenCV::Imgproc::COLOR_YUV2BGRA_NV12()

=item PDL::OpenCV::Imgproc::COLOR_YUV2RGBA_NV21()

=item PDL::OpenCV::Imgproc::COLOR_YUV2BGRA_NV21()

=item PDL::OpenCV::Imgproc::COLOR_YUV420sp2RGBA()

=item PDL::OpenCV::Imgproc::COLOR_YUV420sp2BGRA()

=item PDL::OpenCV::Imgproc::COLOR_YUV2RGB_YV12()

=item PDL::OpenCV::Imgproc::COLOR_YUV2BGR_YV12()

=item PDL::OpenCV::Imgproc::COLOR_YUV2RGB_IYUV()

=item PDL::OpenCV::Imgproc::COLOR_YUV2BGR_IYUV()

=item PDL::OpenCV::Imgproc::COLOR_YUV2RGB_I420()

=item PDL::OpenCV::Imgproc::COLOR_YUV2BGR_I420()

=item PDL::OpenCV::Imgproc::COLOR_YUV420p2RGB()

=item PDL::OpenCV::Imgproc::COLOR_YUV420p2BGR()

=item PDL::OpenCV::Imgproc::COLOR_YUV2RGBA_YV12()

=item PDL::OpenCV::Imgproc::COLOR_YUV2BGRA_YV12()

=item PDL::OpenCV::Imgproc::COLOR_YUV2RGBA_IYUV()

=item PDL::OpenCV::Imgproc::COLOR_YUV2BGRA_IYUV()

=item PDL::OpenCV::Imgproc::COLOR_YUV2RGBA_I420()

=item PDL::OpenCV::Imgproc::COLOR_YUV2BGRA_I420()

=item PDL::OpenCV::Imgproc::COLOR_YUV420p2RGBA()

=item PDL::OpenCV::Imgproc::COLOR_YUV420p2BGRA()

=item PDL::OpenCV::Imgproc::COLOR_YUV2GRAY_420()

=item PDL::OpenCV::Imgproc::COLOR_YUV2GRAY_NV21()

=item PDL::OpenCV::Imgproc::COLOR_YUV2GRAY_NV12()

=item PDL::OpenCV::Imgproc::COLOR_YUV2GRAY_YV12()

=item PDL::OpenCV::Imgproc::COLOR_YUV2GRAY_IYUV()

=item PDL::OpenCV::Imgproc::COLOR_YUV2GRAY_I420()

=item PDL::OpenCV::Imgproc::COLOR_YUV420sp2GRAY()

=item PDL::OpenCV::Imgproc::COLOR_YUV420p2GRAY()

=item PDL::OpenCV::Imgproc::COLOR_YUV2RGB_UYVY()

=item PDL::OpenCV::Imgproc::COLOR_YUV2BGR_UYVY()

=item PDL::OpenCV::Imgproc::COLOR_YUV2RGB_Y422()

=item PDL::OpenCV::Imgproc::COLOR_YUV2BGR_Y422()

=item PDL::OpenCV::Imgproc::COLOR_YUV2RGB_UYNV()

=item PDL::OpenCV::Imgproc::COLOR_YUV2BGR_UYNV()

=item PDL::OpenCV::Imgproc::COLOR_YUV2RGBA_UYVY()

=item PDL::OpenCV::Imgproc::COLOR_YUV2BGRA_UYVY()

=item PDL::OpenCV::Imgproc::COLOR_YUV2RGBA_Y422()

=item PDL::OpenCV::Imgproc::COLOR_YUV2BGRA_Y422()

=item PDL::OpenCV::Imgproc::COLOR_YUV2RGBA_UYNV()

=item PDL::OpenCV::Imgproc::COLOR_YUV2BGRA_UYNV()

=item PDL::OpenCV::Imgproc::COLOR_YUV2RGB_YUY2()

=item PDL::OpenCV::Imgproc::COLOR_YUV2BGR_YUY2()

=item PDL::OpenCV::Imgproc::COLOR_YUV2RGB_YVYU()

=item PDL::OpenCV::Imgproc::COLOR_YUV2BGR_YVYU()

=item PDL::OpenCV::Imgproc::COLOR_YUV2RGB_YUYV()

=item PDL::OpenCV::Imgproc::COLOR_YUV2BGR_YUYV()

=item PDL::OpenCV::Imgproc::COLOR_YUV2RGB_YUNV()

=item PDL::OpenCV::Imgproc::COLOR_YUV2BGR_YUNV()

=item PDL::OpenCV::Imgproc::COLOR_YUV2RGBA_YUY2()

=item PDL::OpenCV::Imgproc::COLOR_YUV2BGRA_YUY2()

=item PDL::OpenCV::Imgproc::COLOR_YUV2RGBA_YVYU()

=item PDL::OpenCV::Imgproc::COLOR_YUV2BGRA_YVYU()

=item PDL::OpenCV::Imgproc::COLOR_YUV2RGBA_YUYV()

=item PDL::OpenCV::Imgproc::COLOR_YUV2BGRA_YUYV()

=item PDL::OpenCV::Imgproc::COLOR_YUV2RGBA_YUNV()

=item PDL::OpenCV::Imgproc::COLOR_YUV2BGRA_YUNV()

=item PDL::OpenCV::Imgproc::COLOR_YUV2GRAY_UYVY()

=item PDL::OpenCV::Imgproc::COLOR_YUV2GRAY_YUY2()

=item PDL::OpenCV::Imgproc::COLOR_YUV2GRAY_Y422()

=item PDL::OpenCV::Imgproc::COLOR_YUV2GRAY_UYNV()

=item PDL::OpenCV::Imgproc::COLOR_YUV2GRAY_YVYU()

=item PDL::OpenCV::Imgproc::COLOR_YUV2GRAY_YUYV()

=item PDL::OpenCV::Imgproc::COLOR_YUV2GRAY_YUNV()

=item PDL::OpenCV::Imgproc::COLOR_RGBA2mRGBA()

=item PDL::OpenCV::Imgproc::COLOR_mRGBA2RGBA()

=item PDL::OpenCV::Imgproc::COLOR_RGB2YUV_I420()

=item PDL::OpenCV::Imgproc::COLOR_BGR2YUV_I420()

=item PDL::OpenCV::Imgproc::COLOR_RGB2YUV_IYUV()

=item PDL::OpenCV::Imgproc::COLOR_BGR2YUV_IYUV()

=item PDL::OpenCV::Imgproc::COLOR_RGBA2YUV_I420()

=item PDL::OpenCV::Imgproc::COLOR_BGRA2YUV_I420()

=item PDL::OpenCV::Imgproc::COLOR_RGBA2YUV_IYUV()

=item PDL::OpenCV::Imgproc::COLOR_BGRA2YUV_IYUV()

=item PDL::OpenCV::Imgproc::COLOR_RGB2YUV_YV12()

=item PDL::OpenCV::Imgproc::COLOR_BGR2YUV_YV12()

=item PDL::OpenCV::Imgproc::COLOR_RGBA2YUV_YV12()

=item PDL::OpenCV::Imgproc::COLOR_BGRA2YUV_YV12()

=item PDL::OpenCV::Imgproc::COLOR_BayerBG2BGR()

=item PDL::OpenCV::Imgproc::COLOR_BayerGB2BGR()

=item PDL::OpenCV::Imgproc::COLOR_BayerRG2BGR()

=item PDL::OpenCV::Imgproc::COLOR_BayerGR2BGR()

=item PDL::OpenCV::Imgproc::COLOR_BayerBG2RGB()

=item PDL::OpenCV::Imgproc::COLOR_BayerGB2RGB()

=item PDL::OpenCV::Imgproc::COLOR_BayerRG2RGB()

=item PDL::OpenCV::Imgproc::COLOR_BayerGR2RGB()

=item PDL::OpenCV::Imgproc::COLOR_BayerBG2GRAY()

=item PDL::OpenCV::Imgproc::COLOR_BayerGB2GRAY()

=item PDL::OpenCV::Imgproc::COLOR_BayerRG2GRAY()

=item PDL::OpenCV::Imgproc::COLOR_BayerGR2GRAY()

=item PDL::OpenCV::Imgproc::COLOR_BayerBG2BGR_VNG()

=item PDL::OpenCV::Imgproc::COLOR_BayerGB2BGR_VNG()

=item PDL::OpenCV::Imgproc::COLOR_BayerRG2BGR_VNG()

=item PDL::OpenCV::Imgproc::COLOR_BayerGR2BGR_VNG()

=item PDL::OpenCV::Imgproc::COLOR_BayerBG2RGB_VNG()

=item PDL::OpenCV::Imgproc::COLOR_BayerGB2RGB_VNG()

=item PDL::OpenCV::Imgproc::COLOR_BayerRG2RGB_VNG()

=item PDL::OpenCV::Imgproc::COLOR_BayerGR2RGB_VNG()

=item PDL::OpenCV::Imgproc::COLOR_BayerBG2BGR_EA()

=item PDL::OpenCV::Imgproc::COLOR_BayerGB2BGR_EA()

=item PDL::OpenCV::Imgproc::COLOR_BayerRG2BGR_EA()

=item PDL::OpenCV::Imgproc::COLOR_BayerGR2BGR_EA()

=item PDL::OpenCV::Imgproc::COLOR_BayerBG2RGB_EA()

=item PDL::OpenCV::Imgproc::COLOR_BayerGB2RGB_EA()

=item PDL::OpenCV::Imgproc::COLOR_BayerRG2RGB_EA()

=item PDL::OpenCV::Imgproc::COLOR_BayerGR2RGB_EA()

=item PDL::OpenCV::Imgproc::COLOR_BayerBG2BGRA()

=item PDL::OpenCV::Imgproc::COLOR_BayerGB2BGRA()

=item PDL::OpenCV::Imgproc::COLOR_BayerRG2BGRA()

=item PDL::OpenCV::Imgproc::COLOR_BayerGR2BGRA()

=item PDL::OpenCV::Imgproc::COLOR_BayerBG2RGBA()

=item PDL::OpenCV::Imgproc::COLOR_BayerGB2RGBA()

=item PDL::OpenCV::Imgproc::COLOR_BayerRG2RGBA()

=item PDL::OpenCV::Imgproc::COLOR_BayerGR2RGBA()

=item PDL::OpenCV::Imgproc::COLOR_COLORCVT_MAX()

=item PDL::OpenCV::Imgproc::INTERSECT_NONE()

=item PDL::OpenCV::Imgproc::INTERSECT_PARTIAL()

=item PDL::OpenCV::Imgproc::INTERSECT_FULL()

=item PDL::OpenCV::Imgproc::FILLED()

=item PDL::OpenCV::Imgproc::LINE_4()

=item PDL::OpenCV::Imgproc::LINE_8()

=item PDL::OpenCV::Imgproc::LINE_AA()

=item PDL::OpenCV::Imgproc::FONT_HERSHEY_SIMPLEX()

=item PDL::OpenCV::Imgproc::FONT_HERSHEY_PLAIN()

=item PDL::OpenCV::Imgproc::FONT_HERSHEY_DUPLEX()

=item PDL::OpenCV::Imgproc::FONT_HERSHEY_COMPLEX()

=item PDL::OpenCV::Imgproc::FONT_HERSHEY_TRIPLEX()

=item PDL::OpenCV::Imgproc::FONT_HERSHEY_COMPLEX_SMALL()

=item PDL::OpenCV::Imgproc::FONT_HERSHEY_SCRIPT_SIMPLEX()

=item PDL::OpenCV::Imgproc::FONT_HERSHEY_SCRIPT_COMPLEX()

=item PDL::OpenCV::Imgproc::FONT_ITALIC()

=item PDL::OpenCV::Imgproc::MARKER_CROSS()

=item PDL::OpenCV::Imgproc::MARKER_TILTED_CROSS()

=item PDL::OpenCV::Imgproc::MARKER_STAR()

=item PDL::OpenCV::Imgproc::MARKER_DIAMOND()

=item PDL::OpenCV::Imgproc::MARKER_SQUARE()

=item PDL::OpenCV::Imgproc::MARKER_TRIANGLE_UP()

=item PDL::OpenCV::Imgproc::MARKER_TRIANGLE_DOWN()

=item PDL::OpenCV::Imgproc::TM_SQDIFF()

=item PDL::OpenCV::Imgproc::TM_SQDIFF_NORMED()

=item PDL::OpenCV::Imgproc::TM_CCORR()

=item PDL::OpenCV::Imgproc::TM_CCORR_NORMED()

=item PDL::OpenCV::Imgproc::TM_CCOEFF()

=item PDL::OpenCV::Imgproc::TM_CCOEFF_NORMED()

=item PDL::OpenCV::Imgproc::COLORMAP_AUTUMN()

=item PDL::OpenCV::Imgproc::COLORMAP_BONE()

=item PDL::OpenCV::Imgproc::COLORMAP_JET()

=item PDL::OpenCV::Imgproc::COLORMAP_WINTER()

=item PDL::OpenCV::Imgproc::COLORMAP_RAINBOW()

=item PDL::OpenCV::Imgproc::COLORMAP_OCEAN()

=item PDL::OpenCV::Imgproc::COLORMAP_SUMMER()

=item PDL::OpenCV::Imgproc::COLORMAP_SPRING()

=item PDL::OpenCV::Imgproc::COLORMAP_COOL()

=item PDL::OpenCV::Imgproc::COLORMAP_HSV()

=item PDL::OpenCV::Imgproc::COLORMAP_PINK()

=item PDL::OpenCV::Imgproc::COLORMAP_HOT()

=item PDL::OpenCV::Imgproc::COLORMAP_PARULA()

=item PDL::OpenCV::Imgproc::COLORMAP_MAGMA()

=item PDL::OpenCV::Imgproc::COLORMAP_INFERNO()

=item PDL::OpenCV::Imgproc::COLORMAP_PLASMA()

=item PDL::OpenCV::Imgproc::COLORMAP_VIRIDIS()

=item PDL::OpenCV::Imgproc::COLORMAP_CIVIDIS()

=item PDL::OpenCV::Imgproc::COLORMAP_TWILIGHT()

=item PDL::OpenCV::Imgproc::COLORMAP_TWILIGHT_SHIFTED()

=item PDL::OpenCV::Imgproc::COLORMAP_TURBO()

=item PDL::OpenCV::Imgproc::COLORMAP_DEEPGREEN()

=item PDL::OpenCV::Imgproc::Subdiv2D::PTLOC_ERROR()

=item PDL::OpenCV::Imgproc::Subdiv2D::PTLOC_OUTSIDE_RECT()

=item PDL::OpenCV::Imgproc::Subdiv2D::PTLOC_INSIDE()

=item PDL::OpenCV::Imgproc::Subdiv2D::PTLOC_VERTEX()

=item PDL::OpenCV::Imgproc::Subdiv2D::PTLOC_ON_EDGE()

=item PDL::OpenCV::Imgproc::Subdiv2D::NEXT_AROUND_ORG()

=item PDL::OpenCV::Imgproc::Subdiv2D::NEXT_AROUND_DST()

=item PDL::OpenCV::Imgproc::Subdiv2D::PREV_AROUND_ORG()

=item PDL::OpenCV::Imgproc::Subdiv2D::PREV_AROUND_DST()

=item PDL::OpenCV::Imgproc::Subdiv2D::NEXT_AROUND_LEFT()

=item PDL::OpenCV::Imgproc::Subdiv2D::NEXT_AROUND_RIGHT()

=item PDL::OpenCV::Imgproc::Subdiv2D::PREV_AROUND_LEFT()

=item PDL::OpenCV::Imgproc::Subdiv2D::PREV_AROUND_RIGHT()


=back

=cut
#line 14007 "Imgproc.pm"






# Exit with OK status

1;
