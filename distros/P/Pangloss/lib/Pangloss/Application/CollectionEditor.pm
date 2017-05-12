=head1 NAME

Pangloss::Application::CollectionEditor - abstract collection editor app.

=head1 SYNOPSIS

  # abstract - cannot be used directly
  package App::FooEditor;
  use base qw( Pangloss::Application::CollectionEditor );

  my $foo_editor = new App::FooEditor;
  my $view = $foo_editor->add( $obj );
  $foo_editor->get( $key, $view );
  $foo_editor->update( $key, $obj, $view );
  $foo_editor->remove( $key, $view );

=cut

package Pangloss::Application::CollectionEditor;

use strict;
use warnings::register;

use Error qw( :try );

use Pangloss::Collection;
use OpenFrame::WebApp::Error::Abstract;
use Pangloss::Application::View;

use base qw( Pangloss::Application::Base );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.14 $ '))[2];

sub object_name {
    my $self = shift;
    throw OpenFrame::WebApp::Error::Abstract( class => ref($self) );
}

sub objects_name {
    my $self = shift;
    throw OpenFrame::WebApp::Error::Abstract( class => ref($self) );
}

sub collection_name {
    my $self = shift;
    throw OpenFrame::WebApp::Error::Abstract( class => ref($self) );
}

sub collection_class {
    my $self = shift;
    throw OpenFrame::WebApp::Error::Abstract( class => ref($self) );
}

sub get_or_create_collection {
    my $self = shift;
    # TODO: re-implement caching here by using an 'up2date' object in Pixie
    #return $self->{cache}->{$self->collection_name} ||=
      $self->get_or_create_stored_obj( $self->collection_name,
				       $self->collection_class );
}

sub add {
    my $self       = shift;
    my $obj        = shift->clone;
    my $view       = shift || new Pangloss::Application::View;
    my $collection = $self->get_or_create_collection;
    my $name       = $self->object_name;

    try {
	$obj->date(time)->validate;

	$collection->add( $obj );

	$self->save( $collection );

	$view->{add}->{$name}          = $obj->clone;
	$view->{add}->{$name}->{added} = 1;
    } catch Pangloss::StoredObject::Error with {
	$view->{add}->{$name}->{error} = shift;
    };

    $view->{$name} = $view->{add}->{$name};

    return $view;
}

sub list {
    my $self       = shift;
    my $view       = shift || new Pangloss::Application::View;
    my $collection = $self->get_or_create_collection;
    my $names      = $self->objects_name;
    my $clone      = $collection->deep_clone;

    $view->{"$names\_collection"} = $clone;
    $view->{$names} = $collection->list;

    return $view;
}

sub get {
    my $self       = shift;
    my $key        = shift;
    my $view       = shift || new Pangloss::Application::View;
    my $collection = $self->get_or_create_collection;
    my $name       = $self->object_name;

    try {
	$view->{get}->{$name} = $collection->get( $key )->clone;
    } catch Pangloss::StoredObject::Error with {
	$view->{get}->{$name}->{error} = shift;
    };

    $view->{$name} = $view->{get}->{$name};

    return $view;
}

sub modify {
    my $self       = shift;
    my $key        = shift;
    my $new_obj    = shift;
    my $view       = shift || new Pangloss::Application::View;
    my $collection = $self->get_or_create_collection;
    my $name       = $self->object_name;

    try {
	# must be a collection element to modify
	my $obj = $collection->get( $key );

	# save the current object in the view incase there's an error
	$view->{modify}->{$name} = $obj->clone;

	# check element doesn't already exist on a change in key:
	my $new_key = $collection->get_values_key( $new_obj );
	if ( ($new_key ne $key) and $collection->exists( $new_key ) ) {
	    $self->error_key_exists( $new_key );
	}

	$new_obj->date( $obj->date )
	        ->creator( $obj->creator )
		->validate;

	# copy details from the new collection
	# (don't want to just save $new_obj for referential integrity):
	$obj->copy( $new_obj );

	$new_key = $collection->get_values_key( $obj );
	if ($new_key ne $key) {
	    $collection->add( $obj );
	    $collection->remove( $key );
	    $self->save( $collection );
	} else {
	    $self->save( $obj );
	}

	$view->{modify}->{$name}             = $obj->clone;
	$view->{modify}->{$name}->{modified} = 1;
    } catch Pangloss::StoredObject::Error with {
	$view->{modify}->{$name}->{error} = shift;
    };

    $view->{$name} = $view->{modify}->{$name};

    return $view;
}

sub remove {
    my $self       = shift;
    my $key        = shift;
    my $view       = shift || new Pangloss::Application::View;
    my $collection = $self->get_or_create_collection;
    my $name       = $self->object_name;

    try {
	my $obj = $collection->get( $key );

	$collection->remove( $key );

	$self->save( $collection );

	$view->{remove}->{$name}            = $obj->clone;
	$view->{remove}->{$name}->{removed} = 1;
    } catch Pangloss::StoredObject::Error with {
	$view->{remove}->{$name}->{error} = shift;
    };

    $view->{$name} = $view->{remove}->{$name};

    return $view;
}

sub exists {
    my $self = shift;
    my $key  = shift;
    return $self->get_or_create_collection->exists( $key );
}

sub error_key_exists {
    my $self = shift;
    throw OpenFrame::WebApp::Error::Abstract( class => ref($self) );
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class implements a collection editor application for Pangloss.

It inherits from L<Pangloss::Application::Base>.

=head1 METHODS

These methods throw an L<Error> if they cannot perform their jobs.  On success,
each returns a L<Pangloss::Application::View>.  Most set the collection as
$view->{object_name}, and a flag indicating the operation performed.

=over 4

=item $view = $obj->add( $obj [, $view ] )

add a collection.  sets $view->{collection_added}.
throws an error if a collection exists, or the collection is invalid.

=item $view = $obj->list( [ $view ] )

sets $view->{objects_name . '_collection'} to a I<deep clone> of the collection
and sets $view->{objects_name} to the list of items as a shortcut.  (Note the
plural: I<objects_name>)

=item $view = $obj->get( $key [, $view ] )

get a collection.  sets $view->{object_name} only.
throws an error if the collection does not exist.

=item $view = $obj->modify( $key, $obj [, $view ] )

modifies collection named by $key.  copies $obj.
sets $view->{object_name . '_modified'}.
throws an error if the collection does not exist.

=item $view = $obj->remove( $key [, $view ] )

get a collection.  sets $view->{object_name . '_removed'}.
throws an error if the collection does not exist.

=item $bool = $obj->exists( $key )

test to see if the named item exists in the collection.

=back

=head1 SUB-CLASSING

Override the following methods:

=over 4

=item $name = $obj->object_name

constant. name to use for this object in the $view.

=item $name = $obj->objects_name

constant. name to use for lists of this object in the $view.

=item $name = $obj->collection_name

constant. collection name to use in the store (ie: Pixie).

=item $name = $obj->collection_class

constant. class of collection to use.

=item $obj->error_key_exists

abstract. indicates that a L<Pangloss::Error> should be thrown.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>, L<Pangloss::Collection>

=cut
