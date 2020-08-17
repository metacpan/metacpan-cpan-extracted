package SQL::Engine::Operation;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

our $VERSION = '0.03'; # VERSION

# ATTRIBUTES

has bindings => (
  is => 'ro',
  isa => 'HashRef',
  req => 1
);

has statement => (
  is => 'ro',
  isa => 'Str',
  req => 1
);

# METHODS

method parameters(Maybe[HashRef] $values) {
  my $bindings = $self->bindings;
  my @binddata = map $values->{$bindings->{$_}}, sort(keys(%$bindings));

  return wantarray ? (@binddata) : [@binddata];
}

1;

=encoding utf8

=head1 NAME

SQL::Engine::Operation - SQL Operation

=cut

=head1 ABSTRACT

SQL Statement Operation

=cut

=head1 SYNOPSIS

  use SQL::Engine::Operation;

  my $operation = SQL::Engine::Operation->new(
    statement => 'SELECT * FROM "tasks" WHERE "reporter" = ? AND "assigned" = ?',
    bindings => {
      0 => 'user_id',
      1 => 'user_id'
    }
  );

  # my @bindings = $operation->parameters({
  #   user_id => 123
  # });

=cut

=head1 DESCRIPTION

This package provides SQL Statement Operation.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 bindings

  bindings(HashRef)

This attribute is read-only, accepts C<(HashRef)> values, and is required.

=cut

=head2 statement

  statement(Str)

This attribute is read-only, accepts C<(Str)> values, and is required.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 parameters

  parameters(Maybe[HashRef] $values) : ArrayRef

The parameters method returns positional bind values for use with statement
handlers.

=over 4

=item parameters example #1

  # given: synopsis

  my $bindings = $operation->parameters({
    user_id => 123
  });

  # [123, 123]

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