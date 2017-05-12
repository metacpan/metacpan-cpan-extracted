=head1 NAME

Pangloss::Segment::Decline::CantProofreadSelectedTerm - decline unless there's a user
that can add concpets in the session

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::CantProofreadSelectedTerm->new )

=cut

package Pangloss::Segment::Decline::CantProofreadSelectedTerm;

use UNIVERSAL qw( isa );

use base qw( OpenFrame::WebApp::Segment::Decline
	     OpenFrame::WebApp::Segment::User::Session );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.2 $ '))[2];

sub should_decline {
    my $self    = shift;
    my $app     = $self->store->get('Pangloss::Application') || return 1;
    my $user    = $self->get_user_from_session || return 1;
    my $request = $self->store->get('OpenFrame::Request') || return 1;
    my $key     = $request->arguments->{selected_term} || return 1;
    my $view    = $self->store->get('Pangloss::View');

    $view = $app->term_editor->get( $key, $view );

    $self->store->set( $view );

    my $term = $view->{term};
    return 1 unless isa( $term, 'Pangloss::Term' );

    return $user->cant_proofread( $term->language );
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
