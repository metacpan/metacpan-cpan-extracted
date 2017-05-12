=head1 NAME

OpenFrame::WebApp::Segment::Session - abstract class for getting Sessions
from the store.

=head1 SYNOPSIS

  # abstract class - cannot be used directly

  use base qw( OpenFrame::WebApp::Segment::Session );

  sub dispatch {
      ...
      my $session $self->get_session_from_store;
      ...
  }

=cut

package OpenFrame::WebApp::Segment::Session;

use strict;
use warnings::register;

use OpenFrame::WebApp::Session;
use OpenFrame::WebApp::Error::Abstract;

our $VERSION = (split(/ /, '$Revision: 1.2 $'))[1];

use base qw( Pipeline::Segment );

## try various methods to find a session in the store
sub get_session_from_store {
    my $self = shift;
    my $session;

    if ($self->store->isa( 'Pipeline::Store::ISA' )) {
	$session = $self->store->get('OpenFrame::WebApp::Session');
    } else {
	foreach my $class (values %{ OpenFrame::WebApp::Session->types }) {
	    last if( $session = $self->store->get($class) );
	}
    }

    return $session;
}

1;

__END__

=head1 DESCRIPTION

The C<OpenFrame::WebApp::Segment::Session> class provides a method for getting
Session objects from the store.

This class inherits its interface from C<Pipeline::Segment>.  You must override
dispatch() for it to do anything.

=head1 METHODS

=over 4

=item get_session_from_store

If the store is a C<Pipeline::Store::ISA>, looks for a descendant of
C<OpenFrame::WebApp::Session>, otherwise looks for known
OpenFrame::WebApp::Session->types().

=back

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<Pipeline::Segment>,
L<OpenFrame::WebApp::Session>

=cut
