package Test::DB;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;

our $VERSION = '0.07'; # VERSION

# METHODS

method build(Str :$database = $ENV{TESTDB_DATABASE}, Str %options) {
  if (lc($database) eq 'mssql') {
    require Test::DB::Mssql; return Test::DB::Mssql->new(%options);
  }
  elsif (lc($database) eq 'mysql') {
    require Test::DB::Mysql; return Test::DB::Mysql->new(%options);
  }
  elsif (lc($database) eq 'postgres') {
    require Test::DB::Postgres; return Test::DB::Postgres->new(%options);
  }
  elsif (lc($database) eq 'sqlite') {
    require Test::DB::Sqlite; return Test::DB::Sqlite->new(%options);
  }
  else {
    return undef;
  }
}

method create(Str :$database = $ENV{TESTDB_DATABASE}, Str %options) {
  if (my $generator = $self->build(%options, database => $database)) {
    return $generator->create;
  }
  else {
    return undef;
  }
}

method clone(Str :$database = $ENV{TESTDB_DATABASE}, Str %options) {
  if (my $generator = $self->build(%options, database => $database)) {
    return $generator->clone;
  }
  else {
    return undef;
  }
}

method mssql(Str %options) {
  return $self->build(%options, database => 'mssql');
}

method mysql(Str %options) {
  return $self->build(%options, database => 'mysql');
}

method postgres(Str %options) {
  return $self->build(%options, database => 'postgres');
}

method sqlite(Str %options) {
  return $self->build(%options, database => 'sqlite');
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
test-specific databases owned by the user specified. B<Note:> Test databases
are not automatically destroyed and should be cleaned up manually by call the
C<destroy> method on the database-specific test database object.

=head2 process

B<on create, clone>

=over 4

=item #1

Establish a connection to the DB using some "initial" database.

  my $tdbo = $tdb->postgres(initial => 'template0');

=item #2

Using the established connection, create the test/temporary database.

  $tdbo->create;

=item #3

Establish a connection to the newly created test/temporary database.

  $tdbo->create->dbh;

=item #4

Make the test database object immutable.

  $tdbo->create->database('example'); # error

=back

B<on destroy>

=over 4

=item #1

Establish a connection to the DB using the "initial" database.

  # using the created test/temporary database object

=item #2

Using the established connection, drop the test/temporary database.

  $tdbo->destroy;

=back

=head2 usages

B<using DBI>

=over 4

=item #1

  my $tdb = Test::DB->new;
  my $dbh = $tdb->sqlite(%options)->dbh;

=back

B<using DBIx::Class>

=over 4

=item #1

  my $tdb = Test::DB->new;
  my $tdbo = $tdb->postgres(%options)->create;
  my $schema = DBIx::Class::Schema->connect(
    dsn => $tdbo->dsn,
    username => $tdbo->username,
    password => $tdbo->password,
  );

=back

B<using Mojo::mysql>

=over 4

=item #1

  my $tdb = Test::DB->new;
  my $tdbo = $tdb->mysql(%options)->create;
  my $mysql = Mojo::mysql->new($tdbo->uri);

=back

B<using Mojo::Pg>

=over 4

=item #1

  my $tdb = Test::DB->new;
  my $tdbo = $tdb->postgres(%options)->create;
  my $postgres = Mojo::Pg->new($tdbo->uri);

=back

B<using Mojo::Pg (with cloning)>

=over 4

=item #1

  my $tdb = Test::DB->new;
  my $tdbo = $tdb->postgres(%options)->clone('template0');
  my $postgres = Mojo::Pg->new($tdbo->uri);

=back

B<using Mojo::SQLite>

=over 4

=item #1

  my $tdb = Test::DB->new;
  my $tdbo = $tdb->sqlite(%options)->create;
  my $sqlite = Mojo::SQLite->new($tdbo->uri);

=back

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

=head2 mssql

  mssql(Str %options) : Maybe[InstanceOf["Test::DB::Object"]]

The mssql method builds and returns a L<Test::DB::Mssql> object.

=over 4

=item mssql example #1

  # given: synopsis

  $tdb->mssql;

=back

=cut

=head2 mysql

  mysql(Str %options) : Maybe[InstanceOf["Test::DB::Object"]]

The mysql method builds and returns a L<Test::DB::Mysql> object.

=over 4

=item mysql example #1

  # given: synopsis

  $tdb->mysql;

=back

=cut

=head2 postgres

  postgres(Str %options) : Maybe[InstanceOf["Test::DB::Object"]]

The postgres method builds and returns a L<Test::DB::Postgres> object.

=over 4

=item postgres example #1

  # given: synopsis

  $tdb->postgres;

=back

=cut

=head2 sqlite

  sqlite(Str %options) : Maybe[InstanceOf["Test::DB::Object"]]

The sqlite method builds and returns a L<Test::DB::Sqlite> object.

=over 4

=item sqlite example #1

  # given: synopsis

  $tdb->sqlite;

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
