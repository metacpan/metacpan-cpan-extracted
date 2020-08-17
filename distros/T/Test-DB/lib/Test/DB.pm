package Test::DB;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;

our $VERSION = '0.06'; # VERSION

# METHODS

method build(Str :$database = $ENV{TESTDB_DATABASE}, Str %options) {
  delete $options{database};

  if (lc($database) eq 'mssql') {
    require Test::DB::Mssql;

    my $generator = Test::DB::Mssql->new(%options);

    return $generator;
  }
  elsif (lc($database) eq 'mysql') {
    require Test::DB::Mysql;

    my $generator = Test::DB::Mysql->new(%options);

    return $generator;
  }
  elsif (lc($database) eq 'postgres') {
    require Test::DB::Postgres;

    my $generator = Test::DB::Postgres->new(%options);

    return $generator;
  }
  elsif (lc($database) eq 'sqlite') {
    require Test::DB::Sqlite;

    my $generator = Test::DB::Sqlite->new(%options);

    return $generator;
  }
  else {

    return undef;
  }
}

method create(Str :$database = $ENV{TESTDB_DATABASE}, Str %options) {
  my $generator = $self->build(%options);

  if ($generator) {

    return $generator->create;
  }
  else {

    return undef;
  }
}

method clone(Str :$database = $ENV{TESTDB_DATABASE}, Str %options) {
  my $generator = $self->build(%options);

  if ($generator) {

    return $generator->clone;
  }
  else {

    return undef;
  }
}

1;

=encoding utf8

=head1 NAME

Test::DB - Temporary Testing Databases

=cut

=head1 ABSTRACT

Temporary Databases for Testing

=cut

=head1 SYNOPSIS

  use Test::DB;

  my $tdb = Test::DB->new;

  # my $tdbo = $tdb->create(database => 'sqlite');

  # my $dbh = $tdbo->dbh;

=cut

=head1 DESCRIPTION

This package provides a framework for setting up and tearing down temporary
databases for testing purposes. This framework requires a user (optionally with
password) which has the ability to create new databases and works by creating
test-specific databases owned by the user specified.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 clone

  clone(Str :$database, Str %options) : Maybe[InstanceOf["Test::DB::Object"]]

The clone method generates a database based on the type and database template
specified and returns a C<Test::DB::Object> with an active connection, C<dbh>
and C<dsn>. If the database specified doesn't have a corresponding database
driver this method will returned the undefined value. The type of database can
be omitted if the C<TESTDB_DATABASE> environment variable is set, if not the
type of database must be either C<sqlite>, C<mysql>, C<mssql> or C<postgres>.
Any options provided are passed along to the test database object class
constructor.

=over 4

=item clone example #1

  # given: synopsis

  $ENV{TESTDB_DATABASE} = 'postgres';

  $tdb->clone(template => 'template0');

=back

=over 4

=item clone example #2

  # given: synopsis

  $ENV{TESTDB_DATABASE} = 'postgres';
  $ENV{TESTDB_TEMPLATE} = 'template0';

  $tdb->clone;

=back

=over 4

=item clone example #3

  # given: synopsis

  $ENV{TESTDB_TEMPLATE} = 'template0';

  $tdb->clone(database => 'postgres');

=back

=cut

=head2 create

  create(Str :$database, Str %options) : Maybe[InstanceOf["Test::DB::Object"]]

The create method generates a database based on the type specified and returns
a C<Test::DB::Object> with an active connection, C<dbh> and C<dsn>. If the
database specified doesn't have a corresponding database driver this method
will returned the undefined value. The type of database can be omitted if the
C<TESTDB_DATABASE> environment variable is set, if not the type of database
must be either C<sqlite>, C<mysql>, C<mssql> or C<postgres>. Any options
provided are passed along to the test database object class constructor.

=over 4

=item create example #1

  # given: synopsis

  $tdb->create;

=back

=over 4

=item create example #2

  # given: synopsis

  $ENV{TESTDB_DATABASE} = 'sqlite';

  $tdb->create;

=back

=over 4

=item create example #3

  # given: synopsis

  $tdb->create(database => 'sqlite');

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
