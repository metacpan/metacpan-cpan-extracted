=head1 NAME

Pangloss::Segment::ListLanguages - list languages.

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::ListLanguages->new )

=cut

package Pangloss::Segment::ListLanguages;

use Pangloss::Language;

use base qw( Pipeline::Segment );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.10 $ '))[2];

sub dispatch {
    my $self = shift;
    my $app  = $self->store->get('Pangloss::Application') || return;
    my $view = $self->store->get('Pangloss::Application::View');
    return $app->language_editor->list( $view );
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

Uses the pangloss language editor app to load a list of languages, and returns
the resulting view or error.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::Application>

=cut
