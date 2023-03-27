#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::OpenCV::Objdetect;

our @EXPORT_OK = qw( groupRectangles CASCADE_DO_CANNY_PRUNING CASCADE_SCALE_IMAGE CASCADE_FIND_BIGGEST_OBJECT CASCADE_DO_ROUGH_SEARCH );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::OpenCV::Objdetect ;






#line 364 "../genpp.pl"

=head1 NAME

PDL::OpenCV::Objdetect - PDL bindings for OpenCV BaseCascadeClassifier, CascadeClassifier, HOGDescriptor, QRCodeDetector

=head1 SYNOPSIS

 use PDL::OpenCV::Objdetect;

=cut

use strict;
use warnings;
use PDL::OpenCV; # get constants
#line 40 "Objdetect.pm"






=head1 FUNCTIONS

=cut




#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 groupRectangles

=for sig

  Signature: (indx [io,phys] rectList(n1=4,n1d0); int [o,phys] weights(n2d0); int [phys] groupThreshold(); double [phys] eps())

=for ref

 NO BROADCASTING.

=for example

 $weights = groupRectangles($rectList,$groupThreshold); # with defaults
 $weights = groupRectangles($rectList,$groupThreshold,$eps);

@overload

=for bad

groupRectangles ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 82 "Objdetect.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Objdetect::groupRectangles {
  barf "Usage: PDL::OpenCV::Objdetect::groupRectangles(\$rectList,\$groupThreshold,\$eps)\n" if @_ < 2;
  my ($rectList,$groupThreshold,$eps) = @_;
  my ($weights);
  $weights = PDL->null if !defined $weights;
  $eps = 0.2 if !defined $eps;
  PDL::OpenCV::Objdetect::_groupRectangles_int($rectList,$weights,$groupThreshold,$eps);
  !wantarray ? $weights : ($weights)
}
#line 97 "Objdetect.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*groupRectangles = \&PDL::OpenCV::Objdetect::groupRectangles;
#line 104 "Objdetect.pm"



#line 394 "../genpp.pl"

=head1 METHODS for PDL::OpenCV::BaseCascadeClassifier




Subclass of PDL::OpenCV::Algorithm


=cut

@PDL::OpenCV::BaseCascadeClassifier::ISA = qw(PDL::OpenCV::Algorithm);
#line 121 "Objdetect.pm"



#line 394 "../genpp.pl"

=head1 METHODS for PDL::OpenCV::CascadeClassifier


=for ref

Cascade classifier class for object detection.



=cut

@PDL::OpenCV::CascadeClassifier::ISA = qw();
#line 139 "Objdetect.pm"



#line 274 "../genpp.pl"

=head2 new

=for ref

=for example

 $obj = PDL::OpenCV::CascadeClassifier->new;


=cut
#line 155 "Objdetect.pm"



#line 274 "../genpp.pl"

=head2 new2

=for ref

Loads a classifier from a file.

=for example

 $obj = PDL::OpenCV::CascadeClassifier->new2($filename);

Parameters:

=over

=item filename

Name of the file from which the classifier is loaded.

=back


=cut
#line 183 "Objdetect.pm"



#line 274 "../genpp.pl"

=head2 empty

=for ref

Checks whether the classifier has been loaded.

=for example

 $res = $obj->empty;


=cut
#line 201 "Objdetect.pm"



#line 274 "../genpp.pl"

=head2 load

=for ref

Loads a classifier from a file.

=for example

 $res = $obj->load($filename);

Parameters:

=over

=item filename

Name of the file from which the classifier is loaded. The file may contain an old
    HAAR classifier trained by the haartraining application or a new cascade classifier trained by the
    traincascade application.

=back


=cut
#line 231 "Objdetect.pm"



#line 274 "../genpp.pl"

=head2 read

=for ref

Reads a classifier from a FileStorage node.

=for example

 $res = $obj->read($node);

@note The file may contain a new cascade classifier (trained traincascade application) only.

=cut
#line 250 "Objdetect.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 CascadeClassifier_detectMultiScale

=for sig

  Signature: ([phys] image(l2,c2,r2); indx [o,phys] objects(n3=4,n3d0); double [phys] scaleFactor(); int [phys] minNeighbors(); int [phys] flags(); indx [phys] minSize(n7); indx [phys] maxSize(n8); CascadeClassifierWrapper * self)

=for ref

Detects objects of different sizes in the input image. The detected objects are returned as a list
    of rectangles. NO BROADCASTING.

=for example

 $objects = $obj->detectMultiScale($image); # with defaults
 $objects = $obj->detectMultiScale($image,$scaleFactor,$minNeighbors,$flags,$minSize,$maxSize);

The function is parallelized with the TBB library.
@note
-   (Python) A face detection example using cascade classifiers can be found at
opencv_source_code/samples/python/facedetect.py

Parameters:

=over

=item image

Matrix of the type CV_8U containing an image where objects are detected.

=item objects

Vector of rectangles where each rectangle contains the detected object, the
    rectangles may be partially outside the original image.

=item scaleFactor

Parameter specifying how much the image size is reduced at each image scale.

=item minNeighbors

Parameter specifying how many neighbors each candidate rectangle should have
    to retain it.

=item flags

Parameter with the same meaning for an old cascade as in the function
    cvHaarDetectObjects. It is not used for a new cascade.

=item minSize

Minimum possible object size. Objects smaller than that are ignored.

=item maxSize

Maximum possible object size. Objects larger than that are ignored. If `maxSize == minSize` model is evaluated on single scale.

=back


=for bad

