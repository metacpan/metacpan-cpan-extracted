=head1 NAME

Pangloss::Segment::GetTerm - get term.

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::GetTerm->new )

=cut

package Pangloss::Segment::GetTerm;

use Pangloss::Term;

use base qw( Pipeline::Segment );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.5 $ '))[2];

sub dispatch {
    my $self    = shift;
    my $request = $self->store->get('OpenFrame::Request') || return;
    my $app     = $self->store->get('Pangloss::Application') || return;
    my $view    = $self->store->get('Pangloss::Application::View');
    my $args    = $request->arguments;

    if ($args->{get_term}) {
	return $app->term_editor->get( $args->{selected_term}, $view );
    }
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class inherits its interface from C<Pipeline::Segment>.

On dispatch(), if the request has a 'get_term' argument, attempts to get
the term specified by 'selected_term' and return the resulting
view or error.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::Application::TermEditor>

=cut
