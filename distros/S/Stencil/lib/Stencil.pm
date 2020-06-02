package Stencil;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

our $VERSION = '0.03'; # VERSION

# ATTRIBUTES

has 'repo' => (
  is => 'ro',
  isa => 'Object',
  req => 1,
);

has 'space' => (
  is => 'ro',
  isa => 'Maybe[Object]',
  req => 1,
);

has 'spec' => (
  is => 'ro',
  isa => 'Maybe[Object]',
  req => 1,
);

# METHODS

method init() {
  my $store = $self->repo->store;

  $store->child('logs')->mkpath unless -d $store;

  return $self;
}

method seed() {
  my $data = $self->space->source->template('spec');

  $self->spec->file->spew($data);

  return $self;
}

method make() {
  my $files;

  my $data = $self->spec->read;

  for my $op (@{$data->{operations}}) {
    push @$files, $self->space->source->make($op, $data);
  }

  return $files;
}

1;

=encoding utf8

=head1 NAME

Stencil - Code Generation

=cut

=head1 ABSTRACT

Code Generation Tool for Perl 5

=cut

=head1 SYNOPSIS

  use Stencil;
  use Stencil::Repo;
  use Stencil::Space;
  use Stencil::Data;

  my $repo = Stencil::Repo->new;
  my $space = Stencil::Space->new(name => 'test', repo => $repo);
  my $spec = Stencil::Data->new(name => 'foo', repo => $repo);
  my $stencil = Stencil->new(repo  => $repo, space => $space, spec  => $spec);

  # $stencil->init;
  # $stencil->seed;
  # $stencil->make;

=cut

=head1 DESCRIPTION

This package provides a framework for generating source code, and methods for
rapidly generating one or more files from a single, human readable
specification. See the L<stencil> command-line tool for additional usage
details.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 repo

  repo(Object)

This attribute is read-only, accepts C<(Object)> values, and is required.

=cut

=head2 space

  space(Maybe[Object])

This attribute is read-only, accepts C<(Maybe[Object])> values, and is required.

=cut

=head2 spec

  spec(Maybe[Object])

This attribute is read-only, accepts C<(Maybe[Object])> values, and is required.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 init

  init() : Object

The init method initialize the stencil store and logs.

=over 4

=item init example #1

  # given: synopsis

  $stencil->init;

=back

=cut

=head2 make

  make() : ArrayRef[Object]

The make method generate source code from the generator specification (yaml) file.

=over 4

=item make example #1

  # given: synopsis

  $stencil->seed;
  $stencil->make;

=back

=cut

=head2 seed

  seed() : Object

The seed method creates the generator specification (yaml) file.

=over 4

=item seed example #1

  # given: synopsis

  $stencil->seed;

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
