package Stencil::Space;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;
use Data::Object::Space;

use Stencil::Error;

our $VERSION = '0.03'; # VERSION

# ATTRIBUTES

has 'name' => (
  is => 'ro',
  isa => 'Str',
  req => 1,
);

has 'local' => (
  is => 'ro',
  isa => 'Object',
  new => 1,
);

fun new_local($self) {
  Data::Object::Space->new(join '/', 'stencil', 'source', $self->name);
}

has 'global' => (
  is => 'ro',
  isa => 'Object',
  new => 1,
);

fun new_global($self) {
  Data::Object::Space->new($self->name);
}

has 'repo' => (
  is => 'ro',
  isa => 'Object',
  new => 1,
);

fun new_repo($self) {
  Stencil::Repo->new;
}

# METHODS

method locate() {
  my %seen;

  local @INC = grep !$seen{$_}++, '.', 'lib', 'local/lib/perl5', @INC;

  my $local = $self->local;

  return $local if $local->locate;

  my $global = $self->global;

  return $global if $global->locate;

  return undef;
}

method source() {
  my $space;

  # locate
  unless ($space = $self->locate) {
    die Stencil::Error->on_space_locate($self);
  }

  # load-source
  unless (do { local $@; eval{ $space->load } }) {
    die Stencil::Error->on_source_load($self, $space);
  }

  # test-interface
  unless ($space->package->isa('Stencil::Source')) {
    die Stencil::Error->on_source_test($self, $space);
  }

  # load-data
  unless ($space->data) {
    die Stencil::Error->on_source_data($self, $space);
  }

  return $space->build(repo => $self->repo);
}

1;

=encoding utf8

=head1 NAME

Stencil::Space

=cut

=head1 ABSTRACT

Represents a generator class

=cut

=head1 SYNOPSIS

  use Stencil::Space;

  my $space = Stencil::Space->new(name => 'test');

  # global: <Test>
  # local:  <Stencil::Source::Test>

  # $space->locate;

=cut

=head1 DESCRIPTION

This package provides namespace class which represents a Stencil generator
class.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 global

  global(Object)

This attribute is read-only, accepts C<(Object)> values, and is optional.

=cut

=head2 local

  local(Object)

This attribute is read-only, accepts C<(Object)> values, and is optional.

=cut

=head2 name

  name(Str)

This attribute is read-only, accepts C<(Str)> values, and is required.

=cut

=head2 repo

  repo(Object)

This attribute is read-only, accepts C<(Object)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 locate

  locate() : Maybe[Object]

The locate method attempts to return one of the L<Data::Object::Space> objects
in the C<local> and C<global> attributes.

=over 4

=item locate example #1

  # given: synopsis

  $space->locate;

=back

=cut

=head2 source

  source() : InstanceOf["Stencil::Source"]

The source method locates, loads, and validates the L<Stencil::Source> derived
source code generator.

=over 4

=item source example #1

  # given: synopsis

  $space->source;

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/stencil/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/stencil/wiki>

L<Project|https://github.com/iamalnewkirk/stencil>

L<Initiatives|https://github.com/iamalnewkirk/stencil/projects>

L<Milestones|https://github.com/iamalnewkirk/stencil/milestones>

L<Contributing|https://github.com/iamalnewkirk/stencil/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/stencil/issues>

=cut