CascadeClassifier_detectMultiScale ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 324 "Objdetect.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::CascadeClassifier::detectMultiScale {
  barf "Usage: PDL::OpenCV::CascadeClassifier::detectMultiScale(\$self,\$image,\$scaleFactor,\$minNeighbors,\$flags,\$minSize,\$maxSize)\n" if @_ < 2;
  my ($self,$image,$scaleFactor,$minNeighbors,$flags,$minSize,$maxSize) = @_;
  my ($objects);
  $objects = PDL->null if !defined $objects;
  $scaleFactor = 1.1 if !defined $scaleFactor;
  $minNeighbors = 3 if !defined $minNeighbors;
  $flags = 0 if !defined $flags;
  $minSize = empty(indx) if !defined $minSize;
  $maxSize = empty(indx) if !defined $maxSize;
  PDL::OpenCV::CascadeClassifier::_CascadeClassifier_detectMultiScale_int($image,$objects,$scaleFactor,$minNeighbors,$flags,$minSize,$maxSize,$self);
  !wantarray ? $objects : ($objects)
}
#line 343 "Objdetect.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 348 "Objdetect.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 CascadeClassifier_detectMultiScale2

=for sig

  Signature: ([phys] image(l2,c2,r2); indx [o,phys] objects(n3=4,n3d0); int [o,phys] numDetections(n4d0); double [phys] scaleFactor(); int [phys] minNeighbors(); int [phys] flags(); indx [phys] minSize(n8); indx [phys] maxSize(n9); CascadeClassifierWrapper * self)

=for ref

 NO BROADCASTING.

=for example

 ($objects,$numDetections) = $obj->detectMultiScale2($image); # with defaults
 ($objects,$numDetections) = $obj->detectMultiScale2($image,$scaleFactor,$minNeighbors,$flags,$minSize,$maxSize);

@overload

Parameters:

=over

=item image

Matrix of the type CV_8U containing an image where objects are detected.

=item objects

Vector of rectangles where each rectangle contains the detected object, the
    rectangles may be partially outside the original image.

=item numDetections

Vector of detection numbers for the corresponding objects. An object's number
    of detections is the number of neighboring positively classified rectangles that were joined
    together to form the object.

=item scaleFactor

Parameter specifying how much the image size is reduced at each image scale.

=item minNeighbors

Parameter specifying how many neighbors each candidate rectangle should have
    to retain it.

=item flags

Parameter with the same meaning for an old cascade as in the function
    cvHaarDetectObjects. It is not used for a new cascade.

=item minSize

Minimum possible object size. Objects smaller than that are ignored.

=item maxSize

Maximum possible object size. Objects larger than that are ignored. If `maxSize == minSize` model is evaluated on single scale.

=back


=for bad

CascadeClassifier_detectMultiScale2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 424 "Objdetect.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::CascadeClassifier::detectMultiScale2 {
  barf "Usage: PDL::OpenCV::CascadeClassifier::detectMultiScale2(\$self,\$image,\$scaleFactor,\$minNeighbors,\$flags,\$minSize,\$maxSize)\n" if @_ < 2;
  my ($self,$image,$scaleFactor,$minNeighbors,$flags,$minSize,$maxSize) = @_;
  my ($objects,$numDetections);
  $objects = PDL->null if !defined $objects;
  $numDetections = PDL->null if !defined $numDetections;
  $scaleFactor = 1.1 if !defined $scaleFactor;
  $minNeighbors = 3 if !defined $minNeighbors;
  $flags = 0 if !defined $flags;
  $minSize = empty(indx) if !defined $minSize;
  $maxSize = empty(indx) if !defined $maxSize;
  PDL::OpenCV::CascadeClassifier::_CascadeClassifier_detectMultiScale2_int($image,$objects,$numDetections,$scaleFactor,$minNeighbors,$flags,$minSize,$maxSize,$self);
  !wantarray ? $numDetections : ($objects,$numDetections)
}
#line 444 "Objdetect.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 449 "Objdetect.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 CascadeClassifier_detectMultiScale3

=for sig

  Signature: ([phys] image(l2,c2,r2); indx [o,phys] objects(n3=4,n3d0); int [o,phys] rejectLevels(n4d0); double [o,phys] levelWeights(n5d0); double [phys] scaleFactor(); int [phys] minNeighbors(); int [phys] flags(); indx [phys] minSize(n9); indx [phys] maxSize(n10); byte [phys] outputRejectLevels(); CascadeClassifierWrapper * self)

=for ref

 NO BROADCASTING.

=for example

 ($objects,$rejectLevels,$levelWeights) = $obj->detectMultiScale3($image); # with defaults
 ($objects,$rejectLevels,$levelWeights) = $obj->detectMultiScale3($image,$scaleFactor,$minNeighbors,$flags,$minSize,$maxSize,$outputRejectLevels);

@overload
This function allows you to retrieve the final stage decision certainty of classification.
For this, one needs to set `outputRejectLevels` on true and provide the `rejectLevels` and `levelWeights` parameter.
For each resulting detection, `levelWeights` will then contain the certainty of classification at the final stage.
This value can then be used to separate strong from weaker classifications.
A code sample on how to use it efficiently can be found below:

     Mat img;
     vector<double> weights;
     vector<int> levels;
     vector<Rect> detections;
     CascadeClassifier model("/path/to/your/model.xml");
     model.detectMultiScale(img, detections, levels, weights, 1.1, 3, 0, Size(), Size(), true);
     cerr << "Detection " << detections[0] << " with weight " << weights[0] << endl;


=for bad

