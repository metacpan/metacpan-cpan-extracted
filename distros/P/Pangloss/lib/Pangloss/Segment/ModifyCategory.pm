=head1 NAME

Pangloss::Segment::ModifyCategory - modify category.

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::ModifyCategory->new )

=cut

package Pangloss::Segment::ModifyCategory;

use Pangloss::Category;

use base qw( Pipeline::Segment );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.9 $ '))[2];

sub dispatch {
    my $self     = shift;
    my $request  = $self->store->get('OpenFrame::Request') || return;
    my $app      = $self->store->get('Pangloss::Application') || return;
    my $category = $self->store->get('Pangloss::Category') || return;
    my $view     = $self->store->get('Pangloss::Application::View');
    my $args     = $request->arguments;

    if ($args->{modify_category}) {
	my $key = $args->{selected_category};
	$self->emit( "modifying category $key" );
	return $app->category_editor->modify( $key, $category, $view );
    }
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class inherits its interface from C<Pipeline::Segment>.

On dispatch(), if the request has an 'modify_category' argument, attempts to modify
the category specified by 'selected_category' and return the resulting view or
error.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::Segment::LoadCategory>,
L<Pangloss::Application::CategoryEditor>

=cut
