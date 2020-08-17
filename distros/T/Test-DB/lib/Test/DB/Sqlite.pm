package Test::DB::Sqlite;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Test::DB::Object';

with 'Data::Object::Role::Buildable';
with 'Data::Object::Role::Immutable';
with 'Data::Object::Role::Stashable';

use DBI;
use File::Copy ();
use File::Spec ();
use File::Temp ();

our $VERSION = '0.06'; # VERSION

# ATTRIBUTES

has 'dbh' => (
  is => 'ro',
  isa => 'Object',
  new => 1,
);

fun new_dbh($self) {
  DBI->connect($self->dsn, '', '', { RaiseError => 1, AutoCommit => 1 })
}

has 'dsn' => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_dsn($self) {
  "dbi:SQLite:dbname=@{[$self->file]}"
}

has 'file' => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_file($self) {
  File::Spec->catfile(File::Temp::tempdir, "@{[$self->database]}.db")
}

# METHODS

method clone(Str $source) {
  File::Copy::copy($source, $self->file);

  return $self->create;
}

method create() {
  my $dbh = $self->dbh;

  $self->immutable;

  return $self;
}

method destroy() {
  my $file = $self->file;

  unlink $file;

  return $self;
}

1;

=encoding utf8

=head1 NAME

Test::DB::Sqlite - Temporary Testing Databases for Sqlite

=cut

=head1 ABSTRACT

Temporary Sqlite Database for Testing

=cut

=head1 SYNOPSIS

  package main;

  use Test::DB::Sqlite;

  my $tdbo = Test::DB::Sqlite->new;

  # my $dbh = $tdbo->create->dbh;

=cut

=head1 DESCRIPTION

This package provides methods for generating and destroying Sqlite databases
for testing purposes.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Test::DB::Object>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Data::Object::Role::Buildable>

L<Data::Object::Role::Immutable>

L<Data::Object::Role::Stashable>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 database

  database(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 dbh

  dbh(Object)

This attribute is read-only, accepts C<(Object)> values, and is optional.

=cut

=head2 dsn

  dsn(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 file

  file(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 clone

  clone(Str $source) : Object

The clone method creates a temporary database from a database template.

=over 4

=item clone example #1

  # given: synopsis

  $tdbo->clone('source.db');

  # <Test::DB::Sqlite>

=back

=cut

=head2 create

  create() : Object

The create method creates a temporary database and returns the invocant.

=over 4

=item create example #1

  # given: synopsis

  $tdbo->create;

  # <Test::DB::Sqlite>

=back

=cut

=head2 destroy

  destroy() : Object

The destroy method destroys (drops) the database and returns the invocant.

=over 4

=item destroy example #1

  # given: synopsis

  $tdbo->create;
  $tdbo->destroy;

  # <Test::DB::Sqlite>

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/test-db/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/test-db/wiki>

L<Project|https://github.com/iamalnewkirk/test-db>

L<Initiatives|https://github.com/iamalnewkirk/test-db/projects>

L<Milestones|https://github.com/iamalnewkirk/test-db/milestones>

L<Contributing|https://github.com/iamalnewkirk/test-db/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/test-db/issues>

=cut
