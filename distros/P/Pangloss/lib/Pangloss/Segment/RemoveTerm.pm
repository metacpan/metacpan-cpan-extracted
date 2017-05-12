=head1 NAME

Pangloss::Segment::RemoveTerm - remove term.

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::RemoveTerm->new )

=cut

package Pangloss::Segment::RemoveTerm;

use Pangloss::Term;

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

    if ($args->{remove_term}) {
	my $name = $args->{selected_term};

	$self->emit( "removing term $name" );

	return $app->term_editor->remove( $name, $view );
    }
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class inherits its interface from C<Pipeline::Segment>.

On dispatch(), if the request has an 'remove_term' argument, attempts to
remove the term specified by 'selected_term' and return the
resulting view or error.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::Application::TermEditor>

=cut
