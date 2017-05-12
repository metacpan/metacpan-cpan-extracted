=head1 NAME

Pangloss::Segment::GetLanguage - get language.

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::GetLanguage->new )

=cut

package Pangloss::Segment::GetLanguage;

use Pangloss::Language;

use base qw( Pipeline::Segment );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.6 $ '))[2];

sub dispatch {
    my $self    = shift;
    my $request = $self->store->get('OpenFrame::Request') || return;
    my $app     = $self->store->get('Pangloss::Application') || return;
    my $view    = $self->store->get('Pangloss::Application::View');
    my $args    = $request->arguments;

    if ($args->{get_language}) {
	return $app->language_editor->get( $args->{selected_language}, $view );
    }
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class inherits its interface from C<Pipeline::Segment>.

On dispatch(), if the request has a 'get_language' argument, attempts to get
the language specified by 'selected_language' and return the resulting
view or error.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::Application::LanguageEditor>

=cut
