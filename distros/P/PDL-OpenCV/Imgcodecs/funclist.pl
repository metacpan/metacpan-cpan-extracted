(
['','imread','@brief Loads an image from a file.

@anchor imread

The function imread loads an image from the specified file and returns it. If the image cannot be
read (because of missing file, improper permissions, unsupported or invalid format), the function
returns an empty matrix ( Mat::data==NULL ).

Currently, the following file formats are supported:

-   Windows bitmaps - \\*.bmp, \\*.dib (always supported)
-   JPEG files - \\*.jpeg, \\*.jpg, \\*.jpe (see the *Note* section)
-   JPEG 2000 files - \\*.jp2 (see the *Note* section)
-   Portable Network Graphics - \\*.png (see the *Note* section)
-   WebP - \\*.webp (see the *Note* section)
-   Portable image format - \\*.pbm, \\*.pgm, \\*.ppm \\*.pxm, \\*.pnm (always supported)
-   PFM files - \\*.pfm (see the *Note* section)
-   Sun rasters - \\*.sr, \\*.ras (always supported)
-   TIFF files - \\*.tiff, \\*.tif (see the *Note* section)
-   OpenEXR Image files - \\*.exr (see the *Note* section)
-   Radiance HDR - \\*.hdr, \\*.pic (always supported)
-   Raster and Vector geospatial data supported by GDAL (see the *Note* section)

@note
-   The function determines the type of an image by the content, not by the file extension.
-   In the case of color images, the decoded images will have the channels stored in **B G R** order.
-   When using IMREAD_GRAYSCALE, the codec\'s internal grayscale conversion will be used, if available.
    Results may differ to the output of cvtColor()
-   On Microsoft Windows\\* OS and MacOSX\\*, the codecs shipped with an OpenCV image (libjpeg,
    libpng, libtiff, and libjasper) are used by default. So, OpenCV can always read JPEGs, PNGs,
    and TIFFs. On MacOSX, there is also an option to use native MacOSX image readers. But beware
    that currently these native image loaders give images with different pixel values because of
    the color management embedded into MacOSX.
-   On Linux\\*, BSD flavors and other Unix-like open-source operating systems, OpenCV looks for
    codecs supplied with an OS image. Install the relevant packages (do not forget the development
    files, for example, "libjpeg-dev", in Debian\\* and Ubuntu\\*) to get the codec support or turn
    on the OPENCV_BUILD_3RDPARTY_LIBS flag in CMake.
-   In the case you set *WITH_GDAL* flag to true in CMake and @ref IMREAD_LOAD_GDAL to load the image,
    then the [GDAL](http://www.gdal.org) driver will be used in order to decode the image, supporting
    the following formats: [Raster](http://www.gdal.org/formats_list.html),
    [Vector](http://www.gdal.org/ogr_formats.html).
-   If EXIF information is embedded in the image file, the EXIF orientation will be taken into account
    and thus the image will be rotated accordingly except if the flags @ref IMREAD_IGNORE_ORIENTATION
    or @ref IMREAD_UNCHANGED are passed.
-   Use the IMREAD_UNCHANGED flag to keep the floating point values from PFM image.
-   By default number of pixels must be less than 2^30. Limit can be set using system
    variable OPENCV_IO_MAX_IMAGE_PIXELS

@param filename Name of file to be loaded.
@param flags Flag that can take values of cv::ImreadModes',0,'Mat',['String','filename','',['/C','/Ref']],['int','flags','IMREAD_COLOR',[]]],
['','imreadmulti','@brief Loads a multi-page image from a file.

The function imreadmulti loads a multi-page image from the specified file into a vector of Mat objects.
@param filename Name of file to be loaded.
@param flags Flag that can take values of cv::ImreadModes, default with cv::IMREAD_ANYCOLOR.
@param mats A vector of Mat objects holding each page, if more than one.
@sa cv::imread',0,'bool',['String','filename','',['/C','/Ref']],['vector_Mat','mats','',['/O','/Ref']],['int','flags','IMREAD_ANYCOLOR',[]]],
['','imreadmulti','@brief Loads a of images of a multi-page image from a file.

The function imreadmulti loads a specified range from a multi-page image from the specified file into a vector of Mat objects.
@param filename Name of file to be loaded.
@param start Start index of the image to load
@param count Count number of images to load
@param flags Flag that can take values of cv::ImreadModes, default with cv::IMREAD_ANYCOLOR.
@param mats A vector of Mat objects holding each page, if more than one.
@sa cv::imread',0,'bool',['String','filename','',['/C','/Ref']],['vector_Mat','mats','',['/O','/Ref']],['int','start','',[]],['int','count','',[]],['int','flags','IMREAD_ANYCOLOR',[]]],
['','imcount','@brief Returns the number of images inside the give file

The function imcount will return the number of pages in a multi-page image, or 1 for single-page images
@param filename Name of file to be loaded.
@param flags Flag that can take values of cv::ImreadModes, default with cv::IMREAD_ANYCOLOR.',0,'size_t',['String','filename','',['/C','/Ref']],['int','flags','IMREAD_ANYCOLOR',[]]],
['','imwrite','@brief Saves an image to a specified file.

The function imwrite saves the image to the specified file. The image format is chosen based on the
filename extension (see cv::imread for the list of extensions). In general, only 8-bit
single-channel or 3-channel (with \'BGR\' channel order) images
can be saved using this function, with these exceptions:

- 16-bit unsigned (CV_16U) images can be saved in the case of PNG, JPEG 2000, and TIFF formats
- 32-bit float (CV_32F) images can be saved in PFM, TIFF, OpenEXR, and Radiance HDR formats;
  3-channel (CV_32FC3) TIFF images will be saved using the LogLuv high dynamic range encoding
  (4 bytes per pixel)
- PNG images with an alpha channel can be saved using this function. To do this, create
8-bit (or 16-bit) 4-channel image BGRA, where the alpha channel goes last. Fully transparent pixels
should have alpha set to 0, fully opaque pixels should have alpha set to 255/65535 (see the code sample below).
- Multiple images (vector of Mat) can be saved in TIFF format (see the code sample below).

If the image format is not supported, the image will be converted to 8-bit unsigned (CV_8U) and saved that way.

If the format, depth or channel order is different, use
Mat::convertTo and cv::cvtColor to convert it before saving. Or, use the universal FileStorage I/O
functions to save the image to XML or YAML format.

The sample below shows how to create a BGRA image, how to set custom compression parameters and save it to a PNG file.
It also demonstrates how to save multiple images in a TIFF file:
@include snippets/imgcodecs_imwrite.cpp
@param filename Name of the file.
@param img (Mat or vector of Mat) Image or Images to be saved.
@param params Format-specific parameters encoded as pairs (paramId_1, paramValue_1, paramId_2, paramValue_2, ... .) see cv::ImwriteFlags',0,'bool',['String','filename','',['/C','/Ref']],['Mat','img','',[]],['vector_int','params','std::vector<int>()',['/C','/Ref']]],
['','imwritemulti','',0,'bool',['String','filename','',['/C','/Ref']],['vector_Mat','img','',[]],['vector_int','params','std::vector<int>()',['/C','/Ref']]],
['','imdecode','@brief Reads an image from a buffer in memory.

The function imdecode reads an image from the specified buffer in the memory. If the buffer is too short or
contains invalid data, the function returns an empty matrix ( Mat::data==NULL ).

See cv::imread for the list of supported formats and flags description.

@note In the case of color images, the decoded images will have the channels stored in **B G R** order.
@param buf Input array or vector of bytes.
@param flags The same flags as in cv::imread, see cv::ImreadModes.',0,'Mat',['Mat','buf','',[]],['int','flags','',[]]],
['','imencode','@brief Encodes an image into a memory buffer.

The function imencode compresses the image and stores it in the memory buffer that is resized to fit the
result. See cv::imwrite for the list of supported formats and flags description.

@param ext File extension that defines the output format.
@param img Image to be written.
@param buf Output buffer resized to fit the compressed image.
@param params Format-specific parameters. See cv::imwrite and cv::ImwriteFlags.',0,'bool',['String','ext','',['/C','/Ref']],['Mat','img','',[]],['vector_uchar','buf','',['/O','/Ref']],['vector_int','params','std::vector<int>()',['/C','/Ref']]],
['','haveImageReader','@brief Returns true if the specified image can be decoded by OpenCV

@param filename File name of the image',0,'bool',['String','filename','',['/C','/Ref']]],
['','haveImageWriter','@brief Returns true if an image with the specified filename can be encoded by OpenCV

 @param filename File name of the image',0,'bool',['String','filename','',['/C','/Ref']]],
);
