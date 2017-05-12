=head1 NAME

Pangloss::Category - a named category in Pangloss.

=head1 SYNOPSIS

  use Pangloss::Category;
  my $category = new Pangloss::Category();

  $category->name( $text )
           ->notes( $text )
           ->creator( $user )
           ->date( time )
           ->validate;

  # catch Pangloss::Category::Errors

=cut

package Pangloss::Category;

use strict;
use warnings::register;

use Error;
use Pangloss::Category::Error;
use Pangloss::StoredObject::Error;

use base qw( Pangloss::StoredObject::Common Pangloss::Collection::Item );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.7 $ '))[2];

sub key {
    my $self = shift;
    return $self->name();
}

sub throw_invalid_error {
    my $self   = shift;
    my $errors = shift;
    throw Pangloss::Category::Error( flag     => eInvalid,
				     category => $self,
				     invalid  => $errors );
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class represents a category in Pangloss.  It inherits its interface from
L<Pangloss::StoredObject::Common> and L<Pangloss::Collection::Item>.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>, L<Pangloss::Category::Error>,
L<Pangloss::Categories>, L<Pangloss::Concept>

=cut

