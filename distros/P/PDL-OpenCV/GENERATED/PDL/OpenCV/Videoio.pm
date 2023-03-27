#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::OpenCV::Videoio;

our @EXPORT_OK = qw( CAP_ANY CAP_VFW CAP_V4L CAP_V4L2 CAP_FIREWIRE CAP_FIREWARE CAP_IEEE1394 CAP_DC1394 CAP_CMU1394 CAP_QT CAP_UNICAP CAP_DSHOW CAP_PVAPI CAP_OPENNI CAP_OPENNI_ASUS CAP_ANDROID CAP_XIAPI CAP_AVFOUNDATION CAP_GIGANETIX CAP_MSMF CAP_WINRT CAP_INTELPERC CAP_REALSENSE CAP_OPENNI2 CAP_OPENNI2_ASUS CAP_OPENNI2_ASTRA CAP_GPHOTO2 CAP_GSTREAMER CAP_FFMPEG CAP_IMAGES CAP_ARAVIS CAP_OPENCV_MJPEG CAP_INTEL_MFX CAP_XINE CAP_UEYE CAP_PROP_POS_MSEC CAP_PROP_POS_FRAMES CAP_PROP_POS_AVI_RATIO CAP_PROP_FRAME_WIDTH CAP_PROP_FRAME_HEIGHT CAP_PROP_FPS CAP_PROP_FOURCC CAP_PROP_FRAME_COUNT CAP_PROP_FORMAT CAP_PROP_MODE CAP_PROP_BRIGHTNESS CAP_PROP_CONTRAST CAP_PROP_SATURATION CAP_PROP_HUE CAP_PROP_GAIN CAP_PROP_EXPOSURE CAP_PROP_CONVERT_RGB CAP_PROP_WHITE_BALANCE_BLUE_U CAP_PROP_RECTIFICATION CAP_PROP_MONOCHROME CAP_PROP_SHARPNESS CAP_PROP_AUTO_EXPOSURE CAP_PROP_GAMMA CAP_PROP_TEMPERATURE CAP_PROP_TRIGGER CAP_PROP_TRIGGER_DELAY CAP_PROP_WHITE_BALANCE_RED_V CAP_PROP_ZOOM CAP_PROP_FOCUS CAP_PROP_GUID CAP_PROP_ISO_SPEED CAP_PROP_BACKLIGHT CAP_PROP_PAN CAP_PROP_TILT CAP_PROP_ROLL CAP_PROP_IRIS CAP_PROP_SETTINGS CAP_PROP_BUFFERSIZE CAP_PROP_AUTOFOCUS CAP_PROP_SAR_NUM CAP_PROP_SAR_DEN CAP_PROP_BACKEND CAP_PROP_CHANNEL CAP_PROP_AUTO_WB CAP_PROP_WB_TEMPERATURE CAP_PROP_CODEC_PIXEL_FORMAT CAP_PROP_BITRATE CAP_PROP_ORIENTATION_META CAP_PROP_ORIENTATION_AUTO CAP_PROP_HW_ACCELERATION CAP_PROP_HW_DEVICE CAP_PROP_HW_ACCELERATION_USE_OPENCL CAP_PROP_OPEN_TIMEOUT_MSEC CAP_PROP_READ_TIMEOUT_MSEC CAP_PROP_STREAM_OPEN_TIME_USEC VIDEOWRITER_PROP_QUALITY VIDEOWRITER_PROP_FRAMEBYTES VIDEOWRITER_PROP_NSTRIPES VIDEOWRITER_PROP_IS_COLOR VIDEOWRITER_PROP_DEPTH VIDEOWRITER_PROP_HW_ACCELERATION VIDEOWRITER_PROP_HW_DEVICE VIDEOWRITER_PROP_HW_ACCELERATION_USE_OPENCL VIDEO_ACCELERATION_NONE VIDEO_ACCELERATION_ANY VIDEO_ACCELERATION_D3D11 VIDEO_ACCELERATION_VAAPI VIDEO_ACCELERATION_MFX CAP_PROP_DC1394_OFF CAP_PROP_DC1394_MODE_MANUAL CAP_PROP_DC1394_MODE_AUTO CAP_PROP_DC1394_MODE_ONE_PUSH_AUTO CAP_PROP_DC1394_MAX CAP_OPENNI_DEPTH_GENERATOR CAP_OPENNI_IMAGE_GENERATOR CAP_OPENNI_IR_GENERATOR CAP_OPENNI_GENERATORS_MASK CAP_PROP_OPENNI_OUTPUT_MODE CAP_PROP_OPENNI_FRAME_MAX_DEPTH CAP_PROP_OPENNI_BASELINE CAP_PROP_OPENNI_FOCAL_LENGTH CAP_PROP_OPENNI_REGISTRATION CAP_PROP_OPENNI_REGISTRATION_ON CAP_PROP_OPENNI_APPROX_FRAME_SYNC CAP_PROP_OPENNI_MAX_BUFFER_SIZE CAP_PROP_OPENNI_CIRCLE_BUFFER CAP_PROP_OPENNI_MAX_TIME_DURATION CAP_PROP_OPENNI_GENERATOR_PRESENT CAP_PROP_OPENNI2_SYNC CAP_PROP_OPENNI2_MIRROR CAP_OPENNI_IMAGE_GENERATOR_PRESENT CAP_OPENNI_IMAGE_GENERATOR_OUTPUT_MODE CAP_OPENNI_DEPTH_GENERATOR_PRESENT CAP_OPENNI_DEPTH_GENERATOR_BASELINE CAP_OPENNI_DEPTH_GENERATOR_FOCAL_LENGTH CAP_OPENNI_DEPTH_GENERATOR_REGISTRATION CAP_OPENNI_DEPTH_GENERATOR_REGISTRATION_ON CAP_OPENNI_IR_GENERATOR_PRESENT CAP_OPENNI_DEPTH_MAP CAP_OPENNI_POINT_CLOUD_MAP CAP_OPENNI_DISPARITY_MAP CAP_OPENNI_DISPARITY_MAP_32F CAP_OPENNI_VALID_DEPTH_MASK CAP_OPENNI_BGR_IMAGE CAP_OPENNI_GRAY_IMAGE CAP_OPENNI_IR_IMAGE CAP_OPENNI_VGA_30HZ CAP_OPENNI_SXGA_15HZ CAP_OPENNI_SXGA_30HZ CAP_OPENNI_QVGA_30HZ CAP_OPENNI_QVGA_60HZ CAP_PROP_GSTREAMER_QUEUE_LENGTH CAP_PROP_PVAPI_MULTICASTIP CAP_PROP_PVAPI_FRAMESTARTTRIGGERMODE CAP_PROP_PVAPI_DECIMATIONHORIZONTAL CAP_PROP_PVAPI_DECIMATIONVERTICAL CAP_PROP_PVAPI_BINNINGX CAP_PROP_PVAPI_BINNINGY CAP_PROP_PVAPI_PIXELFORMAT CAP_PVAPI_FSTRIGMODE_FREERUN CAP_PVAPI_FSTRIGMODE_SYNCIN1 CAP_PVAPI_FSTRIGMODE_SYNCIN2 CAP_PVAPI_FSTRIGMODE_FIXEDRATE CAP_PVAPI_FSTRIGMODE_SOFTWARE CAP_PVAPI_DECIMATION_OFF CAP_PVAPI_DECIMATION_2OUTOF4 CAP_PVAPI_DECIMATION_2OUTOF8 CAP_PVAPI_DECIMATION_2OUTOF16 CAP_PVAPI_PIXELFORMAT_MONO8 CAP_PVAPI_PIXELFORMAT_MONO16 CAP_PVAPI_PIXELFORMAT_BAYER8 CAP_PVAPI_PIXELFORMAT_BAYER16 CAP_PVAPI_PIXELFORMAT_RGB24 CAP_PVAPI_PIXELFORMAT_BGR24 CAP_PVAPI_PIXELFORMAT_RGBA32 CAP_PVAPI_PIXELFORMAT_BGRA32 CAP_PROP_XI_DOWNSAMPLING CAP_PROP_XI_DATA_FORMAT CAP_PROP_XI_OFFSET_X CAP_PROP_XI_OFFSET_Y CAP_PROP_XI_TRG_SOURCE CAP_PROP_XI_TRG_SOFTWARE CAP_PROP_XI_GPI_SELECTOR CAP_PROP_XI_GPI_MODE CAP_PROP_XI_GPI_LEVEL CAP_PROP_XI_GPO_SELECTOR CAP_PROP_XI_GPO_MODE CAP_PROP_XI_LED_SELECTOR CAP_PROP_XI_LED_MODE CAP_PROP_XI_MANUAL_WB CAP_PROP_XI_AUTO_WB CAP_PROP_XI_AEAG CAP_PROP_XI_EXP_PRIORITY CAP_PROP_XI_AE_MAX_LIMIT CAP_PROP_XI_AG_MAX_LIMIT CAP_PROP_XI_AEAG_LEVEL CAP_PROP_XI_TIMEOUT CAP_PROP_XI_EXPOSURE CAP_PROP_XI_EXPOSURE_BURST_COUNT CAP_PROP_XI_GAIN_SELECTOR CAP_PROP_XI_GAIN CAP_PROP_XI_DOWNSAMPLING_TYPE CAP_PROP_XI_BINNING_SELECTOR CAP_PROP_XI_BINNING_VERTICAL CAP_PROP_XI_BINNING_HORIZONTAL CAP_PROP_XI_BINNING_PATTERN CAP_PROP_XI_DECIMATION_SELECTOR CAP_PROP_XI_DECIMATION_VERTICAL CAP_PROP_XI_DECIMATION_HORIZONTAL CAP_PROP_XI_DECIMATION_PATTERN CAP_PROP_XI_TEST_PATTERN_GENERATOR_SELECTOR CAP_PROP_XI_TEST_PATTERN CAP_PROP_XI_IMAGE_DATA_FORMAT CAP_PROP_XI_SHUTTER_TYPE CAP_PROP_XI_SENSOR_TAPS CAP_PROP_XI_AEAG_ROI_OFFSET_X CAP_PROP_XI_AEAG_ROI_OFFSET_Y CAP_PROP_XI_AEAG_ROI_WIDTH CAP_PROP_XI_AEAG_ROI_HEIGHT CAP_PROP_XI_BPC CAP_PROP_XI_WB_KR CAP_PROP_XI_WB_KG CAP_PROP_XI_WB_KB CAP_PROP_XI_WIDTH CAP_PROP_XI_HEIGHT CAP_PROP_XI_REGION_SELECTOR CAP_PROP_XI_REGION_MODE CAP_PROP_XI_LIMIT_BANDWIDTH CAP_PROP_XI_SENSOR_DATA_BIT_DEPTH CAP_PROP_XI_OUTPUT_DATA_BIT_DEPTH CAP_PROP_XI_IMAGE_DATA_BIT_DEPTH CAP_PROP_XI_OUTPUT_DATA_PACKING CAP_PROP_XI_OUTPUT_DATA_PACKING_TYPE CAP_PROP_XI_IS_COOLED CAP_PROP_XI_COOLING CAP_PROP_XI_TARGET_TEMP CAP_PROP_XI_CHIP_TEMP CAP_PROP_XI_HOUS_TEMP CAP_PROP_XI_HOUS_BACK_SIDE_TEMP CAP_PROP_XI_SENSOR_BOARD_TEMP CAP_PROP_XI_CMS CAP_PROP_XI_APPLY_CMS CAP_PROP_XI_IMAGE_IS_COLOR CAP_PROP_XI_COLOR_FILTER_ARRAY CAP_PROP_XI_GAMMAY CAP_PROP_XI_GAMMAC CAP_PROP_XI_SHARPNESS CAP_PROP_XI_CC_MATRIX_00 CAP_PROP_XI_CC_MATRIX_01 CAP_PROP_XI_CC_MATRIX_02 CAP_PROP_XI_CC_MATRIX_03 CAP_PROP_XI_CC_MATRIX_10 CAP_PROP_XI_CC_MATRIX_11 CAP_PROP_XI_CC_MATRIX_12 CAP_PROP_XI_CC_MATRIX_13 CAP_PROP_XI_CC_MATRIX_20 CAP_PROP_XI_CC_MATRIX_21 CAP_PROP_XI_CC_MATRIX_22 CAP_PROP_XI_CC_MATRIX_23 CAP_PROP_XI_CC_MATRIX_30 CAP_PROP_XI_CC_MATRIX_31 CAP_PROP_XI_CC_MATRIX_32 CAP_PROP_XI_CC_MATRIX_33 CAP_PROP_XI_DEFAULT_CC_MATRIX CAP_PROP_XI_TRG_SELECTOR CAP_PROP_XI_ACQ_FRAME_BURST_COUNT CAP_PROP_XI_DEBOUNCE_EN CAP_PROP_XI_DEBOUNCE_T0 CAP_PROP_XI_DEBOUNCE_T1 CAP_PROP_XI_DEBOUNCE_POL CAP_PROP_XI_LENS_MODE CAP_PROP_XI_LENS_APERTURE_VALUE CAP_PROP_XI_LENS_FOCUS_MOVEMENT_VALUE CAP_PROP_XI_LENS_FOCUS_MOVE CAP_PROP_XI_LENS_FOCUS_DISTANCE CAP_PROP_XI_LENS_FOCAL_LENGTH CAP_PROP_XI_LENS_FEATURE_SELECTOR CAP_PROP_XI_LENS_FEATURE CAP_PROP_XI_DEVICE_MODEL_ID CAP_PROP_XI_DEVICE_SN CAP_PROP_XI_IMAGE_DATA_FORMAT_RGB32_ALPHA CAP_PROP_XI_IMAGE_PAYLOAD_SIZE CAP_PROP_XI_TRANSPORT_PIXEL_FORMAT CAP_PROP_XI_SENSOR_CLOCK_FREQ_HZ CAP_PROP_XI_SENSOR_CLOCK_FREQ_INDEX CAP_PROP_XI_SENSOR_OUTPUT_CHANNEL_COUNT CAP_PROP_XI_FRAMERATE CAP_PROP_XI_COUNTER_SELECTOR CAP_PROP_XI_COUNTER_VALUE CAP_PROP_XI_ACQ_TIMING_MODE CAP_PROP_XI_AVAILABLE_BANDWIDTH CAP_PROP_XI_BUFFER_POLICY CAP_PROP_XI_LUT_EN CAP_PROP_XI_LUT_INDEX CAP_PROP_XI_LUT_VALUE CAP_PROP_XI_TRG_DELAY CAP_PROP_XI_TS_RST_MODE CAP_PROP_XI_TS_RST_SOURCE CAP_PROP_XI_IS_DEVICE_EXIST CAP_PROP_XI_ACQ_BUFFER_SIZE CAP_PROP_XI_ACQ_BUFFER_SIZE_UNIT CAP_PROP_XI_ACQ_TRANSPORT_BUFFER_SIZE CAP_PROP_XI_BUFFERS_QUEUE_SIZE CAP_PROP_XI_ACQ_TRANSPORT_BUFFER_COMMIT CAP_PROP_XI_RECENT_FRAME CAP_PROP_XI_DEVICE_RESET CAP_PROP_XI_COLUMN_FPN_CORRECTION CAP_PROP_XI_ROW_FPN_CORRECTION CAP_PROP_XI_SENSOR_MODE CAP_PROP_XI_HDR CAP_PROP_XI_HDR_KNEEPOINT_COUNT CAP_PROP_XI_HDR_T1 CAP_PROP_XI_HDR_T2 CAP_PROP_XI_KNEEPOINT1 CAP_PROP_XI_KNEEPOINT2 CAP_PROP_XI_IMAGE_BLACK_LEVEL CAP_PROP_XI_HW_REVISION CAP_PROP_XI_DEBUG_LEVEL CAP_PROP_XI_AUTO_BANDWIDTH_CALCULATION CAP_PROP_XI_FFS_FILE_ID CAP_PROP_XI_FFS_FILE_SIZE CAP_PROP_XI_FREE_FFS_SIZE CAP_PROP_XI_USED_FFS_SIZE CAP_PROP_XI_FFS_ACCESS_KEY CAP_PROP_XI_SENSOR_FEATURE_SELECTOR CAP_PROP_XI_SENSOR_FEATURE_VALUE CAP_PROP_ARAVIS_AUTOTRIGGER CAP_PROP_IOS_DEVICE_FOCUS CAP_PROP_IOS_DEVICE_EXPOSURE CAP_PROP_IOS_DEVICE_FLASH CAP_PROP_IOS_DEVICE_WHITEBALANCE CAP_PROP_IOS_DEVICE_TORCH CAP_PROP_GIGA_FRAME_OFFSET_X CAP_PROP_GIGA_FRAME_OFFSET_Y CAP_PROP_GIGA_FRAME_WIDTH_MAX CAP_PROP_GIGA_FRAME_HEIGH_MAX CAP_PROP_GIGA_FRAME_SENS_WIDTH CAP_PROP_GIGA_FRAME_SENS_HEIGH CAP_PROP_INTELPERC_PROFILE_COUNT CAP_PROP_INTELPERC_PROFILE_IDX CAP_PROP_INTELPERC_DEPTH_LOW_CONFIDENCE_VALUE CAP_PROP_INTELPERC_DEPTH_SATURATION_VALUE CAP_PROP_INTELPERC_DEPTH_CONFIDENCE_THRESHOLD CAP_PROP_INTELPERC_DEPTH_FOCAL_LENGTH_HORZ CAP_PROP_INTELPERC_DEPTH_FOCAL_LENGTH_VERT CAP_INTELPERC_DEPTH_GENERATOR CAP_INTELPERC_IMAGE_GENERATOR CAP_INTELPERC_IR_GENERATOR CAP_INTELPERC_GENERATORS_MASK CAP_INTELPERC_DEPTH_MAP CAP_INTELPERC_UVDEPTH_MAP CAP_INTELPERC_IR_MAP CAP_INTELPERC_IMAGE CAP_PROP_GPHOTO2_PREVIEW CAP_PROP_GPHOTO2_WIDGET_ENUMERATE CAP_PROP_GPHOTO2_RELOAD_CONFIG CAP_PROP_GPHOTO2_RELOAD_ON_CHANGE CAP_PROP_GPHOTO2_COLLECT_MSGS CAP_PROP_GPHOTO2_FLUSH_MSGS CAP_PROP_SPEED CAP_PROP_APERTURE CAP_PROP_EXPOSUREPROGRAM CAP_PROP_VIEWFINDER CAP_PROP_IMAGES_BASE CAP_PROP_IMAGES_LAST );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::OpenCV::Videoio ;






