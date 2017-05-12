=head1 NAME

Pangloss::Segment::Decline::NoUserInSession - decline unless there's a user in the session

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::NoUserInSession->new )

=cut

package Pangloss::Segment::Decline::NoUserInSession;

use base qw( OpenFrame::WebApp::Segment::Decline
	     OpenFrame::WebApp::Segment::User::Session );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.3 $ '))[2];

sub should_decline {
    my $self = shift;
    my $sess = $self->get_session_from_store || return 1;
    return $sess->get('user') ? 0 : 1;
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

Inherits from C<OpenFrame::WebApp::Segment::Decline> and
C<OpenFrame::WebApp::Segment::User::Session::Session>.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::User>

=cut
