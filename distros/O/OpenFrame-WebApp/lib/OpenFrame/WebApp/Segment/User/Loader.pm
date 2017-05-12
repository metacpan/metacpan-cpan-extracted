=head1 NAME

OpenFrame::WebApp::Segment::User::Loader - abstract segment to load users.

=head1 SYNOPSIS

  # abstract class - cannot be used directly

  use Pipeline;
  use OpenFrame::WebApp;

  my $pipe = new Pipeline;

  my $ufactory = new OpenFrame::WebApp::User::Factory()->type('webapp');
  $pipe->store->set( $ufactory );

  # abstract - must use a sub-class:
  my $uloader = new OpenFrame::WebApp::Segment::User::EnvLoader;
  $pipe->add_segment( $uloader );

  ...

  $pipe->dispatch;

=cut

package OpenFrame::WebApp::Segment::User::Loader;

use strict;
use warnings::register;

use OpenFrame::WebApp::Error::Abstract;

our $VERSION = (split(/ /, '$Revision: 1.2 $'))[1];

use base qw( Pipeline::Segment );

sub dispatch {
    my $self = shift;
    return $self->get_user();
}

sub get_user {
    my $self = shift;
    my $user;

    if (my $id = $self->find_user_id) {
	my $ufactory = $self->store->get('OpenFrame::WebApp::User::Factory');
	$user = $ufactory->new_user()->id( $id );
    }

    return $user;
}

sub find_user_id {
    my $self = shift;
    throw OpenFrame::WebApp::Error::Abstract( class => ref($self) );
}


1;

__END__

=head1 DESCRIPTION

The C<OpenFrame::WebApp::Segment::User::Loader> class is an abstract user
loading segment.  It inherits its interface from C<Pipeline::Segment>.

On dispatch() if a user id is found a new user is created using the Pipeline's
stored C<OpenFrame::WebApp::User::Factory>.

=head1 METHODS

=over 4

=item $user = $obj->dispatch()

dispatch this segment.

=item $user = $obj->get_user()

finds user id, and uses stored C<OpenFrame::WebApp::User::Factory> to create a
new user and set it's id.

=item $id = $obj->find_user_id()

abstract method to find user id.

=back

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<OpenFrame::WebApp::User>,
L<OpenFrame::WebApp::User::Factory>

=cut
