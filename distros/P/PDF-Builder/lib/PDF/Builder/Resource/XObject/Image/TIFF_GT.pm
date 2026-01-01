package PDF::Builder::Resource::XObject::Image::TIFF_GT;

use base 'PDF::Builder::Resource::XObject::Image';

use strict;
use warnings;

our $VERSION = '3.028'; # VERSION
our $LAST_UPDATE = '3.027'; # manually update whenever code is changed

use Compress::Zlib;

use PDF::Builder::Basic::PDF::Utils;
use PDF::Builder::Resource::XObject::Image::TIFF::File_GT;
use PDF::Builder::Util;
use Scalar::Util qw(weaken);
use Graphics::TIFF ':all';  # have already confirmed the appropriate version exists

=head1 NAME

PDF::Builder::Resource::XObject::Image::TIFF_GT - TIFF image support
(Graphics::TIFF enabled)

Inherits from L<PDF::Builder::Resource::XObject::Image>

=head1 METHODS

=head2 new

    $res = PDF::Builder::Resource::XObject::Image::TIFF_GT->new($pdf, $file, %opts)

=over

Returns a TIFF-image object. C<$pdf> is the PDF object being added to, C<$file>
is the input TIFF file, and the optional C<$name> of the new parent image object
defaults to IxAAA.

If the Graphics::TIFF package is installed, and its use is not suppressed via
the C<nouseGT> flag (see Builder documentation for C<image_tiff>), the TIFF_GT
library will be used. Otherwise, the TIFF library will be used instead.

Options:

=over

=item 'notrans' => 1

Ignore any alpha layer (transparency) and make the image fully opaque.

=item 'name' => 'string'

This is the name you can give for the TIFF image object. The default is Ixnnnn.

=back

TIFF support (when using Graphics::TIFF) is for C<PhotometricInterpretation>
values of 0 (bilevel/gray, white is 0), 1 (bilevel/gray, black is 0), 2 (RGB),
and 3 (Palette color). It currently does I<not> support 4 (transparency mask),
5 (separated CMYK), 6 (YCbCr), 8 (CIELab), or higher. There is limited support 
for an Alpha (transparency) channel (due to extremely limited test cases). 
Some tags are not supported, and a PlanarConfiguration of 2 is unknown until 
we get some test cases.

Some applications seem to take odd liberties with TIFF tags, such as adding a
SamplePerPixel without specifying ExtraSamples type. In such cases, we treat
one extra sample (not otherwise defined) as an Alpha channel, and hope for 
the best!

If there are invalid tags or field values within a tag, the Graphics::TIFF
library will attempt to pop-up a warning dialog, rather than just ignoring 
invalid things. If we can find a switch to disable this behavior, we will
look into adding it as an option. According to Graphic::TIFF's owner 
(ticket RT 133955), this is coming directly from libtiff (as write to STDERR), 
so he can't do anything about it!

Finally, while Graphics::TIFF does not directly support passing in a filehandle
(usually a GLOB), PDF::Builder will attempt to detect this issue and write the
content (from the filehandle) to a temporary file, and pass that in as a
normal file. Some operating systems appear to have trouble erasing this
temporary file, so be aware that such files may build up over time!

=back

=cut

