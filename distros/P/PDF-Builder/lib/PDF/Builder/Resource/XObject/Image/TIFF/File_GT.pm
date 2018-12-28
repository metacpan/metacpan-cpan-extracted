package PDF::Builder::Resource::XObject::Image::TIFF::File_GT;

use strict;
use warnings;

our $VERSION = '3.013'; # VERSION
my $LAST_UPDATE = '3.010'; # manually update whenever code is changed

use IO::File;
use Graphics::TIFF ':all';  # already confirmed to be installed

=head1 NAME

PDF::Builder::Resource::XObject::Image::TIFF::File_GT - support routines for TIFF image library (Graphics::TIFF enabled)

=cut

sub new {
    my ($class, $file) = @_;

    my $self = {};
    bless ($self, $class);
    die "Error: $file not found\n" unless -r $file;
    $self->{'object'} = Graphics::TIFF->Open($file, 'r');
    $self->readTags();

    return $self;
}

sub close { ## no critic
    my $self = shift;

    $self->{'object'}->Close();
    delete $self->{'object'};
    return;
}

# presumably this is handling byte order and bit order OK (for tags). we 
# need to look at whether anything in the strip data needs bit/byte swapping.
#
# see list in Graphics::TIFF.pm
# not all of these are used, but PDF::Builder apps may use them
sub readTags {
    my $self = shift;

    # pixels per row (number of columns)
    $self->{'imageWidth'} = $self->{'object'}->GetField(TIFFTAG_IMAGEWIDTH);
    # number of rows of pixels (height). DO NOT CONFUSE with imageLength!
    $self->{'imageHeight'} = $self->{'object'}->GetField(TIFFTAG_IMAGELENGTH);

    #   strips per image is floor(imageLength+RowsPerStrip-1/RowsPerStrip)
    #   calculated by method NumberOfStrips()
    $self->{'RowsPerStrip'} = $self->{'object'}->GetField(TIFFTAG_ROWSPERSTRIP);
    # TIFFTAG_PLANARCONFIGURATION = 1 if pixel components stored contiguously,
    #                             = 2 if pixel components stored in sep. planes
    # N = STRIPS PER IMAGE if PLANAR CONFIGURATION = 1
    #   multiply by SAMPLES PER PIXEL for 2
    # offset is bytes from beginning of file (ReadRawStrip should use)
    $self->{'imageOffset'} = $self->{'object'}->GetField(TIFFTAG_STRIPOFFSETS);
    # STRIP BYTE COUNTS is bytes of compressed data per strip
    #   do NOT confuse with imageHeight! same N as imageOffset
    $self->{'imageLength'} = $self->{'object'}->GetField(TIFFTAG_STRIPBYTECOUNTS);

    # ------ describe each pixel
    # components per pixel (e.g., 1 for mono/gray/palette, 3 for RGB)
    $self->{'SamplesPerPixel'} = $self->{'object'}->GetField(TIFFTAG_SAMPLESPERPIXEL);
    # extra components, such as opacity/alpha
    $self->{'ExtraSamples'} = $self->{'object'}->GetField(TIFFTAG_EXTRASAMPLES);
    # bits per component (R, G, B, and A can have different number of bits)
    # N (Samples per Pixel) components
    $self->{'bitsPerSample'} = $self->{'object'}->GetField(TIFFTAG_BITSPERSAMPLE);
    # 1 (common) most sig bit to least, 2 (rare) least sig bit to most (flip!)
    $self->{'fillOrder'} = $self->{'object'}->GetField(TIFFTAG_FILLORDER);

    # ------ compression method
    $self->{'filter'} = $self->{'object'}->GetField(TIFFTAG_COMPRESSION);
    if      ($self->{'filter'} == COMPRESSION_NONE) { # 1
        delete $self->{'filter'};
    # 2 modified Huffman RLE (COMPRESSION_CCITTRLE)
    } elsif ($self->{'filter'} == COMPRESSION_CCITTFAX3 || $self->{'filter'} == COMPRESSION_CCITT_T4) {  # 3
        $self->{'ccitt'} = $self->{'filter'};
        $self->{'filter'} = 'CCITTFaxDecode';
    } elsif ($self->{'filter'} == COMPRESSION_CCITTFAX4 || $self->{'filter'} == COMPRESSION_CCITT_T6) {  # 4
        # G4 same code as G3
        $self->{'ccitt'} = $self->{'filter'};
        $self->{'filter'} = 'CCITTFaxDecode';
    } elsif ($self->{'filter'} == COMPRESSION_LZW) { # 5
        $self->{'filter'} = 'LZWDecode';
    } elsif ($self->{'filter'} == COMPRESSION_OJPEG || $self->{'filter'} == COMPRESSION_JPEG) { # 6  JPEG is 'new' JPEG?
        $self->{'filter'} = 'DCTDecode';
    # 7 'new' JPEG
    } elsif ($self->{'filter'} == COMPRESSION_ADOBE_DEFLATE || $self->{'filter'} == COMPRESSION_DEFLATE) { # 8  same? see 32946
        $self->{'filter'} = 'FlateDecode';
    # 9  T.85 
    # 10 T.43
    # 32766 COMPRESSION_NEXT
    # 32771 COMPRESSION_CCITTRLEW
    } elsif ($self->{'filter'} == COMPRESSION_PACKBITS) { # 32773
        $self->{'filter'} = 'RunLengthDecode';
    # 32809 COMPRESSION_THUNDERSCAN
    # 32895 COMPRESSION_IT8CTPAD
    # 32896 COMPRESSION_IT8LW
    # 32897 COMPRESSION_IT8MP
    # 32898 COMPRESSION_IT8BL
    # 32908 COMPRESSION_PIXARFILM
    # 32909 COMPRESSION_PIXARLOG
    # 32946 COMPRESSION_DEFLATE
    # 32947 COMPRESSION_DCS
    # 34661 COMPRESSION_JBIG
    # 34676 COMPRESSION_SGILOG
    # 34677 COMPRESSION_SGILOG24
    # 34712 COMPRESSION_JP2000
    } else {
        die "Unknown/unsupported TIFF compression method with id '".$self->{'filter'}."'.\n";
    }

    # ------ interpretation of color values 
    $self->{'colorSpace'} = $self->{'object'}->GetField(TIFFTAG_PHOTOMETRIC);
    if      ($self->{'colorSpace'} == PHOTOMETRIC_MINISWHITE) { # 0=WhiteIsZero
        $self->{'colorSpace'} = 'DeviceGray';
        $self->{'whiteIsZero'} = 1;
        $self->{'blackIsZero'} = 0;
    } elsif ($self->{'colorSpace'} == PHOTOMETRIC_MINISBLACK) { # 1=BlackIsZero
        $self->{'colorSpace'} = 'DeviceGray';
        $self->{'blackIsZero'} = 1;
        $self->{'whiteIsZero'} = 0;
    } elsif ($self->{'colorSpace'} == PHOTOMETRIC_RGB) { # 2=RGB in that order
        $self->{'colorSpace'} = 'DeviceRGB';
    } elsif ($self->{'colorSpace'} == PHOTOMETRIC_PALETTE) { # 3=palette index
        $self->{'colorSpace'} = 'Indexed';
   #} elsif ($self->{'colorSpace'} == PHOTOMETRIC_MASK) { # 4=transparency mask
   #    $self->{'colorSpace'} = 'TransMask';
    } elsif ($self->{'colorSpace'} == PHOTOMETRIC_SEPARATED) { # 5=(us.) CMYK
        $self->{'colorSpace'} = 'DeviceCMYK';
    } elsif ($self->{'colorSpace'} == PHOTOMETRIC_YCBCR) { # 6=YCbCr
        $self->{'colorSpace'} = 'DeviceRGB';
    } elsif ($self->{'colorSpace'} == PHOTOMETRIC_CIELAB) { # 8=CIE L*a*b
        $self->{'colorSpace'} = 'Lab';
    # 9=CIE L*a*b alternate encoding (ICC)
    # 10=CIE L*a*b alternate encoding (ITU-T Rec T.42)
    # 32803=CFA
    # 32844=Pixar LogL
    # 32845=Pixar LogLuv
    # 34892=LinearRaw
    } else {
        die "Unknown/unsupported TIFF photometric interpretation with id '".$self->{'colorSpace'}."'.\n";
    }

    # TIFFTAG_THRESHHOLDING force grays to black or white
    # TIFFTAG_CELLWIDTH dithering or halftoning matrix cell width
    # TIFFTAG_CELLLENGTH dithering or halftoning matrix cell height
    # palette RGB table definition
    $self->{'colorMapOffset'} = $self->{'object'}->GetField(TIFFTAG_COLORMAP);
    $self->{'colorMapSamples'} = $#{$self->{'colorMapOffset'}}+1;
    $self->{'colorMapLength'} = $self->{'colorMapSamples'}*2; # shorts!
    # TIFFTAG_GRAYRESPONSEUNIT describe integer->float mapping
    # TIFFTAG_GRAYRESPONSECURVE optical density of Gray curve at each point

    $self->{'imageDescription'} = $self->{'object'}->GetField(TIFFTAG_IMAGEDESCRIPTION);
    # TIFFTAG_MAKE scanner or camera manufacturer
    # TIFFTAG_MODEL scanner or camera model or name
    # TIFFTAG_SOFTWARE name/version of softwar that produced TIFF
    # TIFFTAG_DATETIME YYYY:MM:DD HH:MM:SS\0 string, creation timestamp
    # TIFFTAG_ARTIST who created the image (was used for copyright, too)
    # TIFFTAG_COPYRIGHT full copyright statement for the image
    # TIFFTAG_HOSTCOMPUTER describe computer/OS used to create image

    $self->{'xRes'} = $self->{'object'}->GetField(TIFFTAG_XRESOLUTION);
    $self->{'yRes'} = $self->{'object'}->GetField(TIFFTAG_YRESOLUTION);
    $self->{'resUnit'} = $self->{'object'}->GetField(TIFFTAG_RESOLUTIONUNIT);
    # TIFFTAG_ORIENTATION = 1 data starts at top left
    # may also be known as T4Options
    $self->{'g3Options'} = $self->{'object'}->GetField(TIFFTAG_GROUP3OPTIONS);
    # may also be known as T6Options or Group4Options
    $self->{'g4Options'} = $self->{'object'}->GetField(TIFFTAG_GROUP4OPTIONS);

    $self->{'lzwPredictor'} = $self->{'object'}->GetField(TIFFTAG_PREDICTOR);
    $self->{'imageId'} = $self->{'object'}->GetField(TIFFTAG_OPIIMAGEID);
    # TIFFTAG_SUBFILETYPE = 3 bits for various subfiles within image file
    # TIFFTAG_OSUBFILETYPE = 3 values concerning image types
    # TIFFTAG_MINSAMPLEVALUE = SamplesPerPixel min value 
    # TIFFTAG_MAXSAMPLEVALUE = SamplesPerPixel max value 
    # TIFFTAG_FREEOFFSETS (ignore, early memory management attempt)
    # TIFFTAG_FREEBYTECOUNTS (ignore, early memory mmanagement attempt)

    return $self;
}

1;
