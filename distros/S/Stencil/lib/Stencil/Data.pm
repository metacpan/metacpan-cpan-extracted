package Stencil::Data;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

our $VERSION = '0.03'; # VERSION

# ATTRIBUTES

has 'name' => (
  is => 'ro',
  isa => 'Str',
  req => 1
);

has 'repo' => (
  is => 'ro',
  isa => 'Object',
  req => 1,
);

has 'file' => (
  is => 'ro',
  isa => 'Object',
  new => 1
);

fun new_file($self) {
  $self->repo->store(join '.', $self->name, 'yaml');
}

# METHODS

method read() {
  require YAML::PP;

  my $yaml = YAML::PP->new;

  $yaml->load_file($self->file);
}

method write($data) {
  require YAML::PP;

  my $yaml = YAML::PP->new;

  $yaml->dump_file($self->file, $data);
}

1;

=encoding utf8

=head1 NAME

Stencil::Data

=cut

=head1 ABSTRACT

Represents the generator specification

=cut

=head1 SYNOPSIS

  use Stencil::Repo;
  use Stencil::Data;

  my $repo = Stencil::Repo->new;

  $repo->store->mkpath;

  my $spec = Stencil::Data->new(name => 'foo', repo => $repo);

  # $spec->read;
  # $spec->write($data);

=cut

=head1 DESCRIPTION

This package provides a spec class which represents the generator
specification.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 file

  file(Object)

This attribute is read-only, accepts C<(Object)> values, and is optional.

=cut

=head2 name

  name(Str)

This attribute is read-only, accepts C<(Str)> values, and is required.

=cut

=head2 repo

  repo(Object)

This attribute is read-only, accepts C<(Object)> values, and is required.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 read

  read() : HashRef

The read method reads the generator specification (yaml) file and returns the
data.

=over 4

=item read example #1

  # given: synopsis

  $spec->read($spec->write({ name => 'gen' }));

=back

=cut

=head2 write

  write(HashRef $data) : InstanceOf["Path::Tiny"]

The write method write the generator specification (yaml) file and returns the
file written.

=over 4

=item write example #1

  # given: synopsis

  $spec->write($spec->read);

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
