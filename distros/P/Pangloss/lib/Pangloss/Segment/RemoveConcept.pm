=head1 NAME

Pangloss::Segment::RemoveConcept - remove concept.

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::RemoveConcept->new )

=cut

package Pangloss::Segment::RemoveConcept;

use Pangloss::Concept;

use base qw( Pipeline::Segment );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.6 $ '))[2];

sub dispatch {
    my $self    = shift;
    my $request = $self->store->get('OpenFrame::Request') || return;
    my $app     = $self->store->get('Pangloss::Application') || return;
    my $view    = $self->store->get('Pangloss::Application::View');
    my $args    = $request->arguments;
    my %details = ();

    if ($args->{remove_concept}) {
	my $name = $args->{selected_concept};

	$self->emit( "removing concept $name" );

	return $app->concept_editor->remove( $name, $view );
    }
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class inherits its interface from C<Pipeline::Segment>.

On dispatch(), if the request has an 'remove_concept' argument, attempts to
remove the concept specified by 'selected_concept' and return the
resulting view or error.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::Application::ConceptEditor>

=cut
