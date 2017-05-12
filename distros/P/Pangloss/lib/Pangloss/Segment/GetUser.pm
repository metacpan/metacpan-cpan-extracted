=head1 NAME

Pangloss::Segment::GetUser - get user.

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::GetUser->new )

=cut

package Pangloss::Segment::GetUser;

use Pangloss::User;

use base qw( Pipeline::Segment );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.7 $ '))[2];

sub dispatch {
    my $self    = shift;
    my $request = $self->store->get('OpenFrame::Request') || return;
    my $app     = $self->store->get('Pangloss::Application') || return;
    my $view    = $self->store->get('Pangloss::Application::View');
    my $args    = $request->arguments;

    if ($args->{get_user}) {
	return $app->user_editor->get( $args->{selected_user}, $view );
    }
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class inherits its interface from C<Pipeline::Segment>.

On dispatch(), if the request has a 'get_user' argument, attempts to
get the user specified by 'selected_user' and return the resulting view or
error.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::Application::UserEditor>

=cut
