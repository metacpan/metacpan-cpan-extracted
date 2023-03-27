#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::OpenCV::Tracking;

our @EXPORT_OK = qw( CamShift meanShift buildOpticalFlowPyramid calcOpticalFlowPyrLK calcOpticalFlowFarneback computeECC findTransformECC findTransformECC2 readOpticalFlow writeOpticalFlow OPTFLOW_USE_INITIAL_FLOW OPTFLOW_LK_GET_MIN_EIGENVALS OPTFLOW_FARNEBACK_GAUSSIAN MOTION_TRANSLATION MOTION_EUCLIDEAN MOTION_AFFINE MOTION_HOMOGRAPHY );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::OpenCV::Tracking ;






#line 364 "../genpp.pl"

=head1 NAME

PDL::OpenCV::Tracking - PDL bindings for OpenCV DISOpticalFlow, DenseOpticalFlow, FarnebackOpticalFlow, KalmanFilter, SparseOpticalFlow, SparsePyrLKOpticalFlow, Tracker, TrackerCSRT, TrackerDaSiamRPN, TrackerGOTURN, TrackerKCF, TrackerMIL, VariationalRefinement

=head1 SYNOPSIS

 use PDL::OpenCV::Tracking;

=cut

use strict;
use warnings;
use PDL::OpenCV; # get constants
#line 40 "Tracking.pm"






=head1 FUNCTIONS

=cut




#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 CamShift

=for sig

  Signature: ([phys] probImage(l1,c1,r1); indx [io,phys] window(n2=4); TermCriteriaWrapper * criteria; [o] RotatedRectWrapper * res)

=for ref

Finds an object center, size, and orientation.

=for example

 $res = CamShift($probImage,$window,$criteria);

@cite Bradski98 . First, it finds an
object center using meanShift and then adjusts the window size and finds the optimal rotation. The
function returns the rotated rectangle structure that includes the object position, size, and
CV_WRAP orientation. The next position of the search window can be obtained with RotatedRect::boundingRect()
See the OpenCV sample camshiftdemo.c that tracks colored objects.
@note
-   (Python) A sample explaining the camshift tracking algorithm can be found at
opencv_source_code/samples/python/camshift.py

Parameters:

=over

=item probImage

Back projection of the object histogram. See calcBackProject.

=item window

Initial search window.

=item criteria

Stop criteria for the underlying meanShift.
returns
(in old interfaces) Number of iterations CAMSHIFT took to converge
The function implements the CAMSHIFT object tracking algorithm

=back


=for bad

CamShift ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 110 "Tracking.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Tracking::CamShift {
  barf "Usage: PDL::OpenCV::Tracking::CamShift(\$probImage,\$window,\$criteria)\n" if @_ < 3;
  my ($probImage,$window,$criteria) = @_;
  my ($res);
  
  PDL::OpenCV::Tracking::_CamShift_int($probImage,$window,$criteria,$res);
  !wantarray ? $res : ($res)
}
#line 124 "Tracking.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*CamShift = \&PDL::OpenCV::Tracking::CamShift;
#line 131 "Tracking.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 meanShift

=for sig

  Signature: ([phys] probImage(l1,c1,r1); indx [io,phys] window(n2=4); int [o,phys] res(); TermCriteriaWrapper * criteria)

=for ref

Finds an object on a back projection image.

=for example

 $res = meanShift($probImage,$window,$criteria);

Parameters:

=over

=item probImage

Back projection of the object histogram. See calcBackProject for details.

=item window

Initial search window.

=item criteria

Stop criteria for the iterative search algorithm.
returns
:   Number of iterations CAMSHIFT took to converge.
The function implements the iterative object search algorithm. It takes the input back projection of
an object and the initial position. The mass center in window of the back projection image is
computed and the search window center shifts to the mass center. The procedure is repeated until the
specified number of iterations criteria.maxCount is done or until the window center shifts by less
than criteria.epsilon. The algorithm is used inside CamShift and, unlike CamShift , the search
window size or orientation do not change during the search. You can simply pass the output of
calcBackProject to this function. But better results can be obtained if you pre-filter the back
projection and remove the noise. For example, you can do this by retrieving connected components
with findContours , throwing away contours with small area ( contourArea ), and rendering the
remaining contours with drawContours.

=back


=for bad

meanShift ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 191 "Tracking.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Tracking::meanShift {
  barf "Usage: PDL::OpenCV::Tracking::meanShift(\$probImage,\$window,\$criteria)\n" if @_ < 3;
  my ($probImage,$window,$criteria) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Tracking::_meanShift_int($probImage,$window,$res,$criteria);
  !wantarray ? $res : ($res)
}
#line 205 "Tracking.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*meanShift = \&PDL::OpenCV::Tracking::meanShift;
#line 212 "Tracking.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 buildOpticalFlowPyramid

=for sig

  Signature: ([phys] img(l1,c1,r1); indx [phys] winSize(n3=2); int [phys] maxLevel(); byte [phys] withDerivatives(); int [phys] pyrBorder(); int [phys] derivBorder(); byte [phys] tryReuseInputImage(); int [o,phys] res(); [o] vector_MatWrapper * pyramid)

=for ref

Constructs the image pyramid which can be passed to calcOpticalFlowPyrLK.

=for example

 ($pyramid,$res) = buildOpticalFlowPyramid($img,$winSize,$maxLevel); # with defaults
 ($pyramid,$res) = buildOpticalFlowPyramid($img,$winSize,$maxLevel,$withDerivatives,$pyrBorder,$derivBorder,$tryReuseInputImage);

Parameters:

=over

=item img

8-bit input image.

=item pyramid

output pyramid.

=item winSize

window size of optical flow algorithm. Must be not less than winSize argument of
calcOpticalFlowPyrLK. It is needed to calculate required padding for pyramid levels.

=item maxLevel

0-based maximal pyramid level number.

=item withDerivatives

set to precompute gradients for the every pyramid level. If pyramid is
constructed without the gradients then calcOpticalFlowPyrLK will calculate them internally.

=item pyrBorder

the border mode for pyramid layers.

=item derivBorder

the border mode for gradients.

=item tryReuseInputImage

put ROI of input image into the pyramid if possible. You can pass false
to force data copying.

=back

Returns: number of levels in constructed pyramid. Can be less than maxLevel.


=for bad

buildOpticalFlowPyramid ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 286 "Tracking.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Tracking::buildOpticalFlowPyramid {
  barf "Usage: PDL::OpenCV::Tracking::buildOpticalFlowPyramid(\$img,\$winSize,\$maxLevel,\$withDerivatives,\$pyrBorder,\$derivBorder,\$tryReuseInputImage)\n" if @_ < 3;
  my ($img,$winSize,$maxLevel,$withDerivatives,$pyrBorder,$derivBorder,$tryReuseInputImage) = @_;
  my ($pyramid,$res);
  $withDerivatives = 1 if !defined $withDerivatives;
  $pyrBorder = BORDER_REFLECT_101() if !defined $pyrBorder;
  $derivBorder = BORDER_CONSTANT() if !defined $derivBorder;
  $tryReuseInputImage = 1 if !defined $tryReuseInputImage;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Tracking::_buildOpticalFlowPyramid_int($img,$winSize,$maxLevel,$withDerivatives,$pyrBorder,$derivBorder,$tryReuseInputImage,$res,$pyramid);
  !wantarray ? $res : ($pyramid,$res)
}
#line 304 "Tracking.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*buildOpticalFlowPyramid = \&PDL::OpenCV::Tracking::buildOpticalFlowPyramid;
#line 311 "Tracking.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 calcOpticalFlowPyrLK

