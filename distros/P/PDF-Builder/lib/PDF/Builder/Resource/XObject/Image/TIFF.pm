package PDF::Builder::Resource::XObject::Image::TIFF;

use base 'PDF::Builder::Resource::XObject::Image';

use strict;
use warnings;

our $VERSION = '3.027'; # VERSION
our $LAST_UPDATE = '3.027'; # manually update whenever code is changed

use Compress::Zlib;

use PDF::Builder::Basic::PDF::Utils;
use PDF::Builder::Resource::XObject::Image::TIFF::File;
use PDF::Builder::Util;
use Scalar::Util qw(weaken);

=head1 NAME

PDF::Builder::Resource::XObject::Image::TIFF - TIFF image support

Inherits from L<PDF::Builder::Resource::XObject::Image>

=head1 METHODS

=head2 new

    $res = PDF::Builder::Resource::XObject::Image::TIFF->new($pdf, $file, %opts)

=over

Returns a TIFF-image object.

If the Graphics::TIFF package is installed, the TIFF_GT library will be used
instead of the TIFF library. In such a case, use of the TIFF library may be 
forced via the C<nouseGT> flag (see Builder documentation for C<image_tiff()>).

Options:

=over

=item 'name' => 'string'

This is the name you can give for the TIFF image object. The default is Ixnnnn.

=back

Remember that you need to use the Builder.pm method image_tiff in order to
display a TIFF file.

=back

=cut

sub new {
    my ($class, $pdf, $file, %opts) = @_;
    # copy dashed option names to preferred undashed names
    if (defined $opts{'-nouseGT'} && !defined $opts{'nouseGT'}) { $opts{'nouseGT'} = delete($opts{'-nouseGT'}); }
    if (defined $opts{'-name'} && !defined $opts{'name'}) { $opts{'name'} = delete($opts{'-name'}); }
    if (defined $opts{'-compress'} && !defined $opts{'compress'}) { $opts{'compress'} = delete($opts{'-compress'}); }

    my ($name, $compress);
    if (exists $opts{'name'}) { $name = $opts{'name'}; }
   #if (exists $opts{'compress'}) { $compress = $opts{'compress'}; }

    my $self;

    my $tif = PDF::Builder::Resource::XObject::Image::TIFF::File->new($file, %opts);

 # dump everything in tif except huge data streams
# foreach (sort keys %{ $tif }) {
# if ($_ eq ' stream') { next; }
# if ($_ eq ' apipdf') { next; }
# if ($_ eq ' realised') { next; }
# if ($_ eq ' uid') { next; }
#  if (defined $tif->{$_}) {
#   print "\$tif->{'$_'} = '".($tif->{$_})."'\n";
#  } else {
#   print "\$tif->{'$_'} = ?\n";
#  }
# }

    # in case of problematic things
    #  proxy to other modules

    $class = ref($class) if ref($class);

    $self = $class->SUPER::new($pdf, $name || 'Ix'.pdfkey());
    $pdf->new_obj($self) unless $self->is_obj($pdf);

    $self->{' apipdf'} = $pdf;
    weaken $self->{' apipdf'};

    $self->read_tiff($pdf, $tif);

    $tif->close();

    return $self;
}

=head2 usesLib

    $mode = $tif->usesLib()

=over

Returns 1 if Graphics::TIFF installed and used, 0 if not installed, or -1 if
installed but not used (nouseGT option given to C<image_tiff>).

B<Caution:> this method can only be used I<after> the image object has been
created. It can't tell you whether Graphics::TIFF is available in
advance of actually using it, in case you want to use some functionality
available only in TIFF_GT. See the <PDF::Builder> LA_GT() call if you
need to know in advance.

=back

=cut

sub usesLib {
    my ($self) = shift;
    # should be 0 for Graphics::TIFF not installed, or -1 for is installed,
    # but not using it
    return $self->{'usesGT'}->val();
}

