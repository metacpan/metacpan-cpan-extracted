package Test::DB::Postgres;

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

our $VERSION = '0.07'; # VERSION

# ATTRIBUTES

has 'dbh' => (
  is => 'ro',
  isa => 'Object',
  new => 1,
);

fun new_dbh($self) {
  DBI->connect($self->dsn, $self->username, $self->password, {
    RaiseError => 1,
    AutoCommit => 1
  })
}

has 'dsn' => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_dsn($self) {
  $self->dsngen($self->database)
}

has 'hostname' => (
  is => 'ro',
  isa => 'Maybe[Str]',
  new => 1,
);

fun new_hostname($self) {
  $ENV{TESTDB_HOSTNAME}
}

has 'hostport' => (
  is => 'ro',
  isa => 'Maybe[Str]',
  new => 1,
);

fun new_hostport($self) {
  $ENV{TESTDB_HOSTPORT}
}

has 'initial' => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_initial($self) {
  $ENV{TESTDB_INITIAL} || 'postgres'
}

has 'uri' => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_uri($self) {
  $self->urigen($self->database)
}

has 'username' => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_username($self) {
  $ENV{TESTDB_USERNAME} || ''
}

has 'password' => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_password($self) {
  $ENV{TESTDB_PASSWORD} || ''
}

# METHODS

method clone(Str $source = $self->template) {
  my $initial = $self->initial;

  my $dbh = DBI->connect($self->dsngen($initial),
    $self->username,
    $self->password,
    {
      RaiseError => 1,
      AutoCommit => 1
    }
  );

  my $sth = $dbh->prepare(qq(CREATE DATABASE "@{[$self->database]}" TEMPLATE "$source"));

  $sth->execute;
  $dbh->disconnect;

  $self->dbh;
  $self->uri;
  $self->immutable;

  return $self;
}

method create() {
  my $initial = $self->initial;

  my $dbh = DBI->connect($self->dsngen($initial),
    $self->username,
    $self->password,
    {
      RaiseError => 1,
      AutoCommit => 1
    }
  );

  my $sth = $dbh->prepare(qq(CREATE DATABASE "@{[$self->database]}"));

  $sth->execute;
  $dbh->disconnect;

  $self->dbh;
  $self->uri;
  $self->immutable;

  return $self;
}

method destroy() {
  my $initial = $self->initial;

  $self->dbh->disconnect if $self->{dbh};

  my $dbh = DBI->connect($self->dsngen($initial),
    $self->username,
    $self->password,
    {
      RaiseError => 1,
      AutoCommit => 1
    }
  );

  my $sth = $dbh->prepare(qq(DROP DATABASE "@{[$self->database]}"));

  $sth->execute;
  $dbh->disconnect;

  return $self;
}

method dsngen(Str $name) {
  join(';', "dbi:Pg:dbname=$name", join ';',
    ($self->hostname ? ("host=@{[$self->hostname]}") : ()),
    ($self->hostport ? ("port=@{[$self->hostport]}") : ()),
  )
}

method urigen(Str $name) {
  join('/', 'postgresql:', ($self->username ? '' : ()), ($self->username ?
    join('@', join(':', $self->username ? ($self->username, ($self->password ? $self->password : ())) : ()),
    $self->hostname ? ($self->hostport ? (join(':', $self->hostname, $self->hostport)) : $self->hostname) : '') : ()),
    $name
  )
}

1;

=encoding utf8

=head1 NAME

Test::DB::Postgres - Temporary Testing Databases for Postgres

=cut

=head1 ABSTRACT

Temporary Postgres Database for Testing

=cut

=head1 SYNOPSIS

  package main;

  use Test::DB::Postgres;

  my $tdbo = Test::DB::Postgres->new;

  # my $dbh = $tdbo->create->dbh;

=cut

=head1 DESCRIPTION

This package provides methods for generating and destroying Postgres databases
for testing purposes. The attributes can be set using their respective
environment variables: C<TESTDB_TEMPLATE>, C<TESTDB_DATABASE>,
C<TESTDB_USERNAME>, C<TESTDB_PASSWORD>, C<TESTDB_HOSTNAME>, and
C<TESTDB_HOSTPORT>.

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

=head2 hostname

  hostname(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 hostport

  hostport(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 password

  password(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 uri

  uri(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 username

  username(Str)

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

  $tdbo->clone('template0');

  # <Test::DB::Postgres>

=back

=cut

=head2 create

  create() : Object

The create method creates a temporary database and returns the invocant.

=over 4

=item create example #1

  # given: synopsis

  $tdbo->create;

  # <Test::DB::Postgres>

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

  # <Test::DB::Postgres>

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
