package PDF::Builder::Resource;

use base 'PDF::Builder::Basic::PDF::Dict';

use strict;
use warnings;

our $VERSION = '3.024'; # VERSION
our $LAST_UPDATE = '3.024'; # manually update whenever code is changed

use PDF::Builder::Util qw(pdfkey);
use PDF::Builder::Basic::PDF::Utils; # PDFName

use Scalar::Util qw(weaken);

=head1 NAME

PDF::Builder::Resource - Base class for PDF resources. Inherit from L<PDF::Builder::Basic::PDF::Dict>

=head1 METHODS

=over

=item $resource = PDF::Builder::Resource->new($pdf, $name)

Returns a resource object.

=cut

sub new {
    my ($class, $pdf, $name) = @_;

    $class = ref($class) if ref($class);

    my $self = $class->SUPER::new();

    $pdf->new_obj($self) unless $self->is_obj($pdf);

    $self->name($name or pdfkey());

    $self->{' apipdf'} = $pdf;
    weaken $self->{' apipdf'};

    return $self;
}

# Note: new_api() removed in favor of new():
#   new_api($api, ...)  replace with new($api->{'pdf'}, ...)

=item $name = $resource->name() # Get

=item $resource->name($name) # Set

Get or set the name of the resource.

=cut

sub name {
    my $self = shift @_;
    if (scalar @_ and defined $_[0]) {
        $self->{'Name'} = PDFName($_[0]);
    }
    return $self->{'Name'}->val();
}

#sub outobjdeep {
#    my ($self, $fh, $pdf, %options) = @_;
#
#    delete $self->{' api'};
#    delete $self->{' apipdf'};
#    return $self->SUPER::outobjdeep($fh, $pdf, %options);
#}

=back

=cut

1;
