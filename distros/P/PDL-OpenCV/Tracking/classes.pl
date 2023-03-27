(
['TrackerCSRT',['Tracker'],'@brief the CSRT tracker

The implementation is based on @cite Lukezic_IJCV2018 Discriminative Correlation Filter with Channel and Spatial Reliability',1,'cv::TrackerCSRT::create',[[[],'@brief Create CSRT tracker instance
    @param parameters CSRT parameters TrackerCSRT::Params']]],
['TrackerKCF',['Tracker'],'@brief the KCF (Kernelized Correlation Filter) tracker

 * KCF is a novel tracking framework that utilizes properties of circulant matrix to enhance the processing speed.
 * This tracking method is an implementation of @cite KCF_ECCV which is extended to KCF with color-names features (@cite KCF_CN).
 * The original paper of KCF is available at <http://www.robots.ox.ac.uk/~joao/publications/henriques_tpami2015.pdf>
 * as well as the matlab implementation. For more information about KCF with color-names features, please refer to
 * <http://www.cvl.isy.liu.se/research/objrec/visualtracking/colvistrack/index.html>.',1,'cv::TrackerKCF::create',[[[],'@brief Create KCF tracker instance
    @param parameters KCF parameters TrackerKCF::Params']]],
['KalmanFilter',[],'@brief Kalman filter class.

The class implements a standard Kalman filter <http://en.wikipedia.org/wiki/Kalman_filter>,
@cite Welch95 . However, you can modify transitionMatrix, controlMatrix, and measurementMatrix to get
an extended Kalman filter functionality.
@note In C API when CvKalman\\* kalmanFilter structure is not needed anymore, it should be released
with cvReleaseKalman(&kalmanFilter)',0,'cv::KalmanFilter',[[[],''],[[['int','dynamParams','',[]],['int','measureParams','',[]],['int','controlParams','0',[]],['int','type','CV_32F',[]]],'@overload
    @param dynamParams Dimensionality of the state.
    @param measureParams Dimensionality of the measurement.
    @param controlParams Dimensionality of the control vector.
    @param type Type of the created matrices that should be CV_32F or CV_64F.']]],
['DenseOpticalFlow',['Algorithm'],'Base class for dense optical flow algorithms'],
['SparseOpticalFlow',['Algorithm'],'@brief Base interface for sparse optical flow algorithms.'],
['FarnebackOpticalFlow',['DenseOpticalFlow'],'@brief Class computing a dense optical flow using the Gunnar Farneback\'s algorithm.',1,'cv::FarnebackOpticalFlow::create',[[[['int','numLevels','5',[]],['double','pyrScale','0.5',[]],['bool','fastPyramids','false',[]],['int','winSize','13',[]],['int','numIters','10',[]],['int','polyN','5',[]],['double','polySigma','1.1',[]],['int','flags','0',[]]],'']]],
['VariationalRefinement',['DenseOpticalFlow'],'@brief Variational optical flow refinement

This class implements variational refinement of the input flow field, i.e.
it uses input flow to initialize the minimization of the following functional:
\\f$E(U) = \\int_{\\Omega} \\delta \\Psi(E_I) + \\gamma \\Psi(E_G) + \\alpha \\Psi(E_S) \\f$,
where \\f$E_I,E_G,E_S\\f$ are color constancy, gradient constancy and smoothness terms
respectively. \\f$\\Psi(s^2)=\\sqrt{s^2+\\epsilon^2}\\f$ is a robust penalizer to limit the
influence of outliers. A complete formulation and a description of the minimization
procedure can be found in @cite Brox2004',1,'cv::VariationalRefinement::create',[[[],'@brief Creates an instance of VariationalRefinement']]],
['DISOpticalFlow',['DenseOpticalFlow'],'@brief DIS optical flow algorithm.

This class implements the Dense Inverse Search (DIS) optical flow algorithm. More
details about the algorithm can be found at @cite Kroeger2016 . Includes three presets with preselected
parameters to provide reasonable trade-off between speed and quality. However, even the slowest preset is
still relatively fast, use DeepFlow if you need better quality and don\'t care about speed.

This implementation includes several additional features compared to the algorithm described in the paper,
including spatial propagation of flow vectors (@ref getUseSpatialPropagation), as well as an option to
utilize an initial flow approximation passed to @ref calc (which is, essentially, temporal propagation,
if the previous frame\'s flow field is passed).',1,'cv::DISOpticalFlow::create',[[[['int','preset','DISOpticalFlow::PRESET_FAST',[]]],'@brief Creates an instance of DISOpticalFlow

    @param preset one of PRESET_ULTRAFAST, PRESET_FAST and PRESET_MEDIUM']]],
['SparsePyrLKOpticalFlow',['SparseOpticalFlow'],'@brief Class used for calculating a sparse optical flow.

The class can calculate an optical flow for a sparse feature set using the
iterative Lucas-Kanade method with pyramids.

@sa calcOpticalFlowPyrLK',1,'cv::SparsePyrLKOpticalFlow::create',[[[['Size','winSize','Size(21, 21)',[]],['int','maxLevel','3',[]],['TermCriteria','crit','TermCriteria(TermCriteria::COUNT+TermCriteria::EPS, 30, 0.01)',[]],['int','flags','0',[]],['double','minEigThreshold','1e-4',[]]],'']]],
['Tracker',[],'@brief Base abstract class for the long-term tracker'],
['TrackerMIL',['Tracker'],'@brief The MIL algorithm trains a classifier in an online manner to separate the object from the
background.

Multiple Instance Learning avoids the drift problem for a robust tracking. The implementation is
based on @cite MIL .

Original code can be found here <http://vision.ucsd.edu/~bbabenko/project_miltrack.shtml>',1,'cv::TrackerMIL::create',[[[],'@brief Create MIL tracker instance
     *  @param parameters MIL parameters TrackerMIL::Params']]],
['TrackerGOTURN',['Tracker'],'@brief the GOTURN (Generic Object Tracking Using Regression Networks) tracker
 *
 *  GOTURN (@cite GOTURN) is kind of trackers based on Convolutional Neural Networks (CNN). While taking all advantages of CNN trackers,
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
 *  GOTURN architecture goturn.prototxt and trained model goturn.caffemodel are accessible on opencv_extra GitHub repository.',1,'cv::TrackerGOTURN::create',[[[],'@brief Constructor
    @param parameters GOTURN parameters TrackerGOTURN::Params']]],
['TrackerDaSiamRPN',['Tracker'],'',1,'cv::TrackerDaSiamRPN::create',[[[],'@brief Constructor
    @param parameters DaSiamRPN parameters TrackerDaSiamRPN::Params']]],
);