=for sig

  Signature: ([phys] prevImg(l1,c1,r1); [phys] nextImg(l2,c2,r2); [phys] prevPts(l3,c3,r3); [io,phys] nextPts(l4,c4,r4); [o,phys] status(l5,c5,r5); [o,phys] err(l6,c6,r6); indx [phys] winSize(n7=2); int [phys] maxLevel(); int [phys] flags(); double [phys] minEigThreshold(); TermCriteriaWrapper * criteria)

=for ref

Calculates an optical flow for a sparse feature set using the iterative Lucas-Kanade method with
pyramids. NO BROADCASTING.

=for example

 ($status,$err) = calcOpticalFlowPyrLK($prevImg,$nextImg,$prevPts,$nextPts); # with defaults
 ($status,$err) = calcOpticalFlowPyrLK($prevImg,$nextImg,$prevPts,$nextPts,$winSize,$maxLevel,$criteria,$flags,$minEigThreshold);

@cite Bouguet00), divided
by number of pixels in a window; if this value is less than minEigThreshold, then a corresponding
feature is filtered out and its flow is not processed, so it allows to remove bad points and get a
performance boost.
The function implements a sparse iterative version of the Lucas-Kanade optical flow in pyramids. See
@cite Bouguet00 . The function is parallelized with the TBB library.
@note
-   An example using the Lucas-Kanade optical flow algorithm can be found at
opencv_source_code/samples/cpp/lkdemo.cpp
-   (Python) An example using the Lucas-Kanade optical flow algorithm can be found at
opencv_source_code/samples/python/lk_track.py
-   (Python) An example using the Lucas-Kanade tracker for homography matching can be found at
opencv_source_code/samples/python/lk_homography.py

Parameters:

=over

=item prevImg

first 8-bit input image or pyramid constructed by buildOpticalFlowPyramid.

=item nextImg

second input image or pyramid of the same size and the same type as prevImg.

=item prevPts

vector of 2D points for which the flow needs to be found; point coordinates must be
single-precision floating-point numbers.

=item nextPts

output vector of 2D points (with single-precision floating-point coordinates)
containing the calculated new positions of input features in the second image; when
OPTFLOW_USE_INITIAL_FLOW flag is passed, the vector must have the same size as in the input.

=item status

output status vector (of unsigned chars); each element of the vector is set to 1 if
the flow for the corresponding features has been found, otherwise, it is set to 0.

=item err

output vector of errors; each element of the vector is set to an error for the
corresponding feature, type of the error measure can be set in flags parameter; if the flow wasn't
found then the error is not defined (use the status parameter to find such cases).

=item winSize

size of the search window at each pyramid level.

=item maxLevel

0-based maximal pyramid level number; if set to 0, pyramids are not used (single
level), if set to 1, two levels are used, and so on; if pyramids are passed to input then
algorithm will use as many levels as pyramids have but no more than maxLevel.

=item criteria

parameter, specifying the termination criteria of the iterative search algorithm
(after the specified maximum number of iterations criteria.maxCount or when the search window
moves by less than criteria.epsilon.

=item flags

operation flags:
 -   **OPTFLOW_USE_INITIAL_FLOW** uses initial estimations, stored in nextPts; if the flag is
     not set, then prevPts is copied to nextPts and is considered the initial estimate.
 -   **OPTFLOW_LK_GET_MIN_EIGENVALS** use minimum eigen values as an error measure (see
     minEigThreshold description); if the flag is not set, then L1 distance between patches
     around the original and a moved point, divided by number of pixels in a window, is used as a
     error measure.

=item minEigThreshold

the algorithm calculates the minimum eigen value of a 2x2 normal matrix of
optical flow equations (this matrix is called a spatial gradient matrix in

=back


=for bad

calcOpticalFlowPyrLK ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 424 "Tracking.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Tracking::calcOpticalFlowPyrLK {
  barf "Usage: PDL::OpenCV::Tracking::calcOpticalFlowPyrLK(\$prevImg,\$nextImg,\$prevPts,\$nextPts,\$winSize,\$maxLevel,\$criteria,\$flags,\$minEigThreshold)\n" if @_ < 4;
  my ($prevImg,$nextImg,$prevPts,$nextPts,$winSize,$maxLevel,$criteria,$flags,$minEigThreshold) = @_;
  my ($status,$err);
  $status = PDL->null if !defined $status;
  $err = PDL->null if !defined $err;
  $winSize = indx(21,21) if !defined $winSize;
  $maxLevel = 3 if !defined $maxLevel;
  $criteria = PDL::OpenCV::TermCriteria->new2(PDL::OpenCV::TermCriteria::COUNT()+PDL::OpenCV::TermCriteria::EPS(), 30, 0.01) if !defined $criteria;
  $flags = 0 if !defined $flags;
  $minEigThreshold = 1e-4 if !defined $minEigThreshold;
  PDL::OpenCV::Tracking::_calcOpticalFlowPyrLK_int($prevImg,$nextImg,$prevPts,$nextPts,$status,$err,$winSize,$maxLevel,$flags,$minEigThreshold,$criteria);
  !wantarray ? $err : ($status,$err)
}
#line 444 "Tracking.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*calcOpticalFlowPyrLK = \&PDL::OpenCV::Tracking::calcOpticalFlowPyrLK;
#line 451 "Tracking.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 calcOpticalFlowFarneback

=for sig

  Signature: ([phys] prev(l1,c1,r1); [phys] next(l2,c2,r2); [io,phys] flow(l3,c3,r3); double [phys] pyr_scale(); int [phys] levels(); int [phys] winsize(); int [phys] iterations(); int [phys] poly_n(); double [phys] poly_sigma(); int [phys] flags())

=for ref

Computes a dense optical flow using the Gunnar Farneback's algorithm.

=for example

 calcOpticalFlowFarneback($prev,$next,$flow,$pyr_scale,$levels,$winsize,$iterations,$poly_n,$poly_sigma,$flags);

\<1) to build pyramids for each image;
pyr_scale=0.5 means a classical pyramid, where each next layer is twice smaller than the previous
one.
C<<< \texttt{winsize}\times\texttt{winsize} >>>filter instead of a box filter of the same size for optical flow estimation; usually, this
option gives z more accurate flow than with a box filter, at the cost of lower speed;
normally, winsize for a Gaussian window should be set to a larger value to achieve the same
level of robustness.
The function finds an optical flow for each prev pixel using the @cite Farneback2003 algorithm so that
\f[\texttt{prev} (y,x)  \sim \texttt{next} ( y + \texttt{flow} (y,x)[1],  x + \texttt{flow} (y,x)[0])\f]
@note
-   An example using the optical flow algorithm described by Gunnar Farneback can be found at
opencv_source_code/samples/cpp/fback.cpp
-   (Python) An example using the optical flow algorithm described by Gunnar Farneback can be
found at opencv_source_code/samples/python/opt_flow.py

Parameters:

=over

=item prev

first 8-bit single-channel input image.

=item next

second input image of the same size and the same type as prev.

=item flow

computed flow image that has the same size as prev and type CV_32FC2.

=item pyr_scale

