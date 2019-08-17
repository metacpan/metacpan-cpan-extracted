package PDF::Builder::Resource::XObject::Image::PNG_IPL;

use base 'PDF::Builder::Resource::XObject::Image';

use strict;
use warnings;

our $VERSION = '3.016'; # VERSION
my $LAST_UPDATE = '3.011'; # manually update whenever code is changed

use Compress::Zlib;
use POSIX qw(ceil floor);

use IO::File;
use PDF::Builder::Util;
use PDF::Builder::Basic::PDF::Utils;
use Image::PNG::Libpng ':all';  # have already confirmed that this exists
use Image::PNG::Const ':all';
use Scalar::Util qw(weaken);

=head1 NAME

PDF::Builder::Resource::XObject::Image::PNG_IPL - support routines for PNG 
image library (using Image::PNG::Libpng). 
Inherits from L<PDF::Builder::Resource::XObject::Image>

=head1 METHODS

=over

=item $res = PDF::Builder::Resource::XObject::Image::PNG_IPL->new($pdf, $file, $name, %opts)

=item $res = PDF::Builder::Resource::XObject::Image::PNG_IPL->new($pdf, $file, $name)

=item $res = PDF::Builder::Resource::XObject::Image::PNG_IPL->new($pdf, $file)

=back 

Returns a PNG-image object. C<$pdf> is the PDF object being added to, C<$file>
is the input PNG file, and the optional C<$name> of the new parent image object
defaults to PxAAA.

If the Image::PNG::Libpng package is installed, and its use is not suppressed
via the C<-nouseIPL> flag (see Builder documentation for C<image_png>), the
PNG_IPL library will be used. Otherwise, the PNG library will be used instead.

B<opts:>

=over

=item -notrans => 1

No transparency -- ignore tRNS chunk if provided, ignore Alpha channel
if provided.

=item -force8bps => 1

If the PNG source is 16bps, tell the libpng library to strip down all
channels to 8bps, permitting use on PDF 1.4 output.

=back

=head2 Supported PNG types

   (0) Gray scale of depth 1, 2, 4, 8, or 16 bits per pixel (2, 4, 16, 256,
       or 65536 gray levels). Full transparency (of one 16-bit gray value) 
       via the tRNS chunk is allowed, unless the -notrans option specifies 
       that it be ignored.

   (2) RGB truecolor with 8 or 16 bits per sample (3 samples: 16.7 million 
       or 281.5 trillion colors). Full transparency (of one 3x16-bit RGB 
       color value) via the tRNS chunk is allowed, unless the -notrans 
       option specifies that it be ignored.

   (3) Palette color with 1, 2, 4, or 8 bits per pixel (2, 4, 16, or 256
       color table/palette entries). 16 bpp is not currently supported by
       PNG or PDF. Partial transparency (8-bit Alpha) for each palette
       entry via the tRNS chunk is allowed, unless the -notrans option 
       specifies that it be ignored (all entries fully opaque).

   (4) Gray scale of depth 8 or 16 bits per pixel plus equal-sized Alpha
       channel (256 or 65536 gray levels and 256 or 65536 levels of
       transparency). The Alpha channel is ignored if the -notrans 
       option is given. The tRNS chunk is not permitted.

   (6) RGB truecolor with 8 or 16 bits per sample, with equal-sized 
       Alpha channel (256 or 65536 levels of transparency). The Alpha 
       channel is ignored if the -notrans option is given. The tRNS 
       chunk is not permitted.

In all cases, 16 bits per sample forces PDF 1.5 (or higher) output, unless
you give the C<-force8bps> option, to "strip" 16 bit samples to 8 bits, and
permit PDF 1.4-compatible output.
The libpng.a library is assuming standard "network" bit and 
byte ordering (Big Endian), although flags might be added to change this.

The transparency chunk (tRNS) will specify one gray level entry or one RGB
entry to be treated as transparent (Alpha = 0). For palette color, up to 
256 palette entry 8-bit Alpha values are specified (256 levels of transparency, 
from 0 = transparent to 255 = opaque).

Only a limited number of chunks are handled: IHDR, IDAT (internally), PLTE, 
tRNS, and IEND (internally). All other chunks are ignored at this time. Filters
and compression applied to data is handled internally by libpng.a -- there may
be unsupported methods.

=cut

# TBD: gAMA (gamma) chunk, perhaps some others?

