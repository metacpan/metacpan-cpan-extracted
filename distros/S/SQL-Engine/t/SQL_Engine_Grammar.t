use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

SQL::Engine::Grammar

=cut

=tagline

Standard Grammar

=cut

=abstract

SQL::Engine Standard Grammar

=cut

=includes

method: binding
method: column_change
method: column_create
method: column_definition
method: column_drop
method: column_rename
method: column_specification
method: constraint_create
method: constraint_drop
method: constraint_name
method: constraint_option
method: criteria
method: criterion
method: database_create
method: database_drop
method: delete
method: execute
method: expression
method: index_create
method: index_drop
method: index_name
method: insert
method: name
method: operation
method: process
method: schema_create
method: schema_drop
method: schema_rename
method: select
method: table
method: table_create
method: table_drop
method: table_rename
method: term
method: transaction
method: type
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
method: update
method: validate
method: value
method: view_create
method: view_drop
method: wrap

=cut

=synopsis

  use SQL::Engine::Grammar;

  my $grammar = SQL::Engine::Grammar->new(
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

=attributes

operations: ro, opt, InstanceOf["SQL::Engine::Collection"]
schema: ro, req, HashRef
validator: ro, opt, Maybe[InstanceOf["SQL::Validator"]]

=cut

=description

This package provides methods for converting
L<json-sql|https://github.com/iamalnewkirk/json-sql> data structures into
SQL statements.

=cut

=method binding

The binding method registers a SQL statement binding (or placeholder).

=signature binding

binding(Str $name) : Str

=example-1 binding

  # given: synopsis

  $grammar->binding('user_id');
  $grammar->binding('user_id');
  $grammar->binding('user_id');
  $grammar->binding('user_id');
  $grammar->binding('user_id');

=cut

=method column_change

The column_change method generates SQL statements to change a column
definition.

=signature column_change

column_change(HashRef $data) : Object

=example-1 column_change

  my $grammar = SQL::Engine::Grammar->new({
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
  });

  $grammar->column_change($grammar->schema->{'column-change'});

=cut

=method column_create

The column_create method generates SQL statements to add a new table column.

=signature column_create

column_create(HashRef $data) : Object

=example-1 column_create

  # given: synopsis

  $grammar->column_create({
    for => {
      table => 'users'
    },
    column => {
      name => 'accessed',
      type => 'datetime'
    }
  });

=cut

=method column_definition

The column_definition method column definition SQL statement fragments.

=signature column_definition

column_definition(HashRef $data) : HashRef

=example-1 column_definition

  # given: synopsis

  my $column_definition = $grammar->column_definition({
    name => 'id',
    type => 'number',
    primary => 1
  });

=cut

=method column_drop

The column_drop method generates SQL statements to remove a table column.

=signature column_drop

column_drop(HashRef $data) : Object

=example-1 column_drop

  # given: synopsis

  $grammar->column_drop({
    table => 'users',
    column => 'accessed'
  });

=cut

=method column_rename

The column_rename method generates SQL statements to rename a table column.

=signature column_rename

column_rename(HashRef $data) : Object

=example-1 column_rename

  # given: synopsis

  $grammar->column_rename({
    for => {
      table => 'users'
    },
    name => {
      old => 'accessed',
      new => 'accessed_at'
    }
  });

=cut

=method column_specification

The column_specification method a column definition SQL statment partial.

=signature column_specification

column_specification(HashRef $data) : Str

=example-1 column_specification

  # given: synopsis

  my $column_specification = $grammar->column_specification({
    name => 'id',
    type => 'number',
    primary => 1
  });

=cut

=method constraint_create

The constraint_create method generates SQL statements to create a table
constraint.

=signature constraint_create

constraint_create(HashRef $data) : Object

=example-1 constraint_create

  # given: synopsis

  $grammar->constraint_create({
    source => {
      table => 'users',
      column => 'profile_id'
    },
    target => {
      table => 'profiles',
      column => 'id'
    }
  });

=cut

=method constraint_drop

The constraint_drop method generates SQL statements to remove a table
constraint.

=signature constraint_drop

constraint_drop(HashRef $data) : Object

=example-1 constraint_drop

  # given: synopsis

  $grammar->constraint_drop({
    source => {
      table => 'users',
      column => 'profile_id'
    },
    target => {
      table => 'profiles',
      column => 'id'
    }
  });

=cut

=method constraint_name

The constraint_name method returns the generated constraint name.

=signature constraint_name

constraint_name(HashRef $data) : Str

=example-1 constraint_name

  # given: synopsis

  my $constraint_name = $grammar->constraint_name({
    source => {
      table => 'users',
      column => 'profile_id'
    },
    target => {
      table => 'profiles',
      column => 'id'
    }
  });

=cut

=method constraint_option

The constraint_option method returns a SQL expression for the constraint option
provided.

=signature constraint_option

constraint_option(Str $name) : Str

=example-1 constraint_option

  # given: synopsis

  $grammar->constraint_option('no-action');

=cut

=method criteria

The criteria method returns a list of SQL expressions.

=signature criteria

criteria(ArrayRef $data) : ArrayRef[Str]

=example-1 criteria

  # given: synopsis

  my $criteria = $grammar->criteria([
    {
      eq => [{ column => 'id' }, 123]
    },
    {
      'not-null' => { column => 'deleted' }
    }
  ]);

=cut

=method criterion

The criterion method returns a SQL expression.

=signature criterion

criterion(HashRef $data) : Str

=example-1 criterion

  # given: synopsis

  my $criterion = $grammar->criterion({
    in => [{ column => 'theme' }, 'light', 'dark']
  });

=cut

=method database_create

The database_create method generates SQL statements to create a database.

=signature database_create

database_create(HashRef $data) : Object

=example-1 database_create

  # given: synopsis

  $grammar->database_create({
    name => 'todoapp'
  });

=cut

=method database_drop

The database_drop method generates SQL statements to remove a database.

=signature database_drop

database_drop(HashRef $data) : Object

=example-1 database_drop

  # given: synopsis

  $grammar->database_drop({
    name => 'todoapp'
  });

=cut

=method delete

The delete method generates SQL statements to delete table rows.

=signature delete

delete(HashRef $data) : Object

=example-1 delete

  # given: synopsis

  $grammar->delete({
    from => {
      table => 'tasklists'
    }
  });

=cut

=method execute

The execute method validates and processes the object instruction.

=signature execute

execute() : Object

=example-1 execute

  # given: synopsis

  $grammar->operations->clear;

  $grammar->execute;

=cut

=method expression

The expression method returns a SQL expression representing the data provided.

=signature expression

expression(Any $data) : Any

=example-1 expression

  # given: synopsis

  $grammar->expression(undef);

  # NULL

=cut

=method index_create

The index_create method generates SQL statements to create a table index.

=signature index_create

index_create(HashRef $data) : Object

=example-1 index_create

  # given: synopsis

  $grammar->index_create({
    for => {
      table => 'users'
    },
    columns => [
      {
        column => 'name'
      }
    ]
  });

=cut

=method index_drop

The index_drop method generates SQL statements to remove a table index.

=signature index_drop

index_drop(HashRef $data) : Object

=example-1 index_drop

  # given: synopsis

  $grammar->index_drop({
    for => {
      table => 'users'
    },
    columns => [
      {
        column => 'name'
      }
    ]
  });

=cut

=method index_name

The index_name method returns the generated index name.

=signature index_name

index_name(HashRef $data) : Str

=example-1 index_name

  # given: synopsis

  my $index_name = $grammar->index_name({
    for => {
      table => 'users'
    },
    columns => [
      {
        column => 'email'
      }
    ],
    unique => 1
  });

=cut

=method insert

The insert method generates SQL statements to insert table rows.

=signature insert

insert(HashRef $data) : Object

=example-1 insert

  # given: synopsis

  $grammar->insert({
    into => {
      table => 'users'
    },
    values => [
      {
        value => undef
      },
      {
        value => 'Rob Zombie'
      },
      {
        value => {
          function => ['now']
        }
      },
      {
        value => {
          function => ['now']
        }
      },
      {
        value => {
          function => ['now']
        }
      }
    ]
  });

=cut

=method name

The name method returns a qualified quoted object name.

=signature name

name(Any @args) : Str

=example-1 name

  # given: synopsis

  my $name = $grammar->name(undef, 'public', 'users');

  # "public"."users"

=cut

=method operation

The operation method creates and appends an operation to the I<"operations">
collection.

=signature operation

operation(Str $statement) : InstanceOf["SQL::Engine::Operation"]

=example-1 operation

  # given: synopsis

  $grammar->operation('SELECT TRUE');

=cut

=method process

The process method processes the object instructions.

=signature process

process(Mayb[HashRef] $schema) : Object

=example-1 process

  # given: synopsis

  $grammar->process;

=cut

=method schema_create

The schema_create method generates SQL statements to create a schema.

=signature schema_create

schema_create(HashRef $data) : Object

=example-1 schema_create

  # given: synopsis

  $grammar->schema_create({
    name => 'private',
  });

=cut

=method schema_drop

The schema_drop method generates SQL statements to remove a schema.

=signature schema_drop

schema_drop(HashRef $data) : Object

=example-1 schema_drop

  # given: synopsis

  $grammar->schema_drop({
    name => 'private',
  });

=cut

=method schema_rename

The schema_rename method generates SQL statements to rename a schema.

=signature schema_rename

schema_rename(HashRef $data) : Object

=example-1 schema_rename

  # given: synopsis

  $grammar->schema_rename({
    name => {
      old => 'private',
      new => 'restricted'
    }
  });

=cut

=method select

The select method generates SQL statements to select table rows.

=signature select

select(HashRef $data) : Object

=example-1 select

  # given: synopsis

  $grammar->select({
    from => {
      table => 'people'
    },
    columns => [
      { column => 'name' }
    ]
  });

=cut

=method table

The table method returns a qualified quoted table name.

=signature table

table(HashRef $data) : Str

=example-1 table

  # given: synopsis

  my $table = $grammar->table({
    schema => 'public',
    table => 'users',
    alias => 'u'
  });

=cut

=method table_create

The table_create method generates SQL statements to create a table.

=signature table_create

table_create(HashRef $data) : Object

=example-1 table_create

  # given: synopsis

  $grammar->table_create({
    name => 'users',
    columns => [
      {
        name => 'id',
        type => 'integer',
        primary => 1
      }
    ]
  });

=cut

=method table_drop

The table_drop method generates SQL statements to remove a table.

=signature table_drop

table_drop(HashRef $data) : Object

=example-1 table_drop

  # given: synopsis

  $grammar->table_drop({
    name => 'people'
  });

=cut

=method table_rename

The table_rename method generates SQL statements to rename a table.

=signature table_rename

table_rename(HashRef $data) : Object

=example-1 table_rename

  # given: synopsis

  $grammar->table_rename({
    name => {
      old => 'peoples',
      new => 'people'
    }
  });

=cut

=method term

The term method returns a SQL keyword.

=signature term

term(Str @args) : Str

=example-1 term

  # given: synopsis

  $grammar->term('end');

=cut

=method transaction

The transaction method generates SQL statements to commit an atomic database
transaction.

=signature transaction

transaction(HashRef $data) : Object

=example-1 transaction

  my $grammar = SQL::Engine::Grammar->new({
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
  });

  $grammar->transaction($grammar->schema->{'transaction'});

=cut

=method type

The type method return the SQL representation for a data type.

=signature type

type(HashRef $data) : Str

=example-1 type

  # given: synopsis

  $grammar->type({
    type => 'datetime-wtz'
  });

  # datetime

=cut

=method type_binary

The type_binary method returns the SQL expression representing a binary data
type.

=signature type_binary

type_binary(HashRef $data) : Str

=example-1 type_binary

  # given: synopsis

  $grammar->type_binary({});

  # blob

=cut

=method type_boolean

The type_boolean method returns the SQL expression representing a boolean data
type.

=signature type_boolean

type_boolean(HashRef $data) : Str

=example-1 type_boolean

  # given: synopsis

  $grammar->type_boolean({});

  # tinyint(1)

=cut

=method type_char

The type_char method returns the SQL expression representing a char data type.

=signature type_char

type_char(HashRef $data) : Str

=example-1 type_char

  # given: synopsis

  $grammar->type_char({});

  # varchar

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

  # datetime

=cut

=method type_datetime_wtz

The type_datetime_wtz method returns the SQL expression representing a datetime
(and timezone) data type.

=signature type_datetime_wtz

type_datetime_wtz(HashRef $data) : Str

=example-1 type_datetime_wtz

  # given: synopsis

  $grammar->type_datetime_wtz({});

  # datetime

=cut

=method type_decimal

The type_decimal method returns the SQL expression representing a decimal data
type.

=signature type_decimal

type_decimal(HashRef $data) : Str

=example-1 type_decimal

  # given: synopsis

  $grammar->type_decimal({});

  # numeric

=cut

=method type_double

The type_double method returns the SQL expression representing a double data
type.

=signature type_double

type_double(HashRef $data) : Str

=example-1 type_double

  # given: synopsis

  $grammar->type_double({});

  # float

=cut

=method type_enum

The type_enum method returns the SQL expression representing a enum data type.

=signature type_enum

type_enum(HashRef $data) : Str

=example-1 type_enum

  # given: synopsis

  $grammar->type_enum({});

  # varchar

=cut

=method type_float

The type_float method returns the SQL expression representing a float data
type.

=signature type_float

type_float(HashRef $data) : Str

=example-1 type_float

  # given: synopsis

  $grammar->type_float({});

  # float

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

  # integer

=cut

=method type_integer_big_unsigned

The type_integer_big_unsigned method returns the SQL expression representing a
big unsigned integer data type.

=signature type_integer_big_unsigned

type_integer_big_unsigned(HashRef $data) : Str

=example-1 type_integer_big_unsigned

  # given: synopsis

  $grammar->type_integer_big_unsigned({});

  # integer

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

  # integer

=cut

=method type_integer_small_unsigned

The type_integer_small_unsigned method returns the SQL expression representing
a unsigned small integer data type.

=signature type_integer_small_unsigned

type_integer_small_unsigned(HashRef $data) : Str

=example-1 type_integer_small_unsigned

  # given: synopsis

  $grammar->type_integer_small_unsigned({});

  # integer

=cut

=method type_integer_tiny

The type_integer_tiny method returns the SQL expression representing a tiny
integer data type.

=signature type_integer_tiny

type_integer_tiny(HashRef $data) : Str

=example-1 type_integer_tiny

  # given: synopsis

  $grammar->type_integer_tiny({});

  # integer

=cut

=method type_integer_tiny_unsigned

The type_integer_tiny_unsigned method returns the SQL expression representing a
unsigned tiny integer data type.

=signature type_integer_tiny_unsigned

type_integer_tiny_unsigned(HashRef $data) : Str

=example-1 type_integer_tiny_unsigned

  # given: synopsis

  $grammar->type_integer_tiny_unsigned({});

  # integer

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

  # text

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

  # varchar

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

  # time

=cut

=method type_time_wtz

The type_time_wtz method returns the SQL expression representing a time (and
timezone) data type.

=signature type_time_wtz

type_time_wtz(HashRef $data) : Str

=example-1 type_time_wtz

  # given: synopsis

  $grammar->type_time_wtz({});

  # time

=cut

=method type_timestamp

The type_timestamp method returns the SQL expression representing a timestamp
data type.

=signature type_timestamp

type_timestamp(HashRef $data) : Str

=example-1 type_timestamp

  # given: synopsis

  $grammar->type_timestamp({});

  # datetime

=cut

=method type_timestamp_wtz

The type_timestamp_wtz method returns the SQL expression representing a
timestamp (and timezone) data type.

=signature type_timestamp_wtz

type_timestamp_wtz(HashRef $data) : Str

=example-1 type_timestamp_wtz

  # given: synopsis

  $grammar->type_timestamp_wtz({});

  # datetime

=cut

=method type_uuid

The type_uuid method returns the SQL expression representing a uuid data type.

=signature type_uuid

type_uuid(HashRef $data) : Str

=example-1 type_uuid

  # given: synopsis

  $grammar->type_uuid({});

  # varchar

=cut

=method update

The update method generates SQL statements to update table rows.

=signature update

update(HashRef $data) : Object

=example-1 update

  # given: synopsis

  $grammar->update({
    for => {
      table => 'users'
    },
    columns => [
      {
        column => 'updated',
        value => { function => ['now'] }
      }
    ]
  });

=cut

=method validate

The validate method validates the data structure defined in the I<"schema">
property.

=signature validate

validate() : Bool

=example-1 validate

  # given: synopsis

  my $valid = $grammar->validate;

=cut

=method value

The value method returns the SQL representation of a value.

=signature value

value(Any $value) : Str

=example-1 value

  # given: synopsis

  $grammar->value(undef);

  # NULL

=cut

=method view_create

The view_create method generates SQL statements to create a table view.

=signature view_create

view_create(HashRef $data) : Object

=example-1 view_create

  # given: synopsis

  $grammar->view_create({
    name => 'active_users',
    query => {
      select => {
        from => {
          table => 'users'
        },
        columns => [
          {
            column => '*'
          }
        ],
        where => [
          {
            'not-null' => {
              column => 'deleted'
            }
          }
        ]
      }
    }
  });

=cut

=method view_drop

The view_drop method generates SQL statements to remove a table view.

=signature view_drop

view_drop(HashRef $data) : Object

=example-1 view_drop

  # given: synopsis

  $grammar->view_drop({
    name => 'active_users'
  });

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

$subs->example(-1, 'binding', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'column_change', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'column_create', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'column_definition', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'column_drop', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'column_rename', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'column_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'constraint_create', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'constraint_drop', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'constraint_name', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'constraint_option', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'criteria', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'criterion', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'database_create', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'database_drop', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'delete', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'execute', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'expression', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'index_create', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'index_drop', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'index_name', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'insert', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'name', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'operation', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'process', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'schema_create', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'schema_drop', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'schema_rename', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'select', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'table', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'table_create', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'table_drop', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'table_rename', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'term', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'transaction', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'type', 'method', fun($tryable) {
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

$subs->example(-1, 'update', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'validate', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'value', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'view_create', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'view_drop', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'wrap', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
