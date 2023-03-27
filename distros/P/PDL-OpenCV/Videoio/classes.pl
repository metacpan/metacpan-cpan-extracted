(
['VideoCapture',[],'@brief Class for video capturing from video files, image sequences or cameras.

The class provides C++ API for capturing video from cameras or for reading video files and image sequences.

Here is how the class can be used:
@include samples/cpp/videocapture_basic.cpp

@note In @ref videoio_c "C API" the black-box structure `CvCapture` is used instead of %VideoCapture.
@note
-   (C++) A basic sample on using the %VideoCapture interface can be found at
    `OPENCV_SOURCE_CODE/samples/cpp/videocapture_starter.cpp`
-   (Python) A basic sample on using the %VideoCapture interface can be found at
    `OPENCV_SOURCE_CODE/samples/python/video.py`
-   (Python) A multi threaded video processing sample can be found at
    `OPENCV_SOURCE_CODE/samples/python/video_threaded.py`
-   (Python) %VideoCapture sample showcasing some features of the Video4Linux2 backend
    `OPENCV_SOURCE_CODE/samples/python/video_v4l2.py`',0,'cv::VideoCapture',[[[],'@brief Default constructor
    @note In @ref videoio_c "C API", when you finished working with video, release CvCapture structure with
    cvReleaseCapture(), or use Ptr\\<CvCapture\\> that calls cvReleaseCapture() automatically in the
    destructor.'],[[['String','filename','',['/C','/Ref']],['int','apiPreference','CAP_ANY',[]]],'@overload
    @brief  Opens a video file or a capturing device or an IP video stream for video capturing with API Preference

    @param filename it can be:
    - name of video file (eg. `video.avi`)
    - or image sequence (eg. `img_%02d.jpg`, which will read samples like `img_00.jpg, img_01.jpg, img_02.jpg, ...`)
    - or URL of video stream (eg. `protocol://host:port/script_name?script_params|auth`)
    - or GStreamer pipeline string in gst-launch tool format in case if GStreamer is used as backend
      Note that each video stream or IP camera feed has its own URL scheme. Please refer to the
      documentation of source stream to know the right URL.
    @param apiPreference preferred Capture API backends to use. Can be used to enforce a specific reader
    implementation if multiple are available: e.g. cv::CAP_FFMPEG or cv::CAP_IMAGES or cv::CAP_DSHOW.

    @sa cv::VideoCaptureAPIs'],[[['String','filename','',['/C','/Ref']],['int','apiPreference','',[]],['vector_int','params','',['/C','/Ref']]],'@overload
    @brief Opens a video file or a capturing device or an IP video stream for video capturing with API Preference and parameters

    The `params` parameter allows to specify extra parameters encoded as pairs `(paramId_1, paramValue_1, paramId_2, paramValue_2, ...)`.
    See cv::VideoCaptureProperties'],[[['int','index','',[]],['int','apiPreference','CAP_ANY',[]]],'@overload
    @brief  Opens a camera for video capturing

    @param index id of the video capturing device to open. To open default camera using default backend just pass 0.
    (to backward compatibility usage of camera_id + domain_offset (CAP_*) is valid when apiPreference is CAP_ANY)
    @param apiPreference preferred Capture API backends to use. Can be used to enforce a specific reader
    implementation if multiple are available: e.g. cv::CAP_DSHOW or cv::CAP_MSMF or cv::CAP_V4L.

    @sa cv::VideoCaptureAPIs'],[[['int','index','',[]],['int','apiPreference','',[]],['vector_int','params','',['/C','/Ref']]],'@overload
    @brief Opens a camera for video capturing with API Preference and parameters

    The `params` parameter allows to specify extra parameters encoded as pairs `(paramId_1, paramValue_1, paramId_2, paramValue_2, ...)`.
    See cv::VideoCaptureProperties']]],
['VideoWriter',[],'@brief Video writer class.

The class provides C++ API for writing video files or image sequences.',0,'cv::VideoWriter',[[[],'@brief Default constructors

    The constructors/functions initialize video writers.
    -   On Linux FFMPEG is used to write videos;
    -   On Windows FFMPEG or MSWF or DSHOW is used;
    -   On MacOSX AVFoundation is used.'],[[['String','filename','',['/C','/Ref']],['int','fourcc','',[]],['double','fps','',[]],['Size','frameSize','',[]],['bool','isColor','true',[]]],'@overload
    @param filename Name of the output video file.
    @param fourcc 4-character code of codec used to compress the frames. For example,
    VideoWriter::fourcc(\'P\',\'I\',\'M\',\'1\') is a MPEG-1 codec, VideoWriter::fourcc(\'M\',\'J\',\'P\',\'G\') is a
    motion-jpeg codec etc. List of codes can be obtained at [Video Codecs by
    FOURCC](http://www.fourcc.org/codecs.php) page. FFMPEG backend with MP4 container natively uses
    other values as fourcc code: see [ObjectType](http://mp4ra.org/#/codecs),
    so you may receive a warning message from OpenCV about fourcc code conversion.
    @param fps Framerate of the created video stream.
    @param frameSize Size of the video frames.
    @param isColor If it is not zero, the encoder will expect and encode color frames, otherwise it
    will work with grayscale frames.

    @b Tips:
    - With some backends `fourcc=-1` pops up the codec selection dialog from the system.
    - To save image sequence use a proper filename (eg. `img_%02d.jpg`) and `fourcc=0`
      OR `fps=0`. Use uncompressed image format (eg. `img_%02d.BMP`) to save raw frames.
    - Most codecs are lossy. If you want lossless video file you need to use a lossless codecs
      (eg. FFMPEG FFV1, Huffman HFYU, Lagarith LAGS, etc...)
    - If FFMPEG is enabled, using `codec=0; fps=0;` you can create an uncompressed (raw) video file.'],[[['String','filename','',['/C','/Ref']],['int','apiPreference','',[]],['int','fourcc','',[]],['double','fps','',[]],['Size','frameSize','',[]],['bool','isColor','true',[]]],'@overload
    The `apiPreference` parameter allows to specify API backends to use. Can be used to enforce a specific reader implementation
    if multiple are available: e.g. cv::CAP_FFMPEG or cv::CAP_GSTREAMER.'],[[['String','filename','',['/C','/Ref']],['int','fourcc','',[]],['double','fps','',[]],['Size','frameSize','',['/C','/Ref']],['vector_int','params','',['/C','/Ref']]],'@overload
     * The `params` parameter allows to specify extra encoder parameters encoded as pairs (paramId_1, paramValue_1, paramId_2, paramValue_2, ... .)
     * see cv::VideoWriterProperties'],[[['String','filename','',['/C','/Ref']],['int','apiPreference','',[]],['int','fourcc','',[]],['double','fps','',[]],['Size','frameSize','',['/C','/Ref']],['vector_int','params','',['/C','/Ref']]],'@overload']]],
);
