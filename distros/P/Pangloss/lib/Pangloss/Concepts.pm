=head1 NAME

Pangloss::Concepts - a collection of Pangloss concepts.

=head1 SYNOPSIS

  use Pangloss::Concepts;
  my $concepts = new Pangloss::Concepts();

  try {
      my $concept = $concepts->get( $name );
      $concepts->add( $concept );
      $concepts->remove( $concept );
      do { ... } foreach ( $concepts->list );
  } catch Pangloss::Concept::Error with {
      my $e = shift;
      ...
  }

=cut

package Pangloss::Concepts;

use strict;
use warnings::register;

use Error;

use Pangloss::Concept;
use Pangloss::Concept::Error;
use Pangloss::StoredObject::Error;

use base qw( Pangloss::Collection );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.5 $ '))[2];

sub names {
    return shift->keys;
}

sub error_key_nonexistent {
    my $self = shift;
    my $name = shift;
    throw Pangloss::Concept::Error(flag => eNonExistent,
				   name => $name);
}

sub error_key_exists {
    my $self = shift;
    my $name = shift;
    throw Pangloss::Concept::Error(flag => eExists,
				   name => $name);
}


1;


__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class contains a collection of L<Pangloss::Concept> objects.  It inherits
its interface from L<Pangloss::Collection>.

The collection is keyed on $concept->name().

=head1 METHODS

=over 4

=item @names = $obj->names

synonym for $obj->keys()

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>, L<Pangloss::Collection>,
L<Pangloss::Concept>, L<Pangloss::Concept::Error>

=cut