sub new {
    my ($class, $pdf, $file, $name, %opts) = @_;

    my $self;

    $class = ref($class) if ref($class);

    $self = $class->SUPER::new($pdf, $name || 'Px'.pdfkey());
    $pdf->new_obj($self) unless $self->is_obj($pdf);

    $self->{' apipdf'} = $pdf;
    weaken $self->{' apipdf'};

    my $fh = IO::File->new();
    my $png = create_read_struct();
    if (ref($file)) {
        $fh = $file;
    } else {
        open $fh, '<', $file or die "$!: $file";
    }
    binmode($fh, ':raw');
    $png->init_io($fh);

    my ($w,$h, $bpc, $cs, $im, $palette, $trns);
    $self->{' stream'} = '';
    $self->{' nofilt'} = 1;

    # slurp whole PNG file into $png structure
    my $xform = PNG_TRANSFORM_IDENTITY;  # default bit flag (0)
    my $transparency = 1; # default YES, allow transparency/Alpha
    if ($opts{'-notrans'}) { 
        $transparency = 0;
	$xform |= PNG_TRANSFORM_STRIP_ALPHA; 
	# this appears to turn cs=4 into cs=0, and cs=6 into cs=2
    }
    if ($opts{'-force8bps'}) {
	$xform |= PNG_TRANSFORM_STRIP_16;
	# this reduces 16bps channels to 8bps
    }
    $png->read_png($xform);
    close($fh);

    # what chunks are available?
    my $valid = $png->get_valid();
    # IHDR one must exist and be first
    # PLTE one must exist if ColorType 3, and be before IDATs
    # tRNS is optional, must be after PLTE and before IDAT, not allowed if
    #      Alpha channel is given
    # IDAT one or more must exist and be consecutive, obtain with get_rows()
    # any other chunk is just ignored for now
    #    TBD: gAMA (gamma) consider doing, if implemented in PDF
    # IEND one must exist and be last (internally handled)

    # header (IHDR)
    # there had BETTER be a header chunk!
    my $IHDR = $png->get_IHDR();  # hash ref for header data
    $w = $IHDR->{'width'};
    $h = $IHDR->{'height'};

    $bpc = $IHDR->{'bit_depth'}; # bits-per-channel
    if ($bpc > 8) {
        PDF::Builder->verCheckOutput(1.5, "image sample depth > 8 bits");
        # if don't want to allow > 8 bits, can use -force8bps
        # if later PDFs allow other depths > 8, give them their own test
    }

    $im = $IHDR->{'interlace_method'};
    # im = 0 : PNG_INTERLACE_NONE
    # im = 1 : PNG_INTERLACE_ADAM7 
   #if ($IHDR->{'interlace_method'} != PNG_INTERLACE_NONE) {
   #    die "Unsupported interlace method $im (must be NONE)\n";
   #}
   # we don't care what the original interlacing was, as the data should be
   # arranged in the non-interlaced order by the time we see it.
     
    $cs = $IHDR->{'color_type'}; 
   #print "\ncs (color type) = $cs\n"; # if Alpha stripped, is cs-4
    # cs = 0 : PNG_COLOR_TYPE_GRAY
    # cs = 1 : reserved for grayscale via palette
    # cs = 2 : PNG_COLOR_TYPE_RGB (truecolor)
    # cs = 3 : PNG_COLOR_TYPE_PALETTE (truecolor + palette)
    # cs = 4 : PNG_COLOR_TYPE_GRAY_ALPHA
    # cs = 5 : reserved for grayscale via palette + Alpha channel
    # cs = 6 : PNG_COLOR_TYPE_RGB_ALPHA
    # cs = 7 : reserved for truecolor via palette + Alpha channel

    # compression method ($cm), filter ($fm) method not returned.
    # supposedly they were never implemented, and should always be 0.

    # palette (PLTE) if given and valid
    if ($valid->{'PLTE'}) { # should only see for palette color type (3)!
        my $palette_ref = $png->get_PLTE();
	# should be an arrayref of hashes for 'red', 'green', 'blue'
	# is 3 bytes (red, green, blue) one set per palette entry (1..256)
	# convert into format PDF understands
	# old code: count of bytes read into $palette as string 
	my @pal_array = ();
	for (my $i=0; $i<@{$palette_ref}; $i++) {
	    push @pal_array, $palette_ref->[$i]->{'red'};
	    push @pal_array, $palette_ref->[$i]->{'green'};
	    push @pal_array, $palette_ref->[$i]->{'blue'};
        }
	# there should be 3N bytes to pack, N=2,4,16, or 256 entries
	$palette = pack('C*', @pal_array);
	if (length($palette)/3 != int(length($palette)/3)) {
            die "Palette read (length ".length($palette).") that was not 3N bytes long.\n";
	}
	if (length($palette)/3 > 1<<$bpc) {
	    warn "Palette read with ".(length($palette)/3)." entries, when maximum of ".(1<<$bpc)." were expected.\n";
	}
       #print "palette is ".length($palette)." bytes long, expect ".(3*2**$bpc)."\n";
    }
    
    # transparency chunk (tRNS) if given and valid
    # for cs=0 (gray) or cs=2 (RGB) it is the entry to be made transparent
    #   16-bit or 48-bit value(s), regardless of $bpc
    # for cs=3 (palette), it is 8-bit Alpha for each palette entry
    #   Alpha: 0 = transparent, 2**bpc -1 (e.g., 255) is opaque
    my $tRNS_available = 0;
    if ($valid->{'tRNS'}) { 
	$tRNS_available = 1; 
	$trns = $png->get_tRNS();
       #print "tRNS chunk found, is ".length($trns)." bytes long\n";
	# convert into format PDF understands
	# Gray (cs=0) 16-bit gray value to replace by transparent pixel
	#  expects string to unpack, get min and max values into Mask
	#  according to PNG spec, it should be a single value
	#  according to Libpng, $trns->{gray} is value to use (hash)
	# RGB (cs=2) expects a 3 element array (red, green, blue entries)
	#  get min and max of each primary color. PNG only supplies 3 16-bit
	#  values (red, green, blue) to indicate one truecolor to make 
	#  transparent (hash $trns->red, ->green, ->blue)
	# Palette (cs=3) expects an array of 8-bit entries, one per palette
	#  entry, giving the Alpha value 0=transparent to 255=opaque for that
	#  entry. Unlike Gray and RGB, we are NOT selecting one pixel value
	#  to be fully transparent and the rest opaque. $trns is an array ref.
    }

    # transfer over the unpacked (uncompressed, unfiltered) data rows (IDAT) 
    # to self->{' stream'}.  stream is already initialized to empty
    my $rows = $png->get_rows();
    for (my $row = 0; $row < @{$rows}; $row++) {
	$self->{' stream'} .= $rows->[$row];
    }

    $self->width($w);
    $self->height($h);

    # ColorType fields (cs value)
    # bit 0: 0 = actual value given, 1 (1) = palette index given
    # bit 1: 0 = grayscale, 1 (2) = truecolor RGB
    # bit 2: 0 = no Alpha channel, tRNS chunk allowed
    #        1 (4) = Alpha channel given, tRNS chunk forbidden

    if      ($cs == PNG_COLOR_TYPE_GRAY) {  
	# cs=0 grayscale 1,2,4,8,16 bps, no Alpha, optional tRNS
	# $png->get_channels() should return 1 (1 sample per pixel)
        $self->colorspace('DeviceGray');
        $self->bits_per_component($bpc);
        my $dict = PDFDict();
        $self->{'DecodeParms'} = PDFArray($dict);
        $dict->{'BitsPerComponent'} = PDFNum($bpc);
        $dict->{'Colors'} = PDFNum(1);   # samples per pixel (channels)
        $dict->{'Columns'} = PDFNum($w);
        if ($tRNS_available && $transparency) {
            # only need to set the Mask
            my $m = $trns->{'gray'};
	    # should be one 16-bit value in tRNS chunk, corresponding to the
	    # precise gray value to render transparent (Alpha = 0)
            $self->{'Mask'} = PDFArray(PDFNum($m), PDFNum($m));
        }
	# compress all but short streams
	if (length($self->{' stream'}) > 32) {
	    $self->{' stream'} = Compress::Zlib::compress($self->{' stream'});
            $self->filters('FlateDecode');  # tell reader it's compressed...
	    $self->{' nofilt'} = 1;  # ...but writer not to compress on the fly
	} else {
	    # too short to bother compressing. '/Filter [ /FlateDecode ] ' 
	    # takes up 25 bytes all by itself
	    delete $self->{'Filter'};
	    $self->{' nofilt'} = 1;
	}

    # cs=1 reserved for grayscale given by palette (1 channel) -- 
    # not in current PNG spec. you can emulate by cs=3 with R=G=B values,
    #   but this wastes 2/3 of the space used for the palette

    } elsif ($cs == PNG_COLOR_TYPE_RGB) {  
        # cs=2 RGB 8 or 16 bps, no Alpha, optional tRNS
	# $png->get_channels() should return 3 (3 samples per pixel)
        $self->colorspace('DeviceRGB');
        $self->bits_per_component($bpc);
        my $dict = PDFDict();
        $self->{'DecodeParms'} = PDFArray($dict);
        $dict->{'BitsPerComponent'} = PDFNum($bpc);
        $dict->{'Colors'} = PDFNum(3);
        $dict->{'Columns'} = PDFNum($w);
        if ($tRNS_available && $transparency) {
	    # only need to set the Mask
	    # old code unpacked 16-bit ints into an array, pulled out 3 at
	    #   a time into r,g,b arrays, got the max and min values, and 
	    #   created @v array to map to an array, as below. according to
	    #   PNG spec, should be only 3 entries in the first place!
	    # rgb 16-bit values, together form one truecolor entry to make transparent
            my @v = ();
            my $m = $trns->{'red'};
            push @v, $m,$m;
            $m = $trns->{'green'};
            push @v, $m,$m;
            $m = $trns->{'blue'};
            push @v, $m,$m;
            $self->{'Mask'} = PDFArray(map { PDFNum($_) } @v);
        }
	# compress all but short streams
	if (length($self->{' stream'}) > 32) {
	    $self->{' stream'} = Compress::Zlib::compress($self->{' stream'});
            $self->filters('FlateDecode');  # tell reader it's compressed...
	    $self->{' nofilt'} = 1;  # ...but writer not to compress on the fly
	} else {
	    # too short to bother compressing. '/Filter [ /FlateDecode ] ' 
	    # takes up 25 bytes all by itself
	    delete $self->{'Filter'};
	    $self->{' nofilt'} = 1;
	}

    } elsif ($cs == PNG_COLOR_TYPE_PALETTE) {  
        # cs=3 palette 1,2,4,8 bpp depth, no Alpha, optional tRNS
	# $png->get_channels() should return 1 (1 sample per pixel)
	# should not be 16 bpp, as palette limited to 256 entries
	if ($bpc > 8) {
	    die "maximum 256 palette entries, 2**$bpc requested\n";
	}
	# other cs values ignore any palette that happens to be there
	if ($tRNS_available && $transparency) {
	    # $trns is an arrayref containing up to 256 8-bit Alpha entries,
	    # one per palette entry. if necessary, pad out with xFF entries
	    # (opaque) to make enough entries (to match the palette size...
	    # assuming that no pixels request an out-of-range index value). 
	    # x00 is transparent. 
	    # TBD: first pad out the palette to 1<<$bpc entries, just to be
	    #      absolutely certain no out-of-range indices? 0 0 0 bytes?
	    #      or, check all image indices used to make sure $palette (and
	    #      thus $trns), is long enough (don't trust image maker)?
	    # $palette SHOULD be 3x bytes in length
	    for (my $i=@{$trns}; $i<(length($palette)/3); $i++) {
		$trns->[$i] = 255;
	    }
	}
	my $dict = PDFDict();
        $pdf->new_obj($dict);
       #  note that it is legal for palette to be short (too few entries for
       #    its bps value) so long as none of the missing entries are used
       #  compressing palettes seems to cause problems, and such binary data
       #    often doesn't compress well anyway
        $dict->{' stream'} = $palette;
	delete $dict->{'Filter'};
	$dict->{' nofilt'} = 1;
        $palette = ""; # why does this need to be destroyed? to save space?
        $self->colorspace(PDFArray(
			      PDFName('Indexed'), 
	                      PDFName('DeviceRGB'), 
			      PDFNum(int(length($dict->{' stream'})/3)-1), 
			      $dict) );
        $self->bits_per_component($bpc);
	$dict = PDFDict();
        $self->{'DecodeParms'} = PDFArray($dict);
        $dict->{'BitsPerComponent'} = PDFNum($bpc);
        $dict->{'Colors'} = PDFNum(1);  # one palette entry number per pixel
        $dict->{'Columns'} = PDFNum($w);
	if ($tRNS_available && $transparency) {
            $dict = PDFDict();
            $pdf->new_obj($dict);
            $dict->{'Type'} = PDFName('XObject');
            $dict->{'Subtype'} = PDFName('Image');
            $dict->{'Width'} = PDFNum($w);
            $dict->{'Height'} = PDFNum($h);
            $dict->{'ColorSpace'} = PDFName('DeviceGray');
            $dict->{'BitsPerComponent'} = PDFNum(8);
            $self->{'SMask'} = $dict;
	   # now to build an "image" used as an SMask, which is the (8-bit) 
	   # Alpha value to be used for each pixel. get the palette (and thus
	   # $trns) index from the uncompressed/unfiltered image data and
	   # look up the Alpha to stick in each byte of the SMask.
            foreach my $n (0 .. $h*$w-1) {
	        # dict->stream initially empty. fill with Alpha value for
		# each pixel, indexed by pixel value
		vec($dict->{' stream'}, $n, 8) = # each Alpha 8 bits
		    $trns->[vec($self->{' stream'}, $n, $bpc)];
		#               n-th pixel is palette index 1-8 bit integer
		#   $trns[index for n-th pixel] is Alpha to use
	    }
	    # compress all but short streams
	    if (length($dict->{' stream'}) > 32) {
	        $dict->{' stream'} = Compress::Zlib::compress($dict->{' stream'});
                $dict->filters('FlateDecode');  # tell reader it's compressed...
	        $dict->{' nofilt'} = 1;  # ...but writer not to compress on the fly
	    } else {
	        # too short to bother compressing. '/Filter [ /FlateDecode ] ' 
	        # takes up 25 bytes all by itself
	        delete $dict->{'Filter'};
	        $dict->{' nofilt'} = 1;
	    }
	}
	# compress all but short streams
	if (length($self->{' stream'}) > 32) {
	    $self->{' stream'} = Compress::Zlib::compress($self->{' stream'});
            $self->filters('FlateDecode');  # tell reader it's compressed...
	    $self->{' nofilt'} = 1;  # ...but writer not to compress on the fly
	} else {
	    # too short to bother compressing. '/Filter [ /FlateDecode ] ' 
	    # takes up 25 bytes all by itself
	    delete $self->{'Filter'};
	    $self->{' nofilt'} = 1;
	}

    } elsif ($cs == PNG_COLOR_TYPE_GRAY_ALPHA) {  
        # cs=4 grayscale+Alpha 8 or 16 bps, NO tRNS
	# $png->get_channels() should return 2 (2 samples per pixel)
        $self->filters('FlateDecode');
        $self->colorspace('DeviceGray');
        $self->bits_per_component($bpc);
        my $dict = PDFDict();
        $self->{'DecodeParms'} = PDFArray($dict);
        $dict->{'BitsPerComponent'} = PDFNum($bpc);
        $dict->{'Colors'} = PDFNum(1); # not 2 for Alpha b/c only gray part
        $dict->{'Columns'} = PDFNum($w);

        $dict = PDFDict();
        if ($transparency) { # will be in cs=0 if stripped Alpha for -notrans
            $pdf->new_obj($dict);
            $dict->{'Type'} = PDFName('XObject');
            $dict->{'Subtype'} = PDFName('Image');
            $dict->{'Width'} = PDFNum($w);
            $dict->{'Height'} = PDFNum($h);
            $dict->{'ColorSpace'} = PDFName('DeviceGray');
            $dict->{'BitsPerComponent'} = PDFNum($bpc);
            $self->{'SMask'} = $dict;
	    # basically, move all the first half of each pair of samples
	    # (1 or 2 bytes) to self->stream, and the second half (1 or
	    # 2 bytes) into dict->stream as the Alpha SMask. delete 
	    # leftover self->stream.
	    my $clearstream = $self->{' stream'}; # s/b uncompressed, unfiltered
            delete $self->{' nofilt'};
	    delete $self->{' stream'}; # will reduce size 50% when Alpha removed
	    # TBD: the following pixel-by-pixel manipulation is SLOW as
	    #   molasses, but I haven't found anything faster. pack(unpack(..))
	    #   is about 3x slower, and self->stream .= doesn't work (corrupts).
	    #   have requested that it be built into libpng.a.
	    foreach my $n (0 .. $h*$w-1) {
	       # consolidate remaining 1 sample into self->stream
		vec($self->{' stream'}, $n, $bpc) = vec($clearstream, $n*2,   $bpc);
	       # pull out Alpha from pixel into separate Mask area
		vec($dict->{' stream'}, $n, $bpc) = vec($clearstream, $n*2+1, $bpc);
	    }
        }
	# compress all but short streams
	if (length($self->{' stream'}) > 32) {
	    $self->{' stream'} = Compress::Zlib::compress($self->{' stream'});
            $self->filters('FlateDecode');  # tell reader it's compressed...
	    $self->{' nofilt'} = 1;  # ...but writer not to compress on the fly
	} else {
	    # too short to bother compressing. '/Filter [ /FlateDecode ] ' 
	    # takes up 25 bytes all by itself
	    delete $self->{'Filter'};
	    $self->{' nofilt'} = 1;
	}
	if (length($dict->{' stream'}) > 32) {
	    $dict->{' stream'} = Compress::Zlib::compress($dict->{' stream'});
            $dict->filters('FlateDecode');  # tell reader it's compressed...
	    $dict->{' nofilt'} = 1;  # ...but writer not to compress on the fly
	} else {
	    # too short to bother compressing. '/Filter [ /FlateDecode ] ' 
	    # takes up 25 bytes all by itself
	    delete $dict->{'Filter'};
	    $dict->{' nofilt'} = 1;
	}
	# if -notrans, Alpha channel should have been stripped off
	# and we are told it is cs = 0 (visit other section, not this one)

    # cs=5 reserved for grayscale given by palette+Alpha (2 channels) -- 
    # not in current PNG spec. you can emulate by cs=3 with R=G=B values,
    #   but this wastes 2/3 of the space used, and using a tRNS chunk to
    #   specify an 8-bit Alpha for each palette entry. note that this is
    #   a constant Alpha per palette entry, NOT an Alpha per pixel!

    } elsif ($cs == PNG_COLOR_TYPE_RGB_ALPHA) {  
       # about 50 times slower than cs=2! (withOUT -notrans) due to Alpha move
        # cs=6 RGB+Alpha 8 or 16 bps, NO tRNS
	# $png->get_channels() should return 4 (4 samples per pixel)
        $self->filters('FlateDecode');
        $self->colorspace('DeviceRGB');
        $self->bits_per_component($bpc);
        my $dict = PDFDict();
        $self->{'DecodeParms'} = PDFArray($dict);
        $dict->{'BitsPerComponent'} = PDFNum($bpc);
        $dict->{'Colors'} = PDFNum(3); # not 4 for Alpha b/c Alpha removed
        $dict->{'Columns'} = PDFNum($w);

        $dict = PDFDict();
        if ($transparency) { # will be in cs=2 if stripped Alpha for -notrans
            $pdf->new_obj($dict);
            $dict->{'Type'} = PDFName('XObject');
            $dict->{'Subtype'} = PDFName('Image');
            $dict->{'Width'} = PDFNum($w);
            $dict->{'Height'} = PDFNum($h);
            $dict->{'ColorSpace'} = PDFName('DeviceGray');
            $dict->{'Filter'} = PDFArray(PDFName('FlateDecode'));
            $dict->{'BitsPerComponent'} = PDFNum($bpc);
            $self->{'SMask'} = $dict;
	    # basically, move the last quarter of each quartet of samples
	    # (1 or 2 bytes) to dict->stream as the Alpha SMask, and the 
	    # first 3/4 (3 * 1 or 2 bytes) into self->stream as the image. 
	    # delete leftover self->stream.
	    my $clearstream = $self->{' stream'}; # s/b uncompressed, unfiltered
	    delete $self->{' nofilt'};
	    delete $self->{' stream'}; # will reduce size 25% when Alpha removed
	    # TBD: the following pixel-by-pixel manipulation is SLOW as
	    #   molasses, but I haven't found anything faster. pack(unpack(..))
	    #   is about 3x slower, and self->stream .= doesn't work (corrupts).
	    #   have requested that it be built into libpng.a.
	    foreach my $n (0 .. $h*$w-1) {
	       # pull out Alpha from pixel into separate Mask area
	       vec($dict->{' stream'}, $n,     $bpc) = vec($clearstream, $n*4+3, $bpc);
	       # close up remaining 3 samples into self->stream
	       vec($self->{' stream'}, $n*3,   $bpc) = vec($clearstream, $n*4,   $bpc);
	       vec($self->{' stream'}, $n*3+1, $bpc) = vec($clearstream, $n*4+1, $bpc);
	       vec($self->{' stream'}, $n*3+2, $bpc) = vec($clearstream, $n*4+2, $bpc);
	    }
        }
	# compress all but short streams
	if (length($self->{' stream'}) > 32) {
	    $self->{' stream'} = Compress::Zlib::compress($self->{' stream'});
            $self->filters('FlateDecode');  # tell reader it's compressed...
	    $self->{' nofilt'} = 1;  # ...but writer not to compress on the fly
	} else {
	    # too short to bother compressing. '/Filter [ /FlateDecode ] ' 
	    # takes up 25 bytes all by itself
	    delete $self->{'Filter'};
	    $self->{' nofilt'} = 1;
	}
	if (length($dict->{' stream'}) > 32) {
	    $dict->{' stream'} = Compress::Zlib::compress($dict->{' stream'});
            $dict->filters('FlateDecode');  # tell reader it's compressed...
	    $dict->{' nofilt'} = 1;  # ...but writer not to compress on the fly
	} else {
	    # too short to bother compressing. '/Filter [ /FlateDecode ] ' 
	    # takes up 25 bytes all by itself
	    delete $dict->{'Filter'};
	    $dict->{' nofilt'} = 1;
	}
	# if -notrans, Alpha channel should have been stripped off
	# and we are told it is cs = 2 (visit other section, not this one)

    # cs=7 reserved for RGB given by palette+Alpha (2 channels) -- 
    # not in current PNG spec. the closest you can emulate this is cs=3
    # plus tRNS chunk for an 8-bit Alpha per palette entry. note that this
    # is an Alpha per palette index, and NOT an Alpha per pixel!

    } else {
        die "unsupported PNG-color type (cs=$cs).";
    }

    return($self);
}

