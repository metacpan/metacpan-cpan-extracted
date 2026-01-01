package PDF::Builder::Resource::XObject::Image::GD;

use base 'PDF::Builder::Resource::XObject::Image';

use strict;
use warnings;

our $VERSION = '3.028'; # VERSION
our $LAST_UPDATE = '3.027'; # manually update whenever code is changed

use PDF::Builder::Util;
use PDF::Builder::Basic::PDF::Utils;
use Scalar::Util qw(weaken);

=head1 NAME

PDF::Builder::Resource::XObject::Image::GD - Support routines for Graphics Development image library

Inherits from L<PDF::Builder::Resource::XObject::Image>

=head1 METHODS

=head2 new

    $res = PDF::Builder::Resource::XObject::Image::GD->new($pdf, $file, %opts)

=over

Options:

=over

=item 'name' => 'string'

This is the name you can give for the GD image object. The default is Dxnnnn.

=item 'lossless' => 1

Use lossless compression.

=back

An image object is created from GD input. Note that this should be invoked
from Builder.pm's method.

=back

=cut

sub new {
    my ($class, $pdf, $obj, %opts) = @_;
    # copy dashed option names to preferred undashed names
    if (defined $opts{'-name'} && !defined $opts{'name'}) { $opts{'name'} = delete($opts{'-name'}); }
    if (defined $opts{'-compress'} && !defined $opts{'compress'}) { $opts{'compress'} = delete($opts{'-compress'}); }
    if (defined $opts{'-lossless'} && !defined $opts{'lossless'}) { $opts{'lossless'} = delete($opts{'-lossless'}); }

    my ($name, $compress);
    if (exists $opts{'name'}) { $name = $opts{'name'}; }
   #if (exists $opts{'compress'}) { $compress = $opts{'compress'}; }

    my $self;

    $class = ref($class) if ref($class);

    $self = $class->SUPER::new($pdf, $name || 'Dx'.pdfkey());
    $pdf->new_obj($self) unless $self->is_obj($pdf);

    $self->{' apipdf'} = $pdf;
    weaken $self->{' apipdf'};

    $self->read_gd($obj, %opts);

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

    if ($gd->can('jpeg') && ($c > 256) && !$opts{'lossless'}) {

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
