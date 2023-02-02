package main;

use 5.014;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);

=name

Test::DB::Mssql

=cut

$test->for('name');

=tagline

Temporary Testing Databases for Mssql

=cut

$test->for('tagline');

=abstract

Temporary Mssql Database for Testing

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

  use Test::DB::Mssql;

  my $tdbo = Test::DB::Mssql->new;

  # my $dbh = $tdbo->create->dbh;

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

$test->for('attributes');

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

  $test->for('synopsis', sub {
    my ($tryable) = @_;
    ok my $result = $tryable->result;

    # create template0 for clone testing
    $result->create->dbh->do('CREATE DATABASE template0');

    $result
  });

  $test->for('example', 1, 'clone', sub {
    my ($tryable) = @_;
    ok my $result = $tryable->result;
    ok $result->isa('Test::DB::Mssql');
    ok $result->dbh;
    like $result->dsn, qr/dbi:ODBC:DSN=[^;]+;database=testing_db_\d+_\d+_\d+/;

    # destroy template0 after clone testing
    $result->dbh->do('DROP DATABASE template0');

    $result->destroy;

    $result
  });

  $test->for('example', 1, 'create', sub {
    my ($tryable) = @_;
    ok my $result = $tryable->result;
    ok $result->isa('Test::DB::Mssql');
    ok $result->dbh;
    like $result->dsn, qr/dbi:ODBC:DSN=[^;]+;database=testing_db_\d+_\d+_\d+/;

    $result->destroy;
    $result
  });

  $test->for('example', 1, 'destroy', sub {
    my ($tryable) = @_;
    ok my $result = $tryable->result;
    ok $result->isa('Test::DB::Mssql');

    $result
  });
}

$test->render('lib/Test/DB/Mssql.pod') if $ENV{RENDER};

ok 1 and done_testing;