=over

=item  $mode = $png->usesLib()

Returns 1 if Image::PNG::Libpng installed and used, 0 if not installed, or -1 
if installed but not used (-nouseIPL option given to C<image_png>).

B<Caution:> this method can only be used I<after> the image object has been
created. It can't tell you whether Image::PNG::Libpng is available in
advance of actually using it, in case you want to use some functionality
available only in PNG_IPL. See the L<PDF::Builder> LA_IPL() call if you
need to know in advance.

=back

=cut

sub usesLib {
    my ($self) = shift;
    # should be 0 for Image::PNG::Libpng not installed, or -1 for is installed,
    # but not using it
    return $self->{'usesIPL'}->val();
}

1;

__END__

RFC 2083
PNG: Portable Network Graphics
January 1997


4.1.3. IDAT Image data

    The IDAT chunk contains the actual image data.  To create this
    data:

     * Begin with image scanlines represented as described in
       Image layout (Section 2.3); the layout and total size of
       this raw data are determined by the fields of IHDR.
     * Filter the image data according to the filtering method
       specified by the IHDR chunk.  (Note that with filter
       method 0, the only one currently defined, this implies
       prepending a filter type byte to each scanline.)
     * Compress the filtered data using the compression method
       specified by the IHDR chunk.

    The IDAT chunk contains the output datastream of the compression
    algorithm.

    To read the image data, reverse this process.

    There can be multiple IDAT chunks; if so, they must appear
    consecutively with no other intervening chunks.  The compressed
    datastream is then the concatenation of the contents of all the
    IDAT chunks.  The encoder can divide the compressed datastream
    into IDAT chunks however it wishes.  (Multiple IDAT chunks are
    allowed so that encoders can work in a fixed amount of memory;
    typically the chunk size will correspond to the encoder's buffer
    size.) It is important to emphasize that IDAT chunk boundaries
    have no semantic significance and can occur at any point in the
    compressed datastream.  A PNG file in which each IDAT chunk
    contains only one data byte is legal, though remarkably wasteful
    of space.  (For that matter, zero-length IDAT chunks are legal,
    though even more wasteful.)


