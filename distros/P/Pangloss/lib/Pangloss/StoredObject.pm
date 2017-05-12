=head1 NAME

Pangloss::StoredObject - base class for stored objects.

=head1 SYNOPSIS

  # abstract - cannot be used
  use base qw( Pangloss::StoredObject );

  $obj->copy( $another_obj )->validate; # catch Pangloss::Error
  $clone = $obj->clone;

=cut

package Pangloss::StoredObject;

use strict;
use warnings::register;

use Error;
use OpenFrame::WebApp::Error::Abstract;

use base qw( Pangloss::Object );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.8 $ '))[2];

sub clone {
    my $self = shift;
    return $self->new()->copy( $self );
}

sub copy {
    my $self = shift;
    throw OpenFrame::WebApp::Error::Abstract( class => ref($self) );
}

sub validate {
    my $self = shift;
    throw OpenFrame::WebApp::Error::Abstract( class => ref($self) );
}

1;


__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

Base class for stored objects in L<Pangloss>.

=head1 METHODS

=over 4

=item $copy = $obj->copy( $another_obj )

abstract.  copy $another_obj values into this object, returns itself.

=item $clone = $obj->clone

return a new copy of this object.

=item $obj = $obj->validate( [$errors] )

abstract.  validate this object, or throw an error.  returns itself.
an optional hashref of errors can be passed in.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>,
L<OpenFrame::WebApp::Error::Abstract>

=cut