parameter, specifying the image scale (

=item levels

number of pyramid layers including the initial image; levels=1 means that no extra
layers are created and only the original images are used.

=item winsize

averaging window size; larger values increase the algorithm robustness to image
noise and give more chances for fast motion detection, but yield more blurred motion field.

=item iterations

number of iterations the algorithm does at each pyramid level.

=item poly_n

size of the pixel neighborhood used to find polynomial expansion in each pixel;
larger values mean that the image will be approximated with smoother surfaces, yielding more
robust algorithm and more blurred motion field, typically poly_n =5 or 7.

=item poly_sigma

standard deviation of the Gaussian that is used to smooth derivatives used as a
basis for the polynomial expansion; for poly_n=5, you can set poly_sigma=1.1, for poly_n=7, a
good value would be poly_sigma=1.5.

=item flags

operation flags that can be a combination of the following:
 -   **OPTFLOW_USE_INITIAL_FLOW** uses the input flow as an initial flow approximation.
 -   **OPTFLOW_FARNEBACK_GAUSSIAN** uses the Gaussian

=back


=for bad

calcOpticalFlowFarneback ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 550 "Tracking.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Tracking::calcOpticalFlowFarneback {
  barf "Usage: PDL::OpenCV::Tracking::calcOpticalFlowFarneback(\$prev,\$next,\$flow,\$pyr_scale,\$levels,\$winsize,\$iterations,\$poly_n,\$poly_sigma,\$flags)\n" if @_ < 10;
  my ($prev,$next,$flow,$pyr_scale,$levels,$winsize,$iterations,$poly_n,$poly_sigma,$flags) = @_;
    
  PDL::OpenCV::Tracking::_calcOpticalFlowFarneback_int($prev,$next,$flow,$pyr_scale,$levels,$winsize,$iterations,$poly_n,$poly_sigma,$flags);
  
}
#line 563 "Tracking.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*calcOpticalFlowFarneback = \&PDL::OpenCV::Tracking::calcOpticalFlowFarneback;
#line 570 "Tracking.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 computeECC

=for sig

  Signature: ([phys] templateImage(l1,c1,r1); [phys] inputImage(l2,c2,r2); [phys] inputMask(l3,c3,r3); double [o,phys] res())

=for ref

Computes the Enhanced Correlation Coefficient value between two images

=for example

 $res = computeECC($templateImage,$inputImage); # with defaults
 $res = computeECC($templateImage,$inputImage,$inputMask);

@cite EP08 .

Parameters:

=over

=item templateImage

single-channel template image; CV_8U or CV_32F array.

=item inputImage

single-channel input image to be warped to provide an image similar to
 templateImage, same type as templateImage.

=item inputMask

An optional mask to indicate valid values of inputImage.

=back

See also:
findTransformECC


=for bad

computeECC ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 625 "Tracking.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Tracking::computeECC {
  barf "Usage: PDL::OpenCV::Tracking::computeECC(\$templateImage,\$inputImage,\$inputMask)\n" if @_ < 2;
  my ($templateImage,$inputImage,$inputMask) = @_;
  my ($res);
  $inputMask = PDL->zeroes(sbyte,0,0,0) if !defined $inputMask;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Tracking::_computeECC_int($templateImage,$inputImage,$inputMask,$res);
  !wantarray ? $res : ($res)
}
#line 640 "Tracking.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*computeECC = \&PDL::OpenCV::Tracking::computeECC;
#line 647 "Tracking.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 findTransformECC

=for sig

  Signature: ([phys] templateImage(l1,c1,r1); [phys] inputImage(l2,c2,r2); [io,phys] warpMatrix(l3,c3,r3); int [phys] motionType(); [phys] inputMask(l6,c6,r6); int [phys] gaussFiltSize(); double [o,phys] res(); TermCriteriaWrapper * criteria)

=for ref

Finds the geometric transform (warp) between two images in terms of the ECC criterion

=for example

 $res = findTransformECC($templateImage,$inputImage,$warpMatrix,$motionType,$criteria,$inputMask,$gaussFiltSize);

