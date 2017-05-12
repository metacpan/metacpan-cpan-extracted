=head1 NAME

Pangloss::Terms - a collection of Pangloss terms.

=head1 SYNOPSIS

  use Pangloss::Terms;
  my $terms = new Pangloss::Terms();

  try {
      my $term = $terms->get( $name );
      $terms->add( $term );
      $terms->remove( $term );
      do { ... } foreach ( $terms->list );
  } catch Pangloss::Term::Error with {
      my $e = shift;
      ...
  }

=cut

package Pangloss::Terms;

use strict;
use warnings::register;

use Error;

use Pangloss::Term;
use Pangloss::Term::Error;
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
    throw Pangloss::Term::Error(flag => eNonExistent,
				name => $name);
}

sub error_key_exists {
    my $self = shift;
    my $name = shift;
    throw Pangloss::Term::Error(flag => eExists,
				name => $name);
}


1;


__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class contains a collection of L<Pangloss::Term> objects.  It inherits
its interface from L<Pangloss::Collection>.

The collection is keyed on $term->name().

=head1 METHODS

=over 4

=item @names = $obj->names

synonym for $obj->keys()

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>, L<Pangloss::Collection>,
L<Pangloss::Term>, L<Pangloss::Term::Error>

=cut
