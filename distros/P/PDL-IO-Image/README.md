# NAME

PDL::IO::Image - Load/save bitmap from/to PDL (via FreeImage library)

# SYNOPSIS

Functional interface:

    use 5.010;
    use PDL;
    use PDL::IO::Image;

    my $pdl1 = rimage('picture.tiff');
    say $pdl1->info;       # PDL: Byte D [400,300] ... width 400, height 300
    # do some hacking with $piddle
    wimage($pdl1, 'output.tiff');
    # you can also use wimage as PDL's method
    $pdl1->wimage('another-output.png');

    my ($pixels, $palette) = rimage('picture-256colors.gif', { palette=>1 });
    say $pixels->info;     # PDL: Byte D [400,300] ... width 400, height 300
    say $palette->info;    # PDL: Byte D [3,256]
    # do some hacking with $pixels and $palette
    wimage($pixels, 'output.gif', { palette=>$palette });

    # load specific image (page) from multi-page file
    my $pdl2 = rimage('picture.tiff', { page=>0 });

    # load specific image + flit vertically before converting to piddle
    my $pdl3 = rimage('picture.tiff', { flip=>'V' });

    # random pixels + ramdom colors (RGBA - 35 bits per pixel)
    (random(400, 300, 4) * 256)->byte->wimage("random.png");

    my $pix1 = (sin(0.25 * rvals(101, 101)) * 128 + 127)->byte;
    say $pix1->info;       # PDL: Byte D [101,101]
    my $pal1 = yvals(3, 256)->byte;
    $pal1->slice("(2),:") .= 0; # set blue part of palette to zero
    say $pal1->info;       # PDL: Byte D [3,256]
    $pix1->wimage("wave1_grayscale.gif"); # default is grayscale palette
    $pix1->wimage("wave2_yellow.gif", { palette=>$pal1 });

    # rotate /rescale before saving
    my $pix2 = (sin(0.25 * xvals(101, 101)) * 128 + 127)->byte;
    $pix2->wimage("wave3_grayscale.gif", { rescale=>[16,16] }); # rescale to 16x16 pixels
    $pix2->wimage("wave4_grayscale.gif", { rescale_pct=>50 }); # rescale to 50%
    $pix2->wimage("wave5_grayscale.gif", { rotate=>33.33 });

Object oriented (OO) interface:

    use 5.010;
    use PDL;
    use PDL::IO::Image;

    # create PDL::IO::Image object from file
    my $pimage1 = PDL::IO::Image->new_from_file('picture.gif');
    say 'width       = ' . $pimage1->get_width;
    say 'height      = ' . $pimage1->get_height;
    say 'image_type  = ' . $pimage1->get_image_type;
    say 'color_type  = ' . $pimage1->get_color_type;
    say 'colors_used = ' . $pimage1->get_colors_used;
    say 'bpp         = ' . $pimage1->get_bpp;
    # you can do some operations with PDL::IO::Image object
    $pimage1->flip_vertical;
    # export pixels from PDL::IO::Image object content into a piddle
    my $pix_pdl = $pimage1->pixels_to_pdl();
    # export palette from PDL::IO::Image object content into a piddle
    my $pal_pdl = $pimage1->palette_to_pdl();

    # let us have a piddle with pixel data
    my $wave_pixels = (sin(0.008 * xvals(2001, 2001)) * 128 + 127)->byte;
    # create PDL::IO::Image object from PDL piddle
    my $pimage2 = PDL::IO::Image->new_from_pdl($wave_pixels);
    # do some transformation with PDL::IO::Image object
    $pimage2->rotate(45);
    $pimage2->rescale(200, 200);
    # export PDL::IO::Image object content into a image file
    $pimage2->save("output.jpg");

# DESCRIPTION