sub handle_generic {
    my ($self, $pdf, $tif) = @_;

    if ($tif->{'filter'}) {
        # should we die here ?
        # die "unknown tiff-compression ";
        $self->filters($tif->{'filter'});
        $self->{' nofilt'} = 1;
    } else {
        $self->filters('FlateDecode');
    }

    if (ref($tif->{'imageOffset'})) {
        $self->{' stream'} = '';
        my $d = scalar @{$tif->{'imageOffset'}};
        foreach (1 .. $d) {
            my $buf;
            $tif->{'fh'}->seek(shift(@{$tif->{'imageOffset'}}), 0);
            $tif->{'fh'}->read($buf, shift(@{$tif->{'imageLength'}}));
            $self->{' stream'} .= $buf;
        }
    } else {
        $tif->{'fh'}->seek($tif->{'imageOffset'}, 0);
        $tif->{'fh'}->read($self->{' stream'}, $tif->{'imageLength'});
    }

    return $self;
}

sub handle_flate {
    my ($self, $pdf, $tif) = @_;

    $self->filters('FlateDecode');

    if (ref($tif->{'imageOffset'})) {
        $self->{' stream'} = '';
        my $d = scalar @{$tif->{'imageOffset'}};
        foreach (1 .. $d) {
            my $buf;
            $tif->{'fh'}->seek(shift(@{$tif->{'imageOffset'}}), 0);
            $tif->{'fh'}->read($buf, shift(@{$tif->{'imageLength'}}));
            $buf = uncompress($buf);
            $self->{' stream'} .= $buf;
        }
    } else {
        $tif->{'fh'}->seek($tif->{'imageOffset'}, 0);
        $tif->{'fh'}->read($self->{' stream'}, $tif->{'imageLength'});
        $self->{' stream'} = uncompress($self->{' stream'});
    }

    return $self;
}

sub handle_lzw {
    my ($self, $pdf, $tif) = @_;

    $self->{' nofilt'} = 1;
    $self->{'Filter'} = PDFArray(PDFName('LZWDecode'));
    my $decode = PDFDict();
    $self->{'DecodeParms'} = PDFArray($decode);
    $decode->{'Columns'} = PDFNum($tif->{'imageWidth'});
    $decode->{'Rows'} = PDFNum($tif->{'imageHeight'});
    $decode->{'DamagedRowsBeforeError'} = PDFNum(100);
    $decode->{'EndOfLine'} = PDFBool(1);
    $decode->{'EncodedByteAlign'} = PDFBool(1);
    if (defined $tif->{'Predictor'} and $tif->{'Predictor'} > 1) {
        $decode->{'Predictor'} = PDFNum($tif->{'Predictor'});
    }

    if (ref($tif->{'imageOffset'})) {
        $self->{' stream'} = '';
        my $d = scalar @{$tif->{'imageOffset'}};
        foreach (1 .. $d) {
            $tif->{'fh'}->seek(shift(@{$tif->{'imageOffset'}}), 0);
            my $buf;
            $tif->{'fh'}->read($buf, shift(@{$tif->{'imageLength'}}));
            my $filter = PDF::Builder::Basic::PDF::Filter::LZWDecode->new();
            $self->{' stream'} .= $filter->infilt($buf);
        }
        my $filter = PDF::Builder::Basic::PDF::Filter::LZWDecode->new();
        $self->{' stream'} = $filter->outfilt($self->{' stream'});
    } else {
        $tif->{'fh'}->seek($tif->{'imageOffset'}, 0);
        $tif->{'fh'}->read($self->{' stream'}, $tif->{'imageLength'});
    }

    return $self;
}

