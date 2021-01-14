use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Test::DB::Mssql

=cut

=tagline

Temporary Testing Databases for Mssql

=cut

=abstract

Temporary Mssql Database for Testing

=cut

=includes

method: clone
method: create
method: destroy

=cut

=synopsis

  package main;

  use Test::DB::Mssql;

  my $tdbo = Test::DB::Mssql->new;

  # my $dbh = $tdbo->create->dbh;

=cut

=libraries

Types::Standard

=cut

=inherits

Test::DB::Object

=cut

=integrates

Data::Object::Role::Buildable
Data::Object::Role::Immutable
Data::Object::Role::Stashable

=cut

=attributes

dbh: ro, opt, Object
dsn: ro, opt, Str
database: ro, opt, Str
hostname: ro, opt, Str
hostport: ro, opt, Str
uri: ro, opt, Str
username: ro, opt, Str
password: ro, opt, Str

=cut

=description

This package provides methods for generating and destroying Mssql databases
for testing purposes. The attributes can be set using their respective
environment variables: C<TESTDB_TEMPLATE>, C<TESTDB_DATABASE>,
C<TESTDB_USERNAME>, C<TESTDB_PASSWORD>, C<TESTDB_HOSTNAME>, and
C<TESTDB_HOSTPORT>.

=cut

=method clone

The clone method creates a temporary database from a database template.

=signature clone

clone(Str $source) : Object

=example-1 clone

  # given: synopsis

  $tdbo->clone('template0');

  # <Test::DB::Mssql>

=cut

=method create

The create method creates a temporary database and returns the invocant.

=signature create

create() : Object

=example-1 create

  # given: synopsis

  $tdbo->create;

  # <Test::DB::Mssql>

=cut

=method destroy

The destroy method destroys (drops) the database and returns the invocant.

=signature destroy

destroy() : Object

=example-1 destroy

  # given: synopsis

  $tdbo->create;
  $tdbo->destroy;

  # <Test::DB::Mssql>

=cut

package main;

SKIP: {
  if (!$ENV{TESTDB_DATABASE} || lc($ENV{TESTDB_DATABASE}) ne 'mssql') {
    skip 'Environment not configured for Mssql testing';
  }

  my $test = testauto(__FILE__);

  my $subs = $test->standard;

  $subs->synopsis(fun($tryable) {
    ok my $result = $tryable->result;

    # create template0 for clone testing
    $result->create->dbh->do('CREATE DATABASE template0');

    $result
  });

  $subs->example(-1, 'clone', 'method', fun($tryable) {
    ok my $result = $tryable->result;
    ok $result->isa('Test::DB::Mssql');
    ok $result->dbh;
    like $result->dsn, qr/dbi:ODBC:DSN=[^;]+;database=testing_db_\d+_\d+_\d+/;

    # destroy template0 after clone testing
    $result->dbh->do('DROP DATABASE template0');

    $result->destroy;

    $result
  });

  $subs->example(-1, 'create', 'method', fun($tryable) {
    ok my $result = $tryable->result;
    ok $result->isa('Test::DB::Mssql');
    ok $result->dbh;
    like $result->dsn, qr/dbi:ODBC:DSN=[^;]+;database=testing_db_\d+_\d+_\d+/;

    $result->destroy;
    $result
  });

  $subs->example(-1, 'destroy', 'method', fun($tryable) {
    ok my $result = $tryable->result;
    ok $result->isa('Test::DB::Mssql');

    $result
  });
}

ok 1 and done_testing;