4.2.9. tRNS Transparency

    The tRNS chunk specifies that the image uses simple
    transparency: either alpha values associated with palette
    entries (for indexed-color images) or a single transparent
    color (for grayscale and truecolor images).  Although simple
    transparency is not as elegant as the full alpha channel, it
    requires less storage space and is sufficient for many common
    cases.

    For color type 3 (indexed color), the tRNS chunk contains a
    series of one-byte alpha values, corresponding to entries in
    the PLTE chunk:

        Alpha for palette index 0:  1 byte
        Alpha for palette index 1:  1 byte
        ... etc ...

    Each entry indicates that pixels of the corresponding palette
    index must be treated as having the specified alpha value.
    Alpha values have the same interpretation as in an 8-bit full
    alpha channel: 0 is fully transparent, 255 is fully opaque,
    regardless of image bit depth. The tRNS chunk must not contain
    more alpha values than there are palette entries, but tRNS can
    contain fewer values than there are palette entries.  In this
    case, the alpha value for all remaining palette entries is
    assumed to be 255.  In the common case in which only palette
    index 0 need be made transparent, only a one-byte tRNS chunk is
    needed.

    For color type 0 (grayscale), the tRNS chunk contains a single
    gray level value, stored in the format:

        Gray:  2 bytes, range 0 .. (2^bitdepth)-1

    (For consistency, 2 bytes are used regardless of the image bit
    depth.) Pixels of the specified gray level are to be treated as
    transparent (equivalent to alpha value 0); all other pixels are
    to be treated as fully opaque (alpha value (2^bitdepth)-1).

    For color type 2 (truecolor), the tRNS chunk contains a single
    RGB color value, stored in the format:

        Red:   2 bytes, range 0 .. (2^bitdepth)-1
        Green: 2 bytes, range 0 .. (2^bitdepth)-1
        Blue:  2 bytes, range 0 .. (2^bitdepth)-1

    (For consistency, 2 bytes per sample are used regardless of the
    image bit depth.) Pixels of the specified color value are to be
    treated as transparent (equivalent to alpha value 0); all other
    pixels are to be treated as fully opaque (alpha value
    2^bitdepth)-1).

    tRNS is prohibited for color types 4 and 6, since a full alpha
    channel is already present in those cases.

    Note: when dealing with 16-bit grayscale or truecolor data, it
    is important to compare both bytes of the sample values to
    determine whether a pixel is transparent.  Although decoders
    may drop the low-order byte of the samples for display, this
    must not occur until after the data has been tested for
    transparency.  For example, if the grayscale level 0x0001 is
    specified to be transparent, it would be incorrect to compare
    only the high-order byte and decide that 0x0002 is also
    transparent.

    When present, the tRNS chunk must precede the first IDAT chunk,
    and must follow the PLTE chunk, if any.


