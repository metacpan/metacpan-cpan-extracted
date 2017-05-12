=head1 NAME

Pangloss::Segment::ListConcepts - list concepts.

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::ListConcepts->new )

=cut

package Pangloss::Segment::ListConcepts;

use Pangloss::Concept;

use base qw( Pipeline::Segment );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.7 $ '))[2];

sub dispatch {
    my $self = shift;
    my $app  = $self->store->get('Pangloss::Application') || return;
    my $view = $self->store->get('Pangloss::Application::View');
    return $app->concept_editor->list( $view );
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

Uses the pangloss concept editor app to load a list of concepts, and returns
the resulting view or error.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::Application>

=cut
