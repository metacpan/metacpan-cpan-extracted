package PDF::Builder::Resource::ColorSpace;

use base 'PDF::Builder::Basic::PDF::Array';

use strict;
use warnings;
#no warnings qw[ deprecated recursion uninitialized ];

our $VERSION = '3.022'; # VERSION
my $LAST_UPDATE = '3.021'; # manually update whenever code is changed

use PDF::Builder::Basic::PDF::Utils;
use PDF::Builder::Util;
use Scalar::Util qw(weaken);

=head1 NAME

PDF::Builder::Resource::ColorSpace - Base class for PDF color spaces

=head1 METHODS

=over

=item $cs = PDF::Builder::Resource::ColorSpace->new($pdf, $key, %opts)

=item $cs = PDF::Builder::Resource::ColorSpace->new($pdf, $key)

Returns a new colorspace object, base class for all colorspaces.

=cut

sub new {
    my ($class, $pdf, $key, %opts) = @_;

    $class = ref $class if ref $class;
    my $self = $class->SUPER::new();
    $pdf->new_obj($self) unless $self->is_obj($pdf);
    $self->name($key || pdfkey());
    $self->{' apipdf'} = $pdf;
    weaken $self->{' apipdf'};

    return $self;
}

=item $name = $res->name($name)

=item $name = $res->name()

Returns or sets the Name of the resource.

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

=item @param = $cs->param(@param)

Returns properly formatted color-parameters based on the colorspace.

=cut

sub param {
    my $self = shift;

    return (@_);
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

=back

=cut

1;
