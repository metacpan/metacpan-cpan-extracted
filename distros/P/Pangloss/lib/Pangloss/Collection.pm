=head1 NAME

Pangloss::Collection - base class for collections in Pangloss.

=head1 SYNOPSIS

  # abstract - cannot be used directly
  use base qw( Pangloss::Collection );

  # read on...

=cut

package Pangloss::Collection;

use strict;
use warnings::register;

use Error;
use Scalar::Util qw( blessed );
use OpenFrame::WebApp::Error::Abstract;

use base      qw( Pangloss::Object );
use accessors qw( collection );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.14 $ '))[2];

sub init {
    my $self = shift;
    $self->collection( {} );
}

sub keys {
    my $self = shift;
    my @keys = CORE::keys %{ $self->collection };
    return wantarray ? (@keys) : [@keys];
}

sub values {
    my $self = shift;
    my @vals = values %{ $self->collection };
    return wantarray ? (@vals) : [@vals];
}

sub list {
    return shift->values;
}

sub sorted_list {
    my $self = shift;
    my @vals = map {$self->collection->{$_}} sort $self->keys;
    return wantarray ? (@vals) : [@vals];
}

sub iterator {
    my $self = shift;
    # might be an idea to take a copy of keys() and use get() - it'll throw an
    # exception if the collection ever changes.
    return sub { return (each %{ $self->collection })[1] };
}

sub size {
    my $self = shift;
    return scalar CORE::keys( %{ $self->collection } );
}

sub is_empty {
    my $self = shift;
    return $self->size == 0;
}

sub not_empty {
    my $self = shift;
    return $self->size > 0;
}

sub clone {
    my $self  = shift;
    my $clone = $self->class->new;

    $clone->collection( { %{ $self->collection } } );

    return $clone;
}

sub deep_clone {
    my $self  = shift;
    my $clone = $self->class->new;

    $clone->add( map { $_->clone; } $self->values );

    return $clone;
}

sub get {
    my $self = shift;
    my $key  = $self->get_values_key( shift );

    unless ($self->exists( $key )) {
	$self->error_key_nonexistent( $key );
    }

    return $self->collection->{$key};
}

sub exists {
    my $self = shift;
    my $key  = $self->get_values_key( shift );
    return exists($self->collection->{$key});
}

sub add {
    my $self = shift;

    foreach my $value (@_) {
	my $key = $self->get_values_key( $value );
	if ($self->exists( $key )) {
	    $self->error_key_exists( $key );
	} else {
	    $self->collection->{$key} = $value;
	}
    }

    return $self;
}

sub remove {
    my $self = shift;

    foreach my $thing (@_) {
	my $key = $self->get_values_key( $thing );
	if ($self->exists( $key )) {
	    delete $self->collection->{$key};
	} else {
	    $self->error_key_nonexistent( $key );
	}
    }

    return $self;
}

sub get_values_key {
    my $self = shift;
    my $val  = shift;
    return $val unless blessed( $val );
    return $val->isa( 'Pangloss::Collection::Item' ) ? $val->key : $val;
}

sub error_key_nonexistent {
    my $self = shift;
    throw OpenFrame::WebApp::Error::Abstract( class => ref($self) );
}

sub error_key_exists {
    my $self = shift;
    throw OpenFrame::WebApp::Error::Abstract( class => ref($self) );
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class is a simple OO wrapper around a perl Hash.  Perhaps a better name
for it would be Collection::Map.  It should help make storing collections of
objects in L<Pixie> easier.

Items stored in these collections should inherit from L<Pangloss::Collection::Item>.

=head1 METHODS

=over 4

=item @keys = $obj->keys

as in C<keys()>.  uses wantarray for Petal compliancy.

=item @values = $obj->values

as in C<values()>.  uses wantarray for Petal compliancy.

=item @values = $obj->list

synonym for $obj->values().

=item @values = $obj->sorted_list

returns $obj->values() sorted alphabetically by I<key>.

=item $iterator = $obj->iterator

get an iterator code ref for this collection, can be used as such:

  while (my $next_val = $iterator->()) {
      ...
  }

useful for large collections.

=item $boolean = $obj->exists( $key )

as in C<exists()>.

=item $value = $obj->get( $key )

get the value associated with $key.  throws an error if $key does not exist.

=item $obj->add( $value1, $value2, ... )

add values to this collection.  looks up keys for these values with
$obj->get_values_key().  throws an error if values already exists.  returns
this object.

=item $obj->remove( $key1, $value2, ... )

remove keys and/or values from this collection.  throws an error if a key
does not exist.  returns this object.

=item $key = $obj->get_values_key( $value )

gets $value->key() if $value is blessed, or returns $value.

=item $obj2 = $obj->clone

returns a new object containing a shallow copy of this collection.
(ie: objects in the clone's collection are the same)

=item $obj2 = $obj->deep_clone

returns a new object containing a deep copy of this collection.
(ie: objects in the clone's collection are cloned)

=back

=head1 SUB-CLASSING

Override the following methods:

=over 4

=item $key = $obj->error_key_exists( $key )

abstract.  indicates a L<Pangloss::Error> should be thrown.

=item $key = $obj->error_key_nonexistent( $key )

abstract.  indicates a L<Pangloss::Error> should be thrown.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>, L<Pangloss::Collection::Item>,
L<OpenFrame::WebApp::Error::Abstract>

=cut