sub new {
    my ($class, $pdf, $file, %opts) = @_;
    # copy dashed option names to preferred undashed names
    if (defined $opts{'-nouseGT'} && !defined $opts{'nouseGT'}) { $opts{'nouseGT'} = delete($opts{'-nouseGT'}); }
    if (defined $opts{'-name'} && !defined $opts{'name'}) { $opts{'name'} = delete($opts{'-name'}); }
    if (defined $opts{'-compress'} && !defined $opts{'compress'}) { $opts{'compress'} = delete($opts{'-compress'}); }
    if (defined $opts{'-notrans'} && !defined $opts{'notrans'}) { $opts{'notrans'} = delete($opts{'-notrans'}); }

    my ($name, $compress);
    if (exists $opts{'name'}) { $name = $opts{'name'}; }
   #if (exists $opts{'compress'}) { $compress = $opts{'compress'}; }

    my $self;

    my $tif = PDF::Builder::Resource::XObject::Image::TIFF::File_GT->new($file, %opts);

    # in case of problematic things
    #  proxy to other modules

    $class = ref($class) if ref($class);

    $self = $class->SUPER::new($pdf, $name || 'Ix'.pdfkey());
    $pdf->new_obj($self) unless $self->is_obj($pdf);

    $self->{' apipdf'} = $pdf;
    weaken $self->{' apipdf'};

    # set up dict stream for any Alpha channel to be split out from $buffer
    my $dict = PDFDict();

    # let's try to clarify various strange tag combinations
    # one extra SamplesPerPixel (2/4) and no ExtraSamples (or is 0)?
    #   treat as an Alpha channel with ExtraSamples 2 (unassociated alpha)
    if ($tif->{'colorSpace'} eq 'DeviceGray' && 
	$tif->{'SamplesPerPixel'} == 2 &&
        (!defined $tif->{'ExtraSamples'} || $tif->{'ExtraSamples'} == 0)) {
        # let's assume it's realy SPP 1 with ExtraSamples UNASSOC_ALPHA
        $tif->{'SamplesPerPixel'} = 1;
	$tif->{'ExtraSamples'} = EXTRASAMPLE_UNASSALPHA;  # 2
	#print "  changed SPP 2 to 1, ES 0 to 2, to treat as GA\n";
    }
    if ($tif->{'colorSpace'} eq 'DeviceRGB' && 
	$tif->{'SamplesPerPixel'} == 4 &&
        (!defined $tif->{'ExtraSamples'} || $tif->{'ExtraSamples'} == 0)) {
        # let's assume it's realy SPP 3 with ExtraSamples UNASSOC_ALPHA
        $tif->{'SamplesPerPixel'} = 3;
	$tif->{'ExtraSamples'} = EXTRASAMPLE_UNASSALPHA;  # 2
	#print "  changed SPP 4 to 3, ES 0 to 2, to treat as RGBA\n";
    }
    # otherwise ExtraSamples is in order, but have "extra" sample
    if ($tif->{'colorSpace'} eq 'DeviceGray' && 
	$tif->{'SamplesPerPixel'} == 2) {
        $tif->{'SamplesPerPixel'} = 1;
    }
    if ($tif->{'colorSpace'} eq 'DeviceRGB' && 
	$tif->{'SamplesPerPixel'} == 4) {
        $tif->{'SamplesPerPixel'} = 3;
    }

    $self->read_tiff($pdf, $tif, %opts);

    $tif->close();

    return $self;
} # end of new()

=head2 usesLib

    $mode = $tif->usesLib()

=over

Returns 1 if Graphics::TIFF installed and used, 0 if not installed, or -1 if
installed but not used (nouseGT option given to C<image_tiff>).

B<Caution:> this method can only be used I<after> the image object has been
created. It can't tell you whether Graphics::TIFF is available in
advance of actually using it, in case you want to use some functionality
available only in TIFF_GT. See the L<PDF::Builder> LA_GT() call if you
need to know in advance.

=back

=cut

sub usesLib {
    my ($self) = shift;
    # should be 1 for Graphics::TIFF is installed and used
    return $self->{'usesGT'}->val();
}

sub decode_all_strips {
    my ($self, $tif) = @_;
    $self->{' stream'} = '';
    for my $i (0 .. $tif->{object}->NumberOfStrips() - 1) {
        $self->{' stream'} .= $tif->{object}->ReadEncodedStrip($i, -1);
    }
    return;
}

