=head1 NAME

Pangloss::Segment::LoadCategory - load category from an OpenFrame::Request.

=head1 SYNOPSIS

  $pipe->add_segment( Pangloss::Segment::LoadCategory->new )

=cut

package Pangloss::Segment::LoadCategory;

use Pangloss::Category;

use base qw( OpenFrame::WebApp::Segment::User::Session );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.5 $ '))[2];

sub dispatch {
    my $self    = shift;
    my $request = $self->store->get('OpenFrame::Request') || return;
    return $self->new_category_from_args( $request->arguments );
}

sub new_category_from_args {
    my $self = shift;
    my $args = shift;
    my $user = $self->get_user_from_session;

    my $category = new Pangloss::Category();
    my $modified = 0;

    $category->creator( $user->key ) if ($user);

    foreach my $var (qw( name notes )) {
	if (exists( $args->{"new_category_$var"} )) {
	    $category->$var( $args->{"new_category_$var"} );
	    $modified++;
	}
    }

    return $modified ? $category : undef;
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class inherits its interface from C<Pipeline::Segment>.

=head1 METHODS

=over 4

=item $category = $obj->dispatch();

attempts to load a category from the stored C<OpenFrame::Request>'s arguments.

=item $category = $obj->new_category_from_args( \%args );

Creates a new category from the hash given.  uses the following keys:

    new_category_name
    new_category_notes

Returns undef if no useable keys were present.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pipeline::Segment>,
L<Pangloss::Category>

=cut
