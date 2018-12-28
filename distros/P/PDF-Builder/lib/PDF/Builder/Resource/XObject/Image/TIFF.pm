package PDF::Builder::Resource::XObject::Image::TIFF;

use base 'PDF::Builder::Resource::XObject::Image';

use strict;
use warnings;

no warnings 'uninitialized';

our $VERSION = '3.013'; # VERSION
my $LAST_UPDATE = '3.011'; # manually update whenever code is changed

use Compress::Zlib;

use PDF::Builder::Basic::PDF::Utils;
use PDF::Builder::Resource::XObject::Image::TIFF::File;
use PDF::Builder::Util;
use Scalar::Util qw(weaken);

=head1 NAME

PDF::Builder::Resource::XObject::Image::TIFF - TIFF image support

=head1 METHODS

=over

=item  $res = PDF::Builder::Resource::XObject::Image::TIFF->new($pdf, $file, $name)

=item  $res = PDF::Builder::Resource::XObject::Image::TIFF->new($pdf, $file)

Returns a TIFF-image object.

If the Graphics::TIFF package is installed, the TIFF_GT library will be used
instead of the TIFF library. In such a case, use of the TIFF library may be 
forced via the C<-nouseGT> flag (see Builder documentation for C<image_tiff()>).

=cut

sub new {
    my ($class, $pdf, $file, $name) = @_;

    my $self;

    my $tif = PDF::Builder::Resource::XObject::Image::TIFF::File->new($file);

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

=cut

sub usesLib {
    my ($self) = shift;
    # should be 0 for Graphics::TIFF not installed, or -1 for is installed,
    # but not using it
    return $self->{'usesGT'}->val();
}

sub deLZW {
    my ($ibits, $stream) = @_;

    my $bits = $ibits;
    my $resetcode = 1 << ($ibits - 1);
    my $endcode = $resetcode + 1;
    my $nextcode = $endcode + 1;
    my $ptr = 0;
    $stream = unpack('B*', $stream);
    my $maxptr = length($stream);
    my $tag;
    my $out = '';
    my $outptr = 0;

    # print STDERR "reset=$resetcode\nend=$endcode\nmax=$maxptr\n";

    my @d = map { chr($_) } (0 .. $resetcode-1);

    while ($ptr+$bits <= $maxptr) {
        $tag = 0;
        foreach my $off (reverse 1 .. $bits) {
            $tag <<= 1;
            $tag |= substr($stream, $ptr+$bits-$off, 1);
        }
        # print STDERR "ptr=$ptr,tag=$tag,bits=$bits,next=$nextcode\n";
        # print STDERR "tag to large\n" if($tag>$nextcode);
        $ptr += $bits;
        if      ($tag == $resetcode) {
            $bits = $ibits;
            $nextcode = $endcode+1;
            next;
        } elsif ($tag == $endcode) {
            last;
        } elsif ($tag < $resetcode) {
            $d[$nextcode] = $d[$tag];
            $out .= $d[$nextcode];
            $nextcode++;
        } elsif ($tag > $endcode) {
            $d[$nextcode] = $d[$tag];
            $d[$nextcode] .= substr($d[$tag+1], 0, 1);
            $out .= $d[$nextcode];
            $nextcode++;
        }
        $bits++ if $nextcode == (1 << $bits);
    }

    return $out;
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

    $self->filters('FlateDecode');
    my $imageWidth = $tif->{'imageWidth'};
    my $mod = $imageWidth%8;
    if ($mod > 0) {
	$imageWidth += 8-$mod;
    }
    my $max_raw_strip = $imageWidth*$tif->{'bitsPerSample'}*$tif->{'RowsPerStrip'}/8;

    if (ref($tif->{'imageOffset'})) {
        $self->{' stream'} = '';
        my $d = scalar @{$tif->{'imageOffset'}};
        foreach (1 .. $d) {
            my $buf;
            $tif->{'fh'}->seek(shift(@{$tif->{'imageOffset'}}), 0);
            $tif->{'fh'}->read($buf, shift(@{$tif->{'imageLength'}}));
            $buf = deLZW(9, $buf);
            if (length($buf) > $max_raw_strip) {
                $buf = substr($buf, 0, $max_raw_strip);
            }
            $self->{' stream'} .= $buf;
        }
    } else {
        $tif->{'fh'}->seek($tif->{'imageOffset'}, 0);
        $tif->{'fh'}->read($self->{' stream'}, $tif->{'imageLength'});
        $self->{' stream'} = deLZW(9, $self->{' stream'});
    }

    return $self;
}

sub handle_ccitt {
    my ($self, $pdf, $tif) = @_;

    $self->{' nofilt'} = 1;
    $self->{'Filter'} = PDFName('CCITTFaxDecode');
    $self->{'DecodeParms'} = PDFDict();
    $self->{'DecodeParms'}->{'K'} = (($tif->{'ccitt'} == 4 || ($tif->{'g3Options'} & 0x1))? PDFNum(-1): PDFNum(0));
    $self->{'DecodeParms'}->{'Columns'} = PDFNum($tif->{'imageWidth'});
    $self->{'DecodeParms'}->{'Rows'} = PDFNum($tif->{'imageHeight'});
    $self->{'DecodeParms'}->{'BlackIs1'} = PDFBool($tif->{'whiteIsZero'} == 1? 1: 0);
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
    if      (defined $tif->{'filter'} and $tif->{'filter'} eq 'CCITTFaxDecode') {
        $self->handle_ccitt($pdf, $tif);
    } elsif (defined $tif->{'filter'} and $tif->{'filter'} eq 'LZWDecode') {
        $self->handle_lzw($pdf, $tif);
    } elsif (defined $tif->{'filter'} and $tif->{'filter'} eq 'FlateDecode') {
        $self->handle_flate($pdf, $tif);
    } else {
        $self->handle_generic($pdf, $tif);
    }

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

=item $value = $tif->tiffTag($tag)

returns the value of the internal tiff-tag.

B<Useful Tags:>

    imageDescription, imageId (strings)
    xRes, yRes (dpi; pixel/cm if resUnit==3)
    resUnit

=cut

sub tiffTag {
    my ($self, $tag) = @_;
    return $self->{' tiff'}->{$tag};
}

=back

=cut

1;
