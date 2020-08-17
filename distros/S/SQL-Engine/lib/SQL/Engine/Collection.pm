package SQL::Engine::Collection;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

our $VERSION = '0.03'; # VERSION

# ATTRIBUTES

has items => (
  is => 'ro',
  isa => 'ArrayRef[Object]',
  new => 1
);

fun new_items($self) {
  []
}

# METHODS

method clear() {

  return @{$self->items} = ();
}

method count() {

  return scalar @{$self->items};
}

method each(CodeRef $value) {
  my $results = [];

  for my $item ($self->list) {
    push @$results, $value->($item);
  }

  return $results;
}

method first() {

  return $self->items->[0];
}

method last() {

  return $self->items->[1];
}

method list() {

  return wantarray ? (@{$self->items}) : $self->items;
}

method pop() {

  return CORE::pop @{$self->items};
}

method pull() {

  return shift @{$self->items};
}

method push(Object @values) {

  return CORE::push @{$self->items}, @values;
}

1;

=encoding utf8

=head1 NAME

SQL::Engine::Collection - Generic Object Container

=cut

=head1 ABSTRACT

Generic Object Container

=cut

=head1 SYNOPSIS

  use SQL::Engine::Collection;

  my $collection = SQL::Engine::Collection->new;

  # $collection->count;

  # 0

=cut

=head1 DESCRIPTION

This package provides a generic container for working with sets of objects.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 items

  items(ArrayRef[Object])

This attribute is read-only, accepts C<(ArrayRef[Object])> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 clear

  clear() : Bool

The clear method clears the collection and returns an empty list.

=over 4

=item clear example #1

  # given: synopsis

  $collection->clear;

=back

=cut

=head2 count

  count() : Int

The count method counts and returns the number of items in the collection.

=over 4

=item count example #1

  # given: synopsis

  $collection->count;

=back

=cut

=head2 each

  each(CodeRef $value) : ArrayRef[Any]

The each method iterates through the collection executing the callback for each
item and returns the set of results.

=over 4

=item each example #1

  # given: synopsis

  $collection->each(sub {
    my ($item) = shift;

    $item
  });

=back

=cut

=head2 first

  first() : Maybe[Object]

The first method returns the first item in the collection.

=over 4

=item first example #1

  # given: synopsis

  $collection->first;

=back

=cut

=head2 last

  last() : Maybe[Object]

The last method returns the last item in the collection.

=over 4

=item last example #1

  # given: synopsis

  $collection->last;

=back

=cut

=head2 list

  list() : ArrayRef

The list method returns the collection as a list of items.

=over 4

=item list example #1

  # given: synopsis

  $collection->list;

=back

=cut

=head2 pop

  pop() : Maybe[Object]

The pop method removes and returns an item from the tail of the collection.

=over 4

=item pop example #1

  # given: synopsis

  $collection->pop;

=back

=cut

=head2 pull

  pull() : Maybe[Object]

The pull method removes and returns an item from the head of the collection.

=over 4

=item pull example #1

  # given: synopsis

  $collection->pull;

=back

=cut

=head2 push

  push(Object @values) : Int

The push method inserts an item onto the tail of the collection and returns the
count.

=over 4

=item push example #1

  # given: synopsis

  $collection->push(bless {});

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/sql-engine/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/sql-engine/wiki>

L<Project|https://github.com/iamalnewkirk/sql-engine>

L<Initiatives|https://github.com/iamalnewkirk/sql-engine/projects>

L<Milestones|https://github.com/iamalnewkirk/sql-engine/milestones>

L<Contributing|https://github.com/iamalnewkirk/sql-engine/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/sql-engine/issues>

=cut