PDL::IO::Image implements I/O for a number of popular image formats. It is based on
["FreeImage library"](http://freeimage.sourceforge.net/) however there is no need to install
FreeImage library on your system because PDL::IO::Image uses [Alien::FreeImage](https://metacpan.org/pod/Alien::FreeImage) module which
handles building FreeImage library from sources (works on Windows, Cygwin, Mac OS X, Linux and other UNIXes).

Check also an excellent FreeImage documentation at [http://freeimage.sourceforge.net/documentation.html](http://freeimage.sourceforge.net/documentation.html)

## Supported file formats

This module supports loading (["new\_from\_file"](#new_from_file) or ["rimage"](#rimage)) and saving (["save"](#save) or ["wimage"](#wimage))
of the following formats (note that not all formats support writing - see `R/W` column).

        BMP  R/W  Windows or OS/2 Bitmap [extensions: bmp]
        ICO  R/W  Windows Icon [extensions: ico]
       JPEG  R/W  JPEG - JFIF Compliant [extensions: jpg,jif,jpeg,jpe]
        JNG  R/W  JPEG Network Graphics [extensions: jng]
      KOALA  R/-  C64 Koala Graphics [extensions: koa]
        IFF  R/-  IFF Interleaved Bitmap [extensions: iff,lbm]
        MNG  R/-  Multiple-image Network Graphics [extensions: mng]
        PBM  R/W  Portable Bitmap (ASCII) [extensions: pbm]
     PBMRAW  R/W  Portable Bitmap (RAW) [extensions: pbm]
        PCD  R/-  Kodak PhotoCD [extensions: pcd]
        PCX  R/-  Zsoft Paintbrush [extensions: pcx]
        PGM  R/W  Portable Greymap (ASCII) [extensions: pgm]
     PGMRAW  R/W  Portable Greymap (RAW) [extensions: pgm]
        PNG  R/W  Portable Network Graphics [extensions: png]
        PPM  R/W  Portable Pixelmap (ASCII) [extensions: ppm]
     PPMRAW  R/W  Portable Pixelmap (RAW) [extensions: ppm]
        RAS  R/-  Sun Raster Image [extensions: ras]
      TARGA  R/W  Truevision Targa [extensions: tga,targa]
       TIFF  R/W  Tagged Image File Format [extensions: tif,tiff]
       WBMP  R/W  Wireless Bitmap [extensions: wap,wbmp,wbm]
        PSD  R/-  Adobe Photoshop [extensions: psd]
        CUT  R/-  Dr. Halo [extensions: cut]
        XBM  R/-  X11 Bitmap Format [extensions: xbm]
        XPM  R/W  X11 Pixmap Format [extensions: xpm]
        DDS  R/-  DirectX Surface [extensions: dds]
        GIF  R/W  Graphics Interchange Format [extensions: gif]
        HDR  R/W  High Dynamic Range Image [extensions: hdr]
         G3  R/-  Raw fax format CCITT G.3 [extensions: g3]
        SGI  R/-  SGI Image Format [extensions: sgi,rgb,rgba,bw]
        EXR  R/W  ILM OpenEXR [extensions: exr]
        J2K  R/W  JPEG-2000 codestream [extensions: j2k,j2c]
        JP2  R/W  JPEG-2000 File Format [extensions: jp2]
        PFM  R/W  Portable floatmap [extensions: pfm]
       PICT  R/-  Macintosh PICT [extensions: pct,pict,pic]
        RAW  R/-  RAW camera image [extensions: 3fr,arw,bay,bmq,cap,cine,
                      cr2,crw,cs1,dc2, dcr,drf,dsc,dng,erf,fff,ia,iiq,k25,
                      kc2,kdc,mdc,mef,mos,mrw,nef,nrw,orf,pef, ptx,pxn,qtk,
                      raf,raw,rdc,rw2,rwl,rwz,sr2,srf,srw,sti]
       WEBP  R/W  Google WebP image format [extensions: webp]
    JPEG-XR  R/W  JPEG XR image format [extensions: jxr,wdp,hdp]

**IMPORTANT** the strings in the first column (e.g. `'BMP'`, `'JPEG'`, `'PNG'`) are used as a format identifier in
["new\_from\_file"](#new_from_file), ["save"](#save), ["rimage"](#rimage), ["wimage"](#wimage) (+some other methods).

The supported format may differ depending on FreeImage library version. You can list what exactly you FreeImage library
can handle like this:

    for (PDL::IO::Image->format_list) {
      my $r = PDL::IO::Image->format_can_read($_) ? 'R' : '-';
      my $w = PDL::IO::Image->format_can_write($_) ? 'W' : '-';
      my $e = PDL::IO::Image->format_extension_list($_);
      my $d = PDL::IO::Image->format_description($_);
      printf("% 7s  %s/%s  %s [extensions: %s]\n", $_, $r, $w, $d, $e);
    }

## Supported image types

This module can handle the following image types.

    BITMAP   Standard image: 1-, 4-, 8-, 16-, 24-, 32-bit
    UINT16   Array of unsigned short: unsigned 16-bit
    INT16    Array of short: signed 16-bit
    UINT32   Array of unsigned long: unsigned 32-bit
    INT32    Array of long: signed 32-bit
    FLOAT    Array of float: 32-bit IEEE floating point
    DOUBLE   Array of double: 64-bit IEEE floating point
    RGB16    48-bit RGB image: 3 x 16-bit
    RGBA16   64-bit RGBA image: 4 x 16-bit
    RGBF     96-bit RGB float image: 3 x 32-bit IEEE floating point
    RGBAF    128-bit RGBA float image: 4 x 32-bit IEEE floating point

Currently **NOT SUPPORTED**:

    COMPLEX  Array of FICOMPLEX: 2 x 64-bit IEEE floating point

Image type is important especially when you want to load image data from PDL piddle into a PDL::IO::Image object
(and later save to a file). Based on piddle size and piddle type the image type is detected (in ["new\_from\_pdl"](#new_from_pdl)
and ["wimage"](#wimage)).

    W .. image width
    H .. image height
    PDL Byte     [W,H]       BITMAP 1-/4-/8-bits per pixel
    PDL Byte     [W,H,3]     BITMAP 24-bits per pixel (RGB)
    PDL Byte     [W,H,4]     BITMAP 32-bits per pixel (RGBA)
    PDL Ushort   [W,H]       UINT16
    PDL Short    [W,H]       INT16
    PDL LongLong [W,H]       UINT32 (unfortunately there is no PDL Ulong type)
    PDL Long     [W,H]       INT32
    PDL Float    [W,H]       FLOAT
    PDL Double   [W,H]       DOUBLE
    PDL Ushort   [W,H,3]     RGB16
    PDL Ushort   [W,H,4]     RGBA16
    PDL Float    [W,H,3]     RGBf
    PDL Float    [W,H,4]     RGBAF

**IMPORTANT** the strings with type name (e.g. `'BITMAP'`, `'UINT16'`, `'RGBAF'`) are used as a image type
identifier in method ["convert\_image\_type"](#convert_image_type) and a return value of method ["get\_image\_type"](#get_image_type).

Not all file formats support all image formats above (especially those non-BITMAP image types). If you are in doubts use
`tiff` format for storing unusual image types.

# FUNCTIONS

The functional interface comprises of two functions ["rimage"](#rimage) and ["wimage"](#wimage) - both are exported by default.

## rimage

Loads image into a PDL piddle (or into two piddles in case of palette-based images).

    my $pixels_pdl = rimage($filename);
    #or
    my $pixels_pdl = rimage($filename, \%options);
    #or
    my ($pixels_pdl, $palette_pdl) = rimage($filename, { palette=>1 });

Internally it works in these steps:

- Create PDL::IO::Image object from the input file.
- Do optional transformations (based on `%options`) with PDL::IO::Image object.
- Export PDL::IO::Image object into a piddle(s) via ["pixels\_to\_pdl"](#pixels_to_pdl) and ["palette\_to\_pdl"](#palette_to_pdl).
- **IMPORTANT:** ["rimage"](#rimage) returns piddle(s) not a PDL::IO::Image object

Items supported in **options** hash:

- format

    String identifying file format (e.g. `'JPEG'` - for valid values see ["Supported file formats"](#supported-file-formats)), default
    is `'AUTO'` which means that format is auto detected.

- format\_flag

    Optional flag related to loading given file format - see ["new\_from\_file"](#new_from_file) method for more info.

- page

    Index (0-based) of a specific page to load from multi-page images (TIFF, ICO or animated GIF).

- flip

    Values `'H'`, `'V'` or `'HV'` specifying horizontal, vertical or horizontal+vertical flipping.
    Default: do not flip.

- rotate

    Optional floating point value with rotation angle (in degrees) - see ["rotate"](#rotate) method for more info.
    Default: do not rotate.

- convert\_image\_type

    String identifying image type (e.g. `'BITMAP'` - for valid values see ["Supported image types"](#supported-image-types)).
    Default: no conversion.

- region

    An arrayref with a region specification like `[$x1,$x2,$y1,$y2]` - see ["pixels\_to\_pdl"](#pixels_to_pdl) method for more info.
    Default: create the output piddle from the whole image.

- palette

    Values `0` (default) or `1` - whether to load (or not) color lookup table (aka LUT).

## wimage

Write PDL piddle(s) into a image file.

    $pixels_pdl->wimage($filename);
    #or
    $pixels_pdl->wimage($filename, \%options);

    wimage($pixels_pdl, $filename);
    #or
    wimage($pixels_pdl, $filename, \%options);

Internally it works in these steps:

- Create PDL::IO::Image object from the `$pixels_piddle` (+ `$palette_piddle` passed as `palette` option).
- Dimensions and type of `$pixels_piddle` must comply with ["Supported image types"](#supported-image-types).
- Do optional transformations (based on `%options`) with PDL::IO::Image object.
- Export PDL::IO::Image object into a image file via ["save"](#save) method.

Items supported in **options** hash:

- format

    String identifying file format (e.g. `'JPEG'` - for valid values see ["Supported file formats"](#supported-file-formats)), default
    is `'AUTO'` which means that format is auto detected from extension of `$filename`.

- format\_flag

    Optional flag related to saving given file format - see ["save"](#save) method for more info.

- palette

    Optional PDL piddle with color palette (has to be `PDL Byte[3,N]` where 0 < N <= 256) containing RGB triplets.

- flip

    Values `'H'`, `'V'` or `'HV'` specifying horizontal, vertical or horizontal+vertical flipping.
    Default: do not flip.

- rotate

    Optional floating point value with rotation angle (in degrees) - see ["rotate"](#rotate) method for more info.
    Default: do not rotate.

- rescale

    Optional arrayref with rescale specification (in pixels) e.g. `[$new_w, $new_h]` - see ["rescale"](#rescale) method for more info.
    Default: do not rescale.

- rescale\_pct

    Optional floating point value with rescale ratio in percent - see ["rescale\_pct"](#rescale_pct) method for more info.
    Default: do not rescale.

- convert\_image\_type

    String identifying image type (e.g. `'BITMAP'` - for valid values see ["Supported image types"](#supported-image-types)).
    Default: no conversion.

# METHODS

## new\_from\_file

Create PDL::IO::Image object from image file.

    my $pimage = IO::PDL::Image->new_from_file($filename);
    #or
    my $pimage = IO::PDL::Image->new_from_file($filename, $format);
    #or
    my $pimage = IO::PDL::Image->new_from_file($filename, $format, $format_flag);
    #or
    my $pimage = IO::PDL::Image->new_from_file($filename, $format, $format_flag, $page);

    #if you have image file content in a scalar variable you can use
    my $pimage = IO::PDL::Image->new_from_file(\$variable_with_image_data);

`$filename` - input image file name or a reference to scalar variable with imiga data.

`$format` - string identifying file format (e.g. `'JPEG'` - for valid values see ["Supported file formats"](#supported-file-formats)),
default is `'AUTO'` which means that format is auto detected (based on file header with fall-back to detection based
on file extension).

`$format_flag` - optional flag related to loading given file format, default if `0` (no extra flags). The flag can be
created by OR-ing some of available constants:

    PDL::IO::Image::GIF_LOAD256        Load the image as a 256 color image with unused
                                       palette entries, if it's 16 or 2 color
    PDL::IO::Image::GIF_PLAYBACK       'Play' the GIF to generate each frame (as 32bpp)
                                       instead of returning raw frame data when loading
    PDL::IO::Image::ICO_MAKEALPHA      Convert to 32-bit and create an alpha channel from
                                       the ANDmask when loading
    PDL::IO::Image::JPEG_FAST          Load the file as fast as possible, sacrificing some quality
    PDL::IO::Image::JPEG_ACCURATE      Load the file with the best quality, sacrificing some speed
    PDL::IO::Image::JPEG_CMYK          This flag will load CMYK bitmaps as 32-bit separated CMYK
    PDL::IO::Image::JPEG_GREYSCALE     Load and convert to a 8-bit greyscale image (faster than
                                       loading as 24-bit and converting to 8-bit)
    PDL::IO::Image::JPEG_EXIFROTATE    Load and rotate according to Exif 'Orientation' tag if available
    PDL::IO::Image::PCD_BASE           This flag will load the one sized 768 x 512
    PDL::IO::Image::PCD_BASEDIV4       This flag will load the bitmap sized 384 x 256
    PDL::IO::Image::PCD_BASEDIV16      This flag will load the bitmap sized 192 x 128
    PDL::IO::Image::PNG_IGNOREGAMMA    Avoid gamma correction on loading
    PDL::IO::Image::PSD_CMYK           Reads tags for separated CMYK (default is conversion to RGB)
    PDL::IO::Image::PSD_LAB            Reads tags for CIELab (default is conversion to RGB)
    PDL::IO::Image::RAW_PREVIEW        Try to load the embedded JPEG preview with included Exif
                                       data or default to RGB 24-bit
    PDL::IO::Image::RAW_DISPLAY        Load the file as RGB 24-bit
    PDL::IO::Image::RAW_HALFSIZE       Output a half-size color image
    PDL::IO::Image::TARGA_LOAD_RGB888  If set the loader converts RGB555 and ARGB8888 -> RGB888
    PDL::IO::Image::TIFF_CMYK          Load CMYK bitmaps as separated CMYK (default is conversion to RGB)

## new\_from\_pdl

Create PDL::IO::Image object from PDL piddle with pixel (+ optional palette) data.

    my $pimage = IO::PDL::Image->new_from_pdl($pixels_pdl);
    #or
    my $pimage = IO::PDL::Image->new_from_pdl($pixels_pdl, $palette_pdl);

`$pixels_pdl` - PDL piddle containing pixel data, dimensions and type must comply with ["Supported image types"](#supported-image-types).

`$palette_pdl` - Optional PDL piddle with color palette (has to be `PDL Byte[3,N]` where 0 < N <= 256) containing RGB triplets.

## clone

Create a copy (clone) of PDL::IO::Image object.

    my $pimage_copy = $pimage->clone();

## pixels\_to\_pdl

Export pixel data from PDL::IO::Image object into a piddle.

    my $pixels_pdl = $pimage->pixels_to_pdl;
    #or
    my $pixels_pdl = $pimage->pixels_to_pdl($x1, $x2, $y1, $y2);

`$x1, $x2, $y1, $y2` - Optional specification of image sub-region to be exported. All values are 0-based, negative
values can be used to specify boundary "from the end".

## palette\_to\_pdl

Export palette (aka LUT - color lookup table) data from PDL::IO::Image object into a piddle.

    my $palette_pdl = $pimage->palette_to_pdl;

The output piddle is ususally `PDL Byte [3, 256]`. Returns `undef` if image represented by `$pimage` does not use
palette.

## save

Export PDL::IO::Image object into a image file.

    $pimage->save($filename, $format, $flags);
    #or
    $pimage->save($filename, $format);
    #or
    $pimage->save($filename);

    #you can save the image data to a variable like this
    my $output_image;
    $pimage->save(\$output_image, $format);
    #NOTE: $format is mandatory in this case

Returns `$pimage` (self).

`$filename` - output image file name or a reference to perl scalar variable.

`$format` - string identifying file format (e.g. `'JPEG'` - for valid values see ["Supported file formats"](#supported-file-formats)),
default is `'AUTO'` which means that format is auto detected from extension of `$filename`.

`$format_flag` - optional flag related to saving given file format, default if `0` (no extra flags). The flag can be
created by OR-ing some of available constants:

    PDL::IO::Image::BMP_SAVE_RLE              Compress the bitmap using RLE when saving
    PDL::IO::Image::EXR_FLOAT                 Save data as float instead of as half (not recommended)
    PDL::IO::Image::EXR_NONE                  Save with no compression
    PDL::IO::Image::EXR_ZIP                   Save with zlib compression, in blocks of 16 scan lines
    PDL::IO::Image::EXR_PIZ                   Save with piz-based wavelet compression
    PDL::IO::Image::EXR_PXR24                 Save with lossy 24-bit float compression
    PDL::IO::Image::EXR_B44                   Save with lossy 44% float compression
    PDL::IO::Image::EXR_LC                    Save with one luminance and two chroma channels, rather than RGB (lossy)
      for J2K format: integer X in [1..512]   Save with a X:1 rate (default = 16)
      for JP2 format: integer X in [1..512]   Save with a X:1 rate (default = 16)
    PDL::IO::Image::JPEG_QUALITYSUPERB        Saves with superb quality (100:1)
    PDL::IO::Image::JPEG_QUALITYGOOD          Saves with good quality (75:1 - default)
    PDL::IO::Image::JPEG_QUALITYNORMAL        Saves with normal quality (50:1)
    PDL::IO::Image::JPEG_QUALITYAVERAGE       Saves with average quality (25:1)
    PDL::IO::Image::JPEG_QUALITYBAD           Saves with bad quality (10:1)
      for JPEG format: integer X in [0..100]  Save with quality X:1
    PDL::IO::Image::JPEG_PROGRESSIVE          Saves as a progressive JPEG file
    PDL::IO::Image::JPEG_SUBSAMPLING_411      Save with high 4x1 chroma subsampling (4:1:1)
    PDL::IO::Image::JPEG_SUBSAMPLING_420      Save with medium 2x2 chroma subsampling (4:2:0) - default value
    PDL::IO::Image::JPEG_SUBSAMPLING_422      Save with low 2x1 chroma subsampling (4:2:2)
    PDL::IO::Image::JPEG_SUBSAMPLING_444      Save with no chroma subsampling (4:4:4)
    PDL::IO::Image::JPEG_OPTIMIZE             On saving, compute optimal Huffman coding tables
    PDL::IO::Image::JPEG_BASELINE             Save basic JPEG, without metadata or any markers
      for JXR format: integer X in [1..100)   Save with quality X:1 (default = 80), using X=100 means lossless
    PDL::IO::Image::JXR_LOSSLESS              Save lossless (quality = 100)
    PDL::IO::Image::JXR_PROGRESSIVE           Saves as a progressive JPEG-XR file
    PDL::IO::Image::PNG_Z_BEST_SPEED          Save using ZLib level 1 compression (default value is 6)
    PDL::IO::Image::PNG_Z_DEFAULT_COMPRESSION Save using ZLib level 6 compression (default)
    PDL::IO::Image::PNG_Z_BEST_COMPRESSION    Save using ZLib level 9 compression (default value is 6)
    PDL::IO::Image::PNG_Z_NO_COMPRESSION      Save without ZLib compression
    PDL::IO::Image::PNG_INTERLACED            Save using Adam7 interlacing
    PDL::IO::Image::PNM_SAVE_RAW              Saves the bitmap as a binary file
    PDL::IO::Image::PNM_SAVE_ASCII            Saves the bitmap as an ASCII file
    PDL::IO::Image::TIFF_CMYK                 Stores tags for separated CMYK
    PDL::IO::Image::TIFF_PACKBITS             Save using PACKBITS compression
    PDL::IO::Image::TIFF_DEFLATE              Save using DEFLATE compression (also known as ZLIB compression)
    PDL::IO::Image::TIFF_ADOBE_DEFLATE        Save using ADOBE DEFLATE compression
    PDL::IO::Image::TIFF_NONE                 Save without any compression
    PDL::IO::Image::TIFF_CCITTFAX3            Save using CCITT Group 3 fax encoding
    PDL::IO::Image::TIFF_CCITTFAX4            Save using CCITT Group 4 fax encoding
    PDL::IO::Image::TIFF_LZW                  Save using LZW compression
    PDL::IO::Image::TIFF_JPEG                 Save using JPEG compression (8-bit greyscale and 24-bit only)
    PDL::IO::Image::TIFF_LOGLUV               Save using LogLuv compression (only available with RGBF images
    PDL::IO::Image::TARGA_SAVE_RLE            Save with RLE compression

## dump\_bitmap

Extract raw bitmap data (+ do necessary image type and/or bpp conversions).

    my ($width, $height, $bpp, $pixels, $palette) = $pimage->dump_bitmap;
    #or
    my ($width, $height, $bpp, $pixels, $palette) = $pimage->dump_bitmap($required_bpp);

`$pixels` and `$palette` are raw data buffers containg sequence of RGB (RGBA) byte values.

`$required_bpp` can be 8, 24 or 32 - before dumping the image is converted to `BITMAP` image type + colors depth is
converted to given value. Default is autodetect the lowest sufficient bpp (from 8, 24, 32).

## get\_image\_type

Returns the data type of a bitmap (e.g. `'BITMAP'`, `'UINT16'`) - see ["Supported image types"](#supported-image-types).

    my $imtype = $pimage->get_image_type;

## get\_colors\_used

Returns the palette size for palletised bitmaps (usually 256), and 0 for high-colour bitmaps.

    my $colors = $pimage->get_colors_used;

## get\_bpp

Returns the size of one pixel in the bitmap in bits (aka bits per pixel).

    my $bpp = $pimage->get_bpp;

## get\_width

Returns the width of the bitmap in pixels.

    my $w = $pimage->get_width;

## get\_height

Returns the height of the bitmap in pixels.

    my $h = $pimage->get_height;

## get\_dots\_per\_meter\_x

Returns the horizontal resolution, in pixels-per-meter.

    my $dpmx = $pimage->get_dots_per_meter_x;

## set\_dots\_per\_meter\_x

Set the horizontal resolution, in pixels-per-meter.

    $pimage->set_dots_per_meter_x($res);

Returns `$pimage` (self).

## get\_dots\_per\_meter\_y

Returns the vertical resolution, in pixels-per-meter.

    my $dpmy = $pimage->get_dots_per_meter_y;

## set\_dots\_per\_meter\_y

Set the vertical resolution, in pixels-per-meter.

    $pimage->set_dots_per_meter_y($res);

Returns `$pimage` (self).

## get\_color\_type

Returns color type.

    my $coltype = $pimage->get_color_type;

The return value is a string:

    'MINISBLACK'   Monochrome bitmap (1-bit): first palette entry is black.
                   Palletised bitmap (4 or 8-bit) and single channel non standard bitmap: greyscale palette
    'MINISWHITE'   Monochrome bitmap (1-bit): first palette entry is white.
                   Palletised bitmap (4 or 8-bit): inverted greyscale palette
    'PALETTE'      Palettized bitmap (1, 4 or 8 bit)
    'RGB'          High-color bitmap (16, 24 or 32 bit), RGB16 or RGBF
    'RGBALPHA'     High-color bitmap with an alpha channel (32 bit bitmap, RGBA16 or RGBAF)
    'CMYK'         CMYK bitmap (32 bit only)

## is\_transparent

Returns `1` when the transparency table is enabled (1-, 4- or 8-bit images) or when the
input dib contains alpha values (32-bit images, RGBA16 or RGBAF images). Returns `0` otherwise.

    my $bool = $pimage->is_transparent;

## get\_transparent\_index

Returns the palette entry used as transparent color for the image specified. Works for
palletised images only and returns -1 for high color images or if the image has no color set to
be transparent.

    my $idx = $pimage->get_transparent_index;

## set\_transparent\_index

Sets the index of the palette entry to be used as transparent color for the image specified.
Does nothing on high color images.

    $pimage->set_transparent_index($index);

Returns `$pimage` (self).

## flip\_horizontal

Flip the image horizontally along the vertical axis.

    $pimage->flip_horizontal;

Returns `$pimage` (self).

## flip\_vertical

Flip the image vertically along the horizontal axis.

    $pimage->flip_vertical;

Returns `$pimage` (self).

## rotate

Rotates image, the angle of counter clockwise rotation is specified by the `$angle` parameter in degrees.

    $pimage->rotate($angle);
    #or
    $pimage->rotate($angle, $bg_r, $bg_g, $bg_b, $bg_a);   # RGBA(F|16) images
    $pimage->rotate($angle, $bg_r, $bg_g, $bg_b);          # RGB(F|16) images
    $pimage->rotate($angle, $bg);                          # palette-based images

You can specify optional backgroung color via `$bg_r`, `$bg_g`, `$bg_b`, `$bg_a` or `$bg`.

Returns `$pimage` (self).

## rescale

Performs resampling (scaling/zooming) of a greyscale or RGB(A) image to the desired destination width and height.

    $pimage->rescale($dst_width, $dst_height, $filter);
    #or
    $pimage->rescale($dst_width, 0);  # destination height is computed
    #or
    $pimage->rescale(0, $dst_height); # destination width is computed

Returns `$pimage` (self).

`$filter` - resampling filter identifier:

    0 .. Box, pulse, Fourier window, 1st order (constant) b-spline
    1 .. Mitchell & Netravali's two-param cubic filter
    2 .. Bilinear filter
    3 .. 4th order (cubic) b-spline
    4 .. Catmull-Rom spline, Overhauser spline
    5 .. Lanczos3 filter

## rescale\_pct

Performs resampling by given percentage ratio.

    $pimage->rescale($dst_width_pct, $dst_height_pct, $filter);
    #or
    $pimage->rescale($dst_pct);

Returns `$pimage` (self).

`$filter` - see ["rescale"](#rescale)

## convert\_image\_type

Converts an image to destination `$image_type`.

    $pimage->convert_image_type($image_type, $scale_linear);
    #or
    $pimage->convert_image_type($image_type);

Returns `$pimage` (self).

`$image_type` - string identifying image type (e.g. `'BITMAP'`, `'UINT16'` - for valid values see ["Supported image types"](#supported-image-types)).

## adjust\_colors

Adjusts an image's brightness, contrast and gamma as well as it may optionally invert the image within a single operation.

    $pimage->adjust_colors($brightness, $contrast, $gamma, $invert);

Returns `$pimage` (self).

`$brightness` - real value from range `[-100..100]`, value `0` means no change, less than 0 will make the
image darker and greater than 0 will make the image brighter

`$contrast` - real value from range `[-100..100]`, value `0` means no change, less than 0 will decrease the
contrast and greater than 0 will increase the contrast of the image

`$gamma` - real value greater than 0, value of 1.0 leaves the image alone, less than one
darkens it, and greater than one lightens it

`$invert` - `0` or `1` invert (or not) all pixels

## color\_to\_4bpp

Converts a bitmap to 4 bits. If the bitmap was a high-color bitmap (16, 24 or 32-bit) or if it was
a monochrome or greyscale bitmap (1 or 8-bit), the end result will be a greyscale bitmap,
otherwise (1-bit palletised bitmaps) it will be a palletised bitmap.

    $pimage->color_to_4bpp();

Returns `$pimage` (self).

## color\_to\_8bpp

Converts a bitmap to 8 bits. If the bitmap was a high-color bitmap (16, 24 or 32-bit) or if it was
a monochrome or greyscale bitmap (1 or 4-bit), the end result will be a greyscale bitmap,
otherwise (1 or 4-bit palletised bitmaps) it will be a palletised bitmap.

    $pimage->color_to_8bpp();

Returns `$pimage` (self).

## color\_to\_8bpp\_grey

Converts a bitmap to a 8-bit greyscale image with a linear ramp. Contrary to the
FreeImage\_ConvertTo8Bits function, 1-, 4- and 8-bit palletised images are correctly
converted, as well as images with a FIC\_MINISWHITE color type.

    $pimage->color_to_8bpp_grey();

Returns `$pimage` (self).

## color\_to\_16bpp\_555

Converts a bitmap to 16 bits, where each pixel has a color pattern of 5 bits red, 5 bits green
and 5 bits blue. One bit in each pixel is unused.

    $pimage->color_to_16bpp_555();

Returns `$pimage` (self).

## color\_to\_16bpp\_565

Converts a bitmap to 16 bits, where each pixel has a color pattern of 5 bits red, 6 bits green
and 5 bits blue.

    $pimage->color_to_16bpp_565();

Returns `$pimage` (self).

## color\_to\_24bpp

Converts a bitmap to 24 bits per pixel.

    $pimage->color_to_24bpp();

Returns `$pimage` (self).

## color\_to\_32bpp

Converts a bitmap to 32 bits per pixel.

    $pimage->color_to_32bpp();

Returns `$pimage` (self).

## color\_dither

Converts a bitmap to 1-bit monochrome bitmap using a dithering algorithm.

    $pimage->color_dither($algorithm);
    #or
    $pimage->color_dither();

Returns `$pimage` (self).

Possible `$algorithm` values:

    0 .. Floyd & Steinberg error diffusion (DEFAULT)
    1 .. Bayer ordered dispersed dot dithering (order 2 dithering matrix)
    2 .. Bayer ordered dispersed dot dithering (order 3 dithering matrix)
    3 .. Ordered clustered dot dithering (order 3 - 6x6 matrix)
    4 .. Ordered clustered dot dithering (order 4 - 8x8 matrix)
    5 .. Ordered clustered dot dithering (order 8 - 16x16 matrix)
    6 .. Bayer ordered dispersed dot dithering (order 4 dithering matrix)

## color\_threshhold

Converts a bitmap to 1-bit monochrome bitmap using a `$threshold` between \[0..255\] (default is 127).

    $pimage->color_threshhold($threshold);
    #or
    $pimage->color_threshhold();

Returns `$pimage` (self).

## color\_quantize

    $pimage->color_quantize($quantize);
    #or
    $pimage->color_quantize();

Returns `$pimage` (self).

Possible `$quantize` values:

    0 .. Xiaolin Wu color quantization algorithm
    1 .. NeuQuant neural-net quantization algorithm by Anthony Dekker

## tone\_mapping

Converts a High Dynamic Range image (48-bit RGB or 96-bit RGBF) to a 24-bit RGB image, suitable for display.

    $pimage->tone_mapping($tone_mapping_operator, $param1, $param2);

Returns `$pimage` (self).

`$tone_mapping_operator` - tone mapping operator identifier:

    0 .. Adaptive logarithmic mapping (F. Drago, 2003)
    1 .. Dynamic range reduction inspired by photoreceptor physiology (E. Reinhard, 2005)
    2 .. Gradient domain high dynamic range compression (R. Fattal, 2002)

Optional parameters:

    $pimage->tone_mapping(0, $gamma, $exposure);
    #or
    $pimage->tone_mapping(1, $intensity, $contrast);
    #or
    $pimage->tone_mapping(2, $color_saturation, $attenuation);

## free\_image\_version

Returns a string containing the current version of the library.

    my $v = PDL::IO::Image->free_image_version();

## format\_list

Returns a list of all supported file formats.

    my @f = PDL::IO::Image->format_list();

## format\_extension\_list

Returns a comma-delimited file extension list for given file format.

    my $ext = PDL::IO::Image->format_extension_list($format);

`$format` - string identifying file format (e.g. `'JPEG'` - for valid values see ["Supported file formats"](#supported-file-formats)).

## format\_mime\_type

Returns MIME content type string for given file format.

    my $mtype = PDL::IO::Image->format_mime_type($format);

`$format` - string identifying file format (e.g. `'JPEG'` - for valid values see ["Supported file formats"](#supported-file-formats)).

## format\_description

Returns description string for given file format.

    my $desc = PDL::IO::Image->format_description($format);

`$format` - string identifying file format (e.g. `'JPEG'` - for valid values see ["Supported file formats"](#supported-file-formats)).

## format\_can\_read

Returns `1` or `0` - module supports (or not) reading given file format.

    my $bool = PDL::IO::Image->format_can_read($format);

`$format` - string identifying file format (e.g. `'JPEG'` - for valid values see ["Supported file formats"](#supported-file-formats)).

## format\_can\_write

Returns `1` or `0` - module supports (or not) saving given file format.

    my $bool = PDL::IO::Image->format_can_write($format);

`$format` - string identifying file format (e.g. `'JPEG'` - for valid values see ["Supported file formats"](#supported-file-formats)).

## format\_can\_export\_type

Returns `1` or `0` - module can export (or not) given image type to given file format.

    my $bool = PDL::IO::Image->format_can_export_type($format, $image_type);

`$format` - string identifying file format (e.g. `'JPEG'` - for valid values see ["Supported file formats"](#supported-file-formats)).

`$image_type` - string identifying image type (e.g. `'BITMAP'` - for valid values see ["Supported image types"](#supported-image-types)).

## format\_can\_export\_bpp

Returns `1` or `0` - module can export (or not) given file format in given bits per pixel depth.

    my $bool = PDL::IO::Image->format_can_export_bpp($format, $bpp);

`$format` - string identifying file format (e.g. `'JPEG'` - for valid values see ["Supported file formats"](#supported-file-formats)).

`$bpp` - bits per pixel (e.g. 1, 4, 8, 16, 24, 32)

## format\_from\_mime

Returns file format string (e.g. `'BMP'`, `'JPEG'` - see ["Supported file formats"](#supported-file-formats)) for given mime type.

    my $format = PDL::IO::Image->format_from_mime($mime_type);

## format\_from\_file

Returns file format string (e.g. `'BMP'`, `'JPEG'` - see ["Supported file formats"](#supported-file-formats)) for given `$filename`.

    my $format = PDL::IO::Image->format_from_file($filename);

# CONSTANTS

There many constants which can be used with ["new\_from\_file"](#new_from_file) or ["save"](#save) methods. These constants are not exported
by this module therefore you have to use full names like this:

    use PDL;
    use PDL::IO::Image;

    my $pimage = PDL::IO::Image->new_from_file("in.jpg", "JPEG", PDL::IO::Image::JPEG_ACCURATE);

# SEE ALSO

[PDL](https://metacpan.org/pod/PDL), [PDL::IO::Pic](https://metacpan.org/pod/PDL::IO::Pic), [PDL::IO::GD](https://metacpan.org/pod/PDL::IO::GD), [Alien::FreeImage](https://metacpan.org/pod/Alien::FreeImage), [http://freeimage.sourceforge.net/](http://freeimage.sourceforge.net/)

# LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

# COPYRIGHT

2014+ KMX <kmx@cpan.org>
