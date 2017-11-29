package PDF::Builder::Resource::XObject;

use base 'PDF::Builder::Resource';

use strict;
use warnings;

our $VERSION = '3.009'; # VERSION
my $LAST_UPDATE = '2.031'; # manually update whenever code is changed

use PDF::Builder::Basic::PDF::Utils;

=head1 NAME

PDF::Builder::Resource::XObject - Base class for external objects

=head1 METHODS

=over

=item $xobject = PDF::Builder::Resource::XObject->new($pdf, $name)

Creates an XObject resource.

=cut

sub new {
    my ($class, $pdf, $name) = @_;

    my $self = $class->SUPER::new($pdf, $name);

    $self->type('XObject');

    return $self;
}

=item $type = $xobject->subtype($type)

Get or set the Subtype of the XObject resource.

=cut

sub subtype {
    my $self = shift;

    if (scalar @_) {
        $self->{'Subtype'} = PDFName(shift());
    }
    return $self->{'Subtype'}->val();
}

=back

=cut

1;
