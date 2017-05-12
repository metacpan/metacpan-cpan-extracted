=head1 NAME

Pangloss::Application::Base - base class for application objects.

=head1 SYNOPSIS

  # abstract class - cannot be used directly
  use base qw( Pangloss::Application::Base );

  sub foo {
      my $self = shift;
      $self->parent;
      $self->store;
      my $obj = $self->get_or_create_stored_obj( $key, $class );
      $self->save( $obj );
  }

=cut

package Pangloss::Application::Base;

use strict;
use warnings::register;

use Error;
use Pangloss::Users;

use base      qw( Pangloss::Object );
use accessors qw( parent );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.4 $ '))[2];

sub store {
    my $self = shift;
    $self->parent->store(@_);
}

sub get_or_create_stored_obj {
    my $self  = shift;
    my $key   = shift;
    my $class = shift;
    my $obj   = $self->store->get_object_named( $key );

    unless ($obj) {
	$obj = $class->new();
	$self->store->insert( $obj );
	$self->store->bind_name( $key => $obj );
    }

    return $obj;
}

sub save {
    my $self = shift;
    my $obj  = shift;
    $self->store->insert( $obj );
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This is a base class for all application objects.

=head1 METHODS

=over 4

=item $obj->parent

set/get the parent application.

=item $obj->store

set/get the parent's store.

=item $abc = $obj->get_or_create_stored_obj( $key, $class )

gets or creates an object bound to $key from the store.  calls $class->new
and stores the result if no object is found in the store.

=item $obj->save( $abc )

save this object in the store.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::Application>

=cut
