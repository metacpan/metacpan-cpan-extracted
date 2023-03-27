(
['VideoCapture','open','@brief  Opens a video file or a capturing device or an IP video stream for video capturing.

    @overload

    Parameters are same as the constructor VideoCapture(const String& filename, int apiPreference = CAP_ANY)
    @return `true` if the file has been successfully opened

    The method first calls VideoCapture::release to close the already opened file or camera.',1,'bool',['String','filename','',['/C','/Ref']],['int','apiPreference','CAP_ANY',[]]],
['VideoCapture','open','@brief  Opens a camera for video capturing

    @overload

    The `params` parameter allows to specify extra parameters encoded as pairs `(paramId_1, paramValue_1, paramId_2, paramValue_2, ...)`.
    See cv::VideoCaptureProperties

    @return `true` if the file has been successfully opened

    The method first calls VideoCapture::release to close the already opened file or camera.',1,'bool',['String','filename','',['/C','/Ref']],['int','apiPreference','',[]],['vector_int','params','',['/C','/Ref']]],
['VideoCapture','open','@brief  Opens a camera for video capturing

    @overload

    Parameters are same as the constructor VideoCapture(int index, int apiPreference = CAP_ANY)
    @return `true` if the camera has been successfully opened.

    The method first calls VideoCapture::release to close the already opened file or camera.',1,'bool',['int','index','',[]],['int','apiPreference','CAP_ANY',[]]],
['VideoCapture','open','@brief Returns true if video capturing has been initialized already.

    @overload

    The `params` parameter allows to specify extra parameters encoded as pairs `(paramId_1, paramValue_1, paramId_2, paramValue_2, ...)`.
    See cv::VideoCaptureProperties

    @return `true` if the camera has been successfully opened.

    The method first calls VideoCapture::release to close the already opened file or camera.',1,'bool',['int','index','',[]],['int','apiPreference','',[]],['vector_int','params','',['/C','/Ref']]],
['VideoCapture','isOpened','@brief Returns true if video capturing has been initialized already.

    If the previous call to VideoCapture constructor or VideoCapture::open() succeeded, the method returns
    true.',1,'bool'],
['VideoCapture','release','@brief Closes video file or capturing device.

    The method is automatically called by subsequent VideoCapture::open and by VideoCapture
    destructor.

    The C function also deallocates memory and clears \\*capture pointer.',1,'void'],
['VideoCapture','grab','@brief Grabs the next frame from video file or capturing device.

    @return `true` (non-zero) in the case of success.

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

    @ref tutorial_kinect_openni',1,'bool'],
['VideoCapture','retrieve','@brief Decodes and returns the grabbed video frame.

    @param [out] image the video frame is returned here. If no frames has been grabbed the image will be empty.
    @param flag it could be a frame index or a driver specific flag
    @return `false` if no frames has been grabbed

    The method decodes and returns the just grabbed frame. If no frames has been grabbed
    (camera has been disconnected, or there are no more frames in video file), the method returns false
    and the function returns an empty image (with %cv::Mat, test it with Mat::empty()).

    @sa read()

    @note In @ref videoio_c "C API", functions cvRetrieveFrame() and cv.RetrieveFrame() return image stored inside the video
    capturing structure. It is not allowed to modify or release the image! You can copy the frame using
    cvCloneImage and then do whatever you want with the copy.',1,'bool',['Mat','image','',['/O']],['int','flag','0',[]]],
['VideoCapture','read','@brief Grabs, decodes and returns the next video frame.

    @param [out] image the video frame is returned here. If no frames has been grabbed the image will be empty.
    @return `false` if no frames has been grabbed

    The method/function combines VideoCapture::grab() and VideoCapture::retrieve() in one call. This is the
    most convenient method for reading video files or capturing data from decode and returns the just
    grabbed frame. If no frames has been grabbed (camera has been disconnected, or there are no more
    frames in video file), the method returns false and the function returns empty image (with %cv::Mat, test it with Mat::empty()).

    @note In @ref videoio_c "C API", functions cvRetrieveFrame() and cv.RetrieveFrame() return image stored inside the video
    capturing structure. It is not allowed to modify or release the image! You can copy the frame using
    cvCloneImage and then do whatever you want with the copy.',1,'bool',['Mat','image','',['/O']]],
['VideoCapture','set','@brief Sets a property in the VideoCapture.

    @param propId Property identifier from cv::VideoCaptureProperties (eg. cv::CAP_PROP_POS_MSEC, cv::CAP_PROP_POS_FRAMES, ...)
    or one from @ref videoio_flags_others
    @param value Value of the property.
    @return `true` if the property is supported by backend used by the VideoCapture instance.
    @note Even if it returns `true` this doesn\'t ensure that the property
    value has been accepted by the capture device. See note in VideoCapture::get()',1,'bool',['int','propId','',[]],['double','value','',[]]],
['VideoCapture','get','@brief Returns the specified VideoCapture property

    @param propId Property identifier from cv::VideoCaptureProperties (eg. cv::CAP_PROP_POS_MSEC, cv::CAP_PROP_POS_FRAMES, ...)
    or one from @ref videoio_flags_others
    @return Value for the specified property. Value 0 is returned when querying a property that is
    not supported by the backend used by the VideoCapture instance.

    @note Reading / writing properties involves many layers. Some unexpected result might happens
    along this chain.
    @code{.txt}
    VideoCapture -> API Backend -> Operating System -> Device Driver -> Device Hardware
    @endcode
    The returned value might be different from what really used by the device or it could be encoded
    using device dependent rules (eg. steps or percentage). Effective behaviour depends from device
    driver and API Backend',1,'double',['int','propId','',[]]],
['VideoCapture','getBackendName','@brief Returns used backend API name

     @note Stream should be opened.',1,'String'],
['VideoCapture','setExceptionMode','Switches exceptions mode
     *
     * methods raise exceptions if not successful instead of returning an error code',1,'void',['bool','enable','',[]]],
['VideoCapture','getExceptionMode','',1,'bool'],
['VideoWriter','open','@brief Initializes or reinitializes video writer.

    The method opens video writer. Parameters are the same as in the constructor
    VideoWriter::VideoWriter.
    @return `true` if video writer has been successfully initialized

    The method first calls VideoWriter::release to close the already opened file.',1,'bool',['String','filename','',['/C','/Ref']],['int','fourcc','',[]],['double','fps','',[]],['Size','frameSize','',[]],['bool','isColor','true',[]]],
['VideoWriter','open','@overload',1,'bool',['String','filename','',['/C','/Ref']],['int','apiPreference','',[]],['int','fourcc','',[]],['double','fps','',[]],['Size','frameSize','',[]],['bool','isColor','true',[]]],
['VideoWriter','open','@overload',1,'bool',['String','filename','',['/C','/Ref']],['int','fourcc','',[]],['double','fps','',[]],['Size','frameSize','',['/C','/Ref']],['vector_int','params','',['/C','/Ref']]],
['VideoWriter','open','@overload',1,'bool',['String','filename','',['/C','/Ref']],['int','apiPreference','',[]],['int','fourcc','',[]],['double','fps','',[]],['Size','frameSize','',['/C','/Ref']],['vector_int','params','',['/C','/Ref']]],
['VideoWriter','isOpened','@brief Returns true if video writer has been successfully initialized.',1,'bool'],
['VideoWriter','release','@brief Closes the video writer.

    The method is automatically called by subsequent VideoWriter::open and by the VideoWriter
    destructor.',1,'void'],
['VideoWriter','write','@brief Writes the next video frame

    @param image The written frame. In general, color images are expected in BGR format.

    The function/method writes the specified image to video file. It must have the same size as has
    been specified when opening the video writer.',1,'void',['Mat','image','',[]]],
['VideoWriter','set','@brief Sets a property in the VideoWriter.

     @param propId Property identifier from cv::VideoWriterProperties (eg. cv::VIDEOWRITER_PROP_QUALITY)
     or one of @ref videoio_flags_others

     @param value Value of the property.
     @return  `true` if the property is supported by the backend used by the VideoWriter instance.',1,'bool',['int','propId','',[]],['double','value','',[]]],
['VideoWriter','get','@brief Returns the specified VideoWriter property

     @param propId Property identifier from cv::VideoWriterProperties (eg. cv::VIDEOWRITER_PROP_QUALITY)
     or one of @ref videoio_flags_others

     @return Value for the specified property. Value 0 is returned when querying a property that is
     not supported by the backend used by the VideoWriter instance.',1,'double',['int','propId','',[]]],
['VideoWriter','fourcc','@brief Concatenates 4 chars to a fourcc code

    @return a fourcc code

    This static method constructs the fourcc code of the codec to be used in the constructor
    VideoWriter::VideoWriter or VideoWriter::open.',0,'int',['char','c1','',[]],['char','c2','',[]],['char','c3','',[]],['char','c4','',[]]],
['VideoWriter','getBackendName','@brief Returns used backend API name

     @note Stream should be opened.',1,'String'],
);