#line 364 "../genpp.pl"

=head1 NAME

PDL::OpenCV::Videoio - PDL bindings for OpenCV VideoCapture, VideoWriter

=head1 SYNOPSIS

 use PDL::OpenCV::Videoio;

=cut

use strict;
use warnings;
use PDL::OpenCV; # get constants
#line 40 "Videoio.pm"






=head1 FUNCTIONS

=cut




#line 385 "../genpp.pl"

=pod

None.

=cut
#line 61 "Videoio.pm"



#line 394 "../genpp.pl"

=head1 METHODS for PDL::OpenCV::VideoCapture


=for ref

Class for video capturing from video files, image sequences or cameras.

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
`OPENCV_SOURCE_CODE/samples/python/video_v4l2.py`


=cut

@PDL::OpenCV::VideoCapture::ISA = qw();
#line 92 "Videoio.pm"



#line 274 "../genpp.pl"

=head2 new

=for ref

Default constructor

=for example

 $obj = PDL::OpenCV::VideoCapture->new;

@note In @ref videoio_c "C API", when you finished working with video, release CvCapture structure with
cvReleaseCapture(), or use Ptr\<CvCapture\> that calls cvReleaseCapture() automatically in the
destructor.

=cut
#line 113 "Videoio.pm"



#line 274 "../genpp.pl"

