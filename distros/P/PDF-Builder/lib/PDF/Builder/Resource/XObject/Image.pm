package PDF::Builder::Resource::XObject::Image;

use base 'PDF::Builder::Resource::XObject';

use strict;
use warnings;

our $VERSION = '3.027'; # VERSION
our $LAST_UPDATE = '3.027'; # manually update whenever code is changed

use PDF::Builder::Basic::PDF::Utils;

=head1 NAME

PDF::Builder::Resource::XObject::Image - Base class for external raster image objects

Inherits from L<PDF::Builder::Resource::XObject>

=head1 METHODS

=head2 new

    $image = PDF::Builder::Resource::XObject::Image->new($pdf, $name)

=over

Returns an image resource object.

=back

=cut

sub new {
    my ($class, $pdf, $name) = @_;

    my $self = $class->SUPER::new($pdf, $name);

    $self->subtype('Image');

    return $self;
}

=head2 width

    $width = $image->width()

=over

Get the width (in points) of the image object.

B<Note> that this function also has the ability to I<set> the width,
by giving the new width (in points), but it appears that it never 
worked correctly. The I<set> capability has been B<deprecated>, and 
is scheduled to be removed some time after October, 2025. If you are
using the C<width()> method in some manner to I<set> the image width,
please let us know, so we can plan to keep it enabled!

=back

=cut

sub width {
    my $self = shift;

    $self->{'Width'} = PDFNum(shift()) if scalar @_;
    return $self->{'Width'}->val();
}

=head2 height

    $height = $image->height()

=over

Get the height (in points) of the image object.

B<Note> that this function also has the ability to I<set> the height,
by giving the new height (in points), but it appears that it never 
worked correctly. The I<set> capability has been B<deprecated>, and 
is scheduled to be removed some time after October, 2025. If you are
using the C<height()> method in some manner to I<set> the image height,
please let us know, so we can plan to keep it enabled!

=back

=cut

sub height {
    my $self = shift;

    $self->{'Height'} = PDFNum(shift()) if scalar @_;
    return $self->{'Height'}->val();
}

## probably not useful, so do not add, for now
#=head2 bbox
#
#    ($x1,$x2, $w,$h) = $image->bbox()
#
#=over
#
#Get the image dimensions similarly to a form's I<bounding box>. 
#Note that the C<$x1> and C<$x2> values will always be 0.
#
#This method is offered as an alternative to the C<width> and C<height> methods.
#
#=back
#
#=cut
#
#sub bbox {
#    my $self = shift();
#    my @bb = (0,0, $self->width(),$self->height());
#    return @bb;
#}

=head2 smask

    $image->smask($xobject)

=over

Set the soft-mask image object.

=back

=cut

sub smask {
    my $self = shift;
    $self->{'SMask'} = shift;

    return $self;
}

=head2 mask

    $image->mask(@color_range)

    $image->mask($xobject)

=over

Set the mask to an image mask XObject or an array containing a range
of colors to be applied as a color key mask.

=back

=cut

sub mask {
    my $self = shift();

    if (ref($_[0])) {
        $self->{'Mask'} = shift();
    } else {
        $self->{'Mask'} = PDFArray(map { PDFNum($_) } @_);
    }

    return $self;
}

# imask() functionality rolled into mask()

=head2 colorspace

    $image->colorspace($name)

    $image->colorspace($array)

=over

Set the color space used by the image. Depending on the color space,
this will either be just the name of the color space, or it will be an
array containing the color space and any required parameters.

If passing an array, parameters must already be encoded as PDF
objects. The array itself may also be a PDF object. If not, one will
be created.

=back

=cut

sub colorspace {
    my ($self, @values) = @_;

    if      (scalar @values == 1 and ref($values[0])) {
        $self->{'ColorSpace'} = $values[0];
    } elsif (scalar @values == 1) {
        $self->{'ColorSpace'} = PDFName($values[0]);
    } else {
        $self->{'ColorSpace'} = PDFArray(@values);
    }

    return $self;
}

=head2 bits_per_component

    $image->bits_per_component($integer)

=over

Set the number of bits used to represent each color component.

=back

=cut

sub bits_per_component {
    my $self = shift;

    $self->{'BitsPerComponent'} = PDFNum(shift());

    return $self;
}

# bpc() renamed to bits_per_component()

1;
