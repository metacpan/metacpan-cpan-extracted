package Moodle::Library;

use Data::Object 'Library';

our $MysqlDriver = declare "MysqlDriver",
  as InstanceOf["Mojo::mysql"];

our $PostgresDriver = declare "PostgresDriver",
  as InstanceOf["Mojo::Pg"];

our $SqliteDriver = declare "SqliteDriver",
  as InstanceOf["Mojo::SQLite"];

our $Driver = declare "Driver",
  as $MysqlDriver | $PostgresDriver | $SqliteDriver;

our $Migrator = declare "Migrator",
  as InstanceOf["Doodle::Migration"];

1;

=encoding utf8

=head1 NAME

Moodle

=cut

=head1 ABSTRACT

Moodle Type Library

=cut

=head1 SYNOPSIS

  use Moodle::Library;

=cut

=head1 DESCRIPTION

Moodle::Library is the L<Moodle> type library derived from
L<Data::Object::Library> which is a L<Type::Library>

=cut