6. Filter Algorithms

    This chapter describes the filter algorithms that can be applied
    before compression.  The purpose of these filters is to prepare the
    image data for optimum compression.


6.1. Filter types

    PNG filter method 0 defines five basic filter types:

        Type    Name

        0       None
        1       Sub
        2       Up
        3       Average
        4       Paeth

    (Note that filter method 0 in IHDR specifies exactly this set of
    five filter types.  If the set of filter types is ever extended, a
    different filter method number will be assigned to the extended
    set, so that decoders need not decompress the data to discover
    that it contains unsupported filter types.)

    The encoder can choose which of these filter algorithms to apply
    on a scanline-by-scanline basis.  In the image data sent to the
    compression step, each scanline is preceded by a filter type byte
    that specifies the filter algorithm used for that scanline.

    Filtering algorithms are applied to bytes, not to pixels,
    regardless of the bit depth or color type of the image.  The
    filtering algorithms work on the byte sequence formed by a
    scanline that has been represented as described in Image layout
    (Section 2.3).  If the image includes an alpha channel, the alpha
    data is filtered in the same way as the image data.

    When the image is interlaced, each pass of the interlace pattern
    is treated as an independent image for filtering purposes.  The
    filters work on the byte sequences formed by the pixels actually
    transmitted during a pass, and the "previous scanline" is the one
    previously transmitted in the same pass, not the one adjacent in
    the complete image.  Note that the subimage transmitted in any one
    pass is always rectangular, but is of smaller width and/or height
    than the complete image.  Filtering is not applied when this
    subimage is empty.

    For all filters, the bytes "to the left of" the first pixel in a
    scanline must be treated as being zero.  For filters that refer to
    the prior scanline, the entire prior scanline must be treated as
    being zeroes for the first scanline of an image (or of a pass of
    an interlaced image).

    To reverse the effect of a filter, the decoder must use the
    decoded values of the prior pixel on the same line, the pixel
    immediately above the current pixel on the prior line, and the
    pixel just to the left of the pixel above.  This implies that at
    least one scanline's worth of image data will have to be stored by
    the decoder at all times.  Even though some filter types do not
    refer to the prior scanline, the decoder will always need to store
    each scanline as it is decoded, since the next scanline might use
    a filter that refers to it.

    PNG imposes no restriction on which filter types can be applied to
    an image.  However, the filters are not equally effective on all
    types of data.  See Recommendations for Encoders: Filter selection
    (Section 9.6).

    See also Rationale: Filtering (Section 12.9).



