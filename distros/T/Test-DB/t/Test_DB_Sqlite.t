use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Test::DB::Sqlite

=cut

=tagline

Temporary Testing Databases for Sqlite

=cut

=abstract

Temporary Sqlite Database for Testing

=cut

=includes

method: clone
method: create
method: destroy

=cut

=synopsis

  package main;

  use Test::DB::Sqlite;

  my $tdbo = Test::DB::Sqlite->new;

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
file: ro, opt, Str
uri: ro, opt, Str

=cut

=description

This package provides methods for generating and destroying Sqlite databases
for testing purposes.

=cut

=method clone

The clone method creates a temporary database from a database template.

=signature clone

clone(Str $source) : Object

=example-1 clone

  # given: synopsis

  $tdbo->clone('source.db');

  # <Test::DB::Sqlite>

=cut

=method create

The create method creates a temporary database and returns the invocant.

=signature create

create() : Object

=example-1 create

  # given: synopsis

  $tdbo->create;

  # <Test::DB::Sqlite>

=cut

=method destroy

The destroy method destroys (drops) the database and returns the invocant.

=signature destroy

destroy() : Object

=example-1 destroy

  # given: synopsis

  $tdbo->create;
  $tdbo->destroy;

  # <Test::DB::Sqlite>

=cut

package main;

SKIP: {
  if (!$ENV{TESTDB_DATABASE} || lc($ENV{TESTDB_DATABASE}) ne 'sqlite') {
    skip 'Environment not configured for Sqlite testing';
  }

  my $test = testauto(__FILE__);

  my $subs = $test->standard;

  $subs->synopsis(fun($tryable) {
    ok my $result = $tryable->result;

    $result
  });

  $subs->example(-1, 'clone', 'method', fun($tryable) {
    ok my $result = $tryable->result;
    ok $result->isa('Test::DB::Sqlite');
    ok $result->dbh;
    like $result->dsn, qr/dbi:SQLite:dbname=.*testing_db_\d+_\d+_\d+/;

    $result->destroy;
    $result
  });

  $subs->example(-1, 'create', 'method', fun($tryable) {
    ok my $result = $tryable->result;
    ok $result->isa('Test::DB::Sqlite');
    ok $result->dbh;
    like $result->dsn, qr/dbi:SQLite:dbname=.*testing_db_\d+_\d+_\d+/;

    $result->destroy;
    $result
  });

  $subs->example(-1, 'destroy', 'method', fun($tryable) {
    ok my $result = $tryable->result;
    ok $result->isa('Test::DB::Sqlite');

    $result
  });
}

ok 1 and done_testing;
