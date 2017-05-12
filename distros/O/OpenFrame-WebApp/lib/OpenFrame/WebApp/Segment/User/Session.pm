=head1 NAME

OpenFrame::WebApp::Segment::User::Session - abstract class for working with
users stored in sessions.

=head1 SYNOPSIS

  # abstract - cannot be used directly

  # set session key:
  $OpenFrame::WebApp::Segment::User::Session::USER_KEY = 'my_user';

=cut

package OpenFrame::WebApp::Segment::User::Session;

use strict;
use warnings::register;

use base qw( OpenFrame::WebApp::Segment::Session );

our $VERSION  = (split(/ /, '$Revision: 1.1 $'))[1];
our $USER_KEY = 'user';

sub save_user_in_session {
    my $self    = shift;
    my $user    = shift;
    my $session = $self->get_session_from_store || return;
    $session->set( $USER_KEY, $user );
    return 1;
}

sub get_user_from_session {
    my $self    = shift;
    my $session = $self->get_session_from_store || return;
    return $session->get( $USER_KEY );
}


1;

__END__

=head1 DESCRIPTION

This class contains tools for working with users stored in sessions.

Inherits from C<OpenFrame::WebApp::Segment::Session>.

=over 4

=head1 METHODS

=over 4

=item $bool = $obj->save_user_in_session()

saves user in the stored session, using $USER_KEY.

=item $user = $obj->get_user_from_session()

gets user from the stored session, using $USER_KEY.

=back

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<OpenFrame::WebApp::User>,
L<OpenFrame::WebApp::Segment::Session>,
L<OpenFrame::WebApp::Segment::User::SessionLoader>,
L<OpenFrame::WebApp::Segment::User::SaveInSession>

=cut
