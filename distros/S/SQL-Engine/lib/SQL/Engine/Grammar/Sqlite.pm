package SQL::Engine::Grammar::Sqlite;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;

extends 'SQL::Engine::Grammar';

our $VERSION = '0.03'; # VERSION

# METHODS

method column_change(HashRef $data) {
  my $name = $data->{column}{name};
  my $tempname = join '_', $name, 'discarded', time;

  $self->operation($self->term(qw(begin transaction)));

  # rename column
  $self->column_rename({
    for => $data->{for},
    name => {
      new => $tempname,
      old => $name
    }
  });

  # re-create column
  $self->column_create($data);

  # copy data from column to column
  $self->update({
    for => $data->{for},
    columns => [{
      column => $name,
      value => {column => $tempname}
    }]
  });

  # nullify data from discardd
  $self->update({
    for => $data->{for},
    columns => [{
      column => $tempname,
      value => undef
    }]
  });

  $self->operation($self->term('commit'));

  return $self;
}

method column_definition(HashRef $data) {
  my $def = $self->next::method($data);

  if ($data->{increment}) {
    $def->{increment} = $self->term('autoincrement');
  }

  return $def;
}

method table_drop(HashRef $data) {
  my $sql = [];

  # drop table
  push @$sql, $self->term(qw(drop table)),
    ($data->{safe} ? $self->term(qw(if exists)) : ()),
    $self->name($data->{name});

  # sql statement
  my $result = join ' ', @$sql;

  return $self->operation($result);
}

method transaction(HashRef $data) {
  my @mode;
  if ($data->{mode}) {
    @mode = map $self->term($_), @{$data->{mode}};
  }
  $self->operation($self->term('begin', @mode, 'transaction'));
  $self->process($_) for @{$data->{queries}};
  $self->operation($self->term('commit'));

  return $self;
}

method type_binary(HashRef $data) {

  return 'blob';
}

method type_boolean(HashRef $data) {

  return 'tinyint(1)';
}

method type_char(HashRef $data) {

  return 'varchar';
}

method type_date(HashRef $data) {

  return 'date';
}

method type_datetime(HashRef $data) {

  return 'datetime';
}

method type_datetime_wtz(HashRef $data) {

  return 'datetime';
}

method type_decimal(HashRef $data) {

  return 'numeric';
}

method type_double(HashRef $data) {

  return 'float';
}

method type_enum(HashRef $data) {

  return 'varchar';
}

method type_float(HashRef $data) {

  return 'float';
}

method type_integer(HashRef $data) {

  return 'integer';
}

method type_integer_big(HashRef $data) {

  return 'integer';
}

method type_integer_big_unsigned(HashRef $data) {

  return 'integer';
}

method type_integer_medium(HashRef $data) {

  return 'integer';
}

method type_integer_medium_unsigned(HashRef $data) {

  return 'integer';
}

method type_integer_small(HashRef $data) {

  return 'integer';
}

method type_integer_small_unsigned(HashRef $data) {

  return 'integer';
}

method type_integer_tiny(HashRef $data) {

  return 'integer';
}

method type_integer_tiny_unsigned(HashRef $data) {

  return 'integer';
}

method type_integer_unsigned(HashRef $data) {

  return 'integer';
}

method type_json(HashRef $data) {

  return 'text';
}

method type_number(HashRef $data) {

  return $self->type_integer($data);
}

method type_string(HashRef $data) {

  return 'varchar';
}

method type_text(HashRef $data) {

  return 'text';
}

method type_text_long(HashRef $data) {

  return 'text';
}

method type_text_medium(HashRef $data) {

  return 'text';
}

method type_time(HashRef $data) {

  return 'time';
}

method type_time_wtz(HashRef $data) {

  return 'time';
}

method type_timestamp(HashRef $data) {

  return 'datetime';
}

method type_timestamp_wtz(HashRef $data) {

  return 'datetime';
}

method type_uuid(HashRef $data) {

  return 'varchar';
}

method wrap(Str $name) {

  return qq("$name");
}

1;

=encoding utf8

=head1 NAME

SQL::Engine::Grammar::Sqlite - Grammar For SQLite

=cut

=head1 ABSTRACT

SQL::Engine Grammar For SQLite

=cut

=head1 SYNOPSIS

  use SQL::Engine::Grammar::Sqlite;

  my $grammar = SQL::Engine::Grammar::Sqlite->new(
    schema => {
      select => {
        from => {
          table => 'users'
        },
        columns => [
          {
            column => '*'
          }
        ]
      }
    }
  );

  # $grammar->execute;

=cut

=head1 DESCRIPTION

This package provides methods for converting
L<json-sql|https://github.com/iamalnewkirk/json-sql> data structures into
SQLite statements.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<SQL::Engine::Grammar>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 column_change

  column_change(HashRef $data) : Object

The column_change method generates SQL statements to change a column
definition.

=over 4