CascadeClassifier_detectMultiScale3 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 495 "Objdetect.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::CascadeClassifier::detectMultiScale3 {
  barf "Usage: PDL::OpenCV::CascadeClassifier::detectMultiScale3(\$self,\$image,\$scaleFactor,\$minNeighbors,\$flags,\$minSize,\$maxSize,\$outputRejectLevels)\n" if @_ < 2;
  my ($self,$image,$scaleFactor,$minNeighbors,$flags,$minSize,$maxSize,$outputRejectLevels) = @_;
  my ($objects,$rejectLevels,$levelWeights);
  $objects = PDL->null if !defined $objects;
  $rejectLevels = PDL->null if !defined $rejectLevels;
  $levelWeights = PDL->null if !defined $levelWeights;
  $scaleFactor = 1.1 if !defined $scaleFactor;
  $minNeighbors = 3 if !defined $minNeighbors;
  $flags = 0 if !defined $flags;
  $minSize = empty(indx) if !defined $minSize;
  $maxSize = empty(indx) if !defined $maxSize;
  $outputRejectLevels = 0 if !defined $outputRejectLevels;
  PDL::OpenCV::CascadeClassifier::_CascadeClassifier_detectMultiScale3_int($image,$objects,$rejectLevels,$levelWeights,$scaleFactor,$minNeighbors,$flags,$minSize,$maxSize,$outputRejectLevels,$self);
  !wantarray ? $levelWeights : ($objects,$rejectLevels,$levelWeights)
}
#line 517 "Objdetect.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 522 "Objdetect.pm"



#line 274 "../genpp.pl"

=head2 isOldFormatCascade

=for ref

=for example

 $res = $obj->isOldFormatCascade;


=cut
#line 538 "Objdetect.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 CascadeClassifier_getOriginalWindowSize

=for sig

  Signature: (indx [o,phys] res(n2=2); CascadeClassifierWrapper * self)

=for ref

=for example

 $res = $obj->getOriginalWindowSize;


=for bad

CascadeClassifier_getOriginalWindowSize ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 566 "Objdetect.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::CascadeClassifier::getOriginalWindowSize {
  barf "Usage: PDL::OpenCV::CascadeClassifier::getOriginalWindowSize(\$self)\n" if @_ < 1;
  my ($self) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::CascadeClassifier::_CascadeClassifier_getOriginalWindowSize_int($res,$self);
  !wantarray ? $res : ($res)
}
#line 580 "Objdetect.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 585 "Objdetect.pm"



#line 274 "../genpp.pl"

=head2 getFeatureType

=for ref

=for example

 $res = $obj->getFeatureType;


=cut
#line 601 "Objdetect.pm"



#line 274 "../genpp.pl"

=head2 convert

=for ref

=for example

 $res = PDL::OpenCV::CascadeClassifier::convert($oldcascade,$newcascade);


=cut
#line 617 "Objdetect.pm"



#line 394 "../genpp.pl"

=head1 METHODS for PDL::OpenCV::HOGDescriptor


=for ref

Implementation of HOG (Histogram of Oriented Gradients) descriptor and object detector.

the HOG descriptor algorithm introduced by Navneet Dalal and Bill Triggs @cite Dalal2005 .
useful links:
https://hal.inria.fr/inria-00548512/document/
https://en.wikipedia.org/wiki/Histogram_of_oriented_gradients
https://software.intel.com/en-us/ipp-dev-reference-histogram-of-oriented-gradients-hog-descriptor
http://www.learnopencv.com/histogram-of-oriented-gradients
http://www.learnopencv.com/handwritten-digits-classification-an-opencv-c-python-tutorial


=cut

@PDL::OpenCV::HOGDescriptor::ISA = qw();
#line 642 "Objdetect.pm"



#line 274 "../genpp.pl"

=head2 new

=for ref

Creates the HOG descriptor and detector with default params.

=for example

 $obj = PDL::OpenCV::HOGDescriptor->new;

aqual to HOGDescriptor(Size(64,128), Size(16,16), Size(8,8), Size(8,8), 9 )

=cut
#line 661 "Objdetect.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 HOGDescriptor_new2

=for sig

  Signature: (indx [phys] _winSize(n2=2); indx [phys] _blockSize(n3=2); indx [phys] _blockStride(n4=2); indx [phys] _cellSize(n5=2); int [phys] _nbins(); int [phys] _derivAperture(); double [phys] _winSigma(); int [phys] _histogramNormType(); double [phys] _L2HysThreshold(); byte [phys] _gammaCorrection(); int [phys] _nlevels(); byte [phys] _signedGradient(); char * klass; [o] HOGDescriptorWrapper * res)

=for ref

=for example

 $obj = PDL::OpenCV::HOGDescriptor->new2($_winSize,$_blockSize,$_blockStride,$_cellSize,$_nbins); # with defaults
 $obj = PDL::OpenCV::HOGDescriptor->new2($_winSize,$_blockSize,$_blockStride,$_cellSize,$_nbins,$_derivAperture,$_winSigma,$_histogramNormType,$_L2HysThreshold,$_gammaCorrection,$_nlevels,$_signedGradient);

@overload

Parameters:

=over

=item _winSize

sets winSize with given value.

=item _blockSize

sets blockSize with given value.

=item _blockStride

sets blockStride with given value.

=item _cellSize

sets cellSize with given value.

=item _nbins

sets nbins with given value.

=item _derivAperture

sets derivAperture with given value.

=item _winSigma

sets winSigma with given value.

=item _histogramNormType

sets histogramNormType with given value.

=item _L2HysThreshold

sets L2HysThreshold with given value.

=item _gammaCorrection

sets gammaCorrection with given value.

=item _nlevels

sets nlevels with given value.

=item _signedGradient

sets signedGradient with given value.

=back


=for bad

