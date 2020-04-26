package PDF::Builder::Resource::XObject::Image::GD;

use base 'PDF::Builder::Resource::XObject::Image';

use strict;
no warnings qw[ deprecated recursion uninitialized ];

our $VERSION = '3.018'; # VERSION
my $LAST_UPDATE = '3.004'; # manually update whenever code is changed

use PDF::Builder::Util;
use PDF::Builder::Basic::PDF::Utils;
use Scalar::Util qw(weaken);

=head1 NAME

PDF::Builder::Resource::XObject::Image::GD - support routines for Graphics Development image library. Inherits from L<PDF::Builder::Resource::XObject::Image>

=cut

sub new {
    my ($class, $pdf, $obj, $name, @opts) = @_;

    my $self;

    $class = ref $class if ref $class;

    $self = $class->SUPER::new($pdf, $name || 'Jx'.pdfkey());
    $pdf->new_obj($self) unless $self->is_obj($pdf);

    $self->{' apipdf'} = $pdf;
    weaken $self->{' apipdf'};

    $self->read_gd($obj, @opts);

    return $self;
}

sub read_gd {
    my ($self, $gd, %opts) = @_;

    my ($w,$h) = $gd->getBounds();
    my $c = $gd->colorsTotal();

    $self->width($w);
    $self->height($h);

    $self->bits_per_component(8);
    $self->colorspace('DeviceRGB');

    if ($gd->can('jpeg') && ($c > 256) && !$opts{'-lossless'}) {

        $self->filters('DCTDecode');
        $self->{' nofilt'} = 1;
        $self->{' stream'} = $gd->jpeg(75);

    } elsif ($gd->can('raw')) {

        $self->filters('FlateDecode');
        $self->{' stream'} = $gd->raw();

    } else {

        $self->filters('FlateDecode');
        for(my $y=0; $y<$h; $y++) {
            for(my $x=0; $x<$w; $x++) {
                my $index = $gd->getPixel($x,$y);
                my @rgb = $gd->rgb($index);
                $self->{' stream'} .= pack('CCC', @rgb);
            }
        }

    }

    return $self;
}

1;
