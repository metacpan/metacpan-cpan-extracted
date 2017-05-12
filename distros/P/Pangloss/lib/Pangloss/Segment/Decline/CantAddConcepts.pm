=head1 NAME

Pangloss::Segment::Decline::CantAddConcepts - decline unless there's a user
that can add concpets in the session

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::CantAddConcepts->new )

=cut

package Pangloss::Segment::Decline::CantAddConcepts;

use base qw( OpenFrame::WebApp::Segment::Decline
	     OpenFrame::WebApp::Segment::User::Session );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.3 $ '))[2];

sub should_decline {
    my $self = shift;
    my $user = $self->get_user_from_session || return 1;
    return $user->cant_add_concepts;
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

L<Pangloss>

=cut
