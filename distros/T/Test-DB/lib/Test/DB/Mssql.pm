package Test::DB::Mssql;

use 5.014;

use strict;
use warnings;

use Venus::Class;

with 'Venus::Role::Optional';

use DBI;

# VERSION

our $VERSION = '0.10';

# ATTRIBUTES

attr 'dbh';
attr 'dsn';
attr 'hostname';
attr 'hostport';
attr 'initial';
attr 'uri';
attr 'username';
attr 'password';
attr 'database';
attr 'template';
attr 'odbcdsn';

# OPTIONS

sub lazy_build_dbh {
  my ($self, $data) = @_;

  $data ||= DBI->connect($self->dsn, $self->username, $self->password, {
    RaiseError => 1,
    AutoCommit => 1
  });

  return $data;
}

sub lazy_build_dsn {
  my ($self, $data) = @_;

  return $self->dsngen($self->database);
}

sub lazy_build_hostname {
  my ($self, $data) = @_;

  return $data ? $data : $ENV{TESTDB_HOSTNAME};
}

sub lazy_build_hostport {
  my ($self, $data) = @_;

  return $data ? $data : $ENV{TESTDB_HOSTPORT};
}

sub lazy_build_initial {
  my ($self, $data) = @_;

  return $data ? $data : $ENV{TESTDB_INITIAL} || 'master';
}

sub lazy_build_uri {
  my ($self, $data) = @_;

  return $self->urigen($self->database);
}

sub lazy_build_username {
  my ($self, $data) = @_;

  return $data ? $data : $ENV{TESTDB_USERNAME} || 'sa';
}

sub lazy_build_password {
  my ($self, $data) = @_;

  return $data ? $data : $ENV{TESTDB_PASSWORD} || '';
}

sub lazy_build_database {
  my ($self, $data) = @_;

  return $data ? $data : join '_', 'testing_db', time, $$, sprintf "%04d", rand 999;
}

sub lazy_build_template {
  my ($self, $data) = @_;

  return $data ? $data : $ENV{TESTDB_TEMPLATE};
}

sub lazy_build_odbcdsn {
  my ($self, $data) = @_;

  return $data ? $data : $ENV{TESTDB_ODBCDSN};
}

# METHODS

sub clone {
  my ($self) = @_;

  my $source = $self->template;
  my $initial = $self->initial;

  my $dbh = DBI->connect($self->dsngen($initial),
    $self->username,
    $self->password,
    {
      RaiseError => 1,
      AutoCommit => 1
    }
  );

  my $sth = $dbh->prepare(qq(DBCC CLONEDATABASE([$source], [@{[$self->database]}])));

  $sth->execute;
  $dbh->disconnect;

  $self->dbh;
  $self->uri;

  return $self;
}

sub create {
  my ($self) = @_;

  my $dbh = DBI->connect($self->dsngen($self->initial),
    $self->username,
    $self->password,
    {
      RaiseError => 1,
      AutoCommit => 1
    }
  );

  my $sth = $dbh->prepare(qq(CREATE DATABASE [@{[$self->database]}]));

  $sth->execute;
  $dbh->disconnect;

  $self->dbh;
  $self->uri;

  return $self;
}

sub destroy {
  my ($self) = @_;

  $self->dbh->disconnect if $self->{dbh};

  my $dbh = DBI->connect($self->dsngen($self->initial),
    $self->username,
    $self->password,
    {
      RaiseError => 1,
      AutoCommit => 1
    }
  );

  my $sth = $dbh->prepare(qq(DROP DATABASE [@{[$self->database]}]));

  $sth->execute;
  $dbh->disconnect;

  return $self;
}

sub dsngen {
  my ($self, $name) = @_;

  my $hostname = $self->hostname;
  my $hostport = $self->hostport;

  return join ';', "dbi:ODBC:DSN=@{[$self->odbcdsn]};database=$name", join ';',
    ($hostname ? ("host=@{[$hostname]}") : ()),
    ($hostport ? ("port=@{[$hostport]}") : ())
}

sub urigen {
  my ($self, $name) = @_;

  my $username = $self->username;
  my $password = $self->password;
  my $hostname = $self->hostname;
  my $hostport = $self->hostport;

  return join(
    '/', 'mssql',
    ($username ? '' : ()),
    (
      $username
      ? join('@',
        join(':', $username ? ($username, ($password ? $password : ())) : ()),
        $hostname
        ? ($hostport ? (join(':', $hostname, $hostport)) : $hostname)
        : '')
      : ()
    ),
    $name
    )
}

1;



=head1 NAME

Test::DB::Mssql - Temporary Testing Databases for Mssql

=cut

=head1 ABSTRACT

Temporary Mssql Database for Testing

=cut

=head1 VERSION

0.10

=cut

=head1 SYNOPSIS

  package main;

  use Test::DB::Mssql;

  my $tdbo = Test::DB::Mssql->new;

  # my $dbh = $tdbo->create->dbh;

=cut

=head1 DESCRIPTION

This package provides methods for generating and destroying Mssql databases
for testing purposes. The attributes can be set using their respective
environment variables: C<TESTDB_TEMPLATE>, C<TESTDB_DATABASE>,
C<TESTDB_USERNAME>, C<TESTDB_PASSWORD>, C<TESTDB_HOSTNAME>, and
C<TESTDB_HOSTPORT>.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 dbh

  dbh(Object)

This attribute is read-only, accepts C<(Object)> values, and is optional.

=cut

=head2 dsn

  dsn(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 database

  database(Str)

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

=head2 uri

  uri(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 username

  username(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 password

  password(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 clone

clone(Str $source) : Object

The clone method creates a temporary database from a database template.

=over 4

=item clone example 1

  # given: synopsis

  $tdbo->clone('template0');

  # <Test::DB::Mssql>

=back

=cut

=head2 create

create() : Object

The create method creates a temporary database and returns the invocant.

=over 4

=item create example 1

  # given: synopsis

  $tdbo->create;

  # <Test::DB::Mssql>

=back

=cut

=head2 destroy

destroy() : Object

The destroy method destroys (drops) the database and returns the invocant.

=over 4

=item destroy example 1

  # given: synopsis

  $tdbo->create;
  $tdbo->destroy;

  # <Test::DB::Mssql>

=back

=cut