HOGDescriptor_new2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 746 "Objdetect.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::HOGDescriptor::new2 {
  barf "Usage: PDL::OpenCV::HOGDescriptor::new2(\$klass,\$_winSize,\$_blockSize,\$_blockStride,\$_cellSize,\$_nbins,\$_derivAperture,\$_winSigma,\$_histogramNormType,\$_L2HysThreshold,\$_gammaCorrection,\$_nlevels,\$_signedGradient)\n" if @_ < 6;
  my ($klass,$_winSize,$_blockSize,$_blockStride,$_cellSize,$_nbins,$_derivAperture,$_winSigma,$_histogramNormType,$_L2HysThreshold,$_gammaCorrection,$_nlevels,$_signedGradient) = @_;
  my ($res);
  $_derivAperture = 1 if !defined $_derivAperture;
  $_winSigma = -1 if !defined $_winSigma;
  $_histogramNormType = PDL::OpenCV::HOGDescriptor::L2Hys() if !defined $_histogramNormType;
  $_L2HysThreshold = 0.2 if !defined $_L2HysThreshold;
  $_gammaCorrection = 0 if !defined $_gammaCorrection;
  $_nlevels = PDL::OpenCV::HOGDescriptor::DEFAULT_NLEVELS() if !defined $_nlevels;
  $_signedGradient = 0 if !defined $_signedGradient;
  PDL::OpenCV::HOGDescriptor::_HOGDescriptor_new2_int($_winSize,$_blockSize,$_blockStride,$_cellSize,$_nbins,$_derivAperture,$_winSigma,$_histogramNormType,$_L2HysThreshold,$_gammaCorrection,$_nlevels,$_signedGradient,$klass,$res);
  !wantarray ? $res : ($res)
}
#line 766 "Objdetect.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 771 "Objdetect.pm"



#line 274 "../genpp.pl"

=head2 new3

=for ref

=for example

 $obj = PDL::OpenCV::HOGDescriptor->new3($filename);

@overload

Parameters:

=over

=item filename

The file name containing HOGDescriptor properties and coefficients for the linear SVM classifier.

=back


=cut
#line 799 "Objdetect.pm"



#line 274 "../genpp.pl"

=head2 getDescriptorSize

=for ref

Returns the number of coefficients required for the classification.

=for example

 $res = $obj->getDescriptorSize;


=cut
#line 817 "Objdetect.pm"



#line 274 "../genpp.pl"

=head2 checkDetectorSize

=for ref

Checks if detector size equal to descriptor size.

=for example

 $res = $obj->checkDetectorSize;


=cut
#line 835 "Objdetect.pm"



#line 274 "../genpp.pl"

=head2 getWinSigma

=for ref

Returns winSigma value

=for example

 $res = $obj->getWinSigma;


=cut
#line 853 "Objdetect.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 HOGDescriptor_setSVMDetector

=for sig

  Signature: ([phys] svmdetector(l2,c2,r2); HOGDescriptorWrapper * self)

=for ref

Sets coefficients for the linear SVM classifier.

=for example

 $obj->setSVMDetector($svmdetector);

Parameters:

=over

=item svmdetector

coefficients for the linear SVM classifier.

=back


=for bad

HOGDescriptor_setSVMDetector ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 893 "Objdetect.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::HOGDescriptor::setSVMDetector {
  barf "Usage: PDL::OpenCV::HOGDescriptor::setSVMDetector(\$self,\$svmdetector)\n" if @_ < 2;
  my ($self,$svmdetector) = @_;
    
  PDL::OpenCV::HOGDescriptor::_HOGDescriptor_setSVMDetector_int($svmdetector,$self);
  
}
#line 906 "Objdetect.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 911 "Objdetect.pm"



#line 274 "../genpp.pl"

=head2 load

=for ref

loads HOGDescriptor parameters and coefficients for the linear SVM classifier from a file.

=for example

 $res = $obj->load($filename); # with defaults
 $res = $obj->load($filename,$objname);

Parameters:

=over

=item filename

Path of the file to read.

=item objname

The optional name of the node to read (if empty, the first top-level node will be used).

=back


=cut
#line 944 "Objdetect.pm"



#line 274 "../genpp.pl"

=head2 save

=for ref

saves HOGDescriptor parameters and coefficients for the linear SVM classifier to a file

=for example

 $obj->save($filename); # with defaults
 $obj->save($filename,$objname);

Parameters:

=over

=item filename

File name

=item objname

Object name

=back


=cut
#line 977 "Objdetect.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 HOGDescriptor_compute

=for sig

  Signature: ([phys] img(l2,c2,r2); float [o,phys] descriptors(n3d0); indx [phys] winStride(n4); indx [phys] padding(n5); indx [phys] locations(n6,n6d0); HOGDescriptorWrapper * self)

=for ref

Computes HOG descriptors of given image.
     NO BROADCASTING.

=for example

 $descriptors = $obj->compute($img); # with defaults
 $descriptors = $obj->compute($img,$winStride,$padding,$locations);

Parameters:

=over

=item img

Matrix of the type CV_8U containing an image where HOG features will be calculated.

=item descriptors

Matrix of the type CV_32F

=item winStride

Window stride. It must be a multiple of block stride.

=item padding

Padding

=item locations

Vector of Point

=back


=for bad

HOGDescriptor_compute ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1035 "Objdetect.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::HOGDescriptor::compute {
  barf "Usage: PDL::OpenCV::HOGDescriptor::compute(\$self,\$img,\$winStride,\$padding,\$locations)\n" if @_ < 2;
  my ($self,$img,$winStride,$padding,$locations) = @_;
  my ($descriptors);
  $descriptors = PDL->null if !defined $descriptors;
  $winStride = empty(indx) if !defined $winStride;
  $padding = empty(indx) if !defined $padding;
  $locations = empty(indx) if !defined $locations;
  PDL::OpenCV::HOGDescriptor::_HOGDescriptor_compute_int($img,$descriptors,$winStride,$padding,$locations,$self);
  !wantarray ? $descriptors : ($descriptors)
}
#line 1052 "Objdetect.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 1057 "Objdetect.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 HOGDescriptor_detect

