=head1 NAME

Pangloss::Segment::Decline::NoSelectedUser - decline unless selected user

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::NoSelectedUser->new )

=cut

package Pangloss::Segment::Decline::NoSelectedUser;

use base qw( OpenFrame::WebApp::Segment::Decline );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.5 $ '))[2];

sub should_decline {
    my $self    = shift;
    my $request = $self->store->get('OpenFrame::Request') || return;
    return $request->arguments()->{selected_user} ? 0 : 1;
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class inherits its interface from C<OpenFrame::WebApp::Segment::Decline>.

Declines if the request does not contain a 'selected_user' argument.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>

=cut
