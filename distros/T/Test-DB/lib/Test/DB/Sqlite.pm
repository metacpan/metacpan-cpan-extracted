package Test::DB::Sqlite;

use 5.014;

use strict;
use warnings;

use Venus::Class;

with 'Venus::Role::Optional';

use DBI;
use File::Copy ();
use File::Spec ();
use File::Temp ();

# VERSION

our $VERSION = '0.10';

# ATTRIBUTES

attr 'dbh';
attr 'dsn';
attr 'file';
attr 'uri';
attr 'database';
attr 'template';

# OPTIONS

sub lazy_build_dbh {
  my ($self, $data) = @_;

  $data ||= DBI->connect($self->dsn, '', '', { RaiseError => 1, AutoCommit => 1 });

  return $data;
}

sub lazy_build_dsn {
  my ($self, $data) = @_;

  return $data ? $data : "dbi:SQLite:dbname=@{[$self->file]}";
}

sub lazy_build_file {
  my ($self, $data) = @_;

  my $database = $self->database;

  return $data ? $data : File::Spec->catfile(File::Temp::tempdir, "$database.db");
}

sub lazy_build_uri {
  my ($self, $data) = @_;

  return $data ? $data : "sqlite:@{[$self->file]}";
}

sub lazy_build_database {
  my ($self, $data) = @_;

  return $data ? $data : join '_', 'testing_db', time, $$, sprintf "%04d", rand 999;
}

sub lazy_build_template {
  my ($self, $data) = @_;

  return $data ? $data : $ENV{TESTDB_TEMPLATE};
}

# METHODS

sub clone {
  my ($self, $file) = @_;

  File::Copy::copy($file || $self->template, $self->file);

  return $self->create;
}

sub create {
  my ($self) = @_;

  my $dbh = $self->dbh;

  $self->uri;

  return $self;
}

sub destroy {
  my ($self) = @_;

  my $file = $self->file;

  unlink $file;

  return $self;
}

1;



=head1 NAME

Test::DB::Sqlite - Temporary Testing Databases for Sqlite

=cut

=head1 ABSTRACT

Temporary Sqlite Database for Testing

=cut

=head1 VERSION

0.10

=cut

=head1 SYNOPSIS

  package main;

  use Test::DB::Sqlite;

  my $tdbo = Test::DB::Sqlite->new;

  # my $dbh = $tdbo->create->dbh;

=cut

=head1 DESCRIPTION

This package provides methods for generating and destroying Sqlite databases
for testing purposes.

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

=head2 file

  file(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 uri

  uri(Str)

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

  $tdbo->clone('source.db');

  # <Test::DB::Sqlite>

=back

=cut

=head2 create

create() : Object

The create method creates a temporary database and returns the invocant.

=over 4

=item create example 1

  # given: synopsis

  $tdbo->create;

  # <Test::DB::Sqlite>

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

  # <Test::DB::Sqlite>

=back

=cut