sub handle_ccitt {
    my ($self, $pdf, $tif) = @_;

    $self->{' nofilt'} = 1;
    $self->{'Filter'} = PDFName('CCITTFaxDecode');
    $self->{'DecodeParms'} = PDFDict();
    $self->{'DecodeParms'}->{'K'} = ($tif->{'ccitt'} == 4 || 
        (($tif->{'g3Options'}||0) & 0x1))? PDFNum(-1): PDFNum(0);
    $self->{'DecodeParms'}->{'Columns'} = PDFNum($tif->{'imageWidth'});
    $self->{'DecodeParms'}->{'Rows'} = PDFNum($tif->{'imageHeight'});
    $self->{'DecodeParms'}->{'BlackIs1'} = 
        PDFBool(($tif->{'whiteIsZero'}||0) == 0? 1: 0);
    if (defined($tif->{'g3Options'}) && ($tif->{'g3Options'} & 0x4)) {
        $self->{'DecodeParms'}->{'EndOfLine'} = PDFBool(1);
        $self->{'DecodeParms'}->{'EncodedByteAlign'} = PDFBool(1);
    }
    # $self->{'DecodeParms'} = PDFArray($self->{'DecodeParms'});
    $self->{'DecodeParms'}->{'DamagedRowsBeforeError'} = PDFNum(100);

    if (ref($tif->{'imageOffset'})) {
        die "Chunked CCITT G4 TIFF not supported.";
    } else {
        $tif->{'fh'}->seek($tif->{'imageOffset'}, 0);
        $tif->{'fh'}->read($self->{' stream'}, $tif->{'imageLength'});
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
        $self->colorspace(PDFArray(PDFName($tif->{'colorSpace'}), 
	    	PDFName('DeviceRGB'), PDFNum(2**$tif->{'bitsPerSample'}-1), $dict));
        $dict->{'Filter'} = PDFArray(PDFName('FlateDecode'));
        $tif->{'fh'}->seek($tif->{'colorMapOffset'}, 0);
        my $colormap;
        my $straight;
        $tif->{'fh'}->read($colormap, $tif->{'colorMapLength'});
        $dict->{' stream'} = '';
        $straight .= pack('C', ($_/256)) for 
	    	unpack($tif->{'short'} . '*', $colormap);
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

    # swaps 0 and 1 ([0 1] -> [1 0]) in certain cases
    if (($tif->{'whiteIsZero'}||0) == 1 &&
	($tif->{'filter'}||'') ne 'CCITTFaxDecode') {
        $self->{'Decode'} = PDFArray(PDFNum(1), PDFNum(0));
    }

    # check filters and handle separately
    if      (defined $tif->{'filter'} and $tif->{'filter'} eq 'CCITTFaxDecode') {
        $self->handle_ccitt($pdf, $tif);
    } elsif (defined $tif->{'filter'} and $tif->{'filter'} eq 'LZWDecode') {
        $self->handle_lzw($pdf, $tif);
    } elsif (defined $tif->{'filter'} and $tif->{'filter'} eq 'FlateDecode') {
        $self->handle_flate($pdf, $tif);
    } else {
        $self->handle_generic($pdf, $tif);
    }

# # dump everything in self except huge data streams
# foreach (sort keys %{ $self }) {
#  if ($_ eq ' stream') { next; }
#  if ($_ eq ' apipdf') { next; }
#  if ($_ eq ' realised') { next; }
#  if ($_ eq ' uid') { next; }
#  if (defined $self->{$_}) {
#   print "\$self->{'$_'} = '".($self->{$_}->val())."'\n";
#  } else {
#   print "\$self->{'$_'} = ?\n";
#  }
# }

    if ($tif->{'fillOrder'} == 2) {
        my @bl = ();
        foreach my $n (0 .. 255) {
            my $b = $n;
            my $f = 0;
            foreach (0 .. 7) {
                my $bit = 0;
                if ($b & 0x1) {
                    $bit = 1;
                }
                $b >>= 1;
                $f <<= 1;
                $f |= $bit;
            }
            $bl[$n] = $f;
        }
        my $l = length($self->{' stream'}) - 1;
        foreach my $n (0 .. $l) {
            vec($self->{' stream'}, $n, 8) = $bl[vec($self->{' stream'}, $n, 8)];
        }
    }
    $self->{' tiff'} = $tif;

    return $self;
}

=head2 tiffTag

    $value = $tif->tiffTag($tag)

=over

returns the value of the internal tiff-tag.

B<Useful Tags:>

    imageDescription, imageId (strings)
    xRes, yRes (dpi; pixel/cm if resUnit==3)
    resUnit

=back

=cut

sub tiffTag {
    my ($self, $tag) = @_;
    return $self->{' tiff'}->{$tag};
}

1;
