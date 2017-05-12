=head1 NAME

Pangloss::Segment::AddUser - add user.

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::AddUser->new )

=cut

package Pangloss::Segment::AddUser;

use Pangloss::User;

use base qw( Pipeline::Segment );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.13 $ '))[2];

sub dispatch {
    my $self     = shift;
    my $request  = $self->store->get('OpenFrame::Request') || return;
    my $app      = $self->store->get('Pangloss::Application') || return;
    my $new_user = $self->store->get('Pangloss::User') || return;
    my $view     = $self->store->get('Pangloss::Application::View');
    my $args     = $request->arguments;

    if ($args->{add_user}) {
	$self->emit( "adding user " . $new_user->id );
	return $app->user_editor->add( $new_user, $view );
    }
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class inherits its interface from C<Pipeline::Segment>.

On dispatch(), if the request has an 'add_user' argument, attempts to add the
user and return the resulting view or error.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::Segment::LoadUser>,
L<Pangloss::Application::UserEditor>

=cut
