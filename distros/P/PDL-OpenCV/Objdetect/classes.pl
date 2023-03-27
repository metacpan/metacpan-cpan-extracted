(
['BaseCascadeClassifier',['Algorithm'],''],
['CascadeClassifier',[],'@brief Cascade classifier class for object detection.',0,'cv::CascadeClassifier',[[[],''],[[['String','filename','',['/C','/Ref']]],'@brief Loads a classifier from a file.

    @param filename Name of the file from which the classifier is loaded.']]],
['HOGDescriptor',[],'@brief Implementation of HOG (Histogram of Oriented Gradients) descriptor and object detector.

the HOG descriptor algorithm introduced by Navneet Dalal and Bill Triggs @cite Dalal2005 .

useful links:

https://hal.inria.fr/inria-00548512/document/

https://en.wikipedia.org/wiki/Histogram_of_oriented_gradients

https://software.intel.com/en-us/ipp-dev-reference-histogram-of-oriented-gradients-hog-descriptor

http://www.learnopencv.com/histogram-of-oriented-gradients

http://www.learnopencv.com/handwritten-digits-classification-an-opencv-c-python-tutorial',0,'cv::HOGDescriptor',[[[],'@brief Creates the HOG descriptor and detector with default params.

    aqual to HOGDescriptor(Size(64,128), Size(16,16), Size(8,8), Size(8,8), 9 )'],[[['Size','_winSize','',[]],['Size','_blockSize','',[]],['Size','_blockStride','',[]],['Size','_cellSize','',[]],['int','_nbins','',[]],['int','_derivAperture','1',[]],['double','_winSigma','-1',[]],['HOGDescriptor_HistogramNormType','_histogramNormType','HOGDescriptor::L2Hys',[]],['double','_L2HysThreshold','0.2',[]],['bool','_gammaCorrection','false',[]],['int','_nlevels','HOGDescriptor::DEFAULT_NLEVELS',[]],['bool','_signedGradient','false',[]]],'@overload
    @param _winSize sets winSize with given value.
    @param _blockSize sets blockSize with given value.
    @param _blockStride sets blockStride with given value.
    @param _cellSize sets cellSize with given value.
    @param _nbins sets nbins with given value.
    @param _derivAperture sets derivAperture with given value.
    @param _winSigma sets winSigma with given value.
    @param _histogramNormType sets histogramNormType with given value.
    @param _L2HysThreshold sets L2HysThreshold with given value.
    @param _gammaCorrection sets gammaCorrection with given value.
    @param _nlevels sets nlevels with given value.
    @param _signedGradient sets signedGradient with given value.'],[[['String','filename','',['/C','/Ref']]],'@overload
    @param filename The file name containing HOGDescriptor properties and coefficients for the linear SVM classifier.']]],
['QRCodeDetector',[],'@brief Groups the object candidate rectangles.
    @param rectList  Input/output vector of rectangles. Output vector includes retained and grouped rectangles. (The Python list is not modified in place.)
    @param weights Input/output vector of weights of rectangles. Output vector includes weights of retained and grouped rectangles. (The Python list is not modified in place.)
    @param groupThreshold Minimum possible number of rectangles minus 1. The threshold is used in a group of rectangles to retain it.
    @param eps Relative difference between sides of the rectangles to merge them into a group.',0,'cv::QRCodeDetector',[[[],'']]],
);
