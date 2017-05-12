package Test::DBIC::Versioned;

use strict;
use warnings;
use 5.016;

our $VERSION = '0.02'; # VERSION

=head1 NAME

Test::DBIC::Versioned - Test upgrade scripts for L<< DBIx::Class::Schema::Versioned >>

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use Test::More;
  use Test::DBIC::Versioned;
  use Test::DBIC::Versioned::MySQL;

  my $old_DB = Test::DBIC::Versioned::MySQL->new();
  my $new_DB = Test::DBIC::Versioned::MySQL->new();

  is $old_DB->run_sql('sql/DB-21-MySQL.sql'), '',
    'No errors deploying at version 21';
  is $new_DB->run_sql('sql/DB-22-MySQL.sql'), '',
    'No errors deploying at version 22';

  my $errors = $old_DB->run_sql('upgrades/RL-DB-21-22-MySQL.sql';
  is $errors, '', 'No errors upgrading from 21 to 22';

  is_deeply $old_DB->describe_tables, $new_DB->describe_tables,
    'Upgrade of version 21 to 22 matches a fresh deploy of 22';

  done_testing();

=head1 DESCRIPTION

This module provides helpful a wrapper for testing the correctness of
L<< DBIx::Class::Schema::Versioned >> upgrade scripts. Currently only MySQL
is supported.

=head1 METHODS

=head2 new

A standard L<< Moose >> constructor. Takes no arguments. A temporary database
of the appropriate type will be lazy built when needed.

=head2 run_sql

Runs some SQL commands on the database. Normally this will be the deployment
script to set-up the database schema, or an upgrade script to modify the
schema.

The commands can be in a file, file-handle, or be supplied in a scalar
reference.

Returns any errors as a string, or an empty string if there where none.

=head2 describe_tables

Probes all tables in the database and returns a data structure describing the
schema (columns and indexes) on each table. The structure is intended to be
passed to is_deeply for comparison.

=cut

use JSON;    # Used to convert perl data to a string.
use Moose;
use MooseX::StrictConstructor;

=head1 FIELDS

=head2 dsn

The database dsn string. It can be used to connect to the database.

=cut

has 'dsn' => (
    is  => 'rw',
    isa => 'Str',
);

=head2 dbh

The database dbh handle. It contains a connection to the database.

=cut

has 'dbh' => (
    is         => 'ro',
    isa        => 'DBI::db',
    lazy_build => 1,
);

sub _build_dbh {
    my $self = shift;
    return DBI->connect( $self->dsn );
}

=head2 test_db

The test database. The details of it are dependent on the database specific
subclass. For example in L<< Test::DBIC::Versioned::MySQL >> it is an
instance of L<< Test::mysqld >>.

=cut

has 'test_db' => (
    is         => 'ro',
    isa        => 'Ref',
    lazy_build => 1,
);

has _json_engine => (
    is      => 'ro',
    isa     => 'JSON',
    default => sub { return JSON->new->pretty(1) }
);

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 "spudsoup"

This program is released under the Artistic License version 2.0

=cut

1;
