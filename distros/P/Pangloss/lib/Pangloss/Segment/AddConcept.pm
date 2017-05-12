=head1 NAME

Pangloss::Segment::AddConcept - add concept.

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::AddConcept->new )

=cut

package Pangloss::Segment::AddConcept;

use Pangloss::Concept;

use base qw( Pipeline::Segment );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.8 $ '))[2];

sub dispatch {
    my $self    = shift;
    my $request = $self->store->get('OpenFrame::Request') || return;
    my $app     = $self->store->get('Pangloss::Application') || return;
    my $concept = $self->store->get('Pangloss::Concept') || return;
    my $view    = $self->store->get('Pangloss::Application::View');
    my $args    = $request->arguments;

    if ($args->{add_concept}) {
	$self->emit( "adding concept " . $concept->name );
	return $app->concept_editor->add( $concept, $view );
    }
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class inherits its interface from C<Pipeline::Segment>.

On dispatch(), if the request has an 'add_concept' argument, attempts to add the
concept and return the resulting view or error.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::Segment::LoadConcept>,
L<Pangloss::Application::ConceptEditor>

=cut