sub handle_alpha {
    my ($self, $pdf, $tif, %opts) = @_;
    my $transparency = (defined $opts{'notrans'} && $opts{'notrans'} == 1)? 0: 1;
    my ($alpha, $dict);

    # handle any Alpha channel/layer
    my $h = $tif->{'imageHeight'};  # in pixels
    my $w = $tif->{'imageWidth'};
    my $samples = 1; # fallback

    if      (defined $tif->{'ExtraSamples'} &&
	     $tif->{'ExtraSamples'} == EXTRASAMPLE_ASSOCALPHA) {
	# Gray or RGB pre-multiplication will likely have to be backed out
        if      ($tif->{'colorSpace'} eq 'DeviceGray') {
	    # Gray or Bilevel (pre-multiplied) + Alpha 
	    $samples = 1;
        } elsif ($tif->{'colorSpace'} eq 'DeviceRGB') {
	    # RGB (pre-multiplied) + Alpha 
	    $samples = 3;
	} else {
	    warn "Invalid TIFF file, requested Alpha for $tif->{'colorSpace'}".
	         ", PDF will likely be defective!\n";
	}
	($self->{' stream'}, $alpha) = 
	    split_alpha($self->{' stream'}, $samples, $tif->{'bitsPerSample'}, $w, $h);
	$self->{' stream'} = 
	    descale($self->{' stream'}, $samples, $tif->{'bitsPerSample'}, $alpha, $w*$h);
    } elsif (defined $tif->{'ExtraSamples'} &&
	     $tif->{'ExtraSamples'} == EXTRASAMPLE_UNASSALPHA) {
	# Gray or RGB at full value, no adjustment needed
        if      ($tif->{'colorSpace'} eq 'DeviceGray') {
	    # Gray or Bilevel + Alpha
	    $samples = 1;
        } elsif ($tif->{'colorSpace'} eq 'DeviceRGB') {
	    # RGB + Alpha
	    $samples = 3;
	} else {
	    warn "Invalid TIFF file, requested Alpha for $tif->{'colorSpace'}".
	         ", PDF will likely be defective!\n";
	}
	($self->{' stream'}, $alpha) = 
	    split_alpha($self->{' stream'}, $samples, $tif->{'bitsPerSample'}, $w, $h);
    }

    # $alpha is undef if no alpha layer found
    if (defined $alpha and $transparency) {
        $dict = PDFDict();
        $pdf->new_obj($dict);
        $dict->{'Type'} = PDFName('XObject');
        $dict->{'Subtype'} = PDFName('Image');
        $dict->{'Width'} = PDFNum($w);
        $dict->{'Height'} = PDFNum($h);
        $dict->{'ColorSpace'} = PDFName('DeviceGray');  # Alpha is always
        $dict->{'BitsPerComponent'} = PDFNum($tif->{'bitsPerSample'});
        $self->{'SMask'} = $dict;
        $dict->{' stream'} = $alpha;
    }
    return $dict;
}

# non-CCITT compression methods
sub handle_generic {
    my ($self, $pdf, $tif, %opts) = @_;

    # colorspace DeviceGray or DeviceRGB already set in read_tiff()
    # bits_per_component 1 2 4 8 16? already set in read_tiff()
    my $dict = PDFDict();
    $self->{'DecodeParms'} = PDFArray($dict);
    $dict->{'BitsPerComponent'} = PDFNum($tif->{'bitsPerSample'});
    $dict->{'Colors'} = PDFNum($tif->{'colorSpace'} eq 'DeviceGray'?1 :3);

    # uncompressed bilevel needs to be flipped
    if (!defined $tif->{'filter'} && $tif->{'bitsPerSample'} == 1) {
        $self->{'Decode'} = PDFArray(PDFNum(1), PDFNum(0));
    }
    $self->decode_all_strips($tif);
    my $alpha = $self->handle_alpha($pdf, $tif, %opts);

    # compress all but short streams
    if (length($self->{' stream'}) > 32) {
        $self->{' stream'} = Compress::Zlib::compress($self->{' stream'});
        $self->filters('FlateDecode');  # tell reader it's compressed...
    } else {
        # too short to bother compressing. '/Filter [ /FlateDecode ] ' 
        # takes up 25 bytes all by itself
        delete $self->{'Filter'};
    }
    $self->{' nofilt'} = 1;
    if (defined $alpha and $alpha->{' stream'}) {  # there is transparency?
        if (length($alpha->{' stream'}) > 32) {
            $alpha->{' stream'} = Compress::Zlib::compress($alpha->{' stream'});
            $alpha->filters('FlateDecode');  # tell reader it's compressed...
        } else {
            # too short to bother compressing. '/Filter [ /FlateDecode ] ' 
            # takes up 25 bytes all by itself
            delete $alpha->{'Filter'};
        }
        $alpha->{' nofilt'} = 1;
    }

    return $self;
} # end of handle_generic()

