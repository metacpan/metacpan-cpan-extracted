package Moodle::Library;

use 5.014;

use Data::Object 'Library';

our $VERSION = '0.04'; # VERSION

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

Moodle::Library

=cut

=head1 ABSTRACT

Moodle Type Library

=cut

=head1 SYNOPSIS

  use Moodle::Library;

=cut

=head1 DESCRIPTION

Moodle::Library is the Moodle type library derived from
L<Data::Object::Library> which is a L<Type::Library>.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Data::Object::Library>

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/moodle/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/moodle/wiki>

L<Project|https://github.com/iamalnewkirk/moodle>

L<Initiatives|https://github.com/iamalnewkirk/moodle/projects>

L<Milestones|https://github.com/iamalnewkirk/moodle/milestones>

L<Contributing|https://github.com/iamalnewkirk/moodle/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/moodle/issues>

=cut