=for sig

  Signature: ([phys] img(l2,c2,r2); indx [o,phys] foundLocations(n3=2,n3d0); double [o,phys] weights(n4d0); double [phys] hitThreshold(); indx [phys] winStride(n6); indx [phys] padding(n7); indx [phys] searchLocations(n8,n8d0); HOGDescriptorWrapper * self)

=for ref

Performs object detection without a multi-scale window.
     NO BROADCASTING.

=for example

 ($foundLocations,$weights) = $obj->detect($img); # with defaults
 ($foundLocations,$weights) = $obj->detect($img,$hitThreshold,$winStride,$padding,$searchLocations);

Parameters:

=over

=item img

Matrix of the type CV_8U or CV_8UC3 containing an image where objects are detected.

=item foundLocations

Vector of point where each point contains left-top corner point of detected object boundaries.

=item weights

Vector that will contain confidence values for each detected object.

=item hitThreshold

Threshold for the distance between features and SVM classifying plane.
    Usually it is 0 and should be specified in the detector coefficients (as the last free coefficient).
    But if the free coefficient is omitted (which is allowed), you can specify it manually here.

=item winStride

Window stride. It must be a multiple of block stride.

=item padding

Padding

=item searchLocations

Vector of Point includes set of requested locations to be evaluated.

=back


=for bad

HOGDescriptor_detect ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1125 "Objdetect.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::HOGDescriptor::detect {
  barf "Usage: PDL::OpenCV::HOGDescriptor::detect(\$self,\$img,\$hitThreshold,\$winStride,\$padding,\$searchLocations)\n" if @_ < 2;
  my ($self,$img,$hitThreshold,$winStride,$padding,$searchLocations) = @_;
  my ($foundLocations,$weights);
  $foundLocations = PDL->null if !defined $foundLocations;
  $weights = PDL->null if !defined $weights;
  $hitThreshold = 0 if !defined $hitThreshold;
  $winStride = empty(indx) if !defined $winStride;
  $padding = empty(indx) if !defined $padding;
  $searchLocations = empty(indx) if !defined $searchLocations;
  PDL::OpenCV::HOGDescriptor::_HOGDescriptor_detect_int($img,$foundLocations,$weights,$hitThreshold,$winStride,$padding,$searchLocations,$self);
  !wantarray ? $weights : ($foundLocations,$weights)
}
#line 1144 "Objdetect.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 1149 "Objdetect.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 HOGDescriptor_detectMultiScale

=for sig

  Signature: ([phys] img(l2,c2,r2); indx [o,phys] foundLocations(n3=4,n3d0); double [o,phys] foundWeights(n4d0); double [phys] hitThreshold(); indx [phys] winStride(n6); indx [phys] padding(n7); double [phys] scale(); double [phys] finalThreshold(); byte [phys] useMeanshiftGrouping(); HOGDescriptorWrapper * self)

=for ref

Detects objects of different sizes in the input image. The detected objects are returned as a list
    of rectangles.
     NO BROADCASTING.

=for example

 ($foundLocations,$foundWeights) = $obj->detectMultiScale($img); # with defaults
 ($foundLocations,$foundWeights) = $obj->detectMultiScale($img,$hitThreshold,$winStride,$padding,$scale,$finalThreshold,$useMeanshiftGrouping);

Parameters:

=over

=item img

Matrix of the type CV_8U or CV_8UC3 containing an image where objects are detected.

=item foundLocations

Vector of rectangles where each rectangle contains the detected object.

=item foundWeights

Vector that will contain confidence values for each detected object.

=item hitThreshold

Threshold for the distance between features and SVM classifying plane.
    Usually it is 0 and should be specified in the detector coefficients (as the last free coefficient).
    But if the free coefficient is omitted (which is allowed), you can specify it manually here.

=item winStride

Window stride. It must be a multiple of block stride.

=item padding

Padding

=item scale

Coefficient of the detection window increase.

=item finalThreshold

Final threshold

=item useMeanshiftGrouping

indicates grouping algorithm

=back


=for bad

HOGDescriptor_detectMultiScale ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1226 "Objdetect.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::HOGDescriptor::detectMultiScale {
  barf "Usage: PDL::OpenCV::HOGDescriptor::detectMultiScale(\$self,\$img,\$hitThreshold,\$winStride,\$padding,\$scale,\$finalThreshold,\$useMeanshiftGrouping)\n" if @_ < 2;
  my ($self,$img,$hitThreshold,$winStride,$padding,$scale,$finalThreshold,$useMeanshiftGrouping) = @_;
  my ($foundLocations,$foundWeights);
  $foundLocations = PDL->null if !defined $foundLocations;
  $foundWeights = PDL->null if !defined $foundWeights;
  $hitThreshold = 0 if !defined $hitThreshold;
  $winStride = empty(indx) if !defined $winStride;
  $padding = empty(indx) if !defined $padding;
  $scale = 1.05 if !defined $scale;
  $finalThreshold = 2.0 if !defined $finalThreshold;
  $useMeanshiftGrouping = 0 if !defined $useMeanshiftGrouping;
  PDL::OpenCV::HOGDescriptor::_HOGDescriptor_detectMultiScale_int($img,$foundLocations,$foundWeights,$hitThreshold,$winStride,$padding,$scale,$finalThreshold,$useMeanshiftGrouping,$self);
  !wantarray ? $foundWeights : ($foundLocations,$foundWeights)
}
#line 1247 "Objdetect.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 1252 "Objdetect.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 HOGDescriptor_computeGradient

=for sig

  Signature: ([phys] img(l2,c2,r2); [io,phys] grad(l3,c3,r3); [io,phys] angleOfs(l4,c4,r4); indx [phys] paddingTL(n5); indx [phys] paddingBR(n6); HOGDescriptorWrapper * self)

