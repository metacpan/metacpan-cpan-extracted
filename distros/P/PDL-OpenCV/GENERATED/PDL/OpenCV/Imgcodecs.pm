#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::OpenCV::Imgcodecs;

our @EXPORT_OK = qw( imread imreadmulti imreadmulti2 imcount imwrite imwritemulti imdecode imencode haveImageReader haveImageWriter IMREAD_UNCHANGED IMREAD_GRAYSCALE IMREAD_COLOR IMREAD_ANYDEPTH IMREAD_ANYCOLOR IMREAD_LOAD_GDAL IMREAD_REDUCED_GRAYSCALE_2 IMREAD_REDUCED_COLOR_2 IMREAD_REDUCED_GRAYSCALE_4 IMREAD_REDUCED_COLOR_4 IMREAD_REDUCED_GRAYSCALE_8 IMREAD_REDUCED_COLOR_8 IMREAD_IGNORE_ORIENTATION IMWRITE_JPEG_QUALITY IMWRITE_JPEG_PROGRESSIVE IMWRITE_JPEG_OPTIMIZE IMWRITE_JPEG_RST_INTERVAL IMWRITE_JPEG_LUMA_QUALITY IMWRITE_JPEG_CHROMA_QUALITY IMWRITE_PNG_COMPRESSION IMWRITE_PNG_STRATEGY IMWRITE_PNG_BILEVEL IMWRITE_PXM_BINARY IMWRITE_EXR_TYPE IMWRITE_EXR_COMPRESSION IMWRITE_WEBP_QUALITY IMWRITE_PAM_TUPLETYPE IMWRITE_TIFF_RESUNIT IMWRITE_TIFF_XDPI IMWRITE_TIFF_YDPI IMWRITE_TIFF_COMPRESSION IMWRITE_JPEG2000_COMPRESSION_X1000 IMWRITE_EXR_TYPE_HALF IMWRITE_EXR_TYPE_FLOAT IMWRITE_EXR_COMPRESSION_NO IMWRITE_EXR_COMPRESSION_RLE IMWRITE_EXR_COMPRESSION_ZIPS IMWRITE_EXR_COMPRESSION_ZIP IMWRITE_EXR_COMPRESSION_PIZ IMWRITE_EXR_COMPRESSION_PXR24 IMWRITE_EXR_COMPRESSION_B44 IMWRITE_EXR_COMPRESSION_B44A IMWRITE_EXR_COMPRESSION_DWAA IMWRITE_EXR_COMPRESSION_DWAB IMWRITE_PNG_STRATEGY_DEFAULT IMWRITE_PNG_STRATEGY_FILTERED IMWRITE_PNG_STRATEGY_HUFFMAN_ONLY IMWRITE_PNG_STRATEGY_RLE IMWRITE_PNG_STRATEGY_FIXED IMWRITE_PAM_FORMAT_NULL IMWRITE_PAM_FORMAT_BLACKANDWHITE IMWRITE_PAM_FORMAT_GRAYSCALE IMWRITE_PAM_FORMAT_GRAYSCALE_ALPHA IMWRITE_PAM_FORMAT_RGB IMWRITE_PAM_FORMAT_RGB_ALPHA );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::OpenCV::Imgcodecs ;






#line 364 "../genpp.pl"

=head1 NAME

PDL::OpenCV::Imgcodecs - PDL bindings for OpenCV Imgcodecs

=head1 SYNOPSIS

 use PDL::OpenCV::Imgcodecs;

=cut

use strict;
use warnings;
use PDL::OpenCV; # get constants
#line 40 "Imgcodecs.pm"






=head1 FUNCTIONS

=cut




#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 imread

=for sig

  Signature: (int [phys] flags(); [o,phys] res(l3,c3,r3); StringWrapper* filename)

=for ref

Loads an image from a file. NO BROADCASTING.

=for example

 $res = imread($filename); # with defaults
 $res = imread($filename,$flags);