=head2 new2

=for ref

Opens a video file or a capturing device or an IP video stream for video capturing with API Preference

=for example

 $obj = PDL::OpenCV::VideoCapture->new2($filename); # with defaults
 $obj = PDL::OpenCV::VideoCapture->new2($filename,$apiPreference);

@overload

Parameters:

=over

=item filename

it can be:
    - name of video file (eg. `video.avi`)
    - or image sequence (eg. `img_%02d.jpg`, which will read samples like `img_00.jpg, img_01.jpg, img_02.jpg, ...`)
    - or URL of video stream (eg. `protocol://host:port/script_name?script_params|auth`)
    - or GStreamer pipeline string in gst-launch tool format in case if GStreamer is used as backend
      Note that each video stream or IP camera feed has its own URL scheme. Please refer to the
      documentation of source stream to know the right URL.

=item apiPreference

preferred Capture API backends to use. Can be used to enforce a specific reader
    implementation if multiple are available: e.g. cv::CAP_FFMPEG or cv::CAP_IMAGES or cv::CAP_DSHOW.

=back

See also:
cv::VideoCaptureAPIs


=cut
#line 158 "Videoio.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 VideoCapture_new3

=for sig

  Signature: (int [phys] apiPreference(); int [phys] params(n4d0); char * klass; StringWrapper* filename; [o] VideoCaptureWrapper * res)

=for ref

Opens a video file or a capturing device or an IP video stream for video capturing with API Preference and parameters

=for example

 $obj = PDL::OpenCV::VideoCapture->new3($filename,$apiPreference,$params);

@overload
The `params` parameter allows to specify extra parameters encoded as pairs `(paramId_1, paramValue_1, paramId_2, paramValue_2, ...)`.
See cv::VideoCaptureProperties

=for bad

VideoCapture_new3 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 191 "Videoio.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::VideoCapture::new3 {
  barf "Usage: PDL::OpenCV::VideoCapture::new3(\$klass,\$filename,\$apiPreference,\$params)\n" if @_ < 4;
  my ($klass,$filename,$apiPreference,$params) = @_;
  my ($res);
  
  PDL::OpenCV::VideoCapture::_VideoCapture_new3_int($apiPreference,$params,$klass,$filename,$res);
  !wantarray ? $res : ($res)
}
#line 205 "Videoio.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 210 "Videoio.pm"



#line 274 "../genpp.pl"

=head2 new4

=for ref

Opens a camera for video capturing

=for example

 $obj = PDL::OpenCV::VideoCapture->new4($index); # with defaults
 $obj = PDL::OpenCV::VideoCapture->new4($index,$apiPreference);

@overload

Parameters:

=over

=item index

id of the video capturing device to open. To open default camera using default backend just pass 0.
    (to backward compatibility usage of camera_id + domain_offset (CAP_*) is valid when apiPreference is CAP_ANY)

=item apiPreference

preferred Capture API backends to use. Can be used to enforce a specific reader
    implementation if multiple are available: e.g. cv::CAP_DSHOW or cv::CAP_MSMF or cv::CAP_V4L.

=back

See also:
cv::VideoCaptureAPIs


=cut
#line 250 "Videoio.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 VideoCapture_new5

=for sig

  Signature: (int [phys] index(); int [phys] apiPreference(); int [phys] params(n4d0); char * klass; [o] VideoCaptureWrapper * res)

=for ref

Opens a camera for video capturing with API Preference and parameters

=for example

 $obj = PDL::OpenCV::VideoCapture->new5($index,$apiPreference,$params);

@overload
The `params` parameter allows to specify extra parameters encoded as pairs `(paramId_1, paramValue_1, paramId_2, paramValue_2, ...)`.
See cv::VideoCaptureProperties

=for bad

VideoCapture_new5 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 283 "Videoio.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::VideoCapture::new5 {
  barf "Usage: PDL::OpenCV::VideoCapture::new5(\$klass,\$index,\$apiPreference,\$params)\n" if @_ < 4;
  my ($klass,$index,$apiPreference,$params) = @_;
  my ($res);
  
  PDL::OpenCV::VideoCapture::_VideoCapture_new5_int($index,$apiPreference,$params,$klass,$res);
  !wantarray ? $res : ($res)
}
#line 297 "Videoio.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 302 "Videoio.pm"



#line 274 "../genpp.pl"

=head2 open

=for ref

Opens a video file or a capturing device or an IP video stream for video capturing.

=for example

 $res = $obj->open($filename); # with defaults
 $res = $obj->open($filename,$apiPreference);

@overload
Parameters are same as the constructor VideoCapture(const String& filename, int apiPreference = CAP_ANY)
The method first calls VideoCapture::release to close the already opened file or camera.

Returns: `true` if the file has been successfully opened


=cut
#line 327 "Videoio.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 VideoCapture_open2

=for sig

  Signature: (int [phys] apiPreference(); int [phys] params(n4d0); byte [o,phys] res(); VideoCaptureWrapper * self; StringWrapper* filename)

=for ref

Opens a camera for video capturing

=for example

 $res = $obj->open2($filename,$apiPreference,$params);

@overload
The `params` parameter allows to specify extra parameters encoded as pairs `(paramId_1, paramValue_1, paramId_2, paramValue_2, ...)`.
See cv::VideoCaptureProperties
The method first calls VideoCapture::release to close the already opened file or camera.

Returns: `true` if the file has been successfully opened


=for bad

VideoCapture_open2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 364 "Videoio.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::VideoCapture::open2 {
  barf "Usage: PDL::OpenCV::VideoCapture::open2(\$self,\$filename,\$apiPreference,\$params)\n" if @_ < 4;
  my ($self,$filename,$apiPreference,$params) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::VideoCapture::_VideoCapture_open2_int($apiPreference,$params,$res,$self,$filename);
  !wantarray ? $res : ($res)
}
#line 378 "Videoio.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 383 "Videoio.pm"



#line 274 "../genpp.pl"

=head2 open3

=for ref

Opens a camera for video capturing

=for example

 $res = $obj->open3($index); # with defaults
 $res = $obj->open3($index,$apiPreference);

@overload
Parameters are same as the constructor VideoCapture(int index, int apiPreference = CAP_ANY)
The method first calls VideoCapture::release to close the already opened file or camera.

Returns: `true` if the camera has been successfully opened.


=cut
#line 408 "Videoio.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 VideoCapture_open4

=for sig

  Signature: (int [phys] index(); int [phys] apiPreference(); int [phys] params(n4d0); byte [o,phys] res(); VideoCaptureWrapper * self)

=for ref

Returns true if video capturing has been initialized already.

=for example

 $res = $obj->open4($index,$apiPreference,$params);

@overload
The `params` parameter allows to specify extra parameters encoded as pairs `(paramId_1, paramValue_1, paramId_2, paramValue_2, ...)`.
See cv::VideoCaptureProperties
The method first calls VideoCapture::release to close the already opened file or camera.

Returns: `true` if the camera has been successfully opened.


=for bad

VideoCapture_open4 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 445 "Videoio.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::VideoCapture::open4 {
  barf "Usage: PDL::OpenCV::VideoCapture::open4(\$self,\$index,\$apiPreference,\$params)\n" if @_ < 4;
  my ($self,$index,$apiPreference,$params) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::VideoCapture::_VideoCapture_open4_int($index,$apiPreference,$params,$res,$self);
  !wantarray ? $res : ($res)
}
#line 459 "Videoio.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 464 "Videoio.pm"



#line 274 "../genpp.pl"

=head2 isOpened

=for ref

Returns true if video capturing has been initialized already.

=for example

 $res = $obj->isOpened;

If the previous call to VideoCapture constructor or VideoCapture::open() succeeded, the method returns
true.

=cut
#line 484 "Videoio.pm"



#line 274 "../genpp.pl"

=head2 release

=for ref

Closes video file or capturing device.

=for example

 $obj->release;

