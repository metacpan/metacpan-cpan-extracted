(
['RotatedRect',[],'@brief The class represents rotated (i.e. not up-right) rectangles on a plane.

Each rectangle is specified by the center point (mass center), length of each side (represented by
#Size2f structure) and the rotation angle in degrees.

The sample below demonstrates how to use RotatedRect:
@snippet snippets/core_various.cpp RotatedRect_demo
![image](pics/rotatedrect.png)

@sa CamShift, fitEllipse, minAreaRect, CvBox2D',0,'cv::RotatedRect',[[[],''],[[['Point2f','center','',['/C','/Ref']],['Size2f','size','',['/C','/Ref']],['float','angle','',[]]],'full constructor
    @param center The rectangle mass center.
    @param size Width and height of the rectangle.
    @param angle The rotation angle in a clockwise direction. When the angle is 0, 90, 180, 270 etc.,
    the rectangle becomes an up-right rectangle.']]],
['KeyPoint',[],'@brief Data structure for salient point detectors.

The class instance stores a keypoint, i.e. a point feature found by one of many available keypoint
detectors, such as Harris corner detector, #FAST, %StarDetector, %SURF, %SIFT etc.

The keypoint is characterized by the 2D position, scale (proportional to the diameter of the
neighborhood that needs to be taken into account), orientation and some other parameters. The
keypoint neighborhood is then analyzed by another algorithm that builds a descriptor (usually
represented as a feature vector). The keypoints representing the same object in different images
can then be matched using %KDTree or another method.',0,'cv::KeyPoint',[[[],''],[[['float','x','',[]],['float','y','',[]],['float','size','',[]],['float','angle','-1',[]],['float','response','0',[]],['int','octave','0',[]],['int','class_id','-1',[]]],'@param x x-coordinate of the keypoint
    @param y y-coordinate of the keypoint
    @param size keypoint diameter
    @param angle keypoint orientation
    @param response keypoint detector response on the keypoint (that is, strength of the keypoint)
    @param octave pyramid octave in which the keypoint has been detected
    @param class_id object id']]],
['DMatch',[],'@brief Class for matching keypoint descriptors

query descriptor index, train descriptor index, train image index, and distance between
descriptors.',0,'cv::DMatch',[[[],''],[[['int','_queryIdx','',[]],['int','_trainIdx','',[]],['float','_distance','',[]]],''],[[['int','_queryIdx','',[]],['int','_trainIdx','',[]],['int','_imgIdx','',[]],['float','_distance','',[]]],'']]],
['TermCriteria',[],'@brief The class defining termination criteria for iterative algorithms.

You can initialize it by default constructor and then override any parameters, or the structure may
be fully initialized using the advanced variant of the constructor.',0,'cv::TermCriteria',[[[],''],[[['int','type','',[]],['int','maxCount','',[]],['double','epsilon','',[]]],'@param type The type of termination criteria, one of TermCriteria::Type
    @param maxCount The maximum number of iterations or elements to compute.
    @param epsilon The desired accuracy or change in parameters at which the iterative algorithm stops.']]],
['Moments',[],'@brief struct returned by cv::moments

The spatial moments \\f$\\texttt{Moments::m}_{ji}\\f$ are computed as:

\\f[\\texttt{m} _{ji}= \\sum _{x,y}  \\left ( \\texttt{array} (x,y)  \\cdot x^j  \\cdot y^i \\right )\\f]

The central moments \\f$\\texttt{Moments::mu}_{ji}\\f$ are computed as:

\\f[\\texttt{mu} _{ji}= \\sum _{x,y}  \\left ( \\texttt{array} (x,y)  \\cdot (x -  \\bar{x} )^j  \\cdot (y -  \\bar{y} )^i \\right )\\f]

where \\f$(\\bar{x}, \\bar{y})\\f$ is the mass center:

\\f[\\bar{x} = \\frac{\\texttt{m}_{10}}{\\texttt{m}_{00}} , \\; \\bar{y} = \\frac{\\texttt{m}_{01}}{\\texttt{m}_{00}}\\f]

The normalized central moments \\f$\\texttt{Moments::nu}_{ij}\\f$ are computed as:

\\f[\\texttt{nu} _{ji}= \\frac{\\texttt{mu}_{ji}}{\\texttt{m}_{00}^{(i+j)/2+1}} .\\f]

@note
\\f$\\texttt{mu}_{00}=\\texttt{m}_{00}\\f$, \\f$\\texttt{nu}_{00}=1\\f$
\\f$\\texttt{nu}_{10}=\\texttt{mu}_{10}=\\texttt{mu}_{01}=\\texttt{mu}_{10}=0\\f$ , hence the values are not
stored.

The moments of a contour are defined in the same way but computed using the Green\'s formula (see
<http://en.wikipedia.org/wiki/Green_theorem>). So, due to a limited raster resolution, the moments
computed for a contour are slightly different from the moments computed for the same rasterized
contour.

@note
Since the contour moments are computed using Green formula, you may get seemingly odd results for
contours with self-intersections, e.g. a zero area (m00) for butterfly-shaped contours.'],
['RNG',[],'@brief Random Number Generator

Random number generator. It encapsulates the state (currently, a 64-bit
integer) and has methods to return scalar random values and to fill
arrays with random values. Currently it supports uniform and Gaussian
(normal) distributions. The generator uses Multiply-With-Carry
algorithm, introduced by G. Marsaglia (
<http://en.wikipedia.org/wiki/Multiply-with-carry> ).
Gaussian-distribution random numbers are generated using the Ziggurat
algorithm ( <http://en.wikipedia.org/wiki/Ziggurat_algorithm> ),
introduced by G. Marsaglia and W. W. Tsang.',0,'cv::RNG',[[[],'@brief constructor

    These are the RNG constructors. The first form sets the state to some
    pre-defined value, equal to 2\\*\\*32-1 in the current implementation. The
    second form sets the state to the specified value. If you passed state=0
    , the constructor uses the above default value instead to avoid the
    singular random number sequence, consisting of all zeros.'],[[['uint64','state','',[]]],'@overload
    @param state 64-bit value used to initialize the RNG.']]],
['RNG_MT19937',[],'@brief Mersenne Twister random number generator

Inspired by http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/MT2002/CODES/mt19937ar.c
@todo document'],
['Algorithm',[],'@brief This is a base class for all more or less complex algorithms in OpenCV

especially for classes of algorithms, for which there can be multiple implementations. The examples
are stereo correspondence (for which there are algorithms like block matching, semi-global block
matching, graph-cut etc.), background subtraction (which can be done using mixture-of-gaussians
models, codebook-based algorithm etc.), optical flow (block matching, Lucas-Kanade, Horn-Schunck
etc.).

Here is example of SimpleBlobDetector use in your application via Algorithm interface:
@snippet snippets/core_various.cpp Algorithm'],
['FileStorage',[],'@brief XML/YAML/JSON file storage class that encapsulates all the information necessary for writing or
reading data to/from a file.',0,'cv::FileStorage',[[[],'@brief The constructors.

     The full constructor opens the file. Alternatively you can use the default constructor and then
     call FileStorage::open.'],[[['String','filename','',['/C','/Ref']],['int','flags','',[]],['String','encoding','String()',['/C','/Ref']]],'@overload
     @copydoc open()']]],
['FileNode',[],'@brief File Storage Node class.

The node is used to store each and every element of the file storage opened for reading. When
XML/YAML file is read, it is first parsed and stored in the memory as a hierarchical collection of
nodes. Each node can be a "leaf" that is contain a single number or a string, or be a collection of
other nodes. There can be named collections (mappings) where each element has a name and it is
accessed by a name, and ordered collections (sequences) where elements do not have names but rather
accessed by index. Type of the file node can be determined using FileNode::type method.

Note that file nodes are only used for navigating file storages opened for reading. When a file
storage is opened for writing, no data is stored in memory after it is written.',0,'cv::FileNode',[[[],'@brief The constructors.

     These constructors are used to create a default file node, construct it from obsolete structures or
     from the another file node.']]],
);
