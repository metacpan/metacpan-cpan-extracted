=head1 NAME

Pangloss::Segment::LoadLanguage - load language from an OpenFrame::Request.

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::LoadLanguage->new )

=cut

package Pangloss::Segment::LoadLanguage;

use Pangloss::Language;

use base qw( OpenFrame::WebApp::Segment::User::Session );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.4 $ '))[2];

sub dispatch {
    my $self    = shift;
    my $request = $self->store->get('OpenFrame::Request') || return;
    return $self->new_language_from_args( $request->arguments );
}

sub new_language_from_args {
    my $self = shift;
    my $args = shift;
    my $user = $self->get_user_from_session;

    my $language = new Pangloss::Language();
    my $modified = 0;

    $language->creator( $user->key ) if ($user);

    foreach my $var (qw( name notes iso_code direction )) {
	if (exists( $args->{"new_language_$var"} )) {
	    $language->$var( $args->{"new_language_$var"} );
	    $modified++;
	}
    }

    return $modified ? $language : undef;
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class inherits its interface from C<Pipeline::Segment>.

=head1 METHODS

=over 4

=item $language = $obj->dispatch();

attempts to load a language from the stored C<OpenFrame::Request>'s arguments.

=item $language = $obj->new_language_from_args( \%args );

Creates a new language from the hash given.  uses the following keys:

    new_language_name
    new_language_notes
    new_language_iso_code
    new_language_direction

Returns undef if no useable keys were present.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pipeline::Segment>,
L<Pangloss::Language>

=cut