The method is automatically called by subsequent VideoCapture::open and by VideoCapture
destructor.
The C function also deallocates memory and clears *capture pointer.

=cut
#line 505 "Videoio.pm"



#line 274 "../genpp.pl"

=head2 grab

=for ref

Grabs the next frame from video file or capturing device.

=for example

 $res = $obj->grab;

The method/function grabs the next frame from video file or camera and returns true (non-zero) in
the case of success.
The primary use of the function is in multi-camera environments, especially when the cameras do not
have hardware synchronization. That is, you call VideoCapture::grab() for each camera and after that
call the slower method VideoCapture::retrieve() to decode and get frame from each camera. This way
the overhead on demosaicing or motion jpeg decompression etc. is eliminated and the retrieved frames
from different cameras will be closer in time.
Also, when a connected camera is multi-head (for example, a stereo camera or a Kinect device), the
correct way of retrieving data from it is to call VideoCapture::grab() first and then call
VideoCapture::retrieve() one or more times with different values of the channel parameter.
@ref tutorial_kinect_openni

Returns: `true` (non-zero) in the case of success.


=cut
#line 537 "Videoio.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 VideoCapture_retrieve

=for sig

  Signature: ([o,phys] image(l2,c2,r2); int [phys] flag(); byte [o,phys] res(); VideoCaptureWrapper * self)

=for ref

Decodes and returns the grabbed video frame. NO BROADCASTING.

=for example

 ($image,$res) = $obj->retrieve; # with defaults
 ($image,$res) = $obj->retrieve($flag);

The method decodes and returns the just grabbed frame. If no frames has been grabbed
(camera has been disconnected, or there are no more frames in video file), the method returns false
and the function returns an empty image (with %cv::Mat, test it with Mat::empty()).
@note In @ref videoio_c "C API", functions cvRetrieveFrame() and cv.RetrieveFrame() return image stored inside the video
capturing structure. It is not allowed to modify or release the image! You can copy the frame using
cvCloneImage and then do whatever you want with the copy.

Parameters:

=over

=item [out] image

the video frame is returned here. If no frames has been grabbed the image will be empty.

=item flag

it could be a frame index or a driver specific flag

=back

Returns: `false` if no frames has been grabbed

See also:
read()


=for bad

VideoCapture_retrieve ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 594 "Videoio.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::VideoCapture::retrieve {
  barf "Usage: PDL::OpenCV::VideoCapture::retrieve(\$self,\$flag)\n" if @_ < 1;
  my ($self,$flag) = @_;
  my ($image,$res);
  $image = PDL->null if !defined $image;
  $flag = 0 if !defined $flag;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::VideoCapture::_VideoCapture_retrieve_int($image,$flag,$res,$self);
  !wantarray ? $res : ($image,$res)
}
#line 610 "Videoio.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 615 "Videoio.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 VideoCapture_read

=for sig

  Signature: ([o,phys] image(l2,c2,r2); byte [o,phys] res(); VideoCaptureWrapper * self)

=for ref

Grabs, decodes and returns the next video frame. NO BROADCASTING.

=for example

 ($image,$res) = $obj->read;

The method/function combines VideoCapture::grab() and VideoCapture::retrieve() in one call. This is the
most convenient method for reading video files or capturing data from decode and returns the just
grabbed frame. If no frames has been grabbed (camera has been disconnected, or there are no more
frames in video file), the method returns false and the function returns empty image (with %cv::Mat, test it with Mat::empty()).
@note In @ref videoio_c "C API", functions cvRetrieveFrame() and cv.RetrieveFrame() return image stored inside the video
capturing structure. It is not allowed to modify or release the image! You can copy the frame using
cvCloneImage and then do whatever you want with the copy.

Parameters:

=over

=item [out] image

the video frame is returned here. If no frames has been grabbed the image will be empty.

=back

Returns: `false` if no frames has been grabbed


=for bad

VideoCapture_read ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 665 "Videoio.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::VideoCapture::read {
  barf "Usage: PDL::OpenCV::VideoCapture::read(\$self)\n" if @_ < 1;
  my ($self) = @_;
  my ($image,$res);
  $image = PDL->null if !defined $image;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::VideoCapture::_VideoCapture_read_int($image,$res,$self);
  !wantarray ? $res : ($image,$res)
}
#line 680 "Videoio.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 685 "Videoio.pm"



#line 274 "../genpp.pl"

=head2 set

=for ref

Sets a property in the VideoCapture.

=for example

 $res = $obj->set($propId,$value);

@ref videoio_flags_others
@note Even if it returns `true` this doesn't ensure that the property
value has been accepted by the capture device. See note in VideoCapture::get()

Parameters:

=over

=item propId

Property identifier from cv::VideoCaptureProperties (eg. cv::CAP_PROP_POS_MSEC, cv::CAP_PROP_POS_FRAMES, ...)
    or one from

=item value

Value of the property.

=back

Returns: `true` if the property is supported by backend used by the VideoCapture instance.


=cut
#line 724 "Videoio.pm"



#line 274 "../genpp.pl"

=head2 get

=for ref

Returns the specified VideoCapture property

=for example

 $res = $obj->get($propId);

@ref videoio_flags_others
@note Reading / writing properties involves many layers. Some unexpected result might happens
along this chain.

 {.txt}
     VideoCapture -> API Backend -> Operating System -> Device Driver -> Device Hardware

The returned value might be different from what really used by the device or it could be encoded
using device dependent rules (eg. steps or percentage). Effective behaviour depends from device
driver and API Backend

Parameters:

=over

=item propId

Property identifier from cv::VideoCaptureProperties (eg. cv::CAP_PROP_POS_MSEC, cv::CAP_PROP_POS_FRAMES, ...)
    or one from

=back

Returns: Value for the specified property. Value 0 is returned when querying a property that is
    not supported by the backend used by the VideoCapture instance.


=cut
#line 767 "Videoio.pm"



#line 274 "../genpp.pl"

=head2 getBackendName

=for ref

Returns used backend API name

=for example

 $res = $obj->getBackendName;

@note Stream should be opened.

=cut
#line 786 "Videoio.pm"



#line 274 "../genpp.pl"

=head2 setExceptionMode

=for ref

=for example

 $obj->setExceptionMode($enable);

Switches exceptions mode
*
* methods raise exceptions if not successful instead of returning an error code

=cut
#line 805 "Videoio.pm"



#line 274 "../genpp.pl"

=head2 getExceptionMode

=for ref

=for example

 $res = $obj->getExceptionMode;


=cut
#line 821 "Videoio.pm"



#line 394 "../genpp.pl"

=head1 METHODS for PDL::OpenCV::VideoWriter


=for ref

Video writer class.

The class provides C++ API for writing video files or image sequences.


=cut

@PDL::OpenCV::VideoWriter::ISA = qw();
#line 840 "Videoio.pm"



#line 274 "../genpp.pl"

=head2 new

=for ref

Default constructors

=for example

 $obj = PDL::OpenCV::VideoWriter->new;

The constructors/functions initialize video writers.
-   On Linux FFMPEG is used to write videos;
-   On Windows FFMPEG or MSWF or DSHOW is used;
-   On MacOSX AVFoundation is used.

=cut
#line 862 "Videoio.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 VideoWriter_new2

=for sig

  Signature: (int [phys] fourcc(); double [phys] fps(); indx [phys] frameSize(n5=2); byte [phys] isColor(); char * klass; StringWrapper* filename; [o] VideoWriterWrapper * res)

=for ref

=for example

 $obj = PDL::OpenCV::VideoWriter->new2($filename,$fourcc,$fps,$frameSize); # with defaults
 $obj = PDL::OpenCV::VideoWriter->new2($filename,$fourcc,$fps,$frameSize,$isColor);

@overload
@b Tips:
- With some backends `fourcc=-1` pops up the codec selection dialog from the system.
- To save image sequence use a proper filename (eg. `img_%02d.jpg`) and `fourcc=0`
OR `fps=0`. Use uncompressed image format (eg. `img_%02d.BMP`) to save raw frames.
- Most codecs are lossy. If you want lossless video file you need to use a lossless codecs
(eg. FFMPEG FFV1, Huffman HFYU, Lagarith LAGS, etc...)
- If FFMPEG is enabled, using `codec=0; fps=0;` you can create an uncompressed (raw) video file.

Parameters:

=over

=item filename

Name of the output video file.

=item fourcc