=for ref

Computes gradients and quantized gradient orientations.

=for example

 $obj->computeGradient($img,$grad,$angleOfs); # with defaults
 $obj->computeGradient($img,$grad,$angleOfs,$paddingTL,$paddingBR);

Parameters:

=over

=item img

Matrix contains the image to be computed

=item grad

Matrix of type CV_32FC2 contains computed gradients

=item angleOfs

Matrix of type CV_8UC2 contains quantized gradient orientations

=item paddingTL

Padding from top-left

=item paddingBR

Padding from bottom-right

=back


=for bad

HOGDescriptor_computeGradient ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1309 "Objdetect.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::HOGDescriptor::computeGradient {
  barf "Usage: PDL::OpenCV::HOGDescriptor::computeGradient(\$self,\$img,\$grad,\$angleOfs,\$paddingTL,\$paddingBR)\n" if @_ < 4;
  my ($self,$img,$grad,$angleOfs,$paddingTL,$paddingBR) = @_;
    $paddingTL = empty(indx) if !defined $paddingTL;
  $paddingBR = empty(indx) if !defined $paddingBR;
  PDL::OpenCV::HOGDescriptor::_HOGDescriptor_computeGradient_int($img,$grad,$angleOfs,$paddingTL,$paddingBR,$self);
  
}
#line 1323 "Objdetect.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 1328 "Objdetect.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 HOGDescriptor_getDefaultPeopleDetector

=for sig

  Signature: (float [o,phys] res(n1d0))

=for ref

Returns coefficients of the classifier trained for people detection (for 64x128 windows). NO BROADCASTING.

=for example

 $res = PDL::OpenCV::HOGDescriptor::getDefaultPeopleDetector;


=for bad

HOGDescriptor_getDefaultPeopleDetector ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1358 "Objdetect.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::HOGDescriptor::getDefaultPeopleDetector {
  barf "Usage: PDL::OpenCV::HOGDescriptor::getDefaultPeopleDetector()\n" if @_ < 0;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::HOGDescriptor::_HOGDescriptor_getDefaultPeopleDetector_int($res);
  !wantarray ? $res : ($res)
}
#line 1371 "Objdetect.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 1376 "Objdetect.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 HOGDescriptor_getDaimlerPeopleDetector

=for sig

  Signature: (float [o,phys] res(n1d0))

=for ref

Returns coefficients of the classifier trained for people detection (for 48x96 windows). NO BROADCASTING.

=for example

 $res = PDL::OpenCV::HOGDescriptor::getDaimlerPeopleDetector;


=for bad

HOGDescriptor_getDaimlerPeopleDetector ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1406 "Objdetect.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::HOGDescriptor::getDaimlerPeopleDetector {
  barf "Usage: PDL::OpenCV::HOGDescriptor::getDaimlerPeopleDetector()\n" if @_ < 0;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::HOGDescriptor::_HOGDescriptor_getDaimlerPeopleDetector_int($res);
  !wantarray ? $res : ($res)
}
#line 1419 "Objdetect.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 1424 "Objdetect.pm"



#line 394 "../genpp.pl"

=head1 METHODS for PDL::OpenCV::QRCodeDetector


=for ref

Groups the object candidate rectangles.

Parameters:

=over

=item rectList

Input/output vector of rectangles. Output vector includes retained and grouped rectangles. (The Python list is not modified in place.)

=item weights

Input/output vector of weights of rectangles. Output vector includes weights of retained and grouped rectangles. (The Python list is not modified in place.)

=item groupThreshold

Minimum possible number of rectangles minus 1. The threshold is used in a group of rectangles to retain it.

=item eps

Relative difference between sides of the rectangles to merge them into a group.

=back



=cut

@PDL::OpenCV::QRCodeDetector::ISA = qw();
#line 1464 "Objdetect.pm"



#line 274 "../genpp.pl"

=head2 new

=for ref

=for example

 $obj = PDL::OpenCV::QRCodeDetector->new;


=cut
#line 1480 "Objdetect.pm"



#line 274 "../genpp.pl"

=head2 setEpsX

=for ref

sets the epsilon used during the horizontal scan of QR code stop marker detection.

=for example

 $obj->setEpsX($epsX);

Parameters:

=over

=item epsX

Epsilon neighborhood, which allows you to determine the horizontal pattern
     of the scheme 1:1:3:1:1 according to QR code standard.

=back


=cut
#line 1509 "Objdetect.pm"



#line 274 "../genpp.pl"

=head2 setEpsY

=for ref

sets the epsilon used during the vertical scan of QR code stop marker detection.

=for example

 $obj->setEpsY($epsY);

Parameters:

=over

=item epsY

Epsilon neighborhood, which allows you to determine the vertical pattern
     of the scheme 1:1:3:1:1 according to QR code standard.

=back


=cut
#line 1538 "Objdetect.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 QRCodeDetector_detect

=for sig

  Signature: ([phys] img(l2,c2,r2); [o,phys] points(l3,c3,r3); byte [o,phys] res(); QRCodeDetectorWrapper * self)

=for ref

Detects QR code in image and returns the quadrangle containing the code.
      NO BROADCASTING.

=for example

 ($points,$res) = $obj->detect($img);

Parameters:

=over

=item img

grayscale or color (BGR) image containing (or not) QR code.

=item points

Output vector of vertices of the minimum-area quadrangle containing the code.

=back


=for bad

QRCodeDetector_detect ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1583 "Objdetect.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::QRCodeDetector::detect {
  barf "Usage: PDL::OpenCV::QRCodeDetector::detect(\$self,\$img)\n" if @_ < 2;
  my ($self,$img) = @_;
  my ($points,$res);
  $points = PDL->null if !defined $points;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::QRCodeDetector::_QRCodeDetector_detect_int($img,$points,$res,$self);
  !wantarray ? $res : ($points,$res)
}
#line 1598 "Objdetect.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 1603 "Objdetect.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 QRCodeDetector_decode

