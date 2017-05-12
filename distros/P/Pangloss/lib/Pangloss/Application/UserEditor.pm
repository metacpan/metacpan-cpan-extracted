=head1 NAME

Pangloss::Application::UserEditor - user editor app for Pangloss.

=head1 SYNOPSIS

  use Pangloss::Application::UserEditor;
  my $editor = new Pangloss::Application::UserEditor();

  my $view0 = $editor->list();
  my $view1 = $editor->add( $user );
  my $view2 = $editor->get( $key );
  my $view3 = $editor->update( $key, $user );
  my $view4 = $editor->remove( $key );
  my $view5 = $editor->list_translators();
  my $view6 = $editor->list_proofreaders();

=cut

package Pangloss::Application::UserEditor;

use strict;
use warnings::register;

use Error;

use Pangloss::Users;
use Pangloss::User::Error;
use Pangloss::StoredObject::Error;
use Pangloss::Application::View;

use base qw( Pangloss::Application::CollectionEditor );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.18 $ '))[2];

use constant object_name      => 'user';
use constant objects_name     => 'users';
use constant collection_name  => 'users';
use constant collection_class => 'Pangloss::Users';

sub add {
    my $self = shift;
    my $user = shift;
    unless ($user->creator) {
	# TODO: remove this when catch 22 situation resolved...
	# (ie: how to create admin user, when no user to be it's creator?)
	warn "WARNING: faking creator for user: " . $user->id;
	$user->creator('admin');
    }
    return $self->SUPER::add( $user, @_ );
}

sub error_key_exists {
    my $self = shift;
    my $key  = shift;
    throw Pangloss::User::Error( flag => eExists, id => $key );
}

sub get_or_create_rm_users {
    my $self  = shift;
    return $self->get_or_create_stored_obj( 'removed_users', 'Pangloss::Users' );
}

sub remove {
    my $self     = shift;
    my $userid   = shift;
    my $view     = shift || new Pangloss::Application::View;
    my $rm_users = $self->get_or_create_rm_users;

    $view = $self->SUPER::remove( $userid, $view );
    $rm_users->add( $view->{user} );
    $self->save( $rm_users );

    return $view;
}

sub list_translators {
    my $self  = shift;
    my $view  = shift || new Pangloss::Application::View;
    my $names = $self->objects_name;

    $self->list( $view ) unless $view->{"$names\_collection"};
    my $collection = $view->{"$names\_collection"};

    $view->{translators} = [ grep { $_->is_translator } $collection->list ];

    return $view;
}

sub list_proofreaders {
    my $self  = shift;
    my $view  = shift || new Pangloss::Application::View;
    my $names = $self->objects_name;

    $self->list( $view ) unless $view->{"$names\_collection"};
    my $collection = $view->{"$names\_collection"};

    $view->{proofreaders} = [ grep { $_->is_proofreader } $collection->list ];

    return $view;
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class implements a user editor application for Pangloss.

Inherits from L<Pangloss::Application::CollectionEditor>.

The user editor maintains a list of removed users (which may eventually be
moved to its own editor class, or removed entirely due to lack of purpose).

=head1 METHODS

=over 4

=item $view = $obj->list_translators( [ $view ] )

sets $view->{translators} to a list of users that can translate.  As a
side-effect, the I<users> collection is listed in the view if not already
present.

=item $view = $obj->list_proofreaders( [ $view ] )

sets $view->{proofreaders} to a list of users that can proofread.  As a
side-effect, the I<users> collection is listed in the view if not already
present.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>, L<Pangloss::User>

=cut
