package Nano::Stash;

use 5.014;

use strict;
use warnings;

use registry 'Nano::Types';
use routines;

use Data::Object::Role;
use Data::Object::RoleHas;

requires 'nano';

our $VERSION = '0.06'; # VERSION

# ATTRIBUTES

has stashed => (
  is => 'ro',
  isa => 'HashRef',
  new => 1,
);

fun new_stashed($self) {
  {}
}

# METHODS

method get(Str $name) {
  my $id = $self->stashed->{$name};
  return $id ? $self->nano->find($id) : undef;
}

method set(Str $name, Node $node) {
  $self->stashed->{$name} = $node->id;
  return $node;
}

method stash(Str $name, Maybe[Node] $node) {
  return $node ? $self->set($name, $node) : $self->get($name);
}

1;

=encoding utf8

=head1 NAME

Nano::Stash - Stashable Role

=cut

=head1 ABSTRACT

Stashable Entity Role

=cut

=head1 SYNOPSIS

  package Example;

  use Moo;

  extends 'Nano::Node';

  with 'Nano::Stash';

  sub bestie {
    my ($self, @args) = @_;
    return $self->stash('bestie', @args);
  }

  package main;

  my $example = Example->new;

  # $example->bestie($example);

=cut

=head1 DESCRIPTION

This package provides an entity-stashing role, useful for the ad-hoc persisting
of L<Nano::Node> entities. This role also makes it possible to save/load
circularly dependent entities.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Nano::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 stashed

  stashed(HashRef)

This attribute is read-only, accepts C<(HashRef)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 get

  get(Str $name) : Maybe[Node]

The get method finds and loads a previously stashed L<Nano::Node> entity.

=over 4

=item get example #1

  my $example = Example->new;

  my $bestie = $example->get('bestie');

=back

=over 4

=item get example #2

  my $example = Example->new;

  $example->bestie($example);
  $example->save;

  my $bestie = $example->get('bestie');

=back

=cut

=head2 set

  set(Str $name, Node $node) : Node

The set method stashes the L<Nano::Node> entity provided by name. This does not
save the subject or invocant.

=over 4

=item set example #1

  my $example = Example->new;

  my $bestie = $example->set('bestie', $example);

=back

=cut

=head2 stash

  stash(Str $name, Maybe[Node] $node) : Maybe[Node]

The stash method will L</get> or L</set> a stashed L<Nano::Node> entity based
on the arguments provided.

=over 4

=item stash example #1

  my $example = Example->new;

  my $bestie = $example->stash('bestie');

=back

=over 4

=item stash example #2

  my $example = Example->new;

  $example->bestie($example);
  $example->save;

  my $bestie = $example->stash('bestie');

=back

=over 4

=item stash example #3

  my $example = Example->new;

  my $bestie = $example->stash('bestie', $example);

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