@anchor imread
The function imread loads an image from the specified file and returns it. If the image cannot be
read (because of missing file, improper permissions, unsupported or invalid format), the function
returns an empty matrix ( Mat::data==NULL ).
Currently, the following file formats are supported:
-   Windows bitmaps - *.bmp, *.dib (always supported)
-   JPEG files - *.jpeg, *.jpg, *.jpe (see the *Note* section)
-   JPEG 2000 files - *.jp2 (see the *Note* section)
-   Portable Network Graphics - *.png (see the *Note* section)
-   WebP - *.webp (see the *Note* section)
-   Portable image format - *.pbm, *.pgm, *.ppm *.pxm, *.pnm (always supported)
-   PFM files - *.pfm (see the *Note* section)
-   Sun rasters - *.sr, *.ras (always supported)
-   TIFF files - *.tiff, *.tif (see the *Note* section)
-   OpenEXR Image files - *.exr (see the *Note* section)
-   Radiance HDR - *.hdr, *.pic (always supported)
-   Raster and Vector geospatial data supported by GDAL (see the *Note* section)
@note
-   The function determines the type of an image by the content, not by the file extension.
-   In the case of color images, the decoded images will have the channels stored in **B G R** order.
-   When using IMREAD_GRAYSCALE, the codec's internal grayscale conversion will be used, if available.
Results may differ to the output of cvtColor()
-   On Microsoft Windows* OS and MacOSX*, the codecs shipped with an OpenCV image (libjpeg,
libpng, libtiff, and libjasper) are used by default. So, OpenCV can always read JPEGs, PNGs,
and TIFFs. On MacOSX, there is also an option to use native MacOSX image readers. But beware
that currently these native image loaders give images with different pixel values because of
the color management embedded into MacOSX.
-   On Linux*, BSD flavors and other Unix-like open-source operating systems, OpenCV looks for
codecs supplied with an OS image. Install the relevant packages (do not forget the development
files, for example, "libjpeg-dev", in Debian* and Ubuntu*) to get the codec support or turn
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

Parameters:

=over

=item filename

Name of file to be loaded.

=item flags

Flag that can take values of cv::ImreadModes

=back


=for bad

imread ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 137 "Imgcodecs.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgcodecs::imread {
  barf "Usage: PDL::OpenCV::Imgcodecs::imread(\$filename,\$flags)\n" if @_ < 1;
  my ($filename,$flags) = @_;
  my ($res);
  $flags = IMREAD_COLOR() if !defined $flags;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgcodecs::_imread_int($flags,$res,$filename);
  !wantarray ? $res : ($res)
}
#line 152 "Imgcodecs.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*imread = \&PDL::OpenCV::Imgcodecs::imread;
#line 159 "Imgcodecs.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 imreadmulti

=for sig

  Signature: (int [phys] flags(); byte [o,phys] res(); StringWrapper* filename; [o] vector_MatWrapper * mats)

=for ref

Loads a multi-page image from a file.

=for example

 ($mats,$res) = imreadmulti($filename); # with defaults
 ($mats,$res) = imreadmulti($filename,$flags);

The function imreadmulti loads a multi-page image from the specified file into a vector of Mat objects.

Parameters:

=over

=item filename

Name of file to be loaded.

=item flags

Flag that can take values of cv::ImreadModes, default with cv::IMREAD_ANYCOLOR.

=item mats

A vector of Mat objects holding each page, if more than one.

=back

See also:
cv::imread


=for bad

imreadmulti ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 213 "Imgcodecs.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgcodecs::imreadmulti {
  barf "Usage: PDL::OpenCV::Imgcodecs::imreadmulti(\$filename,\$flags)\n" if @_ < 1;
  my ($filename,$flags) = @_;
  my ($mats,$res);
  $flags = IMREAD_ANYCOLOR() if !defined $flags;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgcodecs::_imreadmulti_int($flags,$res,$filename,$mats);
  !wantarray ? $res : ($mats,$res)
}
#line 228 "Imgcodecs.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*imreadmulti = \&PDL::OpenCV::Imgcodecs::imreadmulti;
#line 235 "Imgcodecs.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 imreadmulti2

=for sig

  Signature: (int [phys] start(); int [phys] count(); int [phys] flags(); byte [o,phys] res(); StringWrapper* filename; [o] vector_MatWrapper * mats)

=for ref

Loads a of images of a multi-page image from a file.

=for example

 ($mats,$res) = imreadmulti2($filename,$start,$count); # with defaults
 ($mats,$res) = imreadmulti2($filename,$start,$count,$flags);

The function imreadmulti loads a specified range from a multi-page image from the specified file into a vector of Mat objects.

Parameters:

=over

=item filename

Name of file to be loaded.

=item start

Start index of the image to load

=item count

Count number of images to load

=item flags

Flag that can take values of cv::ImreadModes, default with cv::IMREAD_ANYCOLOR.

=item mats

A vector of Mat objects holding each page, if more than one.

=back

See also:
cv::imread


=for bad

