=head1 NAME

Pangloss::Users - a collection of Pangloss users.

=head1 SYNOPSIS

  use Pangloss::Users;
  my $users = new Pangloss::Users();

  try {
      my $user = $users->get( $userid );
      $users->add( $user );
      $users->remove( $user );
      do { ... } foreach ( $users->list );
  } catch Pangloss::User::Error with {
      my $e = shift;
      ...
  }

=cut

package Pangloss::Users;

use strict;
use warnings::register;

use Error;

use Pangloss::User;
use Pangloss::User::Error;
use Pangloss::StoredObject::Error;

use base qw( Pangloss::Collection );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.10 $ '))[2];

sub ids {
    return shift->keys;
}

sub error_key_nonexistent {
    my $self = shift;
    my $id   = shift;
    throw Pangloss::User::Error(flag => eNonExistent, userid => $id);
}

sub error_key_exists {
    my $self = shift;
    my $id   = shift;
    throw Pangloss::User::Error(flag => eExists, userid => $id);
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class contains a collection of L<Pangloss::User> objects.  It inherits
its interface from L<Pangloss::Collection>.

The collection is keyed on $user->id().

=head1 METHODS

=over 4

=item @user_ids = $obj->ids

synonym for $obj->keys()

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>, L<Pangloss::Collection>,
L<Pangloss::User>, L<Pangloss::User::Error>

=cut
