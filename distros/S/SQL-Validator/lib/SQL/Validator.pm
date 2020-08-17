package SQL::Validator;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;
use JSON::Validator;

our $VERSION = '0.02'; # VERSION

our $GITHUB_SOURCE = 'iamalnewkirk/json-sql';

# ATTRIBUTES

has schema => (
  is  => 'ro',
  isa => 'Any',
  new => 1
);

fun new_schema($self) {
  my $version = $self->version;
  my $specification = "schemas/$version/rulesets.yaml";
  $ENV{SQL_VALIDATOR_SCHEMA}
    || "https://raw.githubusercontent.com/$GITHUB_SOURCE/master/$specification"
}

has validator => (
  is  => 'ro',
  isa => 'InstanceOf["JSON::Validator"]',
  new => 1
);

fun new_validator($self) {
  local $ENV{JSON_VALIDATOR_CACHE_ANYWAYS} = 1
    unless exists $ENV{JSON_VALIDATOR_CACHE_ANYWAYS};
  JSON::Validator->new
}

has version => (
  is  => 'ro',
  isa => 'Str',
  def => '0.0'
);

# METHODS

method error() {

  return $self->{error};
}

method validate(HashRef $schema) {
  my $validator = $self->validator;

  $validator->coerce('booleans');
  $validator->schema($self->schema);

  my @issues = $validator->validate($schema);

  if (@issues) {
    require SQL::Validator::Error;

    $self->{error} = SQL::Validator::Error->new(
      context => $self,
      issues => [@issues]
    );
  }
  else {
    delete $self->{error};
  }

  return !@issues ? 1 : 0;
}

1;
=encoding utf8

=head1 NAME

SQL::Validator - Validate JSON-SQL

=cut

=head1 ABSTRACT

Validate JSON-SQL Schemas

=cut

=head1 SYNOPSIS

  use SQL::Validator;

  my $sql = SQL::Validator->new;

  # my $valid = $sql->validate({
  #   insert => {
  #     into => {
  #       table => 'users'
  #     },
  #     default => 1
  #   }
  # });

  # i.e. represents (INSERT INTO "users" DEFAULT VALUES)

  # die $sql->error if !$valid;

  # $sql->error->report('insert');

=cut

=head1 DESCRIPTION

This package provides a
L<json-sql|https://github.com/iamalnewkirk/json-sql#readme> data structure
validation library based on the JSON-SQL L<json-schema|https://json-schema.org>
standard.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 schema

  schema(Any)

This attribute is read-only, accepts C<(Any)> values, and is optional.

=cut

=head2 validator

  validator(InstanceOf["JSON::Validator"])

This attribute is read-only, accepts C<(InstanceOf["JSON::Validator"])> values, and is optional.

=cut

=head2 version

  version(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 error

  error() : InstanceOf["SQL::Validator::Error"]

The error method validates the JSON-SQL schema provided.

=over 4

=item error example #1

  # given: synopsis

  $sql->validate({select => {}});

  my $error = $sql->error;

=back

=over 4

=item error example #2

  # given: synopsis

  $sql->validate({select => { from => { table => 'users' } } });

  my $error = $sql->error;

=back

=cut

=head2 validate

  validate(HashRef $schema) : Bool

The validate method validates the JSON-SQL schema provided.

=over 4

=item validate example #1

  # given: synopsis

  my $valid = $sql->validate({
    insert => {
      into => {
        table => 'users'
      },
      default => 1
    }
  });

  # VALID

=back

=over 4

=item validate example #2

  # given: synopsis

  my $valid = $sql->validate({
    insert => {
      into => {
        table => 'users'
      },
      default => 'true' # coerced booleans
    }
  });

  # VALID

=back

=over 4

=item validate example #3

  # given: synopsis

  my $valid = $sql->validate({
    insert => {
      into => 'users',
      values => [1, 2, 3]
    }
  });

  # INVALID

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/sql-validator/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/sql-validator/wiki>

L<Project|https://github.com/iamalnewkirk/sql-validator>

L<Initiatives|https://github.com/iamalnewkirk/sql-validator/projects>

L<Milestones|https://github.com/iamalnewkirk/sql-validator/milestones>

L<Contributing|https://github.com/iamalnewkirk/sql-validator/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/sql-validator/issues>

=cut