imreadmulti2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 297 "Imgcodecs.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgcodecs::imreadmulti2 {
  barf "Usage: PDL::OpenCV::Imgcodecs::imreadmulti2(\$filename,\$start,\$count,\$flags)\n" if @_ < 3;
  my ($filename,$start,$count,$flags) = @_;
  my ($mats,$res);
  $flags = IMREAD_ANYCOLOR() if !defined $flags;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgcodecs::_imreadmulti2_int($start,$count,$flags,$res,$filename,$mats);
  !wantarray ? $res : ($mats,$res)
}
#line 312 "Imgcodecs.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*imreadmulti2 = \&PDL::OpenCV::Imgcodecs::imreadmulti2;
#line 319 "Imgcodecs.pm"



#line 274 "../genpp.pl"

=head2 imcount

=for ref

Returns the number of images inside the give file

=for example

 $res = imcount($filename); # with defaults
 $res = imcount($filename,$flags);

The function imcount will return the number of pages in a multi-page image, or 1 for single-page images

Parameters:

=over

=item filename

Name of file to be loaded.

=item flags

Flag that can take values of cv::ImreadModes, default with cv::IMREAD_ANYCOLOR.

=back


=cut
#line 354 "Imgcodecs.pm"



#line 275 "../genpp.pl"

*imcount = \&PDL::OpenCV::Imgcodecs::imcount;
#line 361 "Imgcodecs.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 imwrite

=for sig

  Signature: ([phys] img(l2,c2,r2); int [phys] params(n3d0); byte [o,phys] res(); StringWrapper* filename)

=for ref

Saves an image to a specified file.

=for example

 $res = imwrite($filename,$img); # with defaults
 $res = imwrite($filename,$img,$params);

The function imwrite saves the image to the specified file. The image format is chosen based on the
filename extension (see cv::imread for the list of extensions). In general, only 8-bit
single-channel or 3-channel (with 'BGR' channel order) images
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

Parameters:

=over

=item filename

Name of the file.

=item img

(Mat or vector of Mat) Image or Images to be saved.

=item params

Format-specific parameters encoded as pairs (paramId_1, paramValue_1, paramId_2, paramValue_2, ... .) see cv::ImwriteFlags

=back


=for bad

imwrite ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 430 "Imgcodecs.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgcodecs::imwrite {
  barf "Usage: PDL::OpenCV::Imgcodecs::imwrite(\$filename,\$img,\$params)\n" if @_ < 2;
  my ($filename,$img,$params) = @_;
  my ($res);
  $params = empty(long) if !defined $params;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgcodecs::_imwrite_int($img,$params,$res,$filename);
  !wantarray ? $res : ($res)
}
#line 445 "Imgcodecs.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*imwrite = \&PDL::OpenCV::Imgcodecs::imwrite;
#line 452 "Imgcodecs.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 imwritemulti

=for sig

  Signature: (int [phys] params(n3d0); byte [o,phys] res(); StringWrapper* filename; vector_MatWrapper * img)

=for ref

=for example

 $res = imwritemulti($filename,$img); # with defaults
 $res = imwritemulti($filename,$img,$params);


=for bad

imwritemulti ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 481 "Imgcodecs.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgcodecs::imwritemulti {
  barf "Usage: PDL::OpenCV::Imgcodecs::imwritemulti(\$filename,\$img,\$params)\n" if @_ < 2;
  my ($filename,$img,$params) = @_;
  my ($res);
  $params = empty(long) if !defined $params;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgcodecs::_imwritemulti_int($params,$res,$filename,$img);
  !wantarray ? $res : ($res)
}
#line 496 "Imgcodecs.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*imwritemulti = \&PDL::OpenCV::Imgcodecs::imwritemulti;
#line 503 "Imgcodecs.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 imdecode

=for sig

  Signature: ([phys] buf(l1,c1,r1); int [phys] flags(); [o,phys] res(l3,c3,r3))

=for ref

Reads an image from a buffer in memory. NO BROADCASTING.

=for example

 $res = imdecode($buf,$flags);

The function imdecode reads an image from the specified buffer in the memory. If the buffer is too short or
contains invalid data, the function returns an empty matrix ( Mat::data==NULL ).
See cv::imread for the list of supported formats and flags description.
@note In the case of color images, the decoded images will have the channels stored in **B G R** order.

Parameters:

=over

=item buf

Input array or vector of bytes.

=item flags

The same flags as in cv::imread, see cv::ImreadModes.

=back


=for bad

