=head1 NAME

Pangloss::Segment::RemoveUser - remove user.

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::RemoveUser->new )

=cut

package Pangloss::Segment::RemoveUser;

use Pangloss::User;

use base qw( Pipeline::Segment );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.8 $ '))[2];

sub dispatch {
    my $self    = shift;
    my $request = $self->store->get('OpenFrame::Request') || return;
    my $app     = $self->store->get('Pangloss::Application') || return;
    my $view    = $self->store->get('Pangloss::Application::View');
    my $args    = $request->arguments;
    my %details = ();

    if ($args->{remove_user}) {
	my $userid = $args->{selected_user};

	$self->emit( "removing user $userid" );

	return $app->user_editor->remove( $userid, $view );
    }
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class inherits its interface from C<Pipeline::Segment>.

On dispatch(), if the request has an 'remove_user' argument, attempts to remove
the user specified by 'selected_user' and return the resulting view or
error.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::Application::UserEditor>

=cut