4-character code of codec used to compress the frames. For example,
    VideoWriter::fourcc('P','I','M','1') is a MPEG-1 codec, VideoWriter::fourcc('M','J','P','G') is a
    motion-jpeg codec etc. List of codes can be obtained at [Video Codecs by
    FOURCC](http://www.fourcc.org/codecs.php) page. FFMPEG backend with MP4 container natively uses
    other values as fourcc code: see [ObjectType](http://mp4ra.org/#/codecs),
    so you may receive a warning message from OpenCV about fourcc code conversion.

=item fps

Framerate of the created video stream.

=item frameSize

Size of the video frames.

=item isColor

If it is not zero, the encoder will expect and encode color frames, otherwise it
    will work with grayscale frames.

=back


=for bad

VideoWriter_new2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 932 "Videoio.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::VideoWriter::new2 {
  barf "Usage: PDL::OpenCV::VideoWriter::new2(\$klass,\$filename,\$fourcc,\$fps,\$frameSize,\$isColor)\n" if @_ < 5;
  my ($klass,$filename,$fourcc,$fps,$frameSize,$isColor) = @_;
  my ($res);
  $isColor = 1 if !defined $isColor;
  PDL::OpenCV::VideoWriter::_VideoWriter_new2_int($fourcc,$fps,$frameSize,$isColor,$klass,$filename,$res);
  !wantarray ? $res : ($res)
}
#line 946 "Videoio.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 951 "Videoio.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 VideoWriter_new3

=for sig

  Signature: (int [phys] apiPreference(); int [phys] fourcc(); double [phys] fps(); indx [phys] frameSize(n6=2); byte [phys] isColor(); char * klass; StringWrapper* filename; [o] VideoWriterWrapper * res)

=for ref

=for example

 $obj = PDL::OpenCV::VideoWriter->new3($filename,$apiPreference,$fourcc,$fps,$frameSize); # with defaults
 $obj = PDL::OpenCV::VideoWriter->new3($filename,$apiPreference,$fourcc,$fps,$frameSize,$isColor);

@overload
The `apiPreference` parameter allows to specify API backends to use. Can be used to enforce a specific reader implementation
if multiple are available: e.g. cv::CAP_FFMPEG or cv::CAP_GSTREAMER.

=for bad

VideoWriter_new3 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 983 "Videoio.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::VideoWriter::new3 {
  barf "Usage: PDL::OpenCV::VideoWriter::new3(\$klass,\$filename,\$apiPreference,\$fourcc,\$fps,\$frameSize,\$isColor)\n" if @_ < 6;
  my ($klass,$filename,$apiPreference,$fourcc,$fps,$frameSize,$isColor) = @_;
  my ($res);
  $isColor = 1 if !defined $isColor;
  PDL::OpenCV::VideoWriter::_VideoWriter_new3_int($apiPreference,$fourcc,$fps,$frameSize,$isColor,$klass,$filename,$res);
  !wantarray ? $res : ($res)
}
#line 997 "Videoio.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 1002 "Videoio.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 VideoWriter_new4

=for sig

  Signature: (int [phys] fourcc(); double [phys] fps(); indx [phys] frameSize(n5=2); int [phys] params(n6d0); char * klass; StringWrapper* filename; [o] VideoWriterWrapper * res)

=for ref

=for example

 $obj = PDL::OpenCV::VideoWriter->new4($filename,$fourcc,$fps,$frameSize,$params);

@overload
* The `params` parameter allows to specify extra encoder parameters encoded as pairs (paramId_1, paramValue_1, paramId_2, paramValue_2, ... .)
* see cv::VideoWriterProperties

=for bad

VideoWriter_new4 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1033 "Videoio.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::VideoWriter::new4 {
  barf "Usage: PDL::OpenCV::VideoWriter::new4(\$klass,\$filename,\$fourcc,\$fps,\$frameSize,\$params)\n" if @_ < 6;
  my ($klass,$filename,$fourcc,$fps,$frameSize,$params) = @_;
  my ($res);
  
  PDL::OpenCV::VideoWriter::_VideoWriter_new4_int($fourcc,$fps,$frameSize,$params,$klass,$filename,$res);
  !wantarray ? $res : ($res)
}
#line 1047 "Videoio.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 1052 "Videoio.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 VideoWriter_new5

=for sig

  Signature: (int [phys] apiPreference(); int [phys] fourcc(); double [phys] fps(); indx [phys] frameSize(n6=2); int [phys] params(n7d0); char * klass; StringWrapper* filename; [o] VideoWriterWrapper * res)

=for ref

=for example

 $obj = PDL::OpenCV::VideoWriter->new5($filename,$apiPreference,$fourcc,$fps,$frameSize,$params);

@overload

=for bad

VideoWriter_new5 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1081 "Videoio.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::VideoWriter::new5 {
  barf "Usage: PDL::OpenCV::VideoWriter::new5(\$klass,\$filename,\$apiPreference,\$fourcc,\$fps,\$frameSize,\$params)\n" if @_ < 7;
  my ($klass,$filename,$apiPreference,$fourcc,$fps,$frameSize,$params) = @_;
  my ($res);
  
  PDL::OpenCV::VideoWriter::_VideoWriter_new5_int($apiPreference,$fourcc,$fps,$frameSize,$params,$klass,$filename,$res);
  !wantarray ? $res : ($res)
}
#line 1095 "Videoio.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 1100 "Videoio.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 VideoWriter_open

=for sig

  Signature: (int [phys] fourcc(); double [phys] fps(); indx [phys] frameSize(n5=2); byte [phys] isColor(); byte [o,phys] res(); VideoWriterWrapper * self; StringWrapper* filename)

=for ref

Initializes or reinitializes video writer.

=for example

 $res = $obj->open($filename,$fourcc,$fps,$frameSize); # with defaults
 $res = $obj->open($filename,$fourcc,$fps,$frameSize,$isColor);

The method opens video writer. Parameters are the same as in the constructor
VideoWriter::VideoWriter.
The method first calls VideoWriter::release to close the already opened file.

Returns: `true` if video writer has been successfully initialized


=for bad

VideoWriter_open ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1137 "Videoio.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::VideoWriter::open {
  barf "Usage: PDL::OpenCV::VideoWriter::open(\$self,\$filename,\$fourcc,\$fps,\$frameSize,\$isColor)\n" if @_ < 5;
  my ($self,$filename,$fourcc,$fps,$frameSize,$isColor) = @_;
  my ($res);
  $isColor = 1 if !defined $isColor;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::VideoWriter::_VideoWriter_open_int($fourcc,$fps,$frameSize,$isColor,$res,$self,$filename);
  !wantarray ? $res : ($res)
}
#line 1152 "Videoio.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 1157 "Videoio.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 VideoWriter_open2

=for sig

  Signature: (int [phys] apiPreference(); int [phys] fourcc(); double [phys] fps(); indx [phys] frameSize(n6=2); byte [phys] isColor(); byte [o,phys] res(); VideoWriterWrapper * self; StringWrapper* filename)

=for ref

=for example

 $res = $obj->open2($filename,$apiPreference,$fourcc,$fps,$frameSize); # with defaults
 $res = $obj->open2($filename,$apiPreference,$fourcc,$fps,$frameSize,$isColor);

@overload

=for bad

VideoWriter_open2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1187 "Videoio.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::VideoWriter::open2 {
  barf "Usage: PDL::OpenCV::VideoWriter::open2(\$self,\$filename,\$apiPreference,\$fourcc,\$fps,\$frameSize,\$isColor)\n" if @_ < 6;
  my ($self,$filename,$apiPreference,$fourcc,$fps,$frameSize,$isColor) = @_;
  my ($res);
  $isColor = 1 if !defined $isColor;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::VideoWriter::_VideoWriter_open2_int($apiPreference,$fourcc,$fps,$frameSize,$isColor,$res,$self,$filename);
  !wantarray ? $res : ($res)
}
#line 1202 "Videoio.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 1207 "Videoio.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 VideoWriter_open3

=for sig

  Signature: (int [phys] fourcc(); double [phys] fps(); indx [phys] frameSize(n5=2); int [phys] params(n6d0); byte [o,phys] res(); VideoWriterWrapper * self; StringWrapper* filename)

=for ref

=for example

 $res = $obj->open3($filename,$fourcc,$fps,$frameSize,$params);

@overload

=for bad

VideoWriter_open3 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1236 "Videoio.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::VideoWriter::open3 {
  barf "Usage: PDL::OpenCV::VideoWriter::open3(\$self,\$filename,\$fourcc,\$fps,\$frameSize,\$params)\n" if @_ < 6;
  my ($self,$filename,$fourcc,$fps,$frameSize,$params) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::VideoWriter::_VideoWriter_open3_int($fourcc,$fps,$frameSize,$params,$res,$self,$filename);
  !wantarray ? $res : ($res)
}
#line 1250 "Videoio.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 1255 "Videoio.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 VideoWriter_open4

=for sig

  Signature: (int [phys] apiPreference(); int [phys] fourcc(); double [phys] fps(); indx [phys] frameSize(n6=2); int [phys] params(n7d0); byte [o,phys] res(); VideoWriterWrapper * self; StringWrapper* filename)

=for ref

=for example

 $res = $obj->open4($filename,$apiPreference,$fourcc,$fps,$frameSize,$params);

@overload

=for bad

VideoWriter_open4 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1284 "Videoio.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::VideoWriter::open4 {
  barf "Usage: PDL::OpenCV::VideoWriter::open4(\$self,\$filename,\$apiPreference,\$fourcc,\$fps,\$frameSize,\$params)\n" if @_ < 7;
  my ($self,$filename,$apiPreference,$fourcc,$fps,$frameSize,$params) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::VideoWriter::_VideoWriter_open4_int($apiPreference,$fourcc,$fps,$frameSize,$params,$res,$self,$filename);
  !wantarray ? $res : ($res)
}
#line 1298 "Videoio.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 1303 "Videoio.pm"



#line 274 "../genpp.pl"

=head2 isOpened

=for ref

Returns true if video writer has been successfully initialized.

=for example

 $res = $obj->isOpened;


=cut
#line 1321 "Videoio.pm"



#line 274 "../genpp.pl"

=head2 release

=for ref

Closes the video writer.

=for example

 $obj->release;

The method is automatically called by subsequent VideoWriter::open and by the VideoWriter
destructor.

