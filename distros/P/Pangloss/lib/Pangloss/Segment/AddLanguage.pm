=head1 NAME

Pangloss::Segment::AddLanguage - add language.

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::AddLanguage->new )

=cut

package Pangloss::Segment::AddLanguage;

use Pangloss::Language;

use base qw( Pipeline::Segment );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.8 $ '))[2];

sub dispatch {
    my $self     = shift;
    my $request  = $self->store->get('OpenFrame::Request') || return;
    my $app      = $self->store->get('Pangloss::Application') || return;
    my $language = $self->store->get('Pangloss::Language') || return;
    my $view     = $self->store->get('Pangloss::Application::View');
    my $args     = $request->arguments;

    if ($args->{add_language}) {
	$self->emit( "adding language " . $language->iso_code );
	return $app->language_editor->add( $language, $view );
    }
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class inherits its interface from C<Pipeline::Segment>.

On dispatch(), if the request has an 'add_language' argument, attempts to add the
language and return the resulting view or error.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::Segment::LoadLanguage>,
L<Pangloss::Application::LanguageEditor>

=cut
