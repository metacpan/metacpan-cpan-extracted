=head1 NAME

Pangloss::Segment::RemoveCategory - remove category.

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::RemoveCategory->new )

=cut

package Pangloss::Segment::RemoveCategory;

use Pangloss::Category;

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

    if ($args->{remove_category}) {
	my $name = $args->{selected_category};

	$self->emit( "removing category $name" );

	return $app->category_editor->remove( $name, $view );
    }
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class inherits its interface from C<Pipeline::Segment>.

On dispatch(), if the request has an 'remove_category' argument, attempts to
remove the category specified by 'selected_category' and return the
resulting view or error.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::Application::CategoryEditor>

=cut
