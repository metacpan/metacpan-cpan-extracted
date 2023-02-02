package main;

use 5.014;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);

=name

Test::DB::Sqlite

=cut

$test->for('name');

=tagline

Temporary Testing Databases for Sqlite

=cut

$test->for('tagline');

=abstract

Temporary Sqlite Database for Testing

=cut

$test->for('abstract');

=includes

method: clone
method: create
method: destroy

=cut

$test->for('includes');

=synopsis

  package main;

  use Test::DB::Sqlite;

  my $tdbo = Test::DB::Sqlite->new;

  # my $dbh = $tdbo->create->dbh;

=cut

=attributes

dbh: ro, opt, Object
dsn: ro, opt, Str
database: ro, opt, Str
file: ro, opt, Str
uri: ro, opt, Str

=cut

$test->for('attributes');

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

  $test->for('synopsis', sub {
    my ($tryable) = @_;
    ok my $result = $tryable->result;

    $result
  });

  $test->for('example', 1, 'clone', sub {
    my ($tryable) = @_;
    ok my $result = $tryable->result;
    ok $result->isa('Test::DB::Sqlite');
    ok $result->dbh;
    like $result->dsn, qr/dbi:SQLite:dbname=.*testing_db_\d+_\d+_\d+/;

    $result->destroy;
    $result
  });

  $test->for('example', 1, 'create', sub {
    my ($tryable) = @_;
    ok my $result = $tryable->result;
    ok $result->isa('Test::DB::Sqlite');
    ok $result->dbh;
    like $result->dsn, qr/dbi:SQLite:dbname=.*testing_db_\d+_\d+_\d+/;

    $result->destroy;
    $result
  });

  $test->for('example', 1, 'destroy', sub {
    my ($tryable) = @_;
    ok my $result = $tryable->result;
    ok $result->isa('Test::DB::Sqlite');

    $result
  });
}

$test->render('lib/Test/DB/Sqlite.pod') if $ENV{RENDER};

ok 1 and done_testing;