6.2. Filter type 0: None

    With the None filter, the scanline is transmitted unmodified; it
    is only necessary to insert a filter type byte before the data.


6.3. Filter type 1: Sub

    The Sub filter transmits the difference between each byte and the
    value of the corresponding byte of the prior pixel.

    To compute the Sub filter, apply the following formula to each
    byte of the scanline:

        Sub(x) = Raw(x) - Raw(x-bpp)

    where x ranges from zero to the number of bytes representing the
    scanline minus one, Raw(x) refers to the raw data byte at that
    byte position in the scanline, and bpp is defined as the number of
    bytes per complete pixel, rounding up to one. For example, for
    color type 2 with a bit depth of 16, bpp is equal to 6 (three
    samples, two bytes per sample); for color type 0 with a bit depth
    of 2, bpp is equal to 1 (rounding up); for color type 4 with a bit
    depth of 16, bpp is equal to 4 (two-byte grayscale sample, plus
    two-byte alpha sample).

    Note this computation is done for each byte, regardless of bit
    depth.  In a 16-bit image, each MSB is predicted from the
    preceding MSB and each LSB from the preceding LSB, because of the
    way that bpp is defined.

    Unsigned arithmetic modulo 256 is used, so that both the inputs
    and outputs fit into bytes.  The sequence of Sub values is
    transmitted as the filtered scanline.

    For all x < 0, assume Raw(x) = 0.

    To reverse the effect of the Sub filter after decompression,
    output the following value:

        Sub(x) + Raw(x-bpp)

    (computed mod 256), where Raw refers to the bytes already decoded.


