=head1 NAME

Pangloss::Segment::RemoteUserLoader - load current user.

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::RemoteUserLoader->new )

=cut

package Pangloss::Segment::RemoteUserLoader;

use Pangloss::User;

use base qw( OpenFrame::WebApp::Segment::User::EnvLoader
	     OpenFrame::WebApp::Segment::Session );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.1 $ '))[2];

sub dispatch {
    my $self    = shift;
    my $app     = $self->store->get('Pangloss::Application') || return;
    my $userid  = $self->look_in_env || return;

    $self->emit("getting user: $userid");

    my $view = $app->user_editor->get( $userid );
    return( $view->{user} );
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This C<Pipeline::Segment> tries to load the user from $ENV{REMOTE_USER}.  If
found, it loads the user object from Pangloss and saves it in the session.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::Application::UserEditor>,
L<OpenFrame::WebApp::Segment::User::EnvLoader>,
L<OpenFrame::WebApp::Segment::Session>

=cut
