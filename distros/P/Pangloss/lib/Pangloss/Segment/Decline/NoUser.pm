=head1 NAME

Pangloss::Segment::Decline::NoUser - decline unless there's a user in the store

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::NoUser->new )

=cut

package Pangloss::Segment::Decline::NoUser;

use base qw( OpenFrame::WebApp::Segment::Decline
	     OpenFrame::WebApp::Segment::User );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.4 $ '))[2];

sub should_decline {
    my $self = shift;
    return $self->get_user_from_store ? 0 : 1;
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class inherits its interface from C<OpenFrame::WebApp::Segment::Decline>
and C<OpenFrame::WebApp::Segment::User::Session>.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::User>

=cut
