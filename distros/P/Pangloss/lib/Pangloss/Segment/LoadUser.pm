=head1 NAME

Pangloss::Segment::LoadUser - load user from an OpenFrame::Request.

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::LoadUser->new )

=cut

package Pangloss::Segment::LoadUser;

use Pangloss::User;

use base qw( OpenFrame::WebApp::Segment::User::Session );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.5 $ '))[2];

sub dispatch {
    my $self    = shift;
    my $request = $self->store->get('OpenFrame::Request') || return;
    return $self->new_user_from_args( $request->arguments );
}

sub new_user_from_args {
    my $self = shift;
    my $args = shift;
    my $user = $self->get_user_from_session;

    my $new_user = new Pangloss::User();
    my $modified = 0;

    $new_user->creator( $user->key ) if ($user);

    foreach my $var (qw( name notes id )) {
	if (exists( $args->{"new_user_$var"} )) {
	    $new_user->$var( $args->{"new_user_$var"} );
	    $modified++;
	}
    }

    $new_user->privileges
      ->admin( $args->{new_user_admin} =~ /on/i ? 1 : undef )
      ->add_concepts( $args->{new_user_add_concepts} =~ /on/i ? 1 : undef )
      ->add_categories( $args->{new_user_add_categories} =~ /on/i ? 1 : undef )
      ->add_translate_languages( $self->get_translate_langs_from_args( $args ) )
      ->add_proofread_languages( $self->get_proofread_langs_from_args( $args ) );

    return $modified ? $new_user : undef;
}

sub get_translate_langs_from_args {
    my $self = shift;
    my $args = shift;
    return map { $_ =~ /^new_user_translate_(.+)$/ ? $1 : () ; } keys( %$args );
}

sub get_proofread_langs_from_args {
    my $self = shift;
    my $args = shift;
    return map { $_ =~ /^new_user_proofread_(.+)$/ ? $1 : () ; } keys( %$args );
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class inherits its interface from C<Pipeline::Segment>.

=head1 METHODS

=over 4

=item $user = $obj->dispatch();

attempts to load a user from the stored C<OpenFrame::Request>'s arguments.

=item $user = $obj->new_user_from_args( \%args );

Creates a new user from the hash given.  uses the following keys:

 *  new_user_id
 *  new_user_name
 *  new_user_notes
    new_user_admin
    new_user_add_concepts
    new_user_add_categories
    new_user_translate_<iso_code>
    new_user_proofread_<iso_code>

Where C<iso_code> is the iso code of a Pangloss::Language.
Returns undef if no useable keys marked with (*) were present.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pipeline::Segment>,
L<Pangloss::User>

=cut