=item column_change example #1

  my $grammar = SQL::Engine::Grammar::Sqlite->new(
    schema => {
      'column-change' => {
        for => {
          table => 'users'
        },
        column => {
          name => 'accessed',
          type => 'datetime',
          nullable => 1
        }
      }
    }
  );

  $grammar->column_change($grammar->schema->{'column-change'});

=back

=cut

=head2 transaction

  transaction(HashRef $data) : Object

The transaction method generates SQL statements to commit an atomic database
transaction.

=over 4

=item transaction example #1

  my $grammar = SQL::Engine::Grammar::Sqlite->new(
    schema => {
      'transaction' => {
        queries => [
          {
            'table-create' => {
              name => 'users',
              columns => [
                {
                  name => 'id',
                  type => 'integer',
                  primary => 1
                }
              ]
            }
          }
        ]
      }
    }
  );

  $grammar->transaction($grammar->schema->{'transaction'});

=back

=cut

=head2 type_binary

  type_binary(HashRef $data) : Str

The type_binary method returns the SQL expression representing a binary data
type.

=over 4

=item type_binary example #1

  # given: synopsis

  $grammar->type_binary({});

  # blob

=back

=cut

=head2 type_boolean

  type_boolean(HashRef $data) : Str

The type_boolean method returns the SQL expression representing a boolean data type.

=over 4

=item type_boolean example #1

  # given: synopsis

  $grammar->type_boolean({});

  # tinyint(1)

=back

=cut

=head2 type_char

  type_char(HashRef $data) : Str

The type_char method returns the SQL expression representing a char data type.

=over 4

=item type_char example #1

  # given: synopsis

  $grammar->type_char({});

  # varchar

=back

=cut

=head2 type_date

  type_date(HashRef $data) : Str

The type_date method returns the SQL expression representing a date data type.

=over 4

=item type_date example #1

  # given: synopsis

  $grammar->type_date({});

  # date

=back

=cut

=head2 type_datetime

  type_datetime(HashRef $data) : Str

The type_datetime method returns the SQL expression representing a datetime
data type.

=over 4

=item type_datetime example #1

  # given: synopsis

  $grammar->type_datetime({});

  # datetime

=back

=cut

=head2 type_datetime_wtz

  type_datetime_wtz(HashRef $data) : Str

The type_datetime_wtz method returns the SQL expression representing a datetime
(and timezone) data type.

=over 4

=item type_datetime_wtz example #1

  # given: synopsis

  $grammar->type_datetime_wtz({});

  # datetime

=back

=cut

=head2 type_decimal

  type_decimal(HashRef $data) : Str

The type_decimal method returns the SQL expression representing a decimal data
type.

=over 4

=item type_decimal example #1

  # given: synopsis

  $grammar->type_decimal({});

  # numeric

=back

=cut

=head2 type_double

  type_double(HashRef $data) : Str

The type_double method returns the SQL expression representing a double data
type.

=over 4

=item type_double example #1

  # given: synopsis

  $grammar->type_double({});

  # float

=back

=cut

=head2 type_enum

  type_enum(HashRef $data) : Str

The type_enum method returns the SQL expression representing a enum data type.

=over 4

=item type_enum example #1

  # given: synopsis

  $grammar->type_enum({ options => ['light', 'dark'] });

  # varchar

=back

=cut

=head2 type_float

  type_float(HashRef $data) : Str

The type_float method returns the SQL expression representing a float data
type.

=over 4

=item type_float example #1

  # given: synopsis

  $grammar->type_float({});

  # float

=back

=cut

=head2 type_integer

  type_integer(HashRef $data) : Str

The type_integer method returns the SQL expression representing a integer data
type.

=over 4

=item type_integer example #1

  # given: synopsis

  $grammar->type_integer({});

  # integer

=back

=cut

=head2 type_integer_big

  type_integer_big(HashRef $data) : Str

The type_integer_big method returns the SQL expression representing a
big-integer data type.

=over 4

=item type_integer_big example #1

  # given: synopsis

  $grammar->type_integer_big({});

  # integer

=back

=cut

=head2 type_integer_big_unsigned

  type_integer_big_unsigned(HashRef $data) : Str

The type_integer_big_unsigned method returns the SQL expression representing a
big unsigned integer data type.

=over 4

=item type_integer_big_unsigned example #1

  # given: synopsis

  $grammar->type_integer_big_unsigned({});

  # integer

=back

=cut

=head2 type_integer_medium

  type_integer_medium(HashRef $data) : Str

The type_integer_medium method returns the SQL expression representing a medium
integer data type.

=over 4

=item type_integer_medium example #1

  # given: synopsis

  $grammar->type_integer_medium({});

  # integer

=back

=cut

=head2 type_integer_medium_unsigned

  type_integer_medium_unsigned(HashRef $data) : Str

The type_integer_medium_unsigned method returns the SQL expression representing
a unsigned medium integer data type.

=over 4

=item type_integer_medium_unsigned example #1

  # given: synopsis

  $grammar->type_integer_medium_unsigned({});

  # integer

=back

=cut

=head2 type_integer_small

  type_integer_small(HashRef $data) : Str

