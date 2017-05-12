=head1 NAME

Pangloss::Segment::LoadTerm - load term from an OpenFrame::Request.

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::LoadTerm->new )

=cut

package Pangloss::Segment::LoadTerm;

use Pangloss::Term;

use base qw( OpenFrame::WebApp::Segment::User::Session );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.4 $ '))[2];

sub dispatch {
    my $self    = shift;
    my $request = $self->store->get('OpenFrame::Request') || return;
    return $self->new_term_from_args( $request->arguments );
}

sub new_term_from_args {
    my $self = shift;
    my $args = shift;
    my $user = $self->get_user_from_session;

    my $term     = new Pangloss::Term();
    my $modified = 0;

    $term->creator( $user->key ) if ($user);

    foreach my $var (qw( name notes concept language )) {
	if (exists( $args->{"new_term_$var"} )) {
	    $term->$var( $args->{"new_term_$var"} );
	    $modified++;
	}
    }

    return $modified ? $term : undef;
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class inherits its interface from C<Pipeline::Segment>.

=head1 METHODS

=over 4

=item $term = $obj->dispatch();

attempts to load a term from the stored C<OpenFrame::Request>'s arguments.

=item $term = $obj->new_term_from_args( \%args );

Creates a new term from the hash given.  uses the following keys:

    new_term_name
    new_term_notes
    new_term_concept
    new_term_language

Returns undef if no useable keys were present.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pipeline::Segment>,
L<Pangloss::Term>

=cut
