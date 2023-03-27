(
['GeneralizedHough',['Algorithm'],'@brief finds arbitrary template in the grayscale image using Generalized Hough Transform'],
['GeneralizedHoughBallard',['GeneralizedHough'],'@brief finds arbitrary template in the grayscale image using Generalized Hough Transform

Detects position only without translation and rotation @cite Ballard1981 .',1,'cv::createGeneralizedHoughBallard',[[[],'@brief Creates a smart pointer to a cv::GeneralizedHoughBallard class and initializes it.']]],
['GeneralizedHoughGuil',['GeneralizedHough'],'@brief finds arbitrary template in the grayscale image using Generalized Hough Transform

Detects position, translation and rotation @cite Guil1999 .',1,'cv::createGeneralizedHoughGuil',[[[],'@brief Creates a smart pointer to a cv::GeneralizedHoughGuil class and initializes it.']]],
['CLAHE',['Algorithm'],'@brief Base class for Contrast Limited Adaptive Histogram Equalization.',1,'cv::createCLAHE',[[[['double','clipLimit','40.0',[]],['Size','tileGridSize','Size(8, 8)',[]]],'@brief Creates a smart pointer to a cv::CLAHE class and initializes it.

@param clipLimit Threshold for contrast limiting.
@param tileGridSize Size of grid for histogram equalization. Input image will be divided into
equally sized rectangular tiles. tileGridSize defines the number of tiles in row and column.']]],
['Subdiv2D',[],'',0,'cv::Subdiv2D',[[[],'creates an empty Subdiv2D object.
    To create a new empty Delaunay subdivision you need to use the #initDelaunay function.'],[[['Rect','rect','',[]]],'@overload

    @param rect Rectangle that includes all of the 2D points that are to be added to the subdivision.

    The function creates an empty Delaunay subdivision where 2D points can be added using the function
    insert() . All of the points to be added must be within the specified rectangle, otherwise a runtime
    error is raised.']]],
['LineSegmentDetector',['Algorithm'],'@brief Line segment detector class

following the algorithm described at @cite Rafael12 .

@note Implementation has been removed from OpenCV version 3.4.6 to 3.4.15 and version 4.1.0 to 4.5.3 due original code license conflict.
restored again after [Computation of a NFA](https://github.com/rafael-grompone-von-gioi/binomial_nfa) code published under the MIT license.',1,'cv::createLineSegmentDetector',[[[['int','refine','LSD_REFINE_STD',[]],['double','scale','0.8',[]],['double','sigma_scale','0.6',[]],['double','quant','2.0',[]],['double','ang_th','22.5',[]],['double','log_eps','0',[]],['double','density_th','0.7',[]],['int','n_bins','1024',[]]],'@brief Creates a smart pointer to a LineSegmentDetector object and initializes it.

The LineSegmentDetector algorithm is defined using the standard values. Only advanced users may want
to edit those, as to tailor it for their own application.

@param refine The way found lines will be refined, see #LineSegmentDetectorModes
@param scale The scale of the image that will be used to find the lines. Range (0..1].
@param sigma_scale Sigma for Gaussian filter. It is computed as sigma = sigma_scale/scale.
@param quant Bound to the quantization error on the gradient norm.
@param ang_th Gradient angle tolerance in degrees.
@param log_eps Detection threshold: -log10(NFA) \\> log_eps. Used only when advance refinement is chosen.
@param density_th Minimal density of aligned region points in the enclosing rectangle.
@param n_bins Number of bins in pseudo-ordering of gradient modulus.']]],
);
