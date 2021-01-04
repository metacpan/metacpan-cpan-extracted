package Nano::Nodes;

use 5.014;

use strict;
use warnings;

use registry 'Nano::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Nano::Node';

our $VERSION = '0.04'; # VERSION

# ATTRIBUTES

has orders => (
  is => 'ro',
  isa => 'ArrayRef[CodeRef]',
  new => 1,
);

fun new_orders($self) {
  []
}

has scopes => (
  is => 'ro',
  isa => 'ArrayRef[CodeRef]',
  new => 1,
);

fun new_scopes($self) {
  []
}

has type => (
  is => 'ro',
  isa => 'Str',
  new => 1,
  req => 1,
);

fun new_type($self) {
  undef
}

# METHODS

method add(HashRef $data) {
  my $object = $self->nano->reify($self->type, $data);
  my $table = $self->nano->table($self->id);
  my $keyval = $table->set($object->id);
  $keyval->send($object->serialize);
  return $object;
}

method all() {
  return $self->search->all;
}

method count() {
  return $self->search->count;
}

method drop() {
  my $table = $self->nano->table($self->id);
  $table->drop;
  $self->next::method;
  return $self;
}

method first() {
  return $self->search->first;
}

method get(Str $name) {
  my $table = $self->nano->table($self->id);
  my $keyval = $table->get($name) or return undef;
  my $object = $keyval->recv or return undef;
  return $self->nano->object($object);
}

method last() {
  return $self->search->last;
}

method order(CodeRef $callback) {
  my $instance = ref($self)->new(
    %{$self},
    orders => [@{$self->orders}, $callback],
  );
  return $instance;
}

method scope(CodeRef $callback) {
  my $instance = ref($self)->new(
    %{$self},
    scopes => [@{$self->scopes}, $callback],
  );
  return $instance;
}

method search() {
  require Nano::Search; Nano::Search->new(
    orders => $self->orders,
    scopes => $self->scopes,
    nodes => $self,
  );
}

method serialize() {
  $self->id;
  {
    '$name' => $self->nano->name($self),
    '$data' => $self->nano->dump($self),
    '$type' => 'nodes',
  }
}

method set(Node $object) {
  my $table = $self->nano->table($self->id);
  my $keyval = $table->set($object->id);
  $keyval->send($object->serialize);
  return $object;
}

1;

=encoding utf8

=head1 NAME

Nano::Nodes - Persistable Index

=cut

=head1 ABSTRACT

Persistable Index Super Class

=cut

=head1 SYNOPSIS

  use Nano::Nodes;

  my $nodes = Nano::Nodes->new(
    type => 'Nano::Node',
  );

  # $nodes->save;

=cut

=head1 DESCRIPTION

This package provides a persistable index super class. It is meant to be
subclassed but can be used directly as well.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Nano::Node>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Nano::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 orders

  orders(ArrayRef[CodeRef])

This attribute is read-only, accepts C<(ArrayRef[CodeRef])> values, and is optional.

=cut

=head2 scopes

  scopes(ArrayRef[CodeRef])

This attribute is read-only, accepts C<(ArrayRef[CodeRef])> values, and is optional.

=cut

=head2 type

  type(Str)

This attribute is read-only, accepts C<(Str)> values, and is required.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 add

  add(HashRef $data) : Object

The add method creates a new object, adds it to the index, and returns the
created object.

=over 4

=item add example #1

  # given: synopsis

  my $node = $nodes->add({ rand => time });

=back

=cut

=head2 all

  all() : ArrayRef[Object]

The all method proxies to the attached L<Nano::Search> instance and returns the
results.

=over 4

=item all example #1

  # given: synopsis

  my $all = $nodes->all;

=back

=cut

=head2 count

  count() : Int

The count method proxies to the attached L<Nano::Search> instance and returns
the results.

=over 4

=item count example #1

  # given: synopsis

  my $count = $nodes->count;

=back

=cut

=head2 drop

  drop() : Object

The drop method deletes the entire index and all of its indices.

=over 4

=item drop example #1

  # given: synopsis

  $nodes = $nodes->drop;

=back

=cut

=head2 first

  first() : Maybe[Object]

The first method proxies to the attached L<Nano::Search> instance and returns
the result.

=over 4

=item first example #1

  # given: synopsis

  my $first = $nodes->first;

=back

=cut

=head2 get

  get(Str $name) : Maybe[Object]

The get method returns the object (based on ID) from the index (if found).

=over 4

=item get example #1

  # given: synopsis

  my $result = $nodes->get('0000001');

=back

=cut

=head2 last

  last() : Maybe[Object]

The last method proxies to the attached L<Nano::Search> instance and returns
the result.

=over 4

=item last example #1

  # given: synopsis

  my $last = $nodes->last;

=back

=cut

=head2 order

  order(CodeRef $callback) : Object

The order method registers a sort order (search ordering) and returns a new
invocant instance.

=over 4

=item order example #1

  # given: synopsis

  $nodes = $nodes->order(sub {
    my ($a, $b) = @_;

    $a->id cmp $b->id
  });

=back

=cut

=head2 scope

  scope(CodeRef $callback) : Object

The scope method registers a scope (search filter) and returns a new invocant
instance.

=over 4

=item scope example #1

  # given: synopsis

  $nodes = $nodes->scope(sub {
    my ($node) = @_;

    !!$node->{active}
  });

=back

=cut

=head2 search

  search() : Search

The search method returns a L<Nano::Search> object associated with the invocant.

=over 4

=item search example #1

  # given: synopsis

  my $search = $nodes->search;

=back

=cut

=head2 serialize

  serialize() : HashRef

The serialize method returns a persistence representaton of the invocant.
Circular dependencies can result in a deep recursion error, however, circular
dependencies can be persisted if modeled properly. B<Note:> blessed objects
which are neither L<Nano::Node> nor L<Nano::Nodes> will be ignored.

=over 4

=item serialize example #1

  # given: synopsis

  my $serial = $nodes->serialize;

=back

=cut

=head2 set

  set(Node $object) : Object

The set method adds the node object provided to the index and returns the
provided object.

=over 4

=item set example #1

  # given: synopsis

  use Nano::Node;

  my $node = Nano::Node->new(id => '0000003');

  $node = $nodes->set($node);

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/cpanery/nano/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/cpanery/nano/wiki>

L<Project|https://github.com/cpanery/nano>

L<Initiatives|https://github.com/cpanery/nano/projects>

L<Milestones|https://github.com/cpanery/nano/milestones>

L<Contributing|https://github.com/cpanery/nano/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/cpanery/nano/issues>

=cut