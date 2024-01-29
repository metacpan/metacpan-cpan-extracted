package PDF::Builder::Resource::XObject;

use base 'PDF::Builder::Resource';

use strict;
use warnings;

our $VERSION = '3.026'; # VERSION
our $LAST_UPDATE = '3.026'; # manually update whenever code is changed

use PDF::Builder::Basic::PDF::Utils;

=head1 NAME

PDF::Builder::Resource::XObject - Base class for external objects

=head1 METHODS

=head2 new

    $xobject = PDF::Builder::Resource::XObject->new($pdf, $name)

=over

Creates an XObject resource.

=back

=cut

sub new {
    my ($class, $pdf, $name) = @_;

    my $self = $class->SUPER::new($pdf, $name);

    $self->type('XObject');

    return $self;
}

=head2 subtype

    $type = $xobject->subtype($type)

=over

Get or set the Subtype of the XObject resource.

=back

=cut

sub subtype {
    my $self = shift;

    if (scalar @_) {
        $self->{'Subtype'} = PDFName(shift());
    }
    return $self->{'Subtype'}->val();
}

1;
