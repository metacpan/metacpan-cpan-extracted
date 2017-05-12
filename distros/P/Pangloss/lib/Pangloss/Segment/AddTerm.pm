=head1 NAME

Pangloss::Segment::AddTerm - add term.

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::AddTerm->new )

=cut

package Pangloss::Segment::AddTerm;

use Pangloss::Term;

use base qw( Pipeline::Segment );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.8 $ '))[2];

sub dispatch {
    my $self    = shift;
    my $request = $self->store->get('OpenFrame::Request') || return;
    my $app     = $self->store->get('Pangloss::Application') || return;
    my $term    = $self->store->get('Pangloss::Term') || return;
    my $view    = $self->store->get('Pangloss::Application::View');
    my $args    = $request->arguments;

    if ($args->{add_term}) {
	$self->emit( "adding term " . $term->name );
	return $app->term_editor->add( $term, $view );
    }
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class inherits its interface from C<Pipeline::Segment>.

On dispatch(), if the request has an 'add_term' argument, attempts to add the
term and return the resulting view or error.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::Segment::LoadTerm>,
L<Pangloss::Application::TermEditor>

=cut
