package PDF::Builder::Resource::ColorSpace;

use base 'PDF::Builder::Basic::PDF::Array';

use strict;
use warnings;

our $VERSION = '3.026'; # VERSION
our $LAST_UPDATE = '3.026'; # manually update whenever code is changed

use PDF::Builder::Basic::PDF::Utils;
use PDF::Builder::Util;
use Scalar::Util qw(weaken);

=head1 NAME

PDF::Builder::Resource::ColorSpace - Base class for PDF color spaces

=head1 METHODS

=head2 new

    $cs = PDF::Builder::Resource::ColorSpace->new($pdf, $key, %opts)

=over

Returns a new colorspace object, base class for all colorspaces.

=back

=cut

sub new {
    my ($class, $pdf, $key, %opts) = @_;

    $class = ref($class) if ref($class);
    my $self = $class->SUPER::new();
    $pdf->new_obj($self) unless $self->is_obj($pdf);
    $self->name($key || pdfkey());
    $self->{' apipdf'} = $pdf;
    weaken $self->{' apipdf'};

    return $self;
}

=head2 name

    $name = $res->name($name) # Set

    $name = $res->name() # Get

=over

Returns or sets the Name of the resource.

=back

=cut

sub name {
    my ($self, $name) = @_;

    if (defined $name) {
        $self->{' name'} = $name;
    }
    return $self->{' name'};
}

sub type {
    my ($self, $type) = @_;

    if (defined $type) {
        $self->{' type'} = $type;
    }
    return $self->{' type'};
}

=head2 param

    @param = $cs->param(@param)

=over

Returns properly formatted color-parameters based on the colorspace.

=back

=cut

sub param {
    my $self = shift;

    return @_;
}

#sub outobjdeep {
#    my ($self, @opts) = @_;
#
#    foreach my $k (qw/ api apipdf /) {
#        $self->{" $k"} = undef;
#        delete($self->{" $k"});
#    }
#    return $self->SUPER::outobjdeep(@opts);
#}

1;
