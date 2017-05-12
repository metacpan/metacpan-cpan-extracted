=head1 NAME

Pangloss::Segment::UserLoader - load current user.

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::UserLoader->new )

=cut

package Pangloss::Segment::UserLoader;

use Pangloss::User;

use base qw( OpenFrame::WebApp::Segment::User::RequestLoader
	     OpenFrame::WebApp::Segment::Session );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.8 $ '))[2];

sub dispatch {
    my $self    = shift;
    my $app     = $self->store->get('Pangloss::Application') || return;
    my $userid  = $self->look_in_request || return;

    $self->emit("getting user: $userid");

    my $view = $app->user_editor->get( $userid );
    return( $view->{user} );
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class inherits its interface from C<Pipeline::Segment>.

On dispatch(), tries to load the user from the request.  If found, it checks
with pangloss to make sure the user is valid, and saves the object in the
session.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::Application::UserEditor>

=cut
