package Test::DB;

use 5.014;

use strict;
use warnings;

use Venus::Class;

# VERSION

our $VERSION = '0.10';

# AUTHORITY

our $AUTHORITY = 'cpan:AWNCORP';

# METHODS

sub build {
  my ($self, %options) = @_;

  my $type = $self->type($options{database});

  if (lc($type) eq 'sqlite') {
    return $self->sqlite(%options);
  }
  elsif (lc($type) eq 'postgres') {
    return $self->postgres(%options);
  }
  elsif (lc($type) eq 'mysql') {
    return $self->mysql(%options);
  }
  elsif (lc($type) eq 'mssql') {
    return $self->mssql(%options);
  }
  else {
    return undef;
  }
}

sub create {
  my ($self, %options) = @_;

  if (my $driver = $self->build(%options)) {
    return $driver->create;
  }
  else {
    return undef;
  }
}

sub clone {
  my ($self, %options) = @_;

  if (my $driver = $self->build(%options)) {
    return $driver->clone;
  }
  else {
    return undef;
  }
}

sub mssql {
  my ($self, %options) = @_;

  require Test::DB::Mssql;

  return Test::DB::Mssql->new(%options);
}

sub mysql {
  my ($self, %options) = @_;

  require Test::DB::Mysql;

  return Test::DB::Mysql->new(%options);
}

sub postgres {
  my ($self, %options) = @_;

  require Test::DB::Postgres;

  return Test::DB::Postgres->new(%options);
}

sub sqlite {
  my ($self, %options) = @_;

  require Test::DB::Sqlite;

  return Test::DB::Sqlite->new(%options);
}

sub type {
  my ($self, $name) = @_;

  return $name || $ENV{TESTDB_DATABASE} || 'sqlite';
}

1;



=head1 NAME

Test::DB - Temporary Testing Databases

=cut

=head1 ABSTRACT

Temporary Databases for Testing

=cut

=head1 VERSION

0.10

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

=head1 METHODS

This package provides the following methods:

=cut

=head2 clone

clone(Str :$database, Str %options) : Maybe[Object]

The clone method generates a database based on the type and database template
specified and returns a driver object with an active connection, C<dbh> and
C<dsn>. If the database specified doesn't have a corresponding database driver
this method will returned the undefined value. The type of database can be
omitted if the C<TESTDB_DATABASE> environment variable is set, if not the type
of database must be either C<sqlite>, C<mysql>, C<mssql> or C<postgres>.  Any
options provided are passed along to the test database object class
constructor.

=over 4

=item clone example 1

  # given: synopsis

  $ENV{TESTDB_DATABASE} = 'postgres';

  $tdb->clone(template => 'template0');

=back

=over 4

=item clone example 2

  # given: synopsis

  $ENV{TESTDB_DATABASE} = 'postgres';
  $ENV{TESTDB_TEMPLATE} = 'template0';

  $tdb->clone;

=back

=over 4

=item clone example 3

  # given: synopsis

  $ENV{TESTDB_TEMPLATE} = 'template0';

  $tdb->clone(database => 'postgres');

=back

=cut

=head2 create

create(Str :$database, Str %options) : Maybe[Object]

The create method generates a database based on the type specified and returns
a driver object with an active connection, C<dbh> and C<dsn>. If the database
specified doesn't have a corresponding database driver this method will
returned the undefined value. The type of database can be omitted if the
C<TESTDB_DATABASE> environment variable is set, if not the type of database
must be either C<sqlite>, C<mysql>, C<mssql> or C<postgres>. Any options
provided are passed along to the test database object class constructor.

=over 4

=item create example 1

  # given: synopsis

  $tdb->create;

=back

=over 4

=item create example 2

  # given: synopsis

  $ENV{TESTDB_DATABASE} = 'sqlite';

  $tdb->create;

=back

=over 4

=item create example 3

  # given: synopsis

  $tdb->create(database => 'sqlite');

=back

=cut

=head2 mssql

mssql(Str %options) : Maybe[InstanceOf["Test::DB::Mssql"]]

The mssql method builds and returns a L<Test::DB::Mssql> object.

=over 4

=item mssql example 1

  # given: synopsis

  $tdb->mssql;

=back

=cut

=head2 mysql

mysql(Str %options) : Maybe[InstanceOf["Test::DB::Mysql"]]

The mysql method builds and returns a L<Test::DB::Mysql> object.

=over 4

=item mysql example 1

  # given: synopsis

  $tdb->mysql;

=back

=cut

=head2 postgres

postgres(Str %options) : Maybe[InstanceOf["Test::DB::Postgres"]]

The postgres method builds and returns a L<Test::DB::Postgres> object.

=over 4

=item postgres example 1

  # given: synopsis

  $tdb->postgres;

=back

=cut

=head2 sqlite

sqlite(Str %options) : Maybe[InstanceOf["Test::DB::Sqlite"]]

The sqlite method builds and returns a L<Test::DB::Sqlite> object.

=over 4

=item sqlite example 1

  # given: synopsis

  $tdb->sqlite;

=back

=cut