@cite EP08 .
C<<< 2\times 3 >>>or C<<< 3\times 3 >>>mapping matrix (warp).
C<<< 2\times 3 >>>with
the first C<<< 2\times 2 >>>part being the unity matrix and the rest two parameters being
estimated.
-   **MOTION_EUCLIDEAN** sets a Euclidean (rigid) transformation as motion model; three
parameters are estimated; warpMatrix is C<<< 2\times 3 >>>.
-   **MOTION_AFFINE** sets an affine motion model (DEFAULT); six parameters are estimated;
warpMatrix is C<<< 2\times 3 >>>.
-   **MOTION_HOMOGRAPHY** sets a homography as a motion model; eight parameters are
estimated;\`warpMatrix\` is C<<< 3\times 3 >>>.
The function estimates the optimum transformation (warpMatrix) with respect to ECC criterion
(@cite EP08), that is
\f[\texttt{warpMatrix} = \arg\max_{W} \texttt{ECC}(\texttt{templateImage}(x,y),\texttt{inputImage}(x',y'))\f]
where
\f[\begin{bmatrix} x' \\ y' \end{bmatrix} = W \cdot \begin{bmatrix} x \\ y \\ 1 \end{bmatrix}\f]
(the equation holds with homogeneous coordinates for homography). It returns the final enhanced
correlation coefficient, that is the correlation coefficient between the template image and the
final warped input image. When a C<<< 3\times 3 >>>matrix is given with motionType =0, 1 or 2, the third
row is ignored.
Unlike findHomography and estimateRigidTransform, the function findTransformECC implements an
area-based alignment that builds on intensity similarities. In essence, the function updates the
initial transformation that roughly aligns the images. If this information is missing, the identity
warp (unity matrix) is used as an initialization. Note that if images undergo strong
displacements/rotations, an initial transformation that roughly aligns the images is necessary
(e.g., a simple euclidean/similarity transform that allows for the images showing the same image
content approximately). Use inverse warping in the second image to take an image close to the first
one, i.e. use the flag WARP_INVERSE_MAP with warpAffine or warpPerspective. See also the OpenCV
sample image_alignment.cpp that demonstrates the use of the function. Note that the function throws
an exception if algorithm does not converges.

Parameters:

=over

=item templateImage

single-channel template image; CV_8U or CV_32F array.

=item inputImage

single-channel input image which should be warped with the final warpMatrix in
order to provide an image similar to templateImage, same type as templateImage.

=item warpMatrix

floating-point

=item motionType

parameter, specifying the type of motion:
 -   **MOTION_TRANSLATION** sets a translational motion model; warpMatrix is

=item criteria

parameter, specifying the termination criteria of the ECC algorithm;
criteria.epsilon defines the threshold of the increment in the correlation coefficient between two
iterations (a negative criteria.epsilon makes criteria.maxcount the only termination criterion).
Default values are shown in the declaration above.

=item inputMask

An optional mask to indicate valid values of inputImage.

=item gaussFiltSize

An optional value indicating size of gaussian blur filter; (DEFAULT: 5)

=back

See also:
computeECC, estimateAffine2D, estimateAffinePartial2D, findHomography


=for bad

findTransformECC ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 750 "Tracking.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Tracking::findTransformECC {
  barf "Usage: PDL::OpenCV::Tracking::findTransformECC(\$templateImage,\$inputImage,\$warpMatrix,\$motionType,\$criteria,\$inputMask,\$gaussFiltSize)\n" if @_ < 7;
  my ($templateImage,$inputImage,$warpMatrix,$motionType,$criteria,$inputMask,$gaussFiltSize) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Tracking::_findTransformECC_int($templateImage,$inputImage,$warpMatrix,$motionType,$inputMask,$gaussFiltSize,$res,$criteria);
  !wantarray ? $res : ($res)
}
#line 764 "Tracking.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*findTransformECC = \&PDL::OpenCV::Tracking::findTransformECC;
#line 771 "Tracking.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 findTransformECC2

=for sig

  Signature: ([phys] templateImage(l1,c1,r1); [phys] inputImage(l2,c2,r2); [io,phys] warpMatrix(l3,c3,r3); int [phys] motionType(); [phys] inputMask(l6,c6,r6); double [o,phys] res(); TermCriteriaWrapper * criteria)

=for ref

=for example

 $res = findTransformECC2($templateImage,$inputImage,$warpMatrix); # with defaults
 $res = findTransformECC2($templateImage,$inputImage,$warpMatrix,$motionType,$criteria,$inputMask);

@overload

=for bad

findTransformECC2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 801 "Tracking.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Tracking::findTransformECC2 {
  barf "Usage: PDL::OpenCV::Tracking::findTransformECC2(\$templateImage,\$inputImage,\$warpMatrix,\$motionType,\$criteria,\$inputMask)\n" if @_ < 3;
  my ($templateImage,$inputImage,$warpMatrix,$motionType,$criteria,$inputMask) = @_;
  my ($res);
  $motionType = MOTION_AFFINE() if !defined $motionType;
  $criteria = PDL::OpenCV::TermCriteria->new2(PDL::OpenCV::TermCriteria::COUNT()+PDL::OpenCV::TermCriteria::EPS(), 50, 0.001) if !defined $criteria;
  $inputMask = PDL->zeroes(sbyte,0,0,0) if !defined $inputMask;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Tracking::_findTransformECC2_int($templateImage,$inputImage,$warpMatrix,$motionType,$inputMask,$res,$criteria);
  !wantarray ? $res : ($res)
}
#line 818 "Tracking.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*findTransformECC2 = \&PDL::OpenCV::Tracking::findTransformECC2;
#line 825 "Tracking.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 readOpticalFlow

=for sig

  Signature: ([o,phys] res(l2,c2,r2); StringWrapper* path)

=for ref

Read a .flo file NO BROADCASTING.

=for example

 $res = readOpticalFlow($path);

The function readOpticalFlow loads a flow field from a file and returns it as a single matrix.
Resulting Mat has a type CV_32FC2 - floating-point, 2-channel. First channel corresponds to the
flow in the horizontal direction (u), second - vertical (v).

Parameters:

=over

=item path

Path to the file to be loaded

=back


=for bad

readOpticalFlow ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 869 "Tracking.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Tracking::readOpticalFlow {
  barf "Usage: PDL::OpenCV::Tracking::readOpticalFlow(\$path)\n" if @_ < 1;
  my ($path) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Tracking::_readOpticalFlow_int($res,$path);
  !wantarray ? $res : ($res)
}
#line 883 "Tracking.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*readOpticalFlow = \&PDL::OpenCV::Tracking::readOpticalFlow;
#line 890 "Tracking.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 writeOpticalFlow

=for sig

  Signature: ([phys] flow(l2,c2,r2); byte [o,phys] res(); StringWrapper* path)

=for ref

Write a .flo to disk

=for example

 $res = writeOpticalFlow($path,$flow);

The function stores a flow field in a file, returns true on success, false otherwise.
The flow field must be a 2-channel, floating-point matrix (CV_32FC2). First channel corresponds
to the flow in the horizontal direction (u), second - vertical (v).

Parameters:

=over

=item path

Path to the file to be written

=item flow

Flow field to be stored

=back


=for bad

writeOpticalFlow ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 938 "Tracking.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Tracking::writeOpticalFlow {
  barf "Usage: PDL::OpenCV::Tracking::writeOpticalFlow(\$path,\$flow)\n" if @_ < 2;
  my ($path,$flow) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Tracking::_writeOpticalFlow_int($flow,$res,$path);
  !wantarray ? $res : ($res)
}
#line 952 "Tracking.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*writeOpticalFlow = \&PDL::OpenCV::Tracking::writeOpticalFlow;
#line 959 "Tracking.pm"



#line 394 "../genpp.pl"

=head1 METHODS for PDL::OpenCV::DISOpticalFlow


=for ref

DIS optical flow algorithm.

This class implements the Dense Inverse Search (DIS) optical flow algorithm. More
details about the algorithm can be found at @cite Kroeger2016 . Includes three presets with preselected
parameters to provide reasonable trade-off between speed and quality. However, even the slowest preset is
still relatively fast, use DeepFlow if you need better quality and don't care about speed.
This implementation includes several additional features compared to the algorithm described in the paper,
including spatial propagation of flow vectors (@ref getUseSpatialPropagation), as well as an option to
utilize an initial flow approximation passed to @ref calc (which is, essentially, temporal propagation,
if the previous frame's flow field is passed).

Subclass of PDL::OpenCV::DenseOpticalFlow


=cut

@PDL::OpenCV::DISOpticalFlow::ISA = qw(PDL::OpenCV::DenseOpticalFlow);
#line 987 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 new

=for ref

Creates an instance of DISOpticalFlow

=for example

 $obj = PDL::OpenCV::DISOpticalFlow->new; # with defaults
 $obj = PDL::OpenCV::DISOpticalFlow->new($preset);

Parameters:

=over

=item preset

one of PRESET_ULTRAFAST, PRESET_FAST and PRESET_MEDIUM

=back


=cut
#line 1016 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 getFinestScale

=for ref

Finest level of the Gaussian pyramid on which the flow is computed (zero level
        corresponds to the original image resolution). The final flow is obtained by bilinear upscaling.

=for example

 $res = $obj->getFinestScale;

See also:
setFinestScale


=cut
#line 1038 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 setFinestScale

=for ref

=for example

 $obj->setFinestScale($val);

@copybrief getFinestScale See also:
getFinestScale


=cut
#line 1057 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 getPatchSize

=for ref

Size of an image patch for matching (in pixels). Normally, default 8x8 patches work well
        enough in most cases.

=for example

 $res = $obj->getPatchSize;

See also:
setPatchSize


=cut
#line 1079 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 setPatchSize

=for ref

=for example

 $obj->setPatchSize($val);

@copybrief getPatchSize See also:
getPatchSize


=cut
#line 1098 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 getPatchStride

=for ref

Stride between neighbor patches. Must be less than patch size. Lower values correspond
        to higher flow quality.

=for example

 $res = $obj->getPatchStride;

See also:
setPatchStride


=cut
#line 1120 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 setPatchStride

=for ref

=for example

 $obj->setPatchStride($val);

@copybrief getPatchStride See also:
getPatchStride


=cut
#line 1139 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 getGradientDescentIterations

=for ref

Maximum number of gradient descent iterations in the patch inverse search stage. Higher values
        may improve quality in some cases.

=for example

 $res = $obj->getGradientDescentIterations;

See also:
setGradientDescentIterations


=cut
#line 1161 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 setGradientDescentIterations

=for ref

=for example

 $obj->setGradientDescentIterations($val);

@copybrief getGradientDescentIterations See also:
getGradientDescentIterations


=cut
#line 1180 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 getVariationalRefinementIterations

=for ref

Number of fixed point iterations of variational refinement per scale. Set to zero to
        disable variational refinement completely. Higher values will typically result in more smooth and
        high-quality flow.

=for example

 $res = $obj->getVariationalRefinementIterations;

See also:
setGradientDescentIterations


=cut
#line 1203 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 setVariationalRefinementIterations

=for ref

=for example

 $obj->setVariationalRefinementIterations($val);

@copybrief getGradientDescentIterations See also:
getGradientDescentIterations


=cut
#line 1222 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 getVariationalRefinementAlpha

=for ref

Weight of the smoothness term

=for example

 $res = $obj->getVariationalRefinementAlpha;

See also:
setVariationalRefinementAlpha


=cut
#line 1243 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 setVariationalRefinementAlpha

=for ref

=for example

 $obj->setVariationalRefinementAlpha($val);

@copybrief getVariationalRefinementAlpha See also:
getVariationalRefinementAlpha


=cut
#line 1262 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 getVariationalRefinementDelta

=for ref

Weight of the color constancy term

=for example

 $res = $obj->getVariationalRefinementDelta;

See also:
setVariationalRefinementDelta


=cut
#line 1283 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 setVariationalRefinementDelta

=for ref

=for example

 $obj->setVariationalRefinementDelta($val);

@copybrief getVariationalRefinementDelta See also:
getVariationalRefinementDelta


=cut
#line 1302 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 getVariationalRefinementGamma

=for ref

Weight of the gradient constancy term

=for example

 $res = $obj->getVariationalRefinementGamma;

See also:
setVariationalRefinementGamma


=cut
#line 1323 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 setVariationalRefinementGamma

=for ref

=for example

 $obj->setVariationalRefinementGamma($val);

@copybrief getVariationalRefinementGamma See also:
getVariationalRefinementGamma


=cut
#line 1342 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 getUseMeanNormalization

=for ref

Whether to use mean-normalization of patches when computing patch distance. It is turned on
        by default as it typically provides a noticeable quality boost because of increased robustness to
        illumination variations. Turn it off if you are certain that your sequence doesn't contain any changes
        in illumination.

=for example

 $res = $obj->getUseMeanNormalization;

See also:
setUseMeanNormalization


=cut
#line 1366 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 setUseMeanNormalization

=for ref

=for example

 $obj->setUseMeanNormalization($val);

@copybrief getUseMeanNormalization See also:
getUseMeanNormalization


=cut
#line 1385 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 getUseSpatialPropagation

=for ref

Whether to use spatial propagation of good optical flow vectors. This option is turned on by
        default, as it tends to work better on average and can sometimes help recover from major errors
        introduced by the coarse-to-fine scheme employed by the DIS optical flow algorithm. Turning this
        option off can make the output flow field a bit smoother, however.

=for example

 $res = $obj->getUseSpatialPropagation;

See also:
setUseSpatialPropagation


=cut
#line 1409 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 setUseSpatialPropagation

=for ref

=for example

 $obj->setUseSpatialPropagation($val);

@copybrief getUseSpatialPropagation See also:
getUseSpatialPropagation


=cut
#line 1428 "Tracking.pm"



#line 394 "../genpp.pl"

=head1 METHODS for PDL::OpenCV::DenseOpticalFlow


Base class for dense optical flow algorithms

Subclass of PDL::OpenCV::Algorithm


=cut

@PDL::OpenCV::DenseOpticalFlow::ISA = qw(PDL::OpenCV::Algorithm);
#line 1445 "Tracking.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 DenseOpticalFlow_calc

=for sig

  Signature: ([phys] I0(l2,c2,r2); [phys] I1(l3,c3,r3); [io,phys] flow(l4,c4,r4); DenseOpticalFlowWrapper * self)

=for ref

Calculates an optical flow.

=for example

 $obj->calc($I0,$I1,$flow);

Parameters:

=over

=item I0

first 8-bit single-channel input image.

=item I1

second input image of the same size and the same type as prev.

=item flow

computed flow image that has the same size as prev and type CV_32FC2.

=back


=for bad

DenseOpticalFlow_calc ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1493 "Tracking.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::DenseOpticalFlow::calc {
  barf "Usage: PDL::OpenCV::DenseOpticalFlow::calc(\$self,\$I0,\$I1,\$flow)\n" if @_ < 4;
  my ($self,$I0,$I1,$flow) = @_;
    
  PDL::OpenCV::DenseOpticalFlow::_DenseOpticalFlow_calc_int($I0,$I1,$flow,$self);
  
}
#line 1506 "Tracking.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 1511 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 collectGarbage

=for ref

Releases all inner buffers.

=for example

 $obj->collectGarbage;


=cut
#line 1529 "Tracking.pm"



#line 394 "../genpp.pl"

=head1 METHODS for PDL::OpenCV::FarnebackOpticalFlow


=for ref

Class computing a dense optical flow using the Gunnar Farneback's algorithm.


Subclass of PDL::OpenCV::DenseOpticalFlow


=cut

@PDL::OpenCV::FarnebackOpticalFlow::ISA = qw(PDL::OpenCV::DenseOpticalFlow);
#line 1549 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 new

=for ref

=for example

 $obj = PDL::OpenCV::FarnebackOpticalFlow->new; # with defaults
 $obj = PDL::OpenCV::FarnebackOpticalFlow->new($numLevels,$pyrScale,$fastPyramids,$winSize,$numIters,$polyN,$polySigma,$flags);


=cut
#line 1566 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 getNumLevels

=for ref

=for example

 $res = $obj->getNumLevels;


=cut
#line 1582 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 setNumLevels

=for ref

=for example

 $obj->setNumLevels($numLevels);


=cut
#line 1598 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 getPyrScale

=for ref

=for example

 $res = $obj->getPyrScale;


=cut
#line 1614 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 setPyrScale

=for ref

=for example

 $obj->setPyrScale($pyrScale);


=cut
#line 1630 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 getFastPyramids

=for ref

=for example

 $res = $obj->getFastPyramids;


=cut
#line 1646 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 setFastPyramids

=for ref

=for example

 $obj->setFastPyramids($fastPyramids);


=cut
#line 1662 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 getWinSize

=for ref

=for example

 $res = $obj->getWinSize;


=cut
#line 1678 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 setWinSize

=for ref

=for example

 $obj->setWinSize($winSize);


=cut
#line 1694 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 getNumIters

=for ref

=for example

 $res = $obj->getNumIters;


=cut
#line 1710 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 setNumIters

=for ref

=for example

 $obj->setNumIters($numIters);


=cut
#line 1726 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 getPolyN

=for ref

=for example

 $res = $obj->getPolyN;


=cut
#line 1742 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 setPolyN

=for ref

=for example

 $obj->setPolyN($polyN);


=cut
#line 1758 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 getPolySigma

=for ref

=for example

 $res = $obj->getPolySigma;


=cut
#line 1774 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 setPolySigma

=for ref

=for example

 $obj->setPolySigma($polySigma);


=cut
#line 1790 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 getFlags

=for ref

=for example

 $res = $obj->getFlags;


=cut
#line 1806 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 setFlags

=for ref

=for example

 $obj->setFlags($flags);


=cut
#line 1822 "Tracking.pm"



#line 394 "../genpp.pl"

=head1 METHODS for PDL::OpenCV::KalmanFilter


=for ref

Kalman filter class.

The class implements a standard Kalman filter <http://en.wikipedia.org/wiki/Kalman_filter>,
@cite Welch95 . However, you can modify transitionMatrix, controlMatrix, and measurementMatrix to get
an extended Kalman filter functionality.
@note In C API when CvKalman* kalmanFilter structure is not needed anymore, it should be released
with cvReleaseKalman(&kalmanFilter)


=cut

@PDL::OpenCV::KalmanFilter::ISA = qw();
#line 1845 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 new

=for ref

=for example

 $obj = PDL::OpenCV::KalmanFilter->new;


=cut
#line 1861 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 new2

=for ref

=for example

 $obj = PDL::OpenCV::KalmanFilter->new2($dynamParams,$measureParams); # with defaults
 $obj = PDL::OpenCV::KalmanFilter->new2($dynamParams,$measureParams,$controlParams,$type);

@overload

Parameters:

=over

=item dynamParams

Dimensionality of the state.

=item measureParams

Dimensionality of the measurement.

=item controlParams

Dimensionality of the control vector.

=item type

Type of the created matrices that should be CV_32F or CV_64F.

=back


=cut
#line 1902 "Tracking.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 KalmanFilter_predict

=for sig

  Signature: ([phys] control(l2,c2,r2); [o,phys] res(l3,c3,r3); KalmanFilterWrapper * self)

=for ref

Computes a predicted state. NO BROADCASTING.

=for example

 $res = $obj->predict; # with defaults
 $res = $obj->predict($control);

Parameters:

=over

=item control

The optional input control

=back


=for bad

KalmanFilter_predict ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1943 "Tracking.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::KalmanFilter::predict {
  barf "Usage: PDL::OpenCV::KalmanFilter::predict(\$self,\$control)\n" if @_ < 1;
  my ($self,$control) = @_;
  my ($res);
  $control = PDL->zeroes(sbyte,0,0,0) if !defined $control;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::KalmanFilter::_KalmanFilter_predict_int($control,$res,$self);
  !wantarray ? $res : ($res)
}
#line 1958 "Tracking.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 1963 "Tracking.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 KalmanFilter_correct

=for sig

  Signature: ([phys] measurement(l2,c2,r2); [o,phys] res(l3,c3,r3); KalmanFilterWrapper * self)

=for ref

Updates the predicted state from the measurement. NO BROADCASTING.

=for example

 $res = $obj->correct($measurement);

Parameters:

=over

=item measurement

The measured system parameters

=back


=for bad

KalmanFilter_correct ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2003 "Tracking.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::KalmanFilter::correct {
  barf "Usage: PDL::OpenCV::KalmanFilter::correct(\$self,\$measurement)\n" if @_ < 2;
  my ($self,$measurement) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::KalmanFilter::_KalmanFilter_correct_int($measurement,$res,$self);
  !wantarray ? $res : ($res)
}
#line 2017 "Tracking.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 2022 "Tracking.pm"



#line 394 "../genpp.pl"

=head1 METHODS for PDL::OpenCV::SparseOpticalFlow


=for ref

Base interface for sparse optical flow algorithms.


Subclass of PDL::OpenCV::Algorithm


=cut

@PDL::OpenCV::SparseOpticalFlow::ISA = qw(PDL::OpenCV::Algorithm);
#line 2042 "Tracking.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 SparseOpticalFlow_calc

=for sig

  Signature: ([phys] prevImg(l2,c2,r2); [phys] nextImg(l3,c3,r3); [phys] prevPts(l4,c4,r4); [io,phys] nextPts(l5,c5,r5); [o,phys] status(l6,c6,r6); [o,phys] err(l7,c7,r7); SparseOpticalFlowWrapper * self)

=for ref

Calculates a sparse optical flow. NO BROADCASTING.

=for example

 ($status,$err) = $obj->calc($prevImg,$nextImg,$prevPts,$nextPts);

Parameters:

=over

=item prevImg

First input image.

=item nextImg

Second input image of the same size and the same type as prevImg.

=item prevPts

Vector of 2D points for which the flow needs to be found.

=item nextPts

Output vector of 2D points containing the calculated new positions of input features in the second image.

=item status

Output status vector. Each element of the vector is set to 1 if the
                  flow for the corresponding features has been found. Otherwise, it is set to 0.

=item err

Optional output vector that contains error response for each point (inverse confidence).

=back


=for bad

SparseOpticalFlow_calc ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2103 "Tracking.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::SparseOpticalFlow::calc {
  barf "Usage: PDL::OpenCV::SparseOpticalFlow::calc(\$self,\$prevImg,\$nextImg,\$prevPts,\$nextPts)\n" if @_ < 5;
  my ($self,$prevImg,$nextImg,$prevPts,$nextPts) = @_;
  my ($status,$err);
  $status = PDL->null if !defined $status;
  $err = PDL->zeroes(sbyte,0,0,0) if !defined $err;
  PDL::OpenCV::SparseOpticalFlow::_SparseOpticalFlow_calc_int($prevImg,$nextImg,$prevPts,$nextPts,$status,$err,$self);
  !wantarray ? $err : ($status,$err)
}
#line 2118 "Tracking.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 2123 "Tracking.pm"



#line 394 "../genpp.pl"

=head1 METHODS for PDL::OpenCV::SparsePyrLKOpticalFlow


=for ref

Class used for calculating a sparse optical flow.

The class can calculate an optical flow for a sparse feature set using the
iterative Lucas-Kanade method with pyramids.
See also:
calcOpticalFlowPyrLK


Subclass of PDL::OpenCV::SparseOpticalFlow


=cut

@PDL::OpenCV::SparsePyrLKOpticalFlow::ISA = qw(PDL::OpenCV::SparseOpticalFlow);
#line 2148 "Tracking.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 SparsePyrLKOpticalFlow_new

=for sig

  Signature: (indx [phys] winSize(n2=2); int [phys] maxLevel(); int [phys] flags(); double [phys] minEigThreshold(); char * klass; TermCriteriaWrapper * crit; [o] SparsePyrLKOpticalFlowWrapper * res)

=for ref

=for example

 $obj = PDL::OpenCV::SparsePyrLKOpticalFlow->new; # with defaults
 $obj = PDL::OpenCV::SparsePyrLKOpticalFlow->new($winSize,$maxLevel,$crit,$flags,$minEigThreshold);


=for bad

SparsePyrLKOpticalFlow_new ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2177 "Tracking.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::SparsePyrLKOpticalFlow::new {
  barf "Usage: PDL::OpenCV::SparsePyrLKOpticalFlow::new(\$klass,\$winSize,\$maxLevel,\$crit,\$flags,\$minEigThreshold)\n" if @_ < 1;
  my ($klass,$winSize,$maxLevel,$crit,$flags,$minEigThreshold) = @_;
  my ($res);
  $winSize = indx(21, 21) if !defined $winSize;
  $maxLevel = 3 if !defined $maxLevel;
  $crit = PDL::OpenCV::TermCriteria->new2(PDL::OpenCV::TermCriteria::COUNT()+PDL::OpenCV::TermCriteria::EPS(), 30, 0.01) if !defined $crit;
  $flags = 0 if !defined $flags;
  $minEigThreshold = 1e-4 if !defined $minEigThreshold;
  PDL::OpenCV::SparsePyrLKOpticalFlow::_SparsePyrLKOpticalFlow_new_int($winSize,$maxLevel,$flags,$minEigThreshold,$klass,$crit,$res);
  !wantarray ? $res : ($res)
}
#line 2195 "Tracking.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 2200 "Tracking.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 SparsePyrLKOpticalFlow_getWinSize

=for sig

  Signature: (indx [o,phys] res(n2=2); SparsePyrLKOpticalFlowWrapper * self)

=for ref

=for example

 $res = $obj->getWinSize;


=for bad

SparsePyrLKOpticalFlow_getWinSize ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2228 "Tracking.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::SparsePyrLKOpticalFlow::getWinSize {
  barf "Usage: PDL::OpenCV::SparsePyrLKOpticalFlow::getWinSize(\$self)\n" if @_ < 1;
  my ($self) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::SparsePyrLKOpticalFlow::_SparsePyrLKOpticalFlow_getWinSize_int($res,$self);
  !wantarray ? $res : ($res)
}
#line 2242 "Tracking.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 2247 "Tracking.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 SparsePyrLKOpticalFlow_setWinSize

=for sig

  Signature: (indx [phys] winSize(n2=2); SparsePyrLKOpticalFlowWrapper * self)

=for ref

=for example

 $obj->setWinSize($winSize);


=for bad

SparsePyrLKOpticalFlow_setWinSize ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2275 "Tracking.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::SparsePyrLKOpticalFlow::setWinSize {
  barf "Usage: PDL::OpenCV::SparsePyrLKOpticalFlow::setWinSize(\$self,\$winSize)\n" if @_ < 2;
  my ($self,$winSize) = @_;
    
  PDL::OpenCV::SparsePyrLKOpticalFlow::_SparsePyrLKOpticalFlow_setWinSize_int($winSize,$self);
  
}
#line 2288 "Tracking.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 2293 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 getMaxLevel

=for ref

=for example

 $res = $obj->getMaxLevel;


=cut
#line 2309 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 setMaxLevel

=for ref

=for example

 $obj->setMaxLevel($maxLevel);


=cut
#line 2325 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 getTermCriteria

=for ref

=for example

 $res = $obj->getTermCriteria;


=cut
#line 2341 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 setTermCriteria

=for ref

=for example

 $obj->setTermCriteria($crit);


=cut
#line 2357 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 getFlags

=for ref

=for example

 $res = $obj->getFlags;


=cut
#line 2373 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 setFlags

=for ref

=for example

 $obj->setFlags($flags);


=cut
#line 2389 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 getMinEigThreshold

=for ref

=for example

 $res = $obj->getMinEigThreshold;


=cut
#line 2405 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 setMinEigThreshold

=for ref

=for example

 $obj->setMinEigThreshold($minEigThreshold);


=cut
#line 2421 "Tracking.pm"



#line 394 "../genpp.pl"

=head1 METHODS for PDL::OpenCV::Tracker


=for ref

Base abstract class for the long-term tracker



=cut

@PDL::OpenCV::Tracker::ISA = qw();
#line 2439 "Tracking.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 Tracker_init

=for sig

  Signature: ([phys] image(l2,c2,r2); indx [phys] boundingBox(n3=4); TrackerWrapper * self)

=for ref

Initialize the tracker with a known bounding box that surrounded the target

=for example

 $obj->init($image,$boundingBox);

Parameters:

=over

=item image

The initial frame

=item boundingBox

The initial bounding box

=back


=for bad

Tracker_init ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2483 "Tracking.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Tracker::init {
  barf "Usage: PDL::OpenCV::Tracker::init(\$self,\$image,\$boundingBox)\n" if @_ < 3;
  my ($self,$image,$boundingBox) = @_;
    
  PDL::OpenCV::Tracker::_Tracker_init_int($image,$boundingBox,$self);
  
}
#line 2496 "Tracking.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 2501 "Tracking.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 Tracker_update

=for sig

  Signature: ([phys] image(l2,c2,r2); indx [o,phys] boundingBox(n3=4); byte [o,phys] res(); TrackerWrapper * self)

=for ref

Update the tracker, find the new most likely bounding box for the target

=for example

 ($boundingBox,$res) = $obj->update($image);

Parameters:

=over

=item image

The current frame

=item boundingBox

The bounding box that represent the new target location, if true was returned, not
    modified otherwise

=back

Returns: True means that target was located and false means that tracker cannot locate target in
    current frame. Note, that latter *does not* imply that tracker has failed, maybe target is indeed
    missing from the frame (say, out of sight)


=for bad

Tracker_update ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2550 "Tracking.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Tracker::update {
  barf "Usage: PDL::OpenCV::Tracker::update(\$self,\$image)\n" if @_ < 2;
  my ($self,$image) = @_;
  my ($boundingBox,$res);
  $boundingBox = PDL->null if !defined $boundingBox;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Tracker::_Tracker_update_int($image,$boundingBox,$res,$self);
  !wantarray ? $res : ($boundingBox,$res)
}
#line 2565 "Tracking.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 2570 "Tracking.pm"



#line 394 "../genpp.pl"

=head1 METHODS for PDL::OpenCV::TrackerCSRT


=for ref

the CSRT tracker

The implementation is based on @cite Lukezic_IJCV2018 Discriminative Correlation Filter with Channel and Spatial Reliability

Subclass of PDL::OpenCV::Tracker


=cut

@PDL::OpenCV::TrackerCSRT::ISA = qw(PDL::OpenCV::Tracker);
#line 2591 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 new

=for ref

Create CSRT tracker instance

=for example

 $obj = PDL::OpenCV::TrackerCSRT->new;

Parameters:

=over

=item parameters

CSRT parameters TrackerCSRT::Params

=back


=cut
#line 2619 "Tracking.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 TrackerCSRT_setInitialMask

=for sig

  Signature: ([phys] mask(l2,c2,r2); TrackerCSRTWrapper * self)

=for ref

=for example

 $obj->setInitialMask($mask);


=for bad

TrackerCSRT_setInitialMask ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2647 "Tracking.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::TrackerCSRT::setInitialMask {
  barf "Usage: PDL::OpenCV::TrackerCSRT::setInitialMask(\$self,\$mask)\n" if @_ < 2;
  my ($self,$mask) = @_;
    
  PDL::OpenCV::TrackerCSRT::_TrackerCSRT_setInitialMask_int($mask,$self);
  
}
#line 2660 "Tracking.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 2665 "Tracking.pm"



#line 394 "../genpp.pl"

=head1 METHODS for PDL::OpenCV::TrackerDaSiamRPN




Subclass of PDL::OpenCV::Tracker


=cut

@PDL::OpenCV::TrackerDaSiamRPN::ISA = qw(PDL::OpenCV::Tracker);
#line 2682 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 new

=for ref

Constructor

=for example

 $obj = PDL::OpenCV::TrackerDaSiamRPN->new;

Parameters:

=over

=item parameters

DaSiamRPN parameters TrackerDaSiamRPN::Params

=back


=cut
#line 2710 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 getTrackingScore

=for ref

Return tracking score

=for example

 $res = $obj->getTrackingScore;


=cut
#line 2728 "Tracking.pm"



#line 394 "../genpp.pl"

=head1 METHODS for PDL::OpenCV::TrackerGOTURN


=for ref

the GOTURN (Generic Object Tracking Using Regression Networks) tracker
 *
 *  GOTURN (

@cite GOTURN) is kind of trackers based on Convolutional Neural Networks (CNN). While taking all advantages of CNN trackers,
*  GOTURN is much faster due to offline training without online fine-tuning nature.
*  GOTURN tracker addresses the problem of single target tracking: given a bounding box label of an object in the first frame of the video,
*  we track that object through the rest of the video. NOTE: Current method of GOTURN does not handle occlusions; however, it is fairly
*  robust to viewpoint changes, lighting changes, and deformations.
*  Inputs of GOTURN are two RGB patches representing Target and Search patches resized to 227x227.
*  Outputs of GOTURN are predicted bounding box coordinates, relative to Search patch coordinate system, in format X1,Y1,X2,Y2.
*  Original paper is here: <http://davheld.github.io/GOTURN/GOTURN.pdf>
*  As long as original authors implementation: <https://github.com/davheld/GOTURN#train-the-tracker>
*  Implementation of training algorithm is placed in separately here due to 3d-party dependencies:
*  <https://github.com/Auron-X/GOTURN_Training_Toolkit>
*  GOTURN architecture goturn.prototxt and trained model goturn.caffemodel are accessible on opencv_extra GitHub repository.

Subclass of PDL::OpenCV::Tracker


=cut

@PDL::OpenCV::TrackerGOTURN::ISA = qw(PDL::OpenCV::Tracker);
#line 2762 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 new

=for ref

Constructor

=for example

 $obj = PDL::OpenCV::TrackerGOTURN->new;

Parameters:

=over

=item parameters

GOTURN parameters TrackerGOTURN::Params

=back


=cut
#line 2790 "Tracking.pm"



#line 394 "../genpp.pl"

=head1 METHODS for PDL::OpenCV::TrackerKCF


=for ref

the KCF (Kernelized Correlation Filter) tracker

* KCF is a novel tracking framework that utilizes properties of circulant matrix to enhance the processing speed.
* This tracking method is an implementation of @cite KCF_ECCV which is extended to KCF with color-names features (@cite KCF_CN).
* The original paper of KCF is available at <http://www.robots.ox.ac.uk/~joao/publications/henriques_tpami2015.pdf>
* as well as the matlab implementation. For more information about KCF with color-names features, please refer to
* <http://www.cvl.isy.liu.se/research/objrec/visualtracking/colvistrack/index.html>.

Subclass of PDL::OpenCV::Tracker


=cut

@PDL::OpenCV::TrackerKCF::ISA = qw(PDL::OpenCV::Tracker);
#line 2815 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 new

=for ref

Create KCF tracker instance

=for example

 $obj = PDL::OpenCV::TrackerKCF->new;

Parameters:

=over

=item parameters

KCF parameters TrackerKCF::Params

=back


=cut
#line 2843 "Tracking.pm"



#line 394 "../genpp.pl"

=head1 METHODS for PDL::OpenCV::TrackerMIL


=for ref

The MIL algorithm trains a classifier in an online manner to separate the object from the
background.

Multiple Instance Learning avoids the drift problem for a robust tracking. The implementation is
based on @cite MIL .
Original code can be found here <http://vision.ucsd.edu/~bbabenko/project_miltrack.shtml>

Subclass of PDL::OpenCV::Tracker


=cut

@PDL::OpenCV::TrackerMIL::ISA = qw(PDL::OpenCV::Tracker);
#line 2867 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 new

=for ref

Create MIL tracker instance
     *

=for example

 $obj = PDL::OpenCV::TrackerMIL->new;

Parameters:

=over

=item parameters

MIL parameters TrackerMIL::Params

=back


=cut
#line 2896 "Tracking.pm"



#line 394 "../genpp.pl"

=head1 METHODS for PDL::OpenCV::VariationalRefinement


=for ref

Variational optical flow refinement

This class implements variational refinement of the input flow field, i.e.
it uses input flow to initialize the minimization of the following functional:
C<<< E(U) = \int_{\Omega} \delta \Psi(E_I) + \gamma \Psi(E_G) + \alpha \Psi(E_S)  >>>,
where C<<< E_I,E_G,E_S >>>are color constancy, gradient constancy and smoothness terms
respectively. C<<< \Psi(s^2)=\sqrt{s^2+\epsilon^2} >>>is a robust penalizer to limit the
influence of outliers. A complete formulation and a description of the minimization
procedure can be found in @cite Brox2004

Subclass of PDL::OpenCV::DenseOpticalFlow


=cut

@PDL::OpenCV::VariationalRefinement::ISA = qw(PDL::OpenCV::DenseOpticalFlow);
#line 2923 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 new

=for ref

Creates an instance of VariationalRefinement

=for example

 $obj = PDL::OpenCV::VariationalRefinement->new;


=cut
#line 2941 "Tracking.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 VariationalRefinement_calcUV

=for sig

  Signature: ([phys] I0(l2,c2,r2); [phys] I1(l3,c3,r3); [io,phys] flow_u(l4,c4,r4); [io,phys] flow_v(l5,c5,r5); VariationalRefinementWrapper * self)

=for ref

=for example

 $obj->calcUV($I0,$I1,$flow_u,$flow_v);

@ref calc function overload to handle separate horizontal (u) and vertical (v) flow components
(to avoid extra splits/merges)

=for bad

VariationalRefinement_calcUV ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2971 "Tracking.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::VariationalRefinement::calcUV {
  barf "Usage: PDL::OpenCV::VariationalRefinement::calcUV(\$self,\$I0,\$I1,\$flow_u,\$flow_v)\n" if @_ < 5;
  my ($self,$I0,$I1,$flow_u,$flow_v) = @_;
    
  PDL::OpenCV::VariationalRefinement::_VariationalRefinement_calcUV_int($I0,$I1,$flow_u,$flow_v,$self);
  
}
#line 2984 "Tracking.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 2989 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 getFixedPointIterations

=for ref

Number of outer (fixed-point) iterations in the minimization procedure.

=for example

 $res = $obj->getFixedPointIterations;

See also:
setFixedPointIterations


=cut
#line 3010 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 setFixedPointIterations

=for ref

=for example

 $obj->setFixedPointIterations($val);

@copybrief getFixedPointIterations See also:
getFixedPointIterations


=cut
#line 3029 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 getSorIterations

=for ref

Number of inner successive over-relaxation (SOR) iterations
        in the minimization procedure to solve the respective linear system.

=for example

 $res = $obj->getSorIterations;

See also:
setSorIterations


=cut
#line 3051 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 setSorIterations

=for ref

=for example

 $obj->setSorIterations($val);

@copybrief getSorIterations See also:
getSorIterations


=cut
#line 3070 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 getOmega

=for ref

Relaxation factor in SOR

=for example

 $res = $obj->getOmega;

See also:
setOmega


=cut
#line 3091 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 setOmega

=for ref

=for example

 $obj->setOmega($val);

@copybrief getOmega See also:
getOmega


=cut
#line 3110 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 getAlpha

=for ref

Weight of the smoothness term

=for example

 $res = $obj->getAlpha;

See also:
setAlpha


=cut
#line 3131 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 setAlpha

=for ref

=for example

 $obj->setAlpha($val);

@copybrief getAlpha See also:
getAlpha


=cut
#line 3150 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 getDelta

=for ref

Weight of the color constancy term

=for example

 $res = $obj->getDelta;

See also:
setDelta


=cut
#line 3171 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 setDelta

=for ref

=for example

 $obj->setDelta($val);

@copybrief getDelta See also:
getDelta


=cut
#line 3190 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 getGamma

=for ref

Weight of the gradient constancy term

=for example

 $res = $obj->getGamma;

See also:
setGamma


=cut
#line 3211 "Tracking.pm"



#line 274 "../genpp.pl"

=head2 setGamma

=for ref

=for example

 $obj->setGamma($val);

@copybrief getGamma See also:
getGamma


=cut
#line 3230 "Tracking.pm"



#line 441 "../genpp.pl"

=head1 CONSTANTS

=over

=item PDL::OpenCV::Tracking::OPTFLOW_USE_INITIAL_FLOW()

=item PDL::OpenCV::Tracking::OPTFLOW_LK_GET_MIN_EIGENVALS()

=item PDL::OpenCV::Tracking::OPTFLOW_FARNEBACK_GAUSSIAN()

=item PDL::OpenCV::Tracking::MOTION_TRANSLATION()

=item PDL::OpenCV::Tracking::MOTION_EUCLIDEAN()

=item PDL::OpenCV::Tracking::MOTION_AFFINE()

=item PDL::OpenCV::Tracking::MOTION_HOMOGRAPHY()

=item PDL::OpenCV::Tracking::DISOpticalFlow::PRESET_ULTRAFAST()

=item PDL::OpenCV::Tracking::DISOpticalFlow::PRESET_FAST()

=item PDL::OpenCV::Tracking::DISOpticalFlow::PRESET_MEDIUM()

=item PDL::OpenCV::Tracking::TrackerKCF::GRAY()

=item PDL::OpenCV::Tracking::TrackerKCF::CN()

=item PDL::OpenCV::Tracking::TrackerKCF::CUSTOM()


=back

=cut
#line 3270 "Tracking.pm"






# Exit with OK status

1;