=cut
#line 1341 "Videoio.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 VideoWriter_write

=for sig

  Signature: ([phys] image(l2,c2,r2); VideoWriterWrapper * self)

=for ref

Writes the next video frame

=for example

 $obj->write($image);

The function/method writes the specified image to video file. It must have the same size as has
been specified when opening the video writer.

Parameters:

=over

=item image

The written frame. In general, color images are expected in BGR format.

=back


=for bad

VideoWriter_write ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1384 "Videoio.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::VideoWriter::write {
  barf "Usage: PDL::OpenCV::VideoWriter::write(\$self,\$image)\n" if @_ < 2;
  my ($self,$image) = @_;
    
  PDL::OpenCV::VideoWriter::_VideoWriter_write_int($image,$self);
  
}
#line 1397 "Videoio.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"
#line 1402 "Videoio.pm"



#line 274 "../genpp.pl"

=head2 set

=for ref

Sets a property in the VideoWriter.

=for example

 $res = $obj->set($propId,$value);

@ref videoio_flags_others

Parameters:

=over

=item propId

Property identifier from cv::VideoWriterProperties (eg. cv::VIDEOWRITER_PROP_QUALITY)
     or one of

=item value

Value of the property.

=back

Returns: `true` if the property is supported by the backend used by the VideoWriter instance.


=cut
#line 1439 "Videoio.pm"



#line 274 "../genpp.pl"

=head2 get

=for ref

Returns the specified VideoWriter property

=for example

 $res = $obj->get($propId);

@ref videoio_flags_others

Parameters:

=over

=item propId

Property identifier from cv::VideoWriterProperties (eg. cv::VIDEOWRITER_PROP_QUALITY)
     or one of

=back

Returns: Value for the specified property. Value 0 is returned when querying a property that is
     not supported by the backend used by the VideoWriter instance.


=cut
#line 1473 "Videoio.pm"



#line 274 "../genpp.pl"

=head2 fourcc

=for ref

Concatenates 4 chars to a fourcc code

=for example

 $res = PDL::OpenCV::VideoWriter::fourcc($c1,$c2,$c3,$c4);

This static method constructs the fourcc code of the codec to be used in the constructor
VideoWriter::VideoWriter or VideoWriter::open.

Returns: a fourcc code


=cut
#line 1496 "Videoio.pm"



#line 274 "../genpp.pl"

=head2 getBackendName

=for ref

Returns used backend API name

=for example

 $res = $obj->getBackendName;

@note Stream should be opened.

=cut
#line 1515 "Videoio.pm"



#line 441 "../genpp.pl"

=head1 CONSTANTS

=over

=item PDL::OpenCV::Videoio::CAP_ANY()

=item PDL::OpenCV::Videoio::CAP_VFW()

=item PDL::OpenCV::Videoio::CAP_V4L()

=item PDL::OpenCV::Videoio::CAP_V4L2()

=item PDL::OpenCV::Videoio::CAP_FIREWIRE()

=item PDL::OpenCV::Videoio::CAP_FIREWARE()

=item PDL::OpenCV::Videoio::CAP_IEEE1394()

=item PDL::OpenCV::Videoio::CAP_DC1394()

=item PDL::OpenCV::Videoio::CAP_CMU1394()

=item PDL::OpenCV::Videoio::CAP_QT()

=item PDL::OpenCV::Videoio::CAP_UNICAP()

=item PDL::OpenCV::Videoio::CAP_DSHOW()

=item PDL::OpenCV::Videoio::CAP_PVAPI()

=item PDL::OpenCV::Videoio::CAP_OPENNI()

=item PDL::OpenCV::Videoio::CAP_OPENNI_ASUS()

=item PDL::OpenCV::Videoio::CAP_ANDROID()

=item PDL::OpenCV::Videoio::CAP_XIAPI()

=item PDL::OpenCV::Videoio::CAP_AVFOUNDATION()

=item PDL::OpenCV::Videoio::CAP_GIGANETIX()

=item PDL::OpenCV::Videoio::CAP_MSMF()

=item PDL::OpenCV::Videoio::CAP_WINRT()

=item PDL::OpenCV::Videoio::CAP_INTELPERC()

=item PDL::OpenCV::Videoio::CAP_REALSENSE()

=item PDL::OpenCV::Videoio::CAP_OPENNI2()

=item PDL::OpenCV::Videoio::CAP_OPENNI2_ASUS()

=item PDL::OpenCV::Videoio::CAP_OPENNI2_ASTRA()

=item PDL::OpenCV::Videoio::CAP_GPHOTO2()

=item PDL::OpenCV::Videoio::CAP_GSTREAMER()

=item PDL::OpenCV::Videoio::CAP_FFMPEG()

=item PDL::OpenCV::Videoio::CAP_IMAGES()

=item PDL::OpenCV::Videoio::CAP_ARAVIS()

=item PDL::OpenCV::Videoio::CAP_OPENCV_MJPEG()

=item PDL::OpenCV::Videoio::CAP_INTEL_MFX()

=item PDL::OpenCV::Videoio::CAP_XINE()

=item PDL::OpenCV::Videoio::CAP_UEYE()

=item PDL::OpenCV::Videoio::CAP_PROP_POS_MSEC()

=item PDL::OpenCV::Videoio::CAP_PROP_POS_FRAMES()

=item PDL::OpenCV::Videoio::CAP_PROP_POS_AVI_RATIO()

=item PDL::OpenCV::Videoio::CAP_PROP_FRAME_WIDTH()

=item PDL::OpenCV::Videoio::CAP_PROP_FRAME_HEIGHT()

=item PDL::OpenCV::Videoio::CAP_PROP_FPS()

=item PDL::OpenCV::Videoio::CAP_PROP_FOURCC()

=item PDL::OpenCV::Videoio::CAP_PROP_FRAME_COUNT()

=item PDL::OpenCV::Videoio::CAP_PROP_FORMAT()

=item PDL::OpenCV::Videoio::CAP_PROP_MODE()

=item PDL::OpenCV::Videoio::CAP_PROP_BRIGHTNESS()

=item PDL::OpenCV::Videoio::CAP_PROP_CONTRAST()

=item PDL::OpenCV::Videoio::CAP_PROP_SATURATION()

=item PDL::OpenCV::Videoio::CAP_PROP_HUE()

=item PDL::OpenCV::Videoio::CAP_PROP_GAIN()

=item PDL::OpenCV::Videoio::CAP_PROP_EXPOSURE()

=item PDL::OpenCV::Videoio::CAP_PROP_CONVERT_RGB()

=item PDL::OpenCV::Videoio::CAP_PROP_WHITE_BALANCE_BLUE_U()

=item PDL::OpenCV::Videoio::CAP_PROP_RECTIFICATION()

=item PDL::OpenCV::Videoio::CAP_PROP_MONOCHROME()

=item PDL::OpenCV::Videoio::CAP_PROP_SHARPNESS()

=item PDL::OpenCV::Videoio::CAP_PROP_AUTO_EXPOSURE()

=item PDL::OpenCV::Videoio::CAP_PROP_GAMMA()

=item PDL::OpenCV::Videoio::CAP_PROP_TEMPERATURE()

=item PDL::OpenCV::Videoio::CAP_PROP_TRIGGER()

=item PDL::OpenCV::Videoio::CAP_PROP_TRIGGER_DELAY()

=item PDL::OpenCV::Videoio::CAP_PROP_WHITE_BALANCE_RED_V()

=item PDL::OpenCV::Videoio::CAP_PROP_ZOOM()

=item PDL::OpenCV::Videoio::CAP_PROP_FOCUS()

=item PDL::OpenCV::Videoio::CAP_PROP_GUID()

=item PDL::OpenCV::Videoio::CAP_PROP_ISO_SPEED()

=item PDL::OpenCV::Videoio::CAP_PROP_BACKLIGHT()

=item PDL::OpenCV::Videoio::CAP_PROP_PAN()

=item PDL::OpenCV::Videoio::CAP_PROP_TILT()

=item PDL::OpenCV::Videoio::CAP_PROP_ROLL()

=item PDL::OpenCV::Videoio::CAP_PROP_IRIS()

=item PDL::OpenCV::Videoio::CAP_PROP_SETTINGS()

=item PDL::OpenCV::Videoio::CAP_PROP_BUFFERSIZE()

=item PDL::OpenCV::Videoio::CAP_PROP_AUTOFOCUS()

=item PDL::OpenCV::Videoio::CAP_PROP_SAR_NUM()

=item PDL::OpenCV::Videoio::CAP_PROP_SAR_DEN()

=item PDL::OpenCV::Videoio::CAP_PROP_BACKEND()

=item PDL::OpenCV::Videoio::CAP_PROP_CHANNEL()

=item PDL::OpenCV::Videoio::CAP_PROP_AUTO_WB()

=item PDL::OpenCV::Videoio::CAP_PROP_WB_TEMPERATURE()

=item PDL::OpenCV::Videoio::CAP_PROP_CODEC_PIXEL_FORMAT()

=item PDL::OpenCV::Videoio::CAP_PROP_BITRATE()

=item PDL::OpenCV::Videoio::CAP_PROP_ORIENTATION_META()

=item PDL::OpenCV::Videoio::CAP_PROP_ORIENTATION_AUTO()

=item PDL::OpenCV::Videoio::CAP_PROP_HW_ACCELERATION()

