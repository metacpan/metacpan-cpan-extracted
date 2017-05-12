=head1 NAME

Pangloss::Concept - a named concept in Pangloss.

=head1 SYNOPSIS

  use Pangloss::Concept;
  my $concept = new Pangloss::Concept();

  $concept->name( $text )
          ->category( $category )
          ->notes( $text )
          ->creator( $user )
          ->date( time )
          ->validate;

  # catch Pangloss::Concept::Errors

=cut

package Pangloss::Concept;

use strict;
use warnings::register;

use Error;
use Pangloss::Concept::Error;
use Pangloss::StoredObject::Error;

use base      qw( Pangloss::StoredObject::Common Pangloss::Collection::Item );
use accessors qw( category );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.13 $ '))[2];

sub key {
    my $self = shift;
    return $self->name();
}

sub copy {
    my $self    = shift;
    my $concept = shift;

    $self->SUPER::copy( $concept )
         ->category( $concept->category );

    return $self;
}

sub throw_invalid_error {
    my $self   = shift;
    my $errors = shift;
    throw Pangloss::Concept::Error( flag    => eInvalid,
				    concept => $self,
				    invalid => $errors );
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class represents a concept in Pangloss.  It inherits its interface from
L<Pangloss::StoredObject::Common> and L<Pangloss::Collection::Item>.

=head1 METHODS

=over 4

=item $obj->category()

set/get L<Pangloss::Category>.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>, L<Pangloss::Concept::Error>,
L<Pangloss::Concepts>, L<Pangloss::Concept>

=cut

