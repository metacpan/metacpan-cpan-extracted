package PDF::Builder::Resource::XObject::Image::TIFF_GT;

use base 'PDF::Builder::Resource::XObject::Image';

use strict;
use warnings;

no warnings 'uninitialized';

our $VERSION = '3.016'; # VERSION
my $LAST_UPDATE = '3.011'; # manually update whenever code is changed

use Compress::Zlib;

use PDF::Builder::Basic::PDF::Utils;
use PDF::Builder::Resource::XObject::Image::TIFF::File_GT;
use PDF::Builder::Util;
use Scalar::Util qw(weaken);
use Graphics::TIFF ':all';  # have already confirmed that this exists

=head1 NAME

PDF::Builder::Resource::XObject::Image::TIFF_GT - TIFF image support
(Graphics::TIFF enabled)

=head1 METHODS

=over

=item  $res = PDF::Builder::Resource::XObject::Image::TIFF_GT->new($pdf, $file, $name)

=item  $res = PDF::Builder::Resource::XObject::Image::TIFF_GT->new($pdf, $file)

Returns a TIFF-image object. C<$pdf> is the PDF object being added to, C<$file>
is the input TIFF file, and the optional C<$name> of the new parent image object
defaults to IxAAA.

If the Graphics::TIFF package is installed, and its use is not suppressed via
the C<-nouseGT> flag (see Builder documentation for C<image_tiff>), the TIFF_GT
library will be used. Otherwise, the TIFF library will be used instead.

=cut

sub new {
    my ($class, $pdf, $file, $name) = @_;

    my $self;

    my $tif = PDF::Builder::Resource::XObject::Image::TIFF::File_GT->new($file);

    # in case of problematic things
    #  proxy to other modules

    $class = ref($class) if ref $class;

    $self = $class->SUPER::new($pdf, $name || 'Ix'.pdfkey());
    $pdf->new_obj($self) unless $self->is_obj($pdf);

    $self->{' apipdf'} = $pdf;
    weaken $self->{' apipdf'};

    $self->read_tiff($pdf, $tif);

    $tif->close();

    return $self;
}

=item  $mode = $tif->usesLib()

Returns 1 if Graphics::TIFF installed and used, 0 if not installed, or -1 if
installed but not used (-nouseGT option given to C<image_tiff>).

B<Caution:> this method can only be used I<after> the image object has been
created. It can't tell you whether Graphics::TIFF is available in
advance of actually using it, in case you want to use some functionality
available only in TIFF_GT. See the <PDF::Builder> LA_GT() call if you
need to know in advance.

=back

=cut

sub usesLib {
    my ($self) = shift;
    # should be 1 for Graphics::TIFF is installed and used
    return $self->{'usesGT'}->val();
}

sub handle_generic {
    my ($self, $pdf, $tif) = @_;
    my ($stripcount, $buffer);

    $self->filters('FlateDecode');

    $stripcount = $tif->{'object'}->NumberOfStrips();
    $buffer = '';
    for my $i (0 .. $stripcount - 1) {
        $buffer .= $tif->{'object'}->ReadEncodedStrip($i, -1);
    }

    if ($tif->{'SamplesPerPixel'} == $tif->{'bitsPerSample'} + 1) {
	if ($tif->{'ExtraSamples'} == EXTRASAMPLE_ASSOCALPHA) {
	    if ($tif->{'bitsPerSample'} == 1) {
		$buffer = sample_greya_to_a($buffer);
            } else {
		warn "Don't know what to do with RGBA image\n";
            }
        } else {
	    warn "Don't know what to do with alpha layer in TIFF\n";
	}
    }
    $self->{' stream'} .= $buffer;

    return $self;
}

sub handle_ccitt {
    my ($self, $pdf, $tif) = @_;
    my ($stripcount);

    $self->{' nofilt'} = 1;
    $self->{'Filter'} = PDFArray(PDFName('CCITTFaxDecode'));
    my $decode = PDFDict();
    $self->{'DecodeParms'} = PDFArray($decode);
    # DecodeParms.K 0 if G3 or there are G3 options with bit 0 set, -1 for G4
    $decode->{'K'} = (($tif->{'ccitt'} == 4 || (defined $tif->{'g3Options'} && $tif->{'g3Options'} & 0x1))? PDFNum(-1): PDFNum(0));
    $decode->{'Columns'} = PDFNum($tif->{'imageWidth'});
    $decode->{'Rows'} = PDFNum($tif->{'imageHeight'});
    # not sure why whiteIsZero needs to be flipped around???
    $decode->{'BlackIs1'} = PDFBool($tif->{'whiteIsZero'} == 0? 1: 0);
    $decode->{'DamagedRowsBeforeError'} = PDFNum(100);

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
		if ($oldByte eq 0 || $oldByte eq 255) { next; }
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
}

sub read_tiff {
    my ($self, $pdf, $tif) = @_;

    $self->width($tif->{'imageWidth'});
    $self->height($tif->{'imageHeight'});
    if ($tif->{'colorSpace'} eq 'Indexed') {
        my $dict = PDFDict();
        $pdf->new_obj($dict);
        $self->colorspace(PDFArray(PDFName($tif->{'colorSpace'}), PDFName('DeviceRGB'), PDFNum(255), $dict));
        $dict->{'Filter'} = PDFArray(PDFName('FlateDecode'));
        $tif->{'fh'}->seek($tif->{'colorMapOffset'}, 0);
        my $colormap;
        my $straight;
        $tif->{'fh'}->read($colormap, $tif->{'colorMapLength'});
        $dict->{' stream'} = '';
        $straight .= pack('C', ($_/256)) for unpack($tif->{'short'} . '*', $colormap);
        foreach my $c (0 .. (($tif->{'colorMapSamples'}/3)-1)) {
            $dict->{' stream'} .= substr($straight, $c, 1);
            $dict->{' stream'} .= substr($straight, $c + ($tif->{'colorMapSamples'}/3), 1);
            $dict->{' stream'} .= substr($straight, $c + ($tif->{'colorMapSamples'}/3)*2, 1);
        }
    } else {
        $self->colorspace($tif->{'colorSpace'});
    }

    $self->{'Interpolate'} = PDFBool(1);
    $self->bits_per_component($tif->{'bitsPerSample'});

    if ($tif->{'whiteIsZero'} == 1 && $tif->{'filter'} ne 'CCITTFaxDecode') {
        $self->{'Decode'} = PDFArray(PDFNum(1), PDFNum(0));
    }

    # check filters and handle separately
    if (defined $tif->{'filter'} and $tif->{'filter'} eq 'CCITTFaxDecode') {
        $self->handle_ccitt($pdf, $tif);
    } else {
        $self->handle_generic($pdf, $tif);
    }

    $self->{' tiff'} = $tif;

    return $self;
}

1;
