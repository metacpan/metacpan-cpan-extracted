=head1 NAME

Pangloss::Categories - a collection of Pangloss categories.

=head1 SYNOPSIS

  use Pangloss::Categories;
  my $categories = new Pangloss::Categories();

  try {
      my $category = $categories->get( $name );
      $categories->add( $category );
      $categories->remove( $category );
      do { ... } foreach ( $categories->list );
  } catch Pangloss::Category::Error with {
      my $e = shift;
      ...
  }

=cut

package Pangloss::Categories;

use strict;
use warnings::register;

use Error;

use Pangloss::Category;
use Pangloss::Category::Error;
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
    throw Pangloss::Category::Error(flag => eNonExistent,
				    name => $name);
}

sub error_key_exists {
    my $self = shift;
    my $name = shift;
    throw Pangloss::Category::Error(flag => eExists,
				    name => $name);
}


1;


__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class contains a collection of L<Pangloss::Category> objects.  It inherits
its interface from L<Pangloss::Collection>.

The collection is keyed on $category->name().

=head1 METHODS

=over 4

=item @names = $obj->names

synonym for $obj->keys()

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>, L<Pangloss::Collection>,
L<Pangloss::Category>, L<Pangloss::Category::Error>

=cut
