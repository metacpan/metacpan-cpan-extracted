package Stencil::Error;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Data::Object::Exception';

our $VERSION = '0.03'; # VERSION

# BUILD

fun on_space_locate(Str $class, Object $self) {
  my $name = $self->name;

  $class->new({
    id => 'on_space_locate',
    message => qq(Unable to locate space for "$name"),
    context => $self,
  });
}

fun on_source_load(Str $class, Object $self, Object $match) {
  my $name = $match->package;

  $class->new({
    id => 'on_source_load',
    message => qq(Unable to load space for "$name"),
    context => $self,
  });
}

fun on_source_test(Str $class, Object $self, Object $match) {
  my $name = $match->package;

  $class->new({
    id => 'on_source_test',
    message => qq(Package "$name" does not inherit from "Stencil::Source"),
    context => $self,
  });
}

fun on_source_data(Str $class, Object $self, Object $match) {
  my $name = $match->package;

  $class->new({
    id => 'on_source_data',
    message => qq(Unable to load __DATA__ from "$name"),
    context => $self,
  });
}

fun on_source_section(Str $class, Object $self, Object $match, Str $ref) {
  my $name = $match->package;

  $class->new({
    id => 'on_source_section',
    message => qq(Unable to find "$ref" within the __DATA__ section of "$name"),
    context => $self,
  });
}

1;

=encoding utf8

=head1 NAME

Stencil::Error

=cut

=head1 ABSTRACT

Represents a Stencil exception

=cut

=head1 SYNOPSIS

  use Stencil::Data;
  use Stencil::Error;
  use Stencil::Repo;
  use Stencil::Space;

  my $repo = Stencil::Repo->new;
  my $error = Stencil::Error->new;
  my $data = Stencil::Data->new(repo => $repo, name => 'foo');
  my $space = Stencil::Space->new(repo => $repo, name => 'test');

=cut

=head1 DESCRIPTION

This package provides an error class which represents a Stencil exception.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Data::Object::Exception>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 FUNCTIONS

This package implements the following functions:

=cut

=head2 on_source_data

  on_source_data(Str $class, Object $self, Object $match) : Object

The on_source_data method returns an exception object for sources without
C<__DATA__> sections.

=over 4

=item on_source_data example #1

  # given: synopsis

  my $result = Stencil::Error->on_source_data($space, $space->locate);

  # $result->id
  # $result->message
  # $result->context

=back

=cut

=head2 on_source_load

  on_source_load(Str $class, Object $self, Object $match) : Object

The on_source_load method returns an exception object for unloadable sources.

=over 4

=item on_source_load example #1

  # given: synopsis

  my $result = Stencil::Error->on_source_load($space, $space->locate);

  # $result->id
  # $result->message
  # $result->context

=back

=cut

=head2 on_source_section

  on_source_section(Str $class, Object $self, Object $match, Str $ref) : Object

The on_source_section method returns an exception object for sources without a
requested template.

=over 4

=item on_source_section example #1

  # given: synopsis

  my $result = Stencil::Error->on_source_section($space, $space->locate, 'setup');

  # $result->id
  # $result->message
  # $result->context

=back

=cut

=head2 on_source_test

  on_source_test(Str $class, Object $self, Object $match) : Object

The on_source_test method returns an exception object for sources with broken
interfaces.

=over 4

=item on_source_test example #1

  # given: synopsis

  my $result = Stencil::Error->on_source_test($space, $space->locate);

  # $result->id
  # $result->message
  # $result->context

=back

=cut

=head2 on_space_locate

  on_space_locate(Str $class, Object $self) : Object

The on_space_locate method returns an exception object for unlocatable spaces.

=over 4

=item on_space_locate example #1

  # given: synopsis

  my $result = Stencil::Error->on_space_locate($space);

  # $result->id
  # $result->message
  # $result->context

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
