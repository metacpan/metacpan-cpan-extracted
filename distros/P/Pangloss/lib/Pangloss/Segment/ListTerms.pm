=head1 NAME

Pangloss::Segment::ListTerms - list terms.

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::ListTerms->new )

=cut

package Pangloss::Segment::ListTerms;

use Pangloss::Term;

use base qw( Pipeline::Segment );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.7 $ '))[2];

sub dispatch {
    my $self = shift;
    my $app  = $self->store->get('Pangloss::Application') || return;
    my $view = $self->store->get('Pangloss::Application::View');
    return $app->term_editor->list( $view );
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

Uses the pangloss term editor app to load a list of terms, and returns the
resulting view or error.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::Application>

=cut