# split alpha from buffer (both strings)
# bps = width of a sample in bits, samples 1 (G) or 3 (RGB)
# returns $buffer and $alpha strings
# TBD: fill order or other directional issues?
sub split_alpha {
    my ($inbuf, $samples, $bps, $w, $h) = @_;
    my $count = $w * $h;
    my $outbuf = '';
    my $alpha = '';

## debug
#my @slice; # TEMP
#if ($count == 999*1056) {
# # French text pag1.tif
# @slice = (823*999, 823*999+125); # row 824/1056
#}elsif($count == 1000*568) {
# # Lorem ipsum alpha.tif
# @slice = (283*1000, 283*1000+125); # row 284/568
#}else{
# @slice = (-1, -1);
#}
 
## debug
## upon entry, what is raw input row? # TEMP
#if ($slice[0]>-1 && $bps==16){
# print "bps==16 raw input slice: ";
# for (my $i=$slice[0]; $i<$slice[1]; $i++){
#  my $pixel = substr($inbuf, $i*($samples+1)*2, ($samples+1)*2);
#  my @pixelbytes = split //, $pixel;
#  foreach (@pixelbytes) {printf("%02X", ord($_));}
#  print " ";
# }
# print "\n";
#}
#if ($slice[0]>-1 && $bps==8){
# print "bps==8 raw input slice: ";
# for (my $i=$slice[0]; $i<$slice[1]; $i++){
#  my $pixel = substr($inbuf, $i*($samples+1), $samples+1);
#  my @pixelbytes = split //, $pixel;
#  foreach (@pixelbytes) {printf("%02X", ord($_));}
#  print " ";
# }
# print "\n";
#}
## bps<8 is ugly to dump and not worth doing

    # COULD have different number of bits per sample, unless GT prevents this
    if      ($bps == 16) {
        # full double bytes to work with (not sure if 16bps in TIFF)
        for (my $i=0; $i<$count; $i++) {
 	    substr($outbuf, $i*$samples*2, $samples*2) =
	        substr($inbuf, $i*($samples+1)*2, $samples*2);
 	    substr($alpha, $i*2, 2) =
	        substr($inbuf, $i*($samples+1)*2+$samples*2, 2);
        }
    } elsif ($bps == 8) {
        # full bytes to work with
        for (my $i=0; $i<$count; $i++) {
 	    substr($outbuf, $i*$samples, $samples) =
	        substr($inbuf, $i*($samples+1), $samples);
        substr($alpha, $i, 1) =
            substr($inbuf, $i*($samples+1)+$samples, 1);
        }
    } else {
        # fractional bytes (bps < 8) possible to have not 2**N?
        my $strideBits = $bps*($samples+1);
	my $inbits = unpack('B*', $inbuf);    # bits from inbuf string
	my $outbits = '';   # bits to outbuf string (starts empty)
	my $outbits_a = '';  # build alpha string (starts empty)
        my $index = 0;
        for my $row (0 .. $h-1) {
            my $rowbuf = '';
            my $rowbuf_a = '';
            for my $column (0 .. $w-1) {
                $rowbuf .= substr($inbits, $index, $samples*$bps);
                $index += $samples*$bps;
                $rowbuf_a .= substr($inbits, $index, $bps);
                $index += $bps;
            }

            # padding for input could be different from output, e.g. width = 4
            # requires no padding on input, but 4 on output.
            $index += $w*$samples*($bps+1) % 8;

            # given that bilevel images with a width that is not divisible by 8
            # are padded to make a whole number of bytes per row, the padding
            # must be adjusted when deinterleaving the alpha layer.
            $outbits .= $rowbuf . pad_buffer($rowbuf, $samples, $bps);
            $outbits_a .= $rowbuf_a . pad_buffer($rowbuf_a, 1, $bps);
        }
        $outbuf = pack('B*', $outbits);
        $alpha = pack('B*', $outbits_a);
    } # end of fractional byte (bits) handling

## debug
## upon exit, what is output data row? # TEMP
#if ($slice[0]>-1 && $bps==16){
# print "bps==16 output data slice: ";
# for (my $i=$slice[0]; $i<$slice[1]; $i++){
#  my $pixel = substr($outbuf, $i*$samples*2, $samples*2);
#  my @pixelbytes = split //, $pixel;
#  foreach (@pixelbytes) {printf("%02X", ord($_));}
#  print " ";
# }
# print "\n";
#}
#if ($slice[0]>-1 && $bps==8){
# print "bps==8 output data slice: ";
# for (my $i=$slice[0]; $i<$slice[1]; $i++){
#  my $pixel = substr($outbuf, $i*$samples, $samples);
#  my @pixelbytes = split //, $pixel;
#  foreach (@pixelbytes) {printf("%02X", ord($_));}
#  print " ";
# }
# print "\n";
#}
## upon exit, what is output alpha row? # TEMP
#if ($slice[0]>-1 && $bps==16){
# print "bps==16 output alpha slice: ";
# for (my $i=$slice[0]; $i<$slice[1]; $i++){
#  my $pixel = substr($alpha, $i*2, 2);
#  my @pixelbytes = split //, $pixel;
#  foreach (@pixelbytes) {printf("%02X", ord($_));}
#  print " ";
# }
# print "\n";
#}
#if ($slice[0]>-1 && $bps==8){
# print "bps==8 output alpha slice: ";
# for (my $i=$slice[0]; $i<$slice[1]; $i++){
#  my $pixel = substr($alpha, $i, 1);
#  my @pixelbytes = split //, $pixel;
#  foreach (@pixelbytes) {printf("%02X", ord($_));}
#  print " ";
# }
# print "\n";
#}

    return ($outbuf, $alpha);
} # end of split_alpha()

