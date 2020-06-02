package Stencil::Repo;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

use Path::Tiny ();

our $VERSION = '0.03'; # VERSION

# ATTRIBUTES

has base => (
  is => 'ro',
  isa => 'Str',
  def => $ENV{STENCIL_HOME} || '.'
);

has path => (
  is => 'ro',
  isa => 'Object',
  new => 1
);

fun new_path($self) {
  Path::Tiny->new($self->base)->absolute;
}

# METHODS

method store(@parts) {
  $self->path->child('.stencil', @parts);
}

1;

=encoding utf8

=head1 NAME

Stencil::Repo

=cut

=head1 ABSTRACT

Represents a Stencil workspace

=cut

=head1 SYNOPSIS

  use Stencil::Repo;

  my $repo = Stencil::Repo->new;

=cut

=head1 DESCRIPTION

This package provides a repo class which represents a Stencil workspace.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 base

  base(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 path

  path(Object)

This attribute is read-only, accepts C<(Object)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 store

  store(Str @parts) : InstanceOf["Path::Tiny"]

The store method returns a L<Path::Tiny> object representing a file or
directory in the stencil workspace.

=over 4

=item store example #1

  # given: synopsis

  $repo->store;

=back

=over 4

=item store example #2

  # given: synopsis

  $repo->store('logs');

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
