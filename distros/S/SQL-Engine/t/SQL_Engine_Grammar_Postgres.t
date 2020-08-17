use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

SQL::Engine::Grammar::Postgres

=cut

=tagline

Grammar For PostgreSQL

=cut

=abstract

SQL::Engine Grammar For PostgreSQL

=cut

=includes

method: column_change
method: transaction
method: type_binary
method: type_boolean
method: type_char
method: type_date
method: type_datetime
method: type_datetime_wtz
method: type_decimal
method: type_double
method: type_enum
method: type_float
method: type_integer
method: type_integer_big
method: type_integer_big_unsigned
method: type_integer_medium
method: type_integer_medium_unsigned
method: type_integer_small
method: type_integer_small_unsigned
method: type_integer_tiny
method: type_integer_tiny_unsigned
method: type_integer_unsigned
method: type_json
method: type_number
method: type_string
method: type_text
method: type_text_long
method: type_text_medium
method: type_time
method: type_time_wtz
method: type_timestamp
method: type_timestamp_wtz
method: type_uuid
method: wrap

=cut

=synopsis

  use SQL::Engine::Grammar::Postgres;

  my $grammar = SQL::Engine::Grammar::Postgres->new(
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

=libraries

Types::Standard

=cut

=inherits

SQL::Engine::Grammar

=cut

=description

This package provides methods for converting
L<json-sql|https://github.com/iamalnewkirk/json-sql> data structures into
PostgreSQL statements.

=cut

=method column_change

The column_change method generates SQL statements to change a column
definition.

=signature column_change

column_change(HashRef $data) : Object

=example-1 column_change

  my $grammar = SQL::Engine::Grammar::Postgres->new(
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

=cut

=method transaction

The transaction method generates SQL statements to commit an atomic database
transaction.

=signature transaction

transaction(HashRef $data) : Object

=example-1 transaction

  my $grammar = SQL::Engine::Grammar::Postgres->new(
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

=cut

=method type_binary

The type_binary method returns the SQL expression representing a binary data
type.

=signature type_binary

type_binary(HashRef $data) : Str

=example-1 type_binary

  # given: synopsis

  $grammar->type_binary({});

  # bytea

=cut

=method type_boolean

The type_boolean method returns the SQL expression representing a boolean data type.

=signature type_boolean

type_boolean(HashRef $data) : Str

=example-1 type_boolean

  # given: synopsis

  $grammar->type_boolean({});

  # boolean

=cut

=method type_char

The type_char method returns the SQL expression representing a char data type.

=signature type_char

type_char(HashRef $data) : Str

=example-1 type_char

  # given: synopsis

  $grammar->type_char({});

  # char(1)

=cut

=method type_date

The type_date method returns the SQL expression representing a date data type.

=signature type_date

type_date(HashRef $data) : Str

=example-1 type_date

  # given: synopsis

  $grammar->type_date({});

  # date

=cut

=method type_datetime

The type_datetime method returns the SQL expression representing a datetime
data type.

=signature type_datetime

type_datetime(HashRef $data) : Str

=example-1 type_datetime

  # given: synopsis

  $grammar->type_datetime({});

  # timestamp(0) without time zone

=cut

=method type_datetime_wtz

The type_datetime_wtz method returns the SQL expression representing a datetime
(and timezone) data type.

=signature type_datetime_wtz

type_datetime_wtz(HashRef $data) : Str

=example-1 type_datetime_wtz

  # given: synopsis

  $grammar->type_datetime_wtz({});

  # timestamp(0) with time zone

=cut

=method type_decimal

The type_decimal method returns the SQL expression representing a decimal data
type.

=signature type_decimal

type_decimal(HashRef $data) : Str

=example-1 type_decimal

  # given: synopsis

  $grammar->type_decimal({});

  # decimal(NULL, NULL)

=cut

=method type_double

The type_double method returns the SQL expression representing a double data
type.

=signature type_double

type_double(HashRef $data) : Str

=example-1 type_double

  # given: synopsis

  $grammar->type_double({});

  # double precision

=cut

=method type_enum

The type_enum method returns the SQL expression representing a enum data type.

=signature type_enum

type_enum(HashRef $data) : Str

=example-1 type_enum

  # given: synopsis

  $grammar->type_enum({ name => 'theme', options => ['light', 'dark'] });

  # varchar(225) check ("theme" in ('light', 'dark'))

=cut

=method type_float

The type_float method returns the SQL expression representing a float data
type.

=signature type_float

type_float(HashRef $data) : Str

=example-1 type_float

  # given: synopsis

  $grammar->type_float({});

  # double precision

=cut

=method type_integer

The type_integer method returns the SQL expression representing a integer data
type.

=signature type_integer

type_integer(HashRef $data) : Str

=example-1 type_integer

  # given: synopsis

  $grammar->type_integer({});

  # integer

=cut

=method type_integer_big

The type_integer_big method returns the SQL expression representing a
big-integer data type.

=signature type_integer_big

type_integer_big(HashRef $data) : Str

=example-1 type_integer_big

  # given: synopsis

  $grammar->type_integer_big({});

  # bigint

=cut

=method type_integer_big_unsigned

The type_integer_big_unsigned method returns the SQL expression representing a
big unsigned integer data type.

=signature type_integer_big_unsigned

type_integer_big_unsigned(HashRef $data) : Str

=example-1 type_integer_big_unsigned

  # given: synopsis

  $grammar->type_integer_big_unsigned({});

  # bigint

=cut

=method type_integer_medium

The type_integer_medium method returns the SQL expression representing a medium
integer data type.

=signature type_integer_medium

type_integer_medium(HashRef $data) : Str

=example-1 type_integer_medium

  # given: synopsis

  $grammar->type_integer_medium({});

  # integer

=cut

=method type_integer_medium_unsigned

The type_integer_medium_unsigned method returns the SQL expression representing
a unsigned medium integer data type.

=signature type_integer_medium_unsigned

type_integer_medium_unsigned(HashRef $data) : Str

=example-1 type_integer_medium_unsigned

  # given: synopsis

  $grammar->type_integer_medium_unsigned({});

  # integer

=cut

=method type_integer_small

The type_integer_small method returns the SQL expression representing a small
integer data type.

=signature type_integer_small

type_integer_small(HashRef $data) : Str

=example-1 type_integer_small

  # given: synopsis

  $grammar->type_integer_small({});

  # smallint

=cut

=method type_integer_small_unsigned

The type_integer_small_unsigned method returns the SQL expression representing
a unsigned small integer data type.

=signature type_integer_small_unsigned

type_integer_small_unsigned(HashRef $data) : Str

=example-1 type_integer_small_unsigned

  # given: synopsis

  $grammar->type_integer_small_unsigned({});

  # smallint

=cut

=method type_integer_tiny

The type_integer_tiny method returns the SQL expression representing a tiny
integer data type.

=signature type_integer_tiny

type_integer_tiny(HashRef $data) : Str

=example-1 type_integer_tiny

  # given: synopsis

  $grammar->type_integer_tiny({});

  # smallint

=cut

=method type_integer_tiny_unsigned

The type_integer_tiny_unsigned method returns the SQL expression representing a
unsigned tiny integer data type.

=signature type_integer_tiny_unsigned

type_integer_tiny_unsigned(HashRef $data) : Str

=example-1 type_integer_tiny_unsigned

  # given: synopsis

  $grammar->type_integer_tiny_unsigned({});

  # smallint

=cut

=method type_integer_unsigned

The type_integer_unsigned method returns the SQL expression representing a
unsigned integer data type.

=signature type_integer_unsigned

type_integer_unsigned(HashRef $data) : Str

=example-1 type_integer_unsigned

  # given: synopsis

  $grammar->type_integer_unsigned({});

  # integer

=cut

=method type_json

The type_json method returns the SQL expression representing a json data type.

=signature type_json

type_json(HashRef $data) : Str

=example-1 type_json

  # given: synopsis

  $grammar->type_json({});

  # json

=cut

=method type_number

The type_number method returns the SQL expression representing a number data
type.

=signature type_number

type_number(HashRef $data) : Str

=example-1 type_number

  # given: synopsis

  $grammar->type_number({});

  # integer

=cut

=method type_string

The type_string method returns the SQL expression representing a string data
type.

=signature type_string

type_string(HashRef $data) : Str

=example-1 type_string

  # given: synopsis

  $grammar->type_string({});

  # varchar(255)

=cut

=method type_text

The type_text method returns the SQL expression representing a text data type.

=signature type_text

type_text(HashRef $data) : Str

=example-1 type_text

  # given: synopsis

  $grammar->type_text({});

  # text

=cut

=method type_text_long

The type_text_long method returns the SQL expression representing a long text
data type.

=signature type_text_long

type_text_long(HashRef $data) : Str

=example-1 type_text_long

  # given: synopsis

  $grammar->type_text_long({});

  # text

=cut

=method type_text_medium

The type_text_medium method returns the SQL expression representing a medium
text data type.

=signature type_text_medium

type_text_medium(HashRef $data) : Str

=example-1 type_text_medium

  # given: synopsis

  $grammar->type_text_medium({});

  # text

=cut

=method type_time

The type_time method returns the SQL expression representing a time data type.

=signature type_time

type_time(HashRef $data) : Str

=example-1 type_time

  # given: synopsis

  $grammar->type_time({});

  # time(0) without time zone

=cut

=method type_time_wtz

The type_time_wtz method returns the SQL expression representing a time (and
timezone) data type.

=signature type_time_wtz

type_time_wtz(HashRef $data) : Str

=example-1 type_time_wtz

  # given: synopsis

  $grammar->type_time_wtz({});

  # time(0) with time zone

=cut

=method type_timestamp

The type_timestamp method returns the SQL expression representing a timestamp
data type.

=signature type_timestamp

type_timestamp(HashRef $data) : Str

=example-1 type_timestamp

  # given: synopsis

  $grammar->type_timestamp({});

  # timestamp(0) without time zone

=cut

=method type_timestamp_wtz

The type_timestamp_wtz method returns the SQL expression representing a
timestamp (and timezone) data type.

=signature type_timestamp_wtz

type_timestamp_wtz(HashRef $data) : Str

=example-1 type_timestamp_wtz

  # given: synopsis

  $grammar->type_timestamp_wtz({});

  # timestamp(0) with time zone

=cut

=method type_uuid

The type_uuid method returns the SQL expression representing a uuid data type.

=signature type_uuid

type_uuid(HashRef $data) : Str

=example-1 type_uuid

  # given: synopsis

  $grammar->type_uuid({});

  # uuid

=cut

=method wrap

The wrap method returns a SQL-escaped string.

=signature wrap

wrap(Str $name) : Str

=example-1 wrap

  # given: synopsis

  $grammar->wrap('field');

  # "field"

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'column_change', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'transaction', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_binary', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_boolean', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_char', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_date', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_datetime', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_datetime_wtz', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_decimal', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_double', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_enum', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_float', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_integer', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_integer_big', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_integer_big_unsigned', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_integer_medium', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_integer_medium_unsigned', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_integer_small', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_integer_small_unsigned', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_integer_tiny', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_integer_tiny_unsigned', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_integer_unsigned', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_json', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_number', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_string', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_text', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_text_long', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_text_medium', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_time', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_time_wtz', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_timestamp', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_timestamp_wtz', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type_uuid', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'wrap', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