imdecode ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 552 "Imgcodecs.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgcodecs::imdecode {
  barf "Usage: PDL::OpenCV::Imgcodecs::imdecode(\$buf,\$flags)\n" if @_ < 2;
  my ($buf,$flags) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgcodecs::_imdecode_int($buf,$flags,$res);
  !wantarray ? $res : ($res)
}
#line 566 "Imgcodecs.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*imdecode = \&PDL::OpenCV::Imgcodecs::imdecode;
#line 573 "Imgcodecs.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 imencode

=for sig

  Signature: ([phys] img(l2,c2,r2); byte [o,phys] buf(n3d0); int [phys] params(n4d0); byte [o,phys] res(); StringWrapper* ext)

=for ref

Encodes an image into a memory buffer. NO BROADCASTING.

=for example

 ($buf,$res) = imencode($ext,$img); # with defaults
 ($buf,$res) = imencode($ext,$img,$params);

The function imencode compresses the image and stores it in the memory buffer that is resized to fit the
result. See cv::imwrite for the list of supported formats and flags description.

Parameters:

=over

=item ext

File extension that defines the output format.

=item img

Image to be written.

=item buf

Output buffer resized to fit the compressed image.

=item params

Format-specific parameters. See cv::imwrite and cv::ImwriteFlags.

=back


=for bad

imencode ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 629 "Imgcodecs.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Imgcodecs::imencode {
  barf "Usage: PDL::OpenCV::Imgcodecs::imencode(\$ext,\$img,\$params)\n" if @_ < 2;
  my ($ext,$img,$params) = @_;
  my ($buf,$res);
  $buf = PDL->null if !defined $buf;
  $params = empty(long) if !defined $params;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Imgcodecs::_imencode_int($img,$buf,$params,$res,$ext);
  !wantarray ? $res : ($buf,$res)
}
#line 645 "Imgcodecs.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*imencode = \&PDL::OpenCV::Imgcodecs::imencode;
#line 652 "Imgcodecs.pm"



#line 274 "../genpp.pl"

=head2 haveImageReader

=for ref

Returns true if the specified image can be decoded by OpenCV

=for example

 $res = haveImageReader($filename);

Parameters:

=over

=item filename

File name of the image

=back


=cut
#line 680 "Imgcodecs.pm"



#line 275 "../genpp.pl"

*haveImageReader = \&PDL::OpenCV::Imgcodecs::haveImageReader;
#line 687 "Imgcodecs.pm"



#line 274 "../genpp.pl"

=head2 haveImageWriter

=for ref

Returns true if an image with the specified filename can be encoded by OpenCV

=for example

 $res = haveImageWriter($filename);

Parameters:

=over

=item filename

File name of the image

=back


=cut
#line 715 "Imgcodecs.pm"



#line 275 "../genpp.pl"

*haveImageWriter = \&PDL::OpenCV::Imgcodecs::haveImageWriter;
#line 722 "Imgcodecs.pm"



#line 441 "../genpp.pl"

=head1 CONSTANTS

=over

=item PDL::OpenCV::Imgcodecs::IMREAD_UNCHANGED()

=item PDL::OpenCV::Imgcodecs::IMREAD_GRAYSCALE()

=item PDL::OpenCV::Imgcodecs::IMREAD_COLOR()

=item PDL::OpenCV::Imgcodecs::IMREAD_ANYDEPTH()

=item PDL::OpenCV::Imgcodecs::IMREAD_ANYCOLOR()

=item PDL::OpenCV::Imgcodecs::IMREAD_LOAD_GDAL()

=item PDL::OpenCV::Imgcodecs::IMREAD_REDUCED_GRAYSCALE_2()

=item PDL::OpenCV::Imgcodecs::IMREAD_REDUCED_COLOR_2()

=item PDL::OpenCV::Imgcodecs::IMREAD_REDUCED_GRAYSCALE_4()

=item PDL::OpenCV::Imgcodecs::IMREAD_REDUCED_COLOR_4()

=item PDL::OpenCV::Imgcodecs::IMREAD_REDUCED_GRAYSCALE_8()

=item PDL::OpenCV::Imgcodecs::IMREAD_REDUCED_COLOR_8()

=item PDL::OpenCV::Imgcodecs::IMREAD_IGNORE_ORIENTATION()

=item PDL::OpenCV::Imgcodecs::IMWRITE_JPEG_QUALITY()

=item PDL::OpenCV::Imgcodecs::IMWRITE_JPEG_PROGRESSIVE()

