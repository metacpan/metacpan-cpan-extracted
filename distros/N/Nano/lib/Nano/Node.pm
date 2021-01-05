package Nano::Node;

use 5.014;

use strict;
use warnings;

use registry 'Nano::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

our $VERSION = '0.05'; # VERSION

# ATTRIBUTES

has id => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_id($self) {
  require Zing::ID; Zing::ID->new->string
}

has nano => (
  is => 'ro',
  isa => 'Nano',
  new => 1,
);

fun new_nano($self) {
  require Nano; Nano->new
}

# METHODS

method drop() {
  my $keyval = $self->nano->keyval($self->id);
  $keyval->drop;
  return $self;
}

method load() {
  return $self->nano->find($self->id);
}

method save() {
  my $serial = $self->serialize;
  my $keyval = $self->nano->keyval($self->id);
  $keyval->send($serial);
  return $keyval->term;
}

method serialize() {
  $self->id;
  {
    '$name' => $self->nano->name($self),
    '$data' => $self->nano->dump($self),
    '$type' => 'node',
  }
}

1;

=encoding utf8

=head1 NAME

Nano::Node - Persistable Entity

=cut

=head1 ABSTRACT

Persistable Entity Super Class

=cut

=head1 SYNOPSIS

  use Nano::Node;

  my $node = Nano::Node->new(
    id => '0000001',
  );

  # $node->save;

=cut

=head1 DESCRIPTION

This package provides a persistable entity super class. It is meant to be
subclassed but can be used directly as well.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Nano::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 id

  id(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 nano

  nano(Nano)

This attribute is read-only, accepts C<(Nano)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 drop

  drop() : Object

The drop method removes the prior persisted object data.

=over 4

=item drop example #1

  # given: synopsis

  $node = $node->drop;

=back

=cut

=head2 load

  load() : Object

The load method reloads and returns an object from source.

=over 4

=item load example #1

  # given: synopsis

  $node->save;

  $node = $node->load;

=back

=cut

=head2 save

  save() : Str

The save method commits the object data to the storage backend.

=over 4

=item save example #1

  # given: synopsis

  my $term = $node->save;

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

  my $serial = $node->serialize;

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