=for sig

  Signature: ([phys] img(l2,c2,r2); [phys] points(l3,c3,r3); [o,phys] straight_qrcode(l4,c4,r4); QRCodeDetectorWrapper * self; [o] StringWrapper* res)

=for ref

Decodes QR code in image once it's found by the detect() method. NO BROADCASTING.

=for example

 ($straight_qrcode,$res) = $obj->decode($img,$points);

Returns UTF8-encoded output string or empty string if the code cannot be decoded.

Parameters:

=over

=item img

grayscale or color (BGR) image containing QR code.

=item points

Quadrangle vertices found by detect() method (or some other algorithm).

=item straight_qrcode

The optional output image containing rectified and binarized QR code

=back


=for bad

QRCodeDetector_decode ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1653 "Objdetect.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::QRCodeDetector::decode {
  barf "Usage: PDL::OpenCV::QRCodeDetector::decode(\$self,\$img,\$points)\n" if @_ < 3;
  my ($self,$img,$points) = @_;
  my ($straight_qrcode,$res);
  $straight_qrcode = PDL->null if !defined $straight_qrcode;
  PDL::OpenCV::QRCodeDetector::_QRCodeDetector_decode_int($img,$points,$straight_qrcode,$self,$res);
  !wantarray ? $res : ($straight_qrcode,$res)
}
#line 1667 "Objdetect.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 1672 "Objdetect.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 QRCodeDetector_decodeCurved

=for sig

  Signature: ([phys] img(l2,c2,r2); [phys] points(l3,c3,r3); [o,phys] straight_qrcode(l4,c4,r4); QRCodeDetectorWrapper * self; [o] StringWrapper* res)

=for ref

Decodes QR code on a curved surface in image once it's found by the detect() method. NO BROADCASTING.

=for example

 ($straight_qrcode,$res) = $obj->decodeCurved($img,$points);

Returns UTF8-encoded output string or empty string if the code cannot be decoded.

Parameters:

=over

=item img

grayscale or color (BGR) image containing QR code.

=item points

Quadrangle vertices found by detect() method (or some other algorithm).

=item straight_qrcode

The optional output image containing rectified and binarized QR code

=back


=for bad

QRCodeDetector_decodeCurved ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1722 "Objdetect.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::QRCodeDetector::decodeCurved {
  barf "Usage: PDL::OpenCV::QRCodeDetector::decodeCurved(\$self,\$img,\$points)\n" if @_ < 3;
  my ($self,$img,$points) = @_;
  my ($straight_qrcode,$res);
  $straight_qrcode = PDL->null if !defined $straight_qrcode;
  PDL::OpenCV::QRCodeDetector::_QRCodeDetector_decodeCurved_int($img,$points,$straight_qrcode,$self,$res);
  !wantarray ? $res : ($straight_qrcode,$res)
}
#line 1736 "Objdetect.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 1741 "Objdetect.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 QRCodeDetector_detectAndDecode

=for sig

  Signature: ([phys] img(l2,c2,r2); [o,phys] points(l3,c3,r3); [o,phys] straight_qrcode(l4,c4,r4); QRCodeDetectorWrapper * self; [o] StringWrapper* res)

=for ref

Both detects and decodes QR code NO BROADCASTING.

=for example

 ($points,$straight_qrcode,$res) = $obj->detectAndDecode($img);

Parameters:

=over

=item img

grayscale or color (BGR) image containing QR code.

=item points

optional output array of vertices of the found QR code quadrangle. Will be empty if not found.

=item straight_qrcode

The optional output image containing rectified and binarized QR code

=back


=for bad

QRCodeDetector_detectAndDecode ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1789 "Objdetect.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::QRCodeDetector::detectAndDecode {
  barf "Usage: PDL::OpenCV::QRCodeDetector::detectAndDecode(\$self,\$img)\n" if @_ < 2;
  my ($self,$img) = @_;
  my ($points,$straight_qrcode,$res);
  $points = PDL->null if !defined $points;
  $straight_qrcode = PDL->null if !defined $straight_qrcode;
  PDL::OpenCV::QRCodeDetector::_QRCodeDetector_detectAndDecode_int($img,$points,$straight_qrcode,$self,$res);
  !wantarray ? $res : ($points,$straight_qrcode,$res)
}
#line 1804 "Objdetect.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 1809 "Objdetect.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 QRCodeDetector_detectAndDecodeCurved

=for sig

  Signature: ([phys] img(l2,c2,r2); [o,phys] points(l3,c3,r3); [o,phys] straight_qrcode(l4,c4,r4); QRCodeDetectorWrapper * self; [o] StringWrapper* res)

=for ref

Both detects and decodes QR code on a curved surface NO BROADCASTING.

=for example

 ($points,$straight_qrcode,$res) = $obj->detectAndDecodeCurved($img);

Parameters:

=over

=item img

grayscale or color (BGR) image containing QR code.

=item points

optional output array of vertices of the found QR code quadrangle. Will be empty if not found.

=item straight_qrcode

The optional output image containing rectified and binarized QR code

=back


=for bad

QRCodeDetector_detectAndDecodeCurved ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1857 "Objdetect.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::QRCodeDetector::detectAndDecodeCurved {
  barf "Usage: PDL::OpenCV::QRCodeDetector::detectAndDecodeCurved(\$self,\$img)\n" if @_ < 2;
  my ($self,$img) = @_;
  my ($points,$straight_qrcode,$res);
  $points = PDL->null if !defined $points;
  $straight_qrcode = PDL->null if !defined $straight_qrcode;
  PDL::OpenCV::QRCodeDetector::_QRCodeDetector_detectAndDecodeCurved_int($img,$points,$straight_qrcode,$self,$res);
  !wantarray ? $res : ($points,$straight_qrcode,$res)
}
#line 1872 "Objdetect.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 1877 "Objdetect.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 QRCodeDetector_detectMulti

