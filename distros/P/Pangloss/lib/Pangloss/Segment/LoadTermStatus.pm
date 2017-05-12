=head1 NAME

Pangloss::Segment::LoadTermStatus - load term status from an OpenFrame::Request.

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::LoadTermStatus->new )

=cut

package Pangloss::Segment::LoadTermStatus;

use Pangloss::Term;

use base qw( OpenFrame::WebApp::Segment::User::Session );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.4 $ '))[2];

sub dispatch {
    my $self    = shift;
    my $request = $self->store->get('OpenFrame::Request') || return;
    return $self->new_term_status_from_args( $request->arguments );
}

sub new_term_status_from_args {
    my $self = shift;
    my $args = shift;
    my $user = $self->get_user_from_session;

    my $status   = new Pangloss::Term::Status();
    my $modified = 0;

    $status->creator( $user->key ) if ($user);

    foreach my $var (qw( code notes )) {
	if (exists( $args->{"new_term_status_$var"} )) {
	    $status->$var( $args->{"new_term_status_$var"} );
	    $modified++;
	}
    }

    return $modified ? $status : undef;
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class inherits its interface from C<Pipeline::Segment>.

=head1 METHODS

=over 4

=item $status = $obj->dispatch();

attempts to load a term status from the stored C<OpenFrame::Request>'s arguments.

=item $status = $obj->new_term_status_from_args( \%args );

Creates a new term status from the hash given.  uses the following keys:

    new_term_status_code
    new_term_status_notes

Returns undef if no useable keys were present.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pipeline::Segment>,
L<Pangloss::Term::Status>

=cut
