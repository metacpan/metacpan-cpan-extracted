package main;

use 5.014;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);

=name

Test::DB

=cut

$test->for('name');

=tagline

Temporary Testing Databases

=cut

$test->for('tagline');

=abstract

Temporary Databases for Testing

=cut

$test->for('abstract');

=includes

method: clone
method: create
method: mssql
method: mysql
method: postgres
method: sqlite

=cut

$test->for('includes');

=synopsis

  use Test::DB;

  my $tdb = Test::DB->new;

  # my $tdbo = $tdb->create(database => 'sqlite');

  # my $dbh = $tdbo->dbh;

=cut

=description

This package provides a framework for setting up and tearing down temporary
databases for testing purposes. This framework requires a user (optionally with
password) which has the ability to create new databases and works by creating
test-specific databases owned by the user specified. B<Note:> Test databases
are not automatically destroyed and should be cleaned up manually by call the
C<destroy> method on the database-specific test database object.

+=head2 process

B<on create, clone>

+=over 4

+=item #1

Establish a connection to the DB using some "initial" database.

  my $tdbo = $tdb->postgres(initial => 'template0');

+=item #2

Using the established connection, create the test/temporary database.

  $tdbo->create;

+=item #3

Establish a connection to the newly created test/temporary database.

  $tdbo->create->dbh;

+=back

B<on destroy>

+=over 4

+=item #1

Establish a connection to the DB using the "initial" database.

  # using the created test/temporary database object

+=item #2

Using the established connection, drop the test/temporary database.

  $tdbo->destroy;

+=back

+=head2 usages

B<using DBI>

+=over 4

+=item #1

  my $tdb = Test::DB->new;
  my $dbh = $tdb->sqlite(%options)->dbh;

+=back

B<using DBIx::Class>

+=over 4

+=item #1

  my $tdb = Test::DB->new;
  my $tdbo = $tdb->postgres(%options)->create;
  my $schema = DBIx::Class::Schema->connect(
    dsn => $tdbo->dsn,
    username => $tdbo->username,
    password => $tdbo->password,
  );

+=back

B<using Mojo::mysql>

+=over 4

+=item #1

  my $tdb = Test::DB->new;
  my $tdbo = $tdb->mysql(%options)->create;
  my $mysql = Mojo::mysql->new($tdbo->uri);

+=back

B<using Mojo::Pg>

+=over 4

+=item #1

  my $tdb = Test::DB->new;
  my $tdbo = $tdb->postgres(%options)->create;
  my $postgres = Mojo::Pg->new($tdbo->uri);

+=back

B<using Mojo::Pg (with cloning)>

+=over 4

+=item #1

  my $tdb = Test::DB->new;
  my $tdbo = $tdb->postgres(%options)->clone('template0');
  my $postgres = Mojo::Pg->new($tdbo->uri);

+=back

B<using Mojo::SQLite>

+=over 4

+=item #1

  my $tdb = Test::DB->new;
  my $tdbo = $tdb->sqlite(%options)->create;
  my $sqlite = Mojo::SQLite->new($tdbo->uri);

+=back

=cut

=method clone

The clone method generates a database based on the type and database template
specified and returns a driver object with an active connection, C<dbh> and
C<dsn>. If the database specified doesn't have a corresponding database driver
this method will returned the undefined value. The type of database can be
omitted if the C<TESTDB_DATABASE> environment variable is set, if not the type
of database must be either C<sqlite>, C<mysql>, C<mssql> or C<postgres>.  Any
options provided are passed along to the test database object class
constructor.

=signature clone

clone(Str :$database, Str %options) : Maybe[Object]

=example-1 clone

  # given: synopsis

  $ENV{TESTDB_DATABASE} = 'postgres';

  $tdb->clone(template => 'template0');

=example-2 clone

  # given: synopsis

  $ENV{TESTDB_DATABASE} = 'postgres';
  $ENV{TESTDB_TEMPLATE} = 'template0';

  $tdb->clone;

=example-3 clone

  # given: synopsis

  $ENV{TESTDB_TEMPLATE} = 'template0';

  $tdb->clone(database => 'postgres');

=cut

=method create

The create method generates a database based on the type specified and returns
a driver object with an active connection, C<dbh> and C<dsn>. If the database
specified doesn't have a corresponding database driver this method will
returned the undefined value. The type of database can be omitted if the
C<TESTDB_DATABASE> environment variable is set, if not the type of database
must be either C<sqlite>, C<mysql>, C<mssql> or C<postgres>. Any options
provided are passed along to the test database object class constructor.

=signature create

create(Str :$database, Str %options) : Maybe[Object]