=for sig

  Signature: ([phys] img(l2,c2,r2); [o,phys] points(l3,c3,r3); byte [o,phys] res(); QRCodeDetectorWrapper * self)

=for ref

Detects QR codes in image and returns the vector of the quadrangles containing the codes.
      NO BROADCASTING.

=for example

 ($points,$res) = $obj->detectMulti($img);

Parameters:

=over

=item img

grayscale or color (BGR) image containing (or not) QR codes.

=item points

Output vector of vector of vertices of the minimum-area quadrangle containing the codes.

=back


=for bad

QRCodeDetector_detectMulti ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1922 "Objdetect.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::QRCodeDetector::detectMulti {
  barf "Usage: PDL::OpenCV::QRCodeDetector::detectMulti(\$self,\$img)\n" if @_ < 2;
  my ($self,$img) = @_;
  my ($points,$res);
  $points = PDL->null if !defined $points;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::QRCodeDetector::_QRCodeDetector_detectMulti_int($img,$points,$res,$self);
  !wantarray ? $res : ($points,$res)
}
#line 1937 "Objdetect.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 1942 "Objdetect.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 QRCodeDetector_decodeMulti

=for sig

  Signature: ([phys] img(l2,c2,r2); [phys] points(l3,c3,r3); byte [o,phys] res(); QRCodeDetectorWrapper * self; [o] vector_StringWrapper * decoded_info; [o] vector_MatWrapper * straight_qrcode)

=for ref

Decodes QR codes in image once it's found by the detect() method.

=for example

 ($decoded_info,$straight_qrcode,$res) = $obj->decodeMulti($img,$points);

Parameters:

=over

=item img

grayscale or color (BGR) image containing QR codes.

=item decoded_info

UTF8-encoded output vector of string or empty vector of string if the codes cannot be decoded.

=item points

vector of Quadrangle vertices found by detect() method (or some other algorithm).

=item straight_qrcode

The optional output vector of images containing rectified and binarized QR codes

=back


=for bad

QRCodeDetector_decodeMulti ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1994 "Objdetect.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::QRCodeDetector::decodeMulti {
  barf "Usage: PDL::OpenCV::QRCodeDetector::decodeMulti(\$self,\$img,\$points)\n" if @_ < 3;
  my ($self,$img,$points) = @_;
  my ($decoded_info,$straight_qrcode,$res);
  $straight_qrcode = undef if !defined $straight_qrcode;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::QRCodeDetector::_QRCodeDetector_decodeMulti_int($img,$points,$res,$self,$decoded_info,$straight_qrcode);
  !wantarray ? $res : ($decoded_info,$straight_qrcode,$res)
}
#line 2009 "Objdetect.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 2014 "Objdetect.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 QRCodeDetector_detectAndDecodeMulti

=for sig

  Signature: ([phys] img(l2,c2,r2); [o,phys] points(l4,c4,r4); byte [o,phys] res(); QRCodeDetectorWrapper * self; [o] vector_StringWrapper * decoded_info; [o] vector_MatWrapper * straight_qrcode)

=for ref

Both detects and decodes QR codes
     NO BROADCASTING.

=for example

 ($decoded_info,$points,$straight_qrcode,$res) = $obj->detectAndDecodeMulti($img);

Parameters:

=over

=item img

grayscale or color (BGR) image containing QR codes.

=item decoded_info

UTF8-encoded output vector of string or empty vector of string if the codes cannot be decoded.

=item points

optional output vector of vertices of the found QR code quadrangles. Will be empty if not found.

=item straight_qrcode

The optional output vector of images containing rectified and binarized QR codes

=back


=for bad

QRCodeDetector_detectAndDecodeMulti ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2067 "Objdetect.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::QRCodeDetector::detectAndDecodeMulti {
  barf "Usage: PDL::OpenCV::QRCodeDetector::detectAndDecodeMulti(\$self,\$img)\n" if @_ < 2;
  my ($self,$img) = @_;
  my ($decoded_info,$points,$straight_qrcode,$res);
  $points = PDL->null if !defined $points;
  $straight_qrcode = undef if !defined $straight_qrcode;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::QRCodeDetector::_QRCodeDetector_detectAndDecodeMulti_int($img,$points,$res,$self,$decoded_info,$straight_qrcode);
  !wantarray ? $res : ($decoded_info,$points,$straight_qrcode,$res)
}
#line 2083 "Objdetect.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 2088 "Objdetect.pm"



#line 441 "../genpp.pl"

=head1 CONSTANTS

=over

=item PDL::OpenCV::Objdetect::CASCADE_DO_CANNY_PRUNING()

=item PDL::OpenCV::Objdetect::CASCADE_SCALE_IMAGE()

=item PDL::OpenCV::Objdetect::CASCADE_FIND_BIGGEST_OBJECT()

=item PDL::OpenCV::Objdetect::CASCADE_DO_ROUGH_SEARCH()

=item PDL::OpenCV::Objdetect::HOGDescriptor::L2Hys()

=item PDL::OpenCV::Objdetect::HOGDescriptor::DEFAULT_NLEVELS()

=item PDL::OpenCV::Objdetect::HOGDescriptor::DESCR_FORMAT_COL_BY_COL()

=item PDL::OpenCV::Objdetect::HOGDescriptor::DESCR_FORMAT_ROW_BY_ROW()


=back

=cut
#line 2118 "Objdetect.pm"






# Exit with OK status

1;
