package Nano::Search;

use 5.014;

use strict;
use warnings;

use registry 'Nano::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

our $VERSION = '0.04'; # VERSION

# ATTRIBUTES

has table => (
  is => 'ro',
  isa => 'Table',
  new => 1,
);

fun new_table($self) {
  $self->nodes->nano->table($self->nodes->id)
}

has nodes => (
  is => 'ro',
  isa => 'Nodes',
  req => 1,
);

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

# METHODS

method all() {
  $self->fetch($self->table->count)
}

method count() {
  @{$self->scopes} ? scalar(@{$self->all}) : $self->table->count
}

method fetch(Int $size = 1) {
  my $i = 0;
  my $nano = $self->nodes->nano;
  my $results = [];
  if (!$size) {
    return $results;
  }
  $self->reset;
  while (my $keyval = $self->table->next) {
    if (my $result = $self->scope($nano->object($keyval->recv))) {
      $i = push @$results, $result;
    }
    if ($i >= $size) {
      last;
    }
  }
  return $self->order($results);
}

method first() {
  my $results;
  my $nano = $self->nodes->nano;
  $self->table->position(undef);
  if (@{$self->orders}) {
    $results = $self->all->[0];
  }
  else {
    $self->reset;
    while (my $keyval = $self->table->next) {
      if (my $result = $self->scope($nano->object($keyval->recv))) {
        $results = $result;
        last;
      }
    }
  }
  return $results;
}

method last() {
  my $results;
  my $nano = $self->nodes->nano;
  $self->table->position($self->table->size);
  if (@{$self->orders}) {
    $results = $self->all->[-1];
  }
  else {
    $self->table->position($self->table->size);
    while (my $keyval = $self->table->prev) {
      if (my $result = $self->scope($nano->object($keyval->recv))) {
        $results = $result;
        last;
      }
    }
  }
  return $results;
}

method next() {
  my $results = [];
  my $nano = $self->nodes->nano;
  if (@{$self->orders}) {
    my $skip = 1;
    for my $item (@{$self->all}) {
      if (defined $self->{last_next}) {
        if ($self->{last_next} == $item->id) {
          $skip = 0;
        }
        next if $skip;
      }
      push @$results, $item;
      $self->{last_next} = $item->id;
      last;
    }
  }
  else {
    while (my $keyval = $self->table->next) {
      if (my $result = $self->scope($nano->object($keyval->recv))) {
        push @$results, $result;
        last;
      }
    }
  }
  return $results->[0];
}

method order(ArrayRef $result) {
  if (@{$self->orders}) {
    for my $order (@{$self->orders}) {
      $result = [sort {$order->($a,$b)} @$result];
    }
    return $result;
  }
  else {
    return $result;
  }
}

method prev() {
  my $results = [];
  my $nano = $self->nodes->nano;
  if (@{$self->orders}) {
    my $skip = 1;
    for my $item (reverse(@{$self->all})) {
      if (defined $self->{last_prev}) {
        if ($self->{last_prev} == $item->id) {
          $skip = 0;
        }
        next if $skip;
      }
      push @$results, $item;
      $self->{last_prev} = $item->id;
      last;
    }
  }
  else {
    while (my $keyval = $self->table->prev) {
      if (my $result = $self->scope($nano->object($keyval->recv))) {
        push @$results, $result;
        last;
      }
    }
  }
  return $results->[0];
}

method reset() {
  $self->table->reset;
  return $self;
}

method scope(Object $object) {
  if (@{$self->scopes}) {
    return (grep {!$_->($object)} @{$self->scopes}) ? undef : $object;
  }
  else {
    return $object;
  }
}

1;

=encoding utf8

=head1 NAME

Nano::Search - Persisted Index Search

=cut

=head1 ABSTRACT

Persisted Index Search

=cut

=head1 SYNOPSIS

  use Nano::Nodes;
  use Nano::Search;

  my $nodes = Nano::Nodes->new(
    type => 'Nano::Node',
  );

  my $search = Nano::Search->new(
    nodes => $nodes,
  );

  # $search->count;

=cut

=head1 DESCRIPTION

This package provides a mechanism for searching a prior persisted index.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Nano::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 nodes

  nodes(Nodes)

This attribute is read-only, accepts C<(Nodes)> values, and is required.

=cut

=head2 orders

  orders(ArrayRef[CodeRef])

This attribute is read-only, accepts C<(ArrayRef[CodeRef])> values, and is optional.

=cut

=head2 scopes

  scopes(ArrayRef[CodeRef])

This attribute is read-only, accepts C<(ArrayRef[CodeRef])> values, and is optional.

=cut

=head2 table

  table(Table)

This attribute is read-only, accepts C<(Table)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 all

  all() : ArrayRef[Object]

The all method returns all objects (qualified via scopes, when present) from
the index.

=over 4

=item all example #1

  # given: synopsis

  my $result = $search->all;

=back

=over 4

=item all example #2

  # given: synopsis

  use Nano::Node;

  $search->nodes->set(Nano::Node->new);
  $search->nodes->set(Nano::Node->new);

  my $result = $search->all;

=back

=cut

=head2 count

  count() : Int

The count method returns the count of objects (qualified via scopes, when
present) in the index.

=over 4

=item count example #1

  # given: synopsis

  my $count = $search->count;

=back

=over 4

=item count example #2

  # given: synopsis

  use Nano::Node;

  $search->nodes->set(Nano::Node->new);
  $search->nodes->set(Nano::Node->new);

  my $count = $search->count;

=back

=cut

=head2 fetch

  fetch(Int $size = 1) : ArrayRef[Object]

The fetch method returns a variable number of objects (qualified via scopes,
when present) from the index.

=over 4

=item fetch example #1

  # given: synopsis

  my $result = $search->fetch;