=example-1 create

  # given: synopsis

  $tdb->create;

=example-2 create

  # given: synopsis

  $ENV{TESTDB_DATABASE} = 'sqlite';

  $tdb->create;

=example-3 create

  # given: synopsis

  $tdb->create(database => 'sqlite');

=cut

=method mssql

The mssql method builds and returns a L<Test::DB::Mssql> object.

=signature mssql

mssql(Str %options) : Maybe[InstanceOf["Test::DB::Mssql"]]

=example-1 mssql

  # given: synopsis

  $tdb->mssql;

=cut

=method mysql

The mysql method builds and returns a L<Test::DB::Mysql> object.

=signature mysql

mysql(Str %options) : Maybe[InstanceOf["Test::DB::Mysql"]]

=example-1 mysql

  # given: synopsis

  $tdb->mysql;

=cut

=method postgres

The postgres method builds and returns a L<Test::DB::Postgres> object.

=signature postgres

postgres(Str %options) : Maybe[InstanceOf["Test::DB::Postgres"]]

=example-1 postgres

  # given: synopsis

  $tdb->postgres;

=cut

=method sqlite

The sqlite method builds and returns a L<Test::DB::Sqlite> object.

=signature sqlite

sqlite(Str %options) : Maybe[InstanceOf["Test::DB::Sqlite"]]

=example-1 sqlite

  # given: synopsis

  $tdb->sqlite;

=cut

package main;

SKIP: {
  if (!$ENV{TESTDB_DATABASE}) {
    skip 'Environment not configured for testing';
  }

  $test->for('synopsis', sub {
    my ($tryable) = @_;
    ok my $result = $tryable->result;

    $result
  });

  $test->for('example', 1, 'mssql', sub {
    my ($tryable) = @_;
    ok my $result = $tryable->result;
    ok $result->isa('Test::DB::Mssql');

    $result
  });

  $test->for('example', 1, 'mysql', sub {
    my ($tryable) = @_;
    ok my $result = $tryable->result;
    ok $result->isa('Test::DB::Mysql');

    $result
  });

  $test->for('example', 1, 'postgres', sub {
    my ($tryable) = @_;
    ok my $result = $tryable->result;
    ok $result->isa('Test::DB::Postgres');

    $result
  });

  $test->for('example', 1, 'sqlite', sub {
    my ($tryable) = @_;
    ok my $result = $tryable->result;
    ok $result->isa('Test::DB::Sqlite');

    $result
  });

  $test->for('example', 1, 'create', sub {
    my ($tryable) = @_;
    ok my $result = $tryable->result;
    my $database = $ENV{TESTDB_DATABASE};
    ok $result->isa('Test::DB::Mssql') if (lc($database) eq 'mssql');
    ok $result->isa('Test::DB::Mysql') if (lc($database) eq 'mysql');
    ok $result->isa('Test::DB::Postgres') if (lc($database) eq 'postgres');
    ok $result->isa('Test::DB::Sqlite') if (lc($database) eq 'sqlite');
    ok $result->destroy;

    $result
  });

  my $is_sqlite = lc($ENV{TESTDB_DATABASE}) eq 'sqlite';
  if (do {local $@; eval {require DBD::SQLite}; $is_sqlite && !$@}) {
    $test->for('example', 2, 'create', sub {
      my ($tryable) = @_;
      ok my $result = $tryable->result;
      ok $result->isa('Test::DB::Sqlite');
      ok $result->destroy;

      $result
    });

    $test->for('example', 3, 'create', sub {
      my ($tryable) = @_;
      ok my $result = $tryable->result;
      ok $result->isa('Test::DB::Sqlite');
      ok $result->destroy;

      $result
    });
  }

  my $is_postgres = lc($ENV{TESTDB_DATABASE}) eq 'postgres';
  if (do {local $@; eval {require DBD::Pg}; $is_postgres && !$@}) {
    $test->for('example', 1, 'clone', sub {
      my ($tryable) = @_;
      ok my $result = $tryable->result;
      ok $result->isa('Test::DB::Postgres');
      ok $result->destroy;

      $result
    });

    $test->for('example', 2, 'clone', sub {
      my ($tryable) = @_;
      ok my $result = $tryable->result;
      ok $result->isa('Test::DB::Postgres');
      ok $result->destroy;

      $result
    });

    $test->for('example', 3, 'clone', sub {
      my ($tryable) = @_;
      ok my $result = $tryable->result;
      ok $result->isa('Test::DB::Postgres');
      ok $result->destroy;

      $result
    });
  }
}

$test->render('lib/Test/DB.pod') if $ENV{RENDER};

ok 1 and done_testing;
