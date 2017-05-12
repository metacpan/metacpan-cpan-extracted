=head1 NAME

Pangloss::Segment::LoadConcept - load concept from an OpenFrame::Request.

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::LoadConcept->new )

=cut

package Pangloss::Segment::LoadConcept;

use Pangloss::Concept;

use base qw( OpenFrame::WebApp::Segment::User::Session );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.4 $ '))[2];

sub dispatch {
    my $self    = shift;
    my $request = $self->store->get('OpenFrame::Request') || return;
    return $self->new_concept_from_args( $request->arguments );
}

sub new_concept_from_args {
    my $self = shift;
    my $args = shift;
    my $user = $self->get_user_from_session;

    my $concept  = new Pangloss::Concept();
    my $modified = 0;

    $concept->creator( $user->key ) if ($user);

    foreach my $var (qw( name notes category )) {
	if (exists( $args->{"new_concept_$var"} )) {
	    $concept->$var( $args->{"new_concept_$var"} );
	    $modified++;
	}
    }

    return $modified ? $concept : undef;
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class inherits its interface from C<Pipeline::Segment>.

=head1 METHODS

=over 4

=item $concept = $obj->dispatch();

attempts to load a concept from the stored C<OpenFrame::Request>'s arguments.

=item $concept = $obj->new_concept_from_args( \%args );

Creates a new concept from the hash given.  uses the following keys:

    new_concept_name
    new_concept_notes
    new_concept_category

Returns undef if no useable keys were present.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pipeline::Segment>,
L<Pangloss::Concept>

=cut
