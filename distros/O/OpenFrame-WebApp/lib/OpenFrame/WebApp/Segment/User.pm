=head1 NAME

OpenFrame::WebApp::Segment::User - abstract class for getting Users
from the store.

=head1 SYNOPSIS

  # abstract class - cannot be used directly

  use base qw( OpenFrame::WebApp::Segment::User );

  sub dispatch {
      ...
      my $user $self->get_user_from_store;
      ...
  }

=cut

package OpenFrame::WebApp::Segment::User;

use strict;
use warnings::register;

use OpenFrame::WebApp::User;
use OpenFrame::WebApp::Error::Abstract;

our $VERSION = (split(/ /, '$Revision: 1.2 $'))[1];

use base qw( Pipeline::Segment );

## try various methods to find a user in the store
sub get_user_from_store {
    my $self = shift;
    my $user;

    if ($self->store->isa( 'Pipeline::Store::ISA' )) {
	$user = $self->store->get('OpenFrame::WebApp::User');
    } else {
	foreach my $class (values %{ OpenFrame::WebApp::User->types }) {
	    last if( $user = $self->store->get($class) );
	}
    }

    return $user;
}

1;

__END__

=head1 DESCRIPTION

The C<OpenFrame::WebApp::Segment::User> class provides a method for getting
User objects from the store.

This class inherits its interface from C<Pipeline::Segment>.  You must override
dispatch() for it to do anything.

=head1 METHODS

=over 4

=item get_user_from_store

If the store is a C<Pipeline::Store::ISA>, looks for a descendant of
C<OpenFrame::WebApp::User>, otherwise looks for known
OpenFrame::WebApp::User->types().

=back

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<Pipeline::Segment>,
L<OpenFrame::WebApp::User>

=cut