=back

=over 4

=item fetch example #2

  # given: synopsis

  use Nano::Node;

  $search->nodes->set(Nano::Node->new);
  $search->nodes->set(Nano::Node->new);

  my $result = $search->fetch;

=back

=over 4

=item fetch example #3

  # given: synopsis

  use Nano::Node;

  $search->nodes->set(Nano::Node->new);
  $search->nodes->set(Nano::Node->new);
  $search->nodes->set(Nano::Node->new);

  my $result = $search->fetch(2);

=back

=cut

=head2 first

  first() : Maybe[Object]

The first method returns the first object (qualified via scopes, when present)
from the index.

=over 4

=item first example #1

  # given: synopsis

  my $first = $search->first;

=back

=over 4

=item first example #2

  # given: synopsis

  use Nano::Node;

  $search->nodes->set(Nano::Node->new(id => '1st'));
  $search->nodes->set(Nano::Node->new(id => '2nd'));
  $search->nodes->set(Nano::Node->new(id => '3rd'));

  my $first = $search->first;

=back

=cut

=head2 last

  last() : Maybe[Object]

The last method returns the last object (qualified via scopes, when present)
from the index.

=over 4

=item last example #1

  # given: synopsis

  my $last = $search->last;

=back

=over 4

=item last example #2

  # given: synopsis

  use Nano::Node;

  $search->nodes->set(Nano::Node->new(id => '1st'));
  $search->nodes->set(Nano::Node->new(id => '2nd'));
  $search->nodes->set(Nano::Node->new(id => '3rd'));

  my $last = $search->last;

=back

=cut

=head2 next

  next() : Maybe[Object]

The next method returns the next object based on the currently held cursor
(qualified via scopes, when present) from the index.

=over 4

=item next example #1

  # given: synopsis

  my $next = $search->next;

=back

=over 4

=item next example #2

  # given: synopsis

  use Nano::Node;

  $search->nodes->set(Nano::Node->new(id => '1st'));
  $search->nodes->set(Nano::Node->new(id => '2nd'));
  $search->nodes->set(Nano::Node->new(id => '3rd'));

  my $next = $search->next;

=back

=over 4

=item next example #3

  # given: synopsis

  use Nano::Node;

  $search->nodes->set(Nano::Node->new(id => '1st'));
  $search->nodes->set(Nano::Node->new(id => '2nd'));
  $search->nodes->set(Nano::Node->new(id => '3rd'));

  my $next;

  $next = $search->next;
  $next = $search->next;

=back

=cut

=head2 order

  order(ArrayRef[Object] $results) : ArrayRef[Object]

The order method determines the sort order of the array of objects provided
based on the registered ordering routines.

=over 4

=item order example #1

  # given: synopsis

  use Nano::Node;

  my $results = [
    Nano::Node->new(id => '1st'),
    Nano::Node->new(id => '2nd'),
    Nano::Node->new(id => '3rd'),
  ];

  $search = Nano::Search->new(
    nodes => $nodes,
    orders => [sub {
      my ($a, $b) = @_;
      $a->id cmp $b->id
    }],
  );

  $results = $search->order($results);

=back

=over 4

=item order example #2

  # given: synopsis

  use Nano::Node;

  my $results = [
    Nano::Node->new(id => '1st'),
    Nano::Node->new(id => '2nd'),
    Nano::Node->new(id => '3rd'),
  ];

  $search = Nano::Search->new(
    nodes => $nodes,
    orders => [sub {
      my ($a, $b) = @_;
      $b->id cmp $a->id
    }],
  );

  $results = $search->order($results);

=back

=cut

=head2 prev

  prev() : Maybe[Object]

The prev method returns the previous object based on the currently held cursor
(qualified via scopes, when present) from the index.

=over 4

=item prev example #1

  # given: synopsis

  my $prev = $search->prev;

=back

=over 4

=item prev example #2

  # given: synopsis

  use Nano::Node;

  $search->table->position(3);

  $search->nodes->set(Nano::Node->new(id => '1st'));
  $search->nodes->set(Nano::Node->new(id => '2nd'));
  $search->nodes->set(Nano::Node->new(id => '3rd'));

  my $prev = $search->prev;

=back

=over 4

=item prev example #3

  # given: synopsis

  use Nano::Node;

  $search->table->position(3);

  $search->nodes->set(Nano::Node->new(id => '1st'));
  $search->nodes->set(Nano::Node->new(id => '2nd'));
  $search->nodes->set(Nano::Node->new(id => '3rd'));

  my $prev;

  $prev = $search->prev;
  $prev = $search->prev;

=back

=cut

=head2 reset

  reset() : Object

The reset method resets the position on the currently held cursor.

=over 4

=item reset example #1

  # given: synopsis

  $search = $search->reset;

=back

=cut

=head2 scope

  scope(Object $object) : Maybe[Object]

The scope method determines whether the object provided passes-through the
registered scopes and if-so returns the object provided.

=over 4

=item scope example #1

  # given: synopsis

  use Nano::Node;

  my $node = Nano::Node->new(id => '0000003');

  my $result = $search->scope($node);

=back

=over 4

=item scope example #2

  # given: synopsis

  use Nano::Node;

  $search = Nano::Search->new(
    nodes => $nodes,
    scopes => [sub {
      my ($node) = @_;
      $node->id ne '0000003'
    }],
  );

  my $node = Nano::Node->new(id => '0000003');

  my $result = $search->scope($node);

=back

=over 4

=item scope example #3

  # given: synopsis

  use Nano::Node;

  $search = Nano::Search->new(
    nodes => $nodes,
    scopes => [sub {
      my ($node) = @_;
      $node->id ne '0000003'
    }],
  );

  my $node = Nano::Node->new(id => '0000004');

  my $result = $search->scope($node);

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