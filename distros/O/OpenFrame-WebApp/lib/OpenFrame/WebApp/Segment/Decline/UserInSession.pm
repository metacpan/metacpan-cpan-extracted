=head1 NAME

OpenFrame::WebApp::Segment::Decline::UserInSession - decline if User found in
Session

=head1 SYNOPSIS

  # see OpenFrame::WebApp::Segment::Decline

  $OpenFrame::WebApp::Segment::Decline::UserInSession::USER_KEY = 'user';

=cut

package OpenFrame::WebApp::Segment::Decline::UserInSession;

use strict;
use warnings::register;

use Pipeline::Production;
use OpenFrame::WebApp::Error::Abstract;

our $VERSION = (split(/ /, '$Revision: 1.1 $'))[1];

use base qw( OpenFrame::WebApp::Segment::Decline
	     OpenFrame::WebApp::Segment::Session );

use constant message => 'declined: user in session';
our $USER_KEY = 'user';

sub should_decline {
    my $self = shift;
    return $self->get_user_from_session ? 1 : 0;
}

sub get_user_from_session {
    my $self    = shift;
    my $session = $self->get_session_from_store || return;
    return $session->get( $USER_KEY );
}

1;

__END__

=head1 DESCRIPTION

Decline to process this pipe if a registered C<OpenFrame::WebApp::User> is
found in the session.

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<OpenFrame::WebApp::Segment::Decline>, L<OpenFrame::WebApp::Segment::User>

=cut