=item PDL::OpenCV::Imgcodecs::IMWRITE_JPEG_OPTIMIZE()

=item PDL::OpenCV::Imgcodecs::IMWRITE_JPEG_RST_INTERVAL()

=item PDL::OpenCV::Imgcodecs::IMWRITE_JPEG_LUMA_QUALITY()

=item PDL::OpenCV::Imgcodecs::IMWRITE_JPEG_CHROMA_QUALITY()

=item PDL::OpenCV::Imgcodecs::IMWRITE_PNG_COMPRESSION()

=item PDL::OpenCV::Imgcodecs::IMWRITE_PNG_STRATEGY()

=item PDL::OpenCV::Imgcodecs::IMWRITE_PNG_BILEVEL()

=item PDL::OpenCV::Imgcodecs::IMWRITE_PXM_BINARY()

=item PDL::OpenCV::Imgcodecs::IMWRITE_EXR_TYPE()

=item PDL::OpenCV::Imgcodecs::IMWRITE_EXR_COMPRESSION()

=item PDL::OpenCV::Imgcodecs::IMWRITE_WEBP_QUALITY()

=item PDL::OpenCV::Imgcodecs::IMWRITE_PAM_TUPLETYPE()

=item PDL::OpenCV::Imgcodecs::IMWRITE_TIFF_RESUNIT()

=item PDL::OpenCV::Imgcodecs::IMWRITE_TIFF_XDPI()

=item PDL::OpenCV::Imgcodecs::IMWRITE_TIFF_YDPI()

=item PDL::OpenCV::Imgcodecs::IMWRITE_TIFF_COMPRESSION()

=item PDL::OpenCV::Imgcodecs::IMWRITE_JPEG2000_COMPRESSION_X1000()

=item PDL::OpenCV::Imgcodecs::IMWRITE_EXR_TYPE_HALF()

=item PDL::OpenCV::Imgcodecs::IMWRITE_EXR_TYPE_FLOAT()

=item PDL::OpenCV::Imgcodecs::IMWRITE_EXR_COMPRESSION_NO()

=item PDL::OpenCV::Imgcodecs::IMWRITE_EXR_COMPRESSION_RLE()

=item PDL::OpenCV::Imgcodecs::IMWRITE_EXR_COMPRESSION_ZIPS()

=item PDL::OpenCV::Imgcodecs::IMWRITE_EXR_COMPRESSION_ZIP()

=item PDL::OpenCV::Imgcodecs::IMWRITE_EXR_COMPRESSION_PIZ()

=item PDL::OpenCV::Imgcodecs::IMWRITE_EXR_COMPRESSION_PXR24()

=item PDL::OpenCV::Imgcodecs::IMWRITE_EXR_COMPRESSION_B44()

=item PDL::OpenCV::Imgcodecs::IMWRITE_EXR_COMPRESSION_B44A()

=item PDL::OpenCV::Imgcodecs::IMWRITE_EXR_COMPRESSION_DWAA()

=item PDL::OpenCV::Imgcodecs::IMWRITE_EXR_COMPRESSION_DWAB()

=item PDL::OpenCV::Imgcodecs::IMWRITE_PNG_STRATEGY_DEFAULT()

=item PDL::OpenCV::Imgcodecs::IMWRITE_PNG_STRATEGY_FILTERED()

=item PDL::OpenCV::Imgcodecs::IMWRITE_PNG_STRATEGY_HUFFMAN_ONLY()

=item PDL::OpenCV::Imgcodecs::IMWRITE_PNG_STRATEGY_RLE()

=item PDL::OpenCV::Imgcodecs::IMWRITE_PNG_STRATEGY_FIXED()

=item PDL::OpenCV::Imgcodecs::IMWRITE_PAM_FORMAT_NULL()

=item PDL::OpenCV::Imgcodecs::IMWRITE_PAM_FORMAT_BLACKANDWHITE()

=item PDL::OpenCV::Imgcodecs::IMWRITE_PAM_FORMAT_GRAYSCALE()

=item PDL::OpenCV::Imgcodecs::IMWRITE_PAM_FORMAT_GRAYSCALE_ALPHA()

=item PDL::OpenCV::Imgcodecs::IMWRITE_PAM_FORMAT_RGB()

=item PDL::OpenCV::Imgcodecs::IMWRITE_PAM_FORMAT_RGB_ALPHA()


=back

=cut
#line 846 "Imgcodecs.pm"






# Exit with OK status

1;
