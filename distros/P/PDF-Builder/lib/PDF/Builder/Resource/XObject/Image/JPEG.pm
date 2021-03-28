package PDF::Builder::Resource::XObject::Image::JPEG;

use base 'PDF::Builder::Resource::XObject::Image';

use strict;
use warnings;

our $VERSION = '3.022'; # VERSION
my $LAST_UPDATE = '3.017'; # manually update whenever code is changed

use IO::File;
use PDF::Builder::Util;
use PDF::Builder::Basic::PDF::Utils;
use Scalar::Util qw(weaken);

=head1 NAME

PDF::Builder::Resource::XObject::Image::JPEG - support routines for JPEG image library. Inherits from L<PDF::Builder::Resource::XObject::Image>

=cut

sub new {
    my ($class, $pdf, $file, $name) = @_;

    my $fh = IO::File->new();

    $class = ref($class) if ref $class;

    my $self = $class->SUPER::new($pdf, $name || 'Jx' . pdfkey());
    $pdf->new_obj($self) unless $self->is_obj($pdf);

    $self->{' apipdf'} = $pdf;
    weaken $self->{' apipdf'};

    if (ref($file)) {
        $fh = $file;
    } else {
        open $fh, "<", $file or die "$!: $file";
    }
    binmode($fh, ':raw');

    $self->read_jpeg($fh);

    if (ref($file)) {
        seek($fh, 0, 0);
        $self->{' stream'} = '';
        my $buf = '';
        while (!eof($fh)) {
            read($fh, $buf, 512);
            $self->{' stream'} .= $buf;
        }
        $self->{'Length'} = PDFNum(length $self->{' stream'});
    } else {
        $self->{'Length'} = PDFNum(-s $file);
        $self->{' streamfile'} = $file;
    }

    $self->filters('DCTDecode');
    $self->{' nofilt'} = 1;

    return $self;
}

sub read_jpeg {
    my ($self, $fh) = @_;

    my ($buf, $p, $h, $w, $c, $ff, $mark, $len);

    $fh->seek(0,0);
    $fh->read($buf,2);
    while (1) {
        $fh->read($buf, 4);
        my ($ff, $mark, $len) = unpack('CCn', $buf);
        last if $ff != 0xFF;
        last if $mark == 0xDA || $mark == 0xD9;  # SOS/EOI
        last if $len < 2;
        last if $fh->eof();
        $fh->read($buf, $len - 2);
        next if $mark == 0xFE;
        next if $mark >= 0xE0 && $mark <= 0xEF;
        if ($mark >= 0xC0 && $mark <= 0xCF && $mark != 0xC4 && $mark != 0xC8 && $mark != 0xCC) {
            ($p, $h, $w, $c) = unpack('CnnC', substr($buf, 0, 6));
            last;
        }
    }

    $self->width($w);
    $self->height($h);
    $self->bits_per_component($p);

    if (!defined $c) { return $self; }
    if      ($c == 3) {
        $self->colorspace('DeviceRGB');
    } elsif ($c == 4) {
        $self->colorspace('DeviceCMYK');
    } elsif ($c == 1) {
        $self->colorspace('DeviceGray');
    }

    return $self;
}

1;