sub pad_buffer {
    my ($buf, $samples, $bps) = @_;
    my $padbuf = '';
    my $pad = length($buf) % 8;
    if ($pad) {
        $pad = 8 - $pad;
    }
    for (0..$samples*$bps*$pad-1) {
        $padbuf .= '0';
    }
    return $padbuf;
}

# bps = width of a sample in bits, samples 1 (G) or 3 (RGB)
# return updated buffer  WARNING: not tested!
sub descale {
    my ($inbuf, $samples, $bps, $alpha, $count) = @_;
    my $outbuf = '';
    if ($bps == 1) {
        # 1 bps no effect
        $outbuf = $inbuf; 
        return $outbuf;
    }
    # 1. assuming alpha is 0.0 fully transparent to 1.0 fully opaque
    # 2. sample has already been multiplied by alpha (0 if fully transparent)
    # 3. if alpha is 0, leave sample as 0. otherwise...
    # 4. convert sample and alpha to decimal 0.0..1.0
    # 5. sample = sample/alpha
    # 6. round, integerize, and clamp sample to 0..max val range
    my $maxVal = 2**$bps - 1;
    my ($pixR, @samplesR, @samplesC, $alphaR);

    # items used for fractional byte (bits)
    my $strideBits = $bps*$samples;
    my @inBits = ();    # bits from inbuf string
    my @outBits = ();   # bits to outbuf string (starts empty)
    my @inABits = ();   # bits from alpha string
    my $inByte = 0;     # 1 or 3 samples only, not changing alpha values
    my $outByte = 0;
    my $inAByte = 0;

    for (my $pix = 0; $pix < $count; $pix++) {
	if      ($bps == 16) { # not sure if TIFF does 16bps 
	    @samplesC = split //, substr($alpha, $pix, 2);
	    $alphaR = (ord($samplesC[0])*256 + ord($samplesC[1]))*1.0/$maxVal;
	    if ($alphaR > 0.0) {
		@samplesC = split //, substr($inbuf, $pix*$samples*2, $samples*2);
		for (my $i=0; $i<$samples; $i++) {
		    $pixR = (ord($samplesC[2*$i])*256+ord($samplesC[2*$i+1]))*1.0/$maxVal;
		    $pixR /= $alphaR;
		    $pixR = int($pixR * $maxVal);
		    $outbuf .= chr($pixR>>8);
		    $outbuf .= chr($pixR%256);
		}
	    } else {
		# alpha is 0 for this pixel, so just use original value
		$outbuf .= substr($inbuf, $pix*$samples*2, $samples*2);
	    }
	} elsif ($bps == 8) {
	    $alphaR = ord(substr($alpha, $pix, 1))*1.0/$maxVal;
	    if ($alphaR > 0.0) {
		@samplesC = split //, substr($inbuf, $pix*$samples, $samples);
		foreach (@samplesC) {
		    $pixR = ord($_)*1.0/$maxVal;
		    $pixR /= $alphaR;
		    $outbuf .= chr(int($pixR * $maxVal));
		}
	    } else {
		# alpha is 0 for this pixel, so just use original value
		$outbuf .= substr($inbuf, $pix*$samples, $samples);
	    }
	} else { # 1 < $bps < 8. $pix-th pixel, $samples 1 or 3
	    # fractions of a byte per sample
	    # pix-th pixel is next 2 or more bits in inBits
	     
	    # build up enough bits in inBits to get full pixel data
	    while (scalar(@inBits) < $strideBits) {
		push @inBits, split(//, unpack('B8', substr($inbuf, $inByte++, 1)));
	    }
	    my @Bits = ();
	    for (my $i=0; $i<$samples; $i++) {
		push @Bits, [splice(@inBits, 0, $bps)];
	    }
	    # now have enough bits in Bits array for recalculating or 
	    #   adding to output buffer (if skip due to alpha)

	    # build up enough bits in inABits to get next alpha
	    while (scalar(@inABits) < $bps) {
		push @inABits, split(//, unpack('B8', substr($alpha, $inAByte++, 1)));
	    }
	    # now have enough bits in inABits array for calculating alpha 
	    my @ABits = splice(@inABits, 0, $bps);
	    $alphaR = ba2ui(@ABits)*1.0/$maxVal;
	    
	    # calculate alpha, and if > 0, make real 0.0-1.0...
	    if ($alphaR > 0.0) {
	        # ...turn sample(s) into reals 0.0-1.0, divide by alpha
	        # turn samples back into ints, then bits to add to outBits
                for (my $i=0; $i<$samples; $i++) {
		    $pixR = ba2ui(@{ $Bits[$i] })*1.0/$maxVal;
		    $pixR /= $alphaR;
		    $Bits[$i] = ui2ba(int($pixR*$maxVal), $bps);
		}
	    }
	    
	    # @Bits returned to outBits, whether original or recalculated
	    for (my $i=0; $i<$samples; $i++) {
	        push @outBits, @{ $Bits[$i] };
	    }

	    # do we have at least one full byte to output to outbuf?
	    while (scalar(@outBits) >= 8) {
		substr($outbuf, $outByte++, 1) = pack('B8', join('', splice(@outBits, 0, 8)));
	    }
	    # there may be leftover bits (for next pixel) in inBits
	    # outBits may also have partial content yet to write
            
        } # end of fractional byte section
    } # loop through pixels ($pix)

    # fractional bytes, anything waiting to be written out?
    # @outBits should be empty for bps=8/16, may be empty otherwise
    if (scalar(@outBits)) {
        # pad out to 8 bits in length (should be no more than 7)
        while (scalar(@outBits) < 8) {
            push @outBits, 0;
        }
        substr($outbuf, $outByte++, 1) = pack('B8', join('', @outBits));
    }

    # not changing Alpha array at all
    return $outbuf;
} # end of descale()

# binary bit stream array to unsigned integer
sub ba2ui {
    my @inArray = @_;

    my $value = 0;
    foreach (@inArray) {
        $value = 2*$value + $_;
    }
    return $value;
}

# unsigned integer to binary bit stream array
sub ui2ba {
    my ($inVal, $maxBits) = @_;

    my $maxVal = 2**$maxBits-1; # not to exceed this value
    if ($inVal > $maxVal) { $inVal = $maxVal; }
    if ($inVal < 0) { $inVal = 0; }

    my @array = ();
    my $bit;
    foreach (1 .. $maxBits) {
        $bit = $inVal%2;
	unshift @array, $bit;
	$inVal >>= 1;
    }

    return @array;
}

sub handle_ccitt {
    my ($self, $pdf, $tif, %opts) = @_;
    my ($stripcount);

    $self->{' nofilt'} = 1;
    $self->{'Filter'} = PDFArray(PDFName('CCITTFaxDecode'));
    my $decode = PDFDict();
    $self->{'DecodeParms'} = PDFArray($decode);
    # DecodeParms.K 0 if G3 or there are G3 options with bit 0 set, -1 for G4
    $decode->{'K'} = ($tif->{'ccitt'} == 4 || 
        (defined $tif->{'g3Options'} && $tif->{'g3Options'} & 0x1))? PDFNum(-1): PDFNum(0);
    $decode->{'Columns'} = PDFNum($tif->{'imageWidth'});
    $decode->{'Rows'} = PDFNum($tif->{'imageHeight'});
    $decode->{'BlackIs1'} = PDFBool($tif->{'whiteIsZero'} == 1? 1: 0);
    $decode->{'DamagedRowsBeforeError'} = PDFNum(100);
    # all CCITT Fax need to flip black/white
    $self->{'Decode'} = PDFArray(PDFNum(1), PDFNum(0));

    # g3Options       bit 0 = 0 for 1-Dimensional, = 1 for 2-Dimensional MR
    #  aka T4Options  bit 1 = 0 (compressed data only)
    #                 bit 2 = 0 non-byte-aligned EOLs, = 1 byte-aligned EOLs
    # g4Options       bit 0 = 0 MMR 2-D compression
    #  aka T6Options  bit 1 = 0 (compressed data only)
    #  aka Group4Options
    if (defined($tif->{'g3Options'}) && ($tif->{'g3Options'} & 0x4)) {
        $decode->{'EndOfLine'} = PDFBool(1);
        $decode->{'EncodedByteAlign'} = PDFBool(1);
    }
    # TBD currently nothing to look at for g4Options

    if (ref($tif->{'imageOffset'})) {
        die "Chunked CCITT G3/G4 TIFF not supported.";
    } else {
	$stripcount = $tif->{'object'}->NumberOfStrips();
	for my $i (0 .. $stripcount - 1) {
            $self->{' stream'} .= $tif->{'object'}->ReadRawStrip($i, -1);
	}
        # if bit fill order in data is opposite of PDF spec (Lsb2Msb), need to 
	# swap each byte end-for-end: x01->x80, x02->x40, x03->xC0, etc.
	#
	# a 256-entry lookup table could probably do just as well and build
	# up the replacement string rather than constantly substr'ing.
	if ($tif->{'fillOrder'} == 2) { # Lsb first, PDF is Msb
	    my ($oldByte, $newByte);
	    for my $j ( 0 .. length($self->{' stream'}) ) {
	        # swapping j-th byte of stream
		$oldByte = ord(substr($self->{' stream'}, $j, 1));
		if ($oldByte == 0 || $oldByte == 255) { next; }
		$newByte = 0;
		if ($oldByte & 0x01) { $newByte |= 0x80; }
		if ($oldByte & 0x02) { $newByte |= 0x40; }
		if ($oldByte & 0x04) { $newByte |= 0x20; }
		if ($oldByte & 0x08) { $newByte |= 0x10; }
		if ($oldByte & 0x10) { $newByte |= 0x08; }
		if ($oldByte & 0x20) { $newByte |= 0x04; }
		if ($oldByte & 0x40) { $newByte |= 0x02; }
		if ($oldByte & 0x80) { $newByte |= 0x01; }
                substr($self->{' stream'}, $j, 1) = chr($newByte);
	    }
        }
    }

    return $self;
} # end of handle_ccitt()

sub handle_lzw {
    my ($self, $pdf, $tif, %opts) = @_;

    # colorspace DeviceGray or DeviceRGB already set in read_tiff()
    # bits_per_component 1 2 4 8 16? already set in read_tiff()
    $self->{' nofilt'} = 1;
    $self->{'Filter'} = PDFArray(PDFName('LZWDecode'));
    my $dict = PDFDict();
    $self->{'DecodeParms'} = PDFArray($dict);
    $dict->{'Columns'} = PDFNum($tif->{'imageWidth'});
    $dict->{'Rows'} = PDFNum($tif->{'imageHeight'});
    # colorspace DeviceGray or DeviceRGB already set in read_tiff()
    # bits_per_component 1 2 4 8 16? already set in read_tiff()
    $dict->{'BitsPerComponent'} = PDFNum($tif->{'bitsPerSample'});
    $dict->{'Colors'} = PDFNum($tif->{'colorSpace'} eq 'DeviceGray'?1 :3);
    if (defined $tif->{'Predictor'} and $tif->{'Predictor'} > 1) {
        $dict->{'Predictor'} = PDFNum($tif->{'Predictor'});
    }

    # have to decode in case we have alpha to split out
    $self->decode_all_strips($tif);
    my $alpha = $self->handle_alpha($pdf, $tif, %opts);

    # bilevel must be flipped
    if ($alpha and $tif->{'bitsPerSample'} == 1) {
        $self->{'Decode'} = PDFArray(PDFNum(1), PDFNum(0));
    }

    my $filter = PDF::Builder::Basic::PDF::Filter::LZWDecode->new($dict);
    $self->{' stream'} = $filter->outfilt($self->{' stream'});

    if (defined $alpha and defined $alpha->{' stream'}) {  # there is transparency?
        if (length($alpha->{' stream'}) > 32) {
            my $filter = PDF::Builder::Basic::PDF::Filter::LZWDecode->new();
            $alpha->{' stream'} = $filter->outfilt($alpha->{' stream'});
            $alpha->filters('LZWDecode');  # tell reader it's compressed...
        } else {
            # too short to bother compressing. '/Filter [ /LZWDecode ] ' 
            # takes up 25 bytes all by itself
            delete $alpha->{Filter};
        }
        $alpha->{' nofilt'} = 1;  # ...but writer not to compress on the fly
    }

    return $self;
} # end of handle_lzw()

sub read_tiff {
    my ($self, $pdf, $tif, %opts) = @_;

    $self->width($tif->{'imageWidth'});
    $self->height($tif->{'imageHeight'});

    if ($tif->{'colorSpace'} eq 'Indexed') {
        my $dict = PDFDict();
        $pdf->new_obj($dict);
        $self->colorspace(PDFArray(PDFName($tif->{'colorSpace'}),
	    	PDFName('DeviceRGB'), PDFNum(2**$tif->{'bitsPerSample'}-1), $dict));
        $dict->{'Filter'} = PDFArray(PDFName('FlateDecode'));
        my ($red, $green, $blue) = @{$tif->{'colorMap'}};
        $dict->{' stream'} = '';
        for my $i (0 .. $#{$red}) {
            $dict->{' stream'} .= pack('C', ($red->[$i]/256));
            $dict->{' stream'} .= pack('C', ($green->[$i]/256));
            $dict->{' stream'} .= pack('C', ($blue->[$i]/256));
        }
    } else {
	# DeviceGray or DeviceRGB
        $self->colorspace($tif->{'colorSpace'});
    }

    $self->{'Interpolate'} = PDFBool(1);
    $self->bits_per_component($tif->{'bitsPerSample'});

    # swaps 0 and 1 ([0 1] -> [1 0]) in certain cases
    if (($tif->{'whiteIsZero'}||0) == 1 &&
	($tif->{'filter'}||'') ne 'CCITTFaxDecode') {
        $self->{'Decode'} = PDFArray(PDFNum(1), PDFNum(0));
    }

    # check filters and handle separately
    if (defined $tif->{'filter'} and $tif->{'filter'} eq 'CCITTFaxDecode') {
        $self->handle_ccitt($pdf, $tif, %opts);
    } elsif (defined $tif->{'filter'} and $tif->{'filter'} eq 'LZWDecode') {
        $self->handle_lzw($pdf, $tif, %opts);
    } else {
        $self->handle_generic($pdf, $tif, %opts);
    }

    $self->{' tiff'} = $tif;

    return $self;
} # end of read_tiff()

1;
