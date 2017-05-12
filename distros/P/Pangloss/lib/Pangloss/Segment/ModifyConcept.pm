=head1 NAME

Pangloss::Segment::ModifyConcept - modify concept.

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::ModifyConcept->new )

=cut

package Pangloss::Segment::ModifyConcept;

use Pangloss::Concept;

use base qw( Pipeline::Segment );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.9 $ '))[2];

sub dispatch {
    my $self    = shift;
    my $request = $self->store->get('OpenFrame::Request') || return;
    my $app     = $self->store->get('Pangloss::Application') || return;
    my $concept = $self->store->get('Pangloss::Concept') || return;
    my $view    = $self->store->get('Pangloss::Application::View');
    my $args    = $request->arguments;

    if ($args->{modify_concept}) {
	my $key = $args->{selected_concept};
	$self->emit( "modifying concept $key" );
	return $app->concept_editor->modify( $key, $concept, $view );
    }
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class inherits its interface from C<Pipeline::Segment>.

On dispatch(), if the request has an 'modify_concept' argument, attempts to modify
the concept specified by 'selected_concept' and return the resulting view or
error.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::Segment::LoadConcept>,
L<Pangloss::Application::ConceptEditor>

=cut