The type_integer_small method returns the SQL expression representing a small
integer data type.

=over 4

=item type_integer_small example #1

  # given: synopsis

  $grammar->type_integer_small({});

  # integer

=back

=cut

=head2 type_integer_small_unsigned

  type_integer_small_unsigned(HashRef $data) : Str

The type_integer_small_unsigned method returns the SQL expression representing
a unsigned small integer data type.

=over 4

=item type_integer_small_unsigned example #1

  # given: synopsis

  $grammar->type_integer_small_unsigned({});

  # integer

=back

=cut

=head2 type_integer_tiny

  type_integer_tiny(HashRef $data) : Str

The type_integer_tiny method returns the SQL expression representing a tiny
integer data type.

=over 4

=item type_integer_tiny example #1

  # given: synopsis

  $grammar->type_integer_tiny({});

  # integer

=back

=cut

=head2 type_integer_tiny_unsigned

  type_integer_tiny_unsigned(HashRef $data) : Str

The type_integer_tiny_unsigned method returns the SQL expression representing a
unsigned tiny integer data type.

=over 4

=item type_integer_tiny_unsigned example #1

  # given: synopsis

  $grammar->type_integer_tiny_unsigned({});

  # integer

=back

=cut

=head2 type_integer_unsigned

  type_integer_unsigned(HashRef $data) : Str

The type_integer_unsigned method returns the SQL expression representing a
unsigned integer data type.

=over 4

=item type_integer_unsigned example #1

  # given: synopsis

  $grammar->type_integer_unsigned({});

  # integer

=back

=cut

=head2 type_json

  type_json(HashRef $data) : Str

The type_json method returns the SQL expression representing a json data type.

=over 4

=item type_json example #1

  # given: synopsis

  $grammar->type_json({});

  # text

=back

=cut

=head2 type_number

  type_number(HashRef $data) : Str

The type_number method returns the SQL expression representing a number data
type.

=over 4

=item type_number example #1

  # given: synopsis

  $grammar->type_number({});

  # integer

=back

=cut

=head2 type_string

  type_string(HashRef $data) : Str

The type_string method returns the SQL expression representing a string data
type.

=over 4

=item type_string example #1

  # given: synopsis

  $grammar->type_string({});

  # varchar

=back

=cut

=head2 type_text

  type_text(HashRef $data) : Str

The type_text method returns the SQL expression representing a text data type.

=over 4

=item type_text example #1

  # given: synopsis

  $grammar->type_text({});

  # text

=back

=cut

=head2 type_text_long

  type_text_long(HashRef $data) : Str

The type_text_long method returns the SQL expression representing a long text
data type.

=over 4

=item type_text_long example #1

  # given: synopsis

  $grammar->type_text_long({});

  # text

=back

=cut

=head2 type_text_medium

  type_text_medium(HashRef $data) : Str

The type_text_medium method returns the SQL expression representing a medium
text data type.

=over 4

=item type_text_medium example #1

  # given: synopsis

  $grammar->type_text_medium({});

  # text

=back

=cut

=head2 type_time

  type_time(HashRef $data) : Str

The type_time method returns the SQL expression representing a time data type.

=over 4

=item type_time example #1

  # given: synopsis

  $grammar->type_time({});

  # time

=back

=cut

=head2 type_time_wtz

  type_time_wtz(HashRef $data) : Str

The type_time_wtz method returns the SQL expression representing a time (and
timezone) data type.

=over 4

=item type_time_wtz example #1

  # given: synopsis

  $grammar->type_time_wtz({});

  # time

=back

=cut

=head2 type_timestamp

  type_timestamp(HashRef $data) : Str

The type_timestamp method returns the SQL expression representing a timestamp
data type.

=over 4

=item type_timestamp example #1

  # given: synopsis

  $grammar->type_timestamp({});

  # datetime

=back

=cut

=head2 type_timestamp_wtz

  type_timestamp_wtz(HashRef $data) : Str

The type_timestamp_wtz method returns the SQL expression representing a
timestamp (and timezone) data type.

=over 4

=item type_timestamp_wtz example #1

  # given: synopsis

  $grammar->type_timestamp_wtz({});

  # datetime

=back

=cut

=head2 type_uuid

  type_uuid(HashRef $data) : Str

The type_uuid method returns the SQL expression representing a uuid data type.

=over 4

=item type_uuid example #1

  # given: synopsis

  $grammar->type_uuid({});

  # varchar

=back

=cut

=head2 wrap

  wrap(Str $name) : Str

The wrap method returns a SQL-escaped string.

=over 4

=item wrap example #1

  # given: synopsis

  $grammar->wrap('field');

  # "field"

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/sql-engine/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/sql-engine/wiki>

L<Project|https://github.com/iamalnewkirk/sql-engine>

L<Initiatives|https://github.com/iamalnewkirk/sql-engine/projects>

L<Milestones|https://github.com/iamalnewkirk/sql-engine/milestones>

L<Contributing|https://github.com/iamalnewkirk/sql-engine/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/sql-engine/issues>

=cut