=item PDL::OpenCV::Videoio::CAP_PROP_HW_DEVICE()

=item PDL::OpenCV::Videoio::CAP_PROP_HW_ACCELERATION_USE_OPENCL()

=item PDL::OpenCV::Videoio::CAP_PROP_OPEN_TIMEOUT_MSEC()

=item PDL::OpenCV::Videoio::CAP_PROP_READ_TIMEOUT_MSEC()

=item PDL::OpenCV::Videoio::CAP_PROP_STREAM_OPEN_TIME_USEC()

=item PDL::OpenCV::Videoio::VIDEOWRITER_PROP_QUALITY()

=item PDL::OpenCV::Videoio::VIDEOWRITER_PROP_FRAMEBYTES()

=item PDL::OpenCV::Videoio::VIDEOWRITER_PROP_NSTRIPES()

=item PDL::OpenCV::Videoio::VIDEOWRITER_PROP_IS_COLOR()

=item PDL::OpenCV::Videoio::VIDEOWRITER_PROP_DEPTH()

=item PDL::OpenCV::Videoio::VIDEOWRITER_PROP_HW_ACCELERATION()

=item PDL::OpenCV::Videoio::VIDEOWRITER_PROP_HW_DEVICE()

=item PDL::OpenCV::Videoio::VIDEOWRITER_PROP_HW_ACCELERATION_USE_OPENCL()

=item PDL::OpenCV::Videoio::VIDEO_ACCELERATION_NONE()

=item PDL::OpenCV::Videoio::VIDEO_ACCELERATION_ANY()

=item PDL::OpenCV::Videoio::VIDEO_ACCELERATION_D3D11()

=item PDL::OpenCV::Videoio::VIDEO_ACCELERATION_VAAPI()

=item PDL::OpenCV::Videoio::VIDEO_ACCELERATION_MFX()

=item PDL::OpenCV::Videoio::CAP_PROP_DC1394_OFF()

=item PDL::OpenCV::Videoio::CAP_PROP_DC1394_MODE_MANUAL()

=item PDL::OpenCV::Videoio::CAP_PROP_DC1394_MODE_AUTO()

=item PDL::OpenCV::Videoio::CAP_PROP_DC1394_MODE_ONE_PUSH_AUTO()

=item PDL::OpenCV::Videoio::CAP_PROP_DC1394_MAX()

=item PDL::OpenCV::Videoio::CAP_OPENNI_DEPTH_GENERATOR()

=item PDL::OpenCV::Videoio::CAP_OPENNI_IMAGE_GENERATOR()

=item PDL::OpenCV::Videoio::CAP_OPENNI_IR_GENERATOR()

=item PDL::OpenCV::Videoio::CAP_OPENNI_GENERATORS_MASK()

=item PDL::OpenCV::Videoio::CAP_PROP_OPENNI_OUTPUT_MODE()

=item PDL::OpenCV::Videoio::CAP_PROP_OPENNI_FRAME_MAX_DEPTH()

=item PDL::OpenCV::Videoio::CAP_PROP_OPENNI_BASELINE()

=item PDL::OpenCV::Videoio::CAP_PROP_OPENNI_FOCAL_LENGTH()

=item PDL::OpenCV::Videoio::CAP_PROP_OPENNI_REGISTRATION()

=item PDL::OpenCV::Videoio::CAP_PROP_OPENNI_REGISTRATION_ON()

=item PDL::OpenCV::Videoio::CAP_PROP_OPENNI_APPROX_FRAME_SYNC()

=item PDL::OpenCV::Videoio::CAP_PROP_OPENNI_MAX_BUFFER_SIZE()

=item PDL::OpenCV::Videoio::CAP_PROP_OPENNI_CIRCLE_BUFFER()

=item PDL::OpenCV::Videoio::CAP_PROP_OPENNI_MAX_TIME_DURATION()

=item PDL::OpenCV::Videoio::CAP_PROP_OPENNI_GENERATOR_PRESENT()

=item PDL::OpenCV::Videoio::CAP_PROP_OPENNI2_SYNC()

=item PDL::OpenCV::Videoio::CAP_PROP_OPENNI2_MIRROR()

=item PDL::OpenCV::Videoio::CAP_OPENNI_IMAGE_GENERATOR_PRESENT()

=item PDL::OpenCV::Videoio::CAP_OPENNI_IMAGE_GENERATOR_OUTPUT_MODE()

=item PDL::OpenCV::Videoio::CAP_OPENNI_DEPTH_GENERATOR_PRESENT()

=item PDL::OpenCV::Videoio::CAP_OPENNI_DEPTH_GENERATOR_BASELINE()

=item PDL::OpenCV::Videoio::CAP_OPENNI_DEPTH_GENERATOR_FOCAL_LENGTH()

=item PDL::OpenCV::Videoio::CAP_OPENNI_DEPTH_GENERATOR_REGISTRATION()

=item PDL::OpenCV::Videoio::CAP_OPENNI_DEPTH_GENERATOR_REGISTRATION_ON()

=item PDL::OpenCV::Videoio::CAP_OPENNI_IR_GENERATOR_PRESENT()

=item PDL::OpenCV::Videoio::CAP_OPENNI_DEPTH_MAP()

=item PDL::OpenCV::Videoio::CAP_OPENNI_POINT_CLOUD_MAP()

=item PDL::OpenCV::Videoio::CAP_OPENNI_DISPARITY_MAP()

=item PDL::OpenCV::Videoio::CAP_OPENNI_DISPARITY_MAP_32F()

=item PDL::OpenCV::Videoio::CAP_OPENNI_VALID_DEPTH_MASK()

=item PDL::OpenCV::Videoio::CAP_OPENNI_BGR_IMAGE()

=item PDL::OpenCV::Videoio::CAP_OPENNI_GRAY_IMAGE()

=item PDL::OpenCV::Videoio::CAP_OPENNI_IR_IMAGE()

=item PDL::OpenCV::Videoio::CAP_OPENNI_VGA_30HZ()

=item PDL::OpenCV::Videoio::CAP_OPENNI_SXGA_15HZ()

=item PDL::OpenCV::Videoio::CAP_OPENNI_SXGA_30HZ()

=item PDL::OpenCV::Videoio::CAP_OPENNI_QVGA_30HZ()

=item PDL::OpenCV::Videoio::CAP_OPENNI_QVGA_60HZ()

=item PDL::OpenCV::Videoio::CAP_PROP_GSTREAMER_QUEUE_LENGTH()

=item PDL::OpenCV::Videoio::CAP_PROP_PVAPI_MULTICASTIP()

=item PDL::OpenCV::Videoio::CAP_PROP_PVAPI_FRAMESTARTTRIGGERMODE()

=item PDL::OpenCV::Videoio::CAP_PROP_PVAPI_DECIMATIONHORIZONTAL()

=item PDL::OpenCV::Videoio::CAP_PROP_PVAPI_DECIMATIONVERTICAL()

=item PDL::OpenCV::Videoio::CAP_PROP_PVAPI_BINNINGX()

=item PDL::OpenCV::Videoio::CAP_PROP_PVAPI_BINNINGY()

=item PDL::OpenCV::Videoio::CAP_PROP_PVAPI_PIXELFORMAT()

=item PDL::OpenCV::Videoio::CAP_PVAPI_FSTRIGMODE_FREERUN()

=item PDL::OpenCV::Videoio::CAP_PVAPI_FSTRIGMODE_SYNCIN1()

=item PDL::OpenCV::Videoio::CAP_PVAPI_FSTRIGMODE_SYNCIN2()

=item PDL::OpenCV::Videoio::CAP_PVAPI_FSTRIGMODE_FIXEDRATE()

=item PDL::OpenCV::Videoio::CAP_PVAPI_FSTRIGMODE_SOFTWARE()

=item PDL::OpenCV::Videoio::CAP_PVAPI_DECIMATION_OFF()

=item PDL::OpenCV::Videoio::CAP_PVAPI_DECIMATION_2OUTOF4()

=item PDL::OpenCV::Videoio::CAP_PVAPI_DECIMATION_2OUTOF8()

=item PDL::OpenCV::Videoio::CAP_PVAPI_DECIMATION_2OUTOF16()

=item PDL::OpenCV::Videoio::CAP_PVAPI_PIXELFORMAT_MONO8()

=item PDL::OpenCV::Videoio::CAP_PVAPI_PIXELFORMAT_MONO16()

=item PDL::OpenCV::Videoio::CAP_PVAPI_PIXELFORMAT_BAYER8()

=item PDL::OpenCV::Videoio::CAP_PVAPI_PIXELFORMAT_BAYER16()

=item PDL::OpenCV::Videoio::CAP_PVAPI_PIXELFORMAT_RGB24()

=item PDL::OpenCV::Videoio::CAP_PVAPI_PIXELFORMAT_BGR24()

=item PDL::OpenCV::Videoio::CAP_PVAPI_PIXELFORMAT_RGBA32()

