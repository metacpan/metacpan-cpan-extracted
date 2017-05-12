=head1 NAME

Pangloss::User::Error - errors specific to Users.

=head1 SYNOPSIS

  use Pangloss::User::Error;
  use Pangloss::StoredObject::Error;

  throw Pangloss::User::Error(flag => eExists, user => $user_object);
  throw Pangloss::User::Error(flag => eNonExistent, userid => $userid);
  throw Pangloss::User::Error(flag => eInvalid, user => $user,
                              invalid => {eIdRequired => 1});

  # with caught errors:
  print $e->user->id;

=cut

package Pangloss::User::Error;

use strict;
use warnings::register;

use Pangloss::User;

use base      qw( Exporter Pangloss::StoredObject::Error );
use accessors qw( user );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.17 $ '))[2];
our @EXPORT   = qw( eIdRequired );

use constant eIdRequired => 'user_id_required';

sub new {
    my $class = shift;
    my %args  = @_;
    local $Error::Depth = $Error::Depth + 1;
    if (my $userid = delete $args{userid}) {
	$args{user} = new Pangloss::User()->id($userid);
    }
    $class->SUPER::new(map { /^user$/ ? '-user' : $_; } %args);
}

sub isIdRequired {
    return shift->is(eIdRequired);
}

sub stringify {
    my $self = shift;
    my $str  = $self->SUPER::stringify . ':user';
    $str    .= '=' . $self->user->key if $self->user;
    return $str;
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

User Errors class.  Inherits interface from L<Pangloss::StoredObject::Error>.
May contain a L<user> object associated with the error.

=head1 EXPORTED FLAGS

Validation errors:
 eIdRequired

=head1 METHODS

=over 4

=item $e->user

set/get Pangloss::User for this error.

=item $bool = $e->isIdRequired

Test if this error's flag is equal to the named flag.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Error>, L<Pangloss::StoredObject::Error>,
L<Pangloss::User>, L<Pangloss::Users>

=cut