6.4. Filter type 2: Up

    The Up filter is just like the Sub filter except that the pixel
    immediately above the current pixel, rather than just to its left,
    is used as the predictor.

    To compute the Up filter, apply the following formula to each byte
    of the scanline:

        Up(x) = Raw(x) - Prior(x)

    where x ranges from zero to the number of bytes representing the
    scanline minus one, Raw(x) refers to the raw data byte at that
    byte position in the scanline, and Prior(x) refers to the
    unfiltered bytes of the prior scanline.

    Note this is done for each byte, regardless of bit depth.
    Unsigned arithmetic modulo 256 is used, so that both the inputs
    and outputs fit into bytes.  The sequence of Up values is
    transmitted as the filtered scanline.

    On the first scanline of an image (or of a pass of an interlaced
    image), assume Prior(x) = 0 for all x.

    To reverse the effect of the Up filter after decompression, output
    the following value:

        Up(x) + Prior(x)

    (computed mod 256), where Prior refers to the decoded bytes of the
    prior scanline.


6.5. Filter type 3: Average

    The Average filter uses the average of the two neighboring pixels
    (left and above) to predict the value of a pixel.

    To compute the Average filter, apply the following formula to each
    byte of the scanline:

        Average(x) = Raw(x) - floor((Raw(x-bpp)+Prior(x))/2)

    where x ranges from zero to the number of bytes representing the
    scanline minus one, Raw(x) refers to the raw data byte at that
    byte position in the scanline, Prior(x) refers to the unfiltered
    bytes of the prior scanline, and bpp is defined as for the Sub
    filter.

    Note this is done for each byte, regardless of bit depth.  The
    sequence of Average values is transmitted as the filtered
    scanline.

    The subtraction of the predicted value from the raw byte must be
    done modulo 256, so that both the inputs and outputs fit into
    bytes.  However, the sum Raw(x-bpp)+Prior(x) must be formed
    without overflow (using at least nine-bit arithmetic).  floor()
    indicates that the result of the division is rounded to the next
    lower integer if fractional; in other words, it is an integer
    division or right shift operation.

    For all x < 0, assume Raw(x) = 0.  On the first scanline of an
    image (or of a pass of an interlaced image), assume Prior(x) = 0
    for all x.

    To reverse the effect of the Average filter after decompression,
    output the following value:

        Average(x) + floor((Raw(x-bpp)+Prior(x))/2)

    where the result is computed mod 256, but the prediction is
    calculated in the same way as for encoding.  Raw refers to the
    bytes already decoded, and Prior refers to the decoded bytes of
    the prior scanline.