=item PDL::OpenCV::Videoio::CAP_PVAPI_PIXELFORMAT_BGRA32()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_DOWNSAMPLING()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_DATA_FORMAT()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_OFFSET_X()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_OFFSET_Y()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_TRG_SOURCE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_TRG_SOFTWARE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_GPI_SELECTOR()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_GPI_MODE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_GPI_LEVEL()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_GPO_SELECTOR()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_GPO_MODE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_LED_SELECTOR()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_LED_MODE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_MANUAL_WB()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_AUTO_WB()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_AEAG()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_EXP_PRIORITY()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_AE_MAX_LIMIT()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_AG_MAX_LIMIT()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_AEAG_LEVEL()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_TIMEOUT()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_EXPOSURE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_EXPOSURE_BURST_COUNT()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_GAIN_SELECTOR()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_GAIN()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_DOWNSAMPLING_TYPE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_BINNING_SELECTOR()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_BINNING_VERTICAL()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_BINNING_HORIZONTAL()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_BINNING_PATTERN()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_DECIMATION_SELECTOR()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_DECIMATION_VERTICAL()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_DECIMATION_HORIZONTAL()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_DECIMATION_PATTERN()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_TEST_PATTERN_GENERATOR_SELECTOR()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_TEST_PATTERN()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_IMAGE_DATA_FORMAT()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_SHUTTER_TYPE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_SENSOR_TAPS()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_AEAG_ROI_OFFSET_X()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_AEAG_ROI_OFFSET_Y()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_AEAG_ROI_WIDTH()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_AEAG_ROI_HEIGHT()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_BPC()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_WB_KR()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_WB_KG()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_WB_KB()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_WIDTH()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_HEIGHT()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_REGION_SELECTOR()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_REGION_MODE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_LIMIT_BANDWIDTH()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_SENSOR_DATA_BIT_DEPTH()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_OUTPUT_DATA_BIT_DEPTH()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_IMAGE_DATA_BIT_DEPTH()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_OUTPUT_DATA_PACKING()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_OUTPUT_DATA_PACKING_TYPE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_IS_COOLED()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_COOLING()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_TARGET_TEMP()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_CHIP_TEMP()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_HOUS_TEMP()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_HOUS_BACK_SIDE_TEMP()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_SENSOR_BOARD_TEMP()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_CMS()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_APPLY_CMS()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_IMAGE_IS_COLOR()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_COLOR_FILTER_ARRAY()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_GAMMAY()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_GAMMAC()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_SHARPNESS()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_CC_MATRIX_00()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_CC_MATRIX_01()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_CC_MATRIX_02()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_CC_MATRIX_03()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_CC_MATRIX_10()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_CC_MATRIX_11()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_CC_MATRIX_12()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_CC_MATRIX_13()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_CC_MATRIX_20()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_CC_MATRIX_21()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_CC_MATRIX_22()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_CC_MATRIX_23()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_CC_MATRIX_30()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_CC_MATRIX_31()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_CC_MATRIX_32()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_CC_MATRIX_33()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_DEFAULT_CC_MATRIX()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_TRG_SELECTOR()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_ACQ_FRAME_BURST_COUNT()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_DEBOUNCE_EN()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_DEBOUNCE_T0()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_DEBOUNCE_T1()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_DEBOUNCE_POL()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_LENS_MODE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_LENS_APERTURE_VALUE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_LENS_FOCUS_MOVEMENT_VALUE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_LENS_FOCUS_MOVE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_LENS_FOCUS_DISTANCE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_LENS_FOCAL_LENGTH()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_LENS_FEATURE_SELECTOR()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_LENS_FEATURE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_DEVICE_MODEL_ID()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_DEVICE_SN()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_IMAGE_DATA_FORMAT_RGB32_ALPHA()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_IMAGE_PAYLOAD_SIZE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_TRANSPORT_PIXEL_FORMAT()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_SENSOR_CLOCK_FREQ_HZ()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_SENSOR_CLOCK_FREQ_INDEX()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_SENSOR_OUTPUT_CHANNEL_COUNT()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_FRAMERATE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_COUNTER_SELECTOR()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_COUNTER_VALUE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_ACQ_TIMING_MODE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_AVAILABLE_BANDWIDTH()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_BUFFER_POLICY()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_LUT_EN()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_LUT_INDEX()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_LUT_VALUE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_TRG_DELAY()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_TS_RST_MODE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_TS_RST_SOURCE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_IS_DEVICE_EXIST()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_ACQ_BUFFER_SIZE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_ACQ_BUFFER_SIZE_UNIT()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_ACQ_TRANSPORT_BUFFER_SIZE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_BUFFERS_QUEUE_SIZE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_ACQ_TRANSPORT_BUFFER_COMMIT()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_RECENT_FRAME()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_DEVICE_RESET()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_COLUMN_FPN_CORRECTION()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_ROW_FPN_CORRECTION()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_SENSOR_MODE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_HDR()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_HDR_KNEEPOINT_COUNT()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_HDR_T1()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_HDR_T2()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_KNEEPOINT1()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_KNEEPOINT2()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_IMAGE_BLACK_LEVEL()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_HW_REVISION()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_DEBUG_LEVEL()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_AUTO_BANDWIDTH_CALCULATION()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_FFS_FILE_ID()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_FFS_FILE_SIZE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_FREE_FFS_SIZE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_USED_FFS_SIZE()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_FFS_ACCESS_KEY()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_SENSOR_FEATURE_SELECTOR()

=item PDL::OpenCV::Videoio::CAP_PROP_XI_SENSOR_FEATURE_VALUE()

=item PDL::OpenCV::Videoio::CAP_PROP_ARAVIS_AUTOTRIGGER()

=item PDL::OpenCV::Videoio::CAP_PROP_IOS_DEVICE_FOCUS()

=item PDL::OpenCV::Videoio::CAP_PROP_IOS_DEVICE_EXPOSURE()

=item PDL::OpenCV::Videoio::CAP_PROP_IOS_DEVICE_FLASH()

=item PDL::OpenCV::Videoio::CAP_PROP_IOS_DEVICE_WHITEBALANCE()

=item PDL::OpenCV::Videoio::CAP_PROP_IOS_DEVICE_TORCH()

=item PDL::OpenCV::Videoio::CAP_PROP_GIGA_FRAME_OFFSET_X()

=item PDL::OpenCV::Videoio::CAP_PROP_GIGA_FRAME_OFFSET_Y()

=item PDL::OpenCV::Videoio::CAP_PROP_GIGA_FRAME_WIDTH_MAX()

=item PDL::OpenCV::Videoio::CAP_PROP_GIGA_FRAME_HEIGH_MAX()

=item PDL::OpenCV::Videoio::CAP_PROP_GIGA_FRAME_SENS_WIDTH()

=item PDL::OpenCV::Videoio::CAP_PROP_GIGA_FRAME_SENS_HEIGH()

=item PDL::OpenCV::Videoio::CAP_PROP_INTELPERC_PROFILE_COUNT()

=item PDL::OpenCV::Videoio::CAP_PROP_INTELPERC_PROFILE_IDX()

=item PDL::OpenCV::Videoio::CAP_PROP_INTELPERC_DEPTH_LOW_CONFIDENCE_VALUE()

=item PDL::OpenCV::Videoio::CAP_PROP_INTELPERC_DEPTH_SATURATION_VALUE()

=item PDL::OpenCV::Videoio::CAP_PROP_INTELPERC_DEPTH_CONFIDENCE_THRESHOLD()

=item PDL::OpenCV::Videoio::CAP_PROP_INTELPERC_DEPTH_FOCAL_LENGTH_HORZ()

=item PDL::OpenCV::Videoio::CAP_PROP_INTELPERC_DEPTH_FOCAL_LENGTH_VERT()

=item PDL::OpenCV::Videoio::CAP_INTELPERC_DEPTH_GENERATOR()

=item PDL::OpenCV::Videoio::CAP_INTELPERC_IMAGE_GENERATOR()

=item PDL::OpenCV::Videoio::CAP_INTELPERC_IR_GENERATOR()

=item PDL::OpenCV::Videoio::CAP_INTELPERC_GENERATORS_MASK()

=item PDL::OpenCV::Videoio::CAP_INTELPERC_DEPTH_MAP()

=item PDL::OpenCV::Videoio::CAP_INTELPERC_UVDEPTH_MAP()

=item PDL::OpenCV::Videoio::CAP_INTELPERC_IR_MAP()

=item PDL::OpenCV::Videoio::CAP_INTELPERC_IMAGE()

=item PDL::OpenCV::Videoio::CAP_PROP_GPHOTO2_PREVIEW()

=item PDL::OpenCV::Videoio::CAP_PROP_GPHOTO2_WIDGET_ENUMERATE()

=item PDL::OpenCV::Videoio::CAP_PROP_GPHOTO2_RELOAD_CONFIG()

=item PDL::OpenCV::Videoio::CAP_PROP_GPHOTO2_RELOAD_ON_CHANGE()

=item PDL::OpenCV::Videoio::CAP_PROP_GPHOTO2_COLLECT_MSGS()

=item PDL::OpenCV::Videoio::CAP_PROP_GPHOTO2_FLUSH_MSGS()

=item PDL::OpenCV::Videoio::CAP_PROP_SPEED()

=item PDL::OpenCV::Videoio::CAP_PROP_APERTURE()

=item PDL::OpenCV::Videoio::CAP_PROP_EXPOSUREPROGRAM()

=item PDL::OpenCV::Videoio::CAP_PROP_VIEWFINDER()

=item PDL::OpenCV::Videoio::CAP_PROP_IMAGES_BASE()

=item PDL::OpenCV::Videoio::CAP_PROP_IMAGES_LAST()


=back

=cut
#line 2249 "Videoio.pm"






# Exit with OK status

1;
