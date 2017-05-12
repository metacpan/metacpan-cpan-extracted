=head1 NAME

Pangloss::Segment::ListStatusCodes - list term status codes.

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::ListStatusCodes->new )

=cut

package Pangloss::Segment::ListStatusCodes;

use base qw( Pipeline::Segment );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.3 $ '))[2];

sub dispatch {
    my $self = shift;
    my $app  = $self->store->get('Pangloss::Application') || return;
    my $view = $self->store->get('Pangloss::Application::View');
    return $app->term_editor->list_status_codes( $view );
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

Uses the pangloss user editor app to load a list of status codes, and returns
the resulting view or error.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::Application>

=cut