6.6. Filter type 4: Paeth

    The Paeth filter computes a simple linear function of the three
    neighboring pixels (left, above, upper left), then chooses as
    predictor the neighboring pixel closest to the computed value.
    This technique is due to Alan W. Paeth [PAETH].

    To compute the Paeth filter, apply the following formula to each
    byte of the scanline:

        Paeth(x) = Raw(x) - PaethPredictor(Raw(x-bpp), Prior(x), Prior(x-bpp))

    where x ranges from zero to the number of bytes representing the
    scanline minus one, Raw(x) refers to the raw data byte at that
    byte position in the scanline, Prior(x) refers to the unfiltered
    bytes of the prior scanline, and bpp is defined as for the Sub
    filter.

    Note this is done for each byte, regardless of bit depth.
    Unsigned arithmetic modulo 256 is used, so that both the inputs
    and outputs fit into bytes.  The sequence of Paeth values is
    transmitted as the filtered scanline.

    The PaethPredictor function is defined by the following
    pseudocode:

        function PaethPredictor (a, b, c)
        begin
            ; a = left, b = above, c = upper left
            p := a + b - c        ; initial estimate
            pa := abs(p - a)      ; distances to a, b, c
            pb := abs(p - b)
            pc := abs(p - c)
            ; return nearest of a,b,c,
            ; breaking ties in order a,b,c.
            if pa <= pb AND pa <= pc then return a
            else if pb <= pc then return b
            else return c
        end

    The calculations within the PaethPredictor function must be
    performed exactly, without overflow.  Arithmetic modulo 256 is to
    be used only for the final step of subtracting the function result
    from the target byte value.

    Note that the order in which ties are broken is critical and must
    not be altered.  The tie break order is: pixel to the left, pixel
    above, pixel to the upper left.  (This order differs from that
    given in Paeth's article.)

    For all x < 0, assume Raw(x) = 0 and Prior(x) = 0.  On the first
    scanline of an image (or of a pass of an interlaced image), assume
    Prior(x) = 0 for all x.

    To reverse the effect of the Paeth filter after decompression,
    output the following value:

        Paeth(x) + PaethPredictor(Raw(x-bpp), Prior(x), Prior(x-bpp))

    (computed mod 256), where Raw and Prior refer to bytes already
    decoded.  Exactly the same PaethPredictor function is used by both
    encoder and decoder.
