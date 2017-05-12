=head1 NAME

Pangloss::StoredObject::Common - common base class for some stored objects.

=head1 SYNOPSIS

  # abstract - cannot be used
  use base qw( Pangloss::StoredObject::Common );

  $obj->name( $name )
      ->notes( $notes )
      ->creator( $user )
      ->date( time )
      ->validate;

  # catch Pangloss::StoredObject::Errors

=cut

package Pangloss::StoredObject::Common;

use strict;
use warnings::register;

use Error;
use Pangloss::StoredObject::Error;
use OpenFrame::WebApp::Error::Abstract;

use base      qw( Pangloss::StoredObject );
use accessors qw( name creator date notes );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.6 $ '))[2];

sub validate {
    my $self   = shift;
    my $errors = shift || {};

    $errors->{eNameRequired()}    = 1 unless ($self->name);
    $errors->{eCreatorRequired()} = 1 unless ($self->creator);
    $errors->{eDateRequired()}    = 1 unless ($self->date);

    $self->throw_invalid_error( $errors ) if (keys %$errors);

    return $self;
}

sub throw_invalid_error {
    my $self = shift;
    throw OpenFrame::WebApp::Error::Abstract( class => ref($self) );
}

sub copy {
    my $self = shift;
    my $obj  = shift;

    $self->name( $obj->name )
         ->notes( $obj->notes )
         ->creator( $obj->creator )
         ->date( $obj->date );

    return $self;
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

Base class for stored objects in Pangloss.

=head1 METHODS

=over 4

=item $obj->name()

set/get name.

=item $obj->notes()

set/get notes.

=item $obj->creator()

set/get the L<Pangloss::User> that created this object.

=item $obj->date()

set/get modified date.

=item $obj->copy( $obj2 )

copy name/notes/creator/date.  returns this object.

=item $obj->validate( [$errors] )

validate this object, or throw an error.  returns itself.
checks name/creator/date.

=item $obj->throw_invalid_error( $errors )

abstract. throws appropriate L<Pangloss::StoredObject::Error>.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>,
L<OpenFrame::WebApp::Error::Abstract>

=cut

