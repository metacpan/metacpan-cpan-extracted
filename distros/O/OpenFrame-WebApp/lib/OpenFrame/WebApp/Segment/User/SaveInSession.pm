=head1 NAME

OpenFrame::WebApp::Segment::User::SaveInSession - save user to session.

=head1 SYNOPSIS

  use Pipeline;
  use OpenFrame::WebApp;

  my $pipe = new Pipeline;

  $OpenFrame::WebApp::Segment::User::Session::USER_KEY = 'my_user';

  my $usaver = new OpenFrame::WebApp::Segment::User::SaveInSession;
  $pipe->add_segment( $uloader, ... $usaver, ... );

  $pipe->dispatch;

=cut

package OpenFrame::WebApp::Segment::User::SaveInSession;

use strict;
use warnings::register;

use base qw( OpenFrame::WebApp::Segment::User
	     OpenFrame::WebApp::Segment::User::Session );

our $VERSION = (split(/ /, '$Revision: 1.2 $'))[1];

sub dispatch {
    my $self = shift;
    my $user = $self->get_user_from_store || return;
    return $self->save_user_in_session( $user );
}

1;

__END__

=head1 DESCRIPTION

Save a User into the Session if both objects can be found in the store.

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<OpenFrame::WebApp::User>,
L<OpenFrame::WebApp::Segment::User>,
L<OpenFrame::WebApp::Segment::User::Session>

=cut
