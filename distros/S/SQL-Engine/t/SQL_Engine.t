use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

SQL::Engine

=cut

=tagline

SQL Generation

=cut

=abstract

SQL Generation for Perl 5

=cut

=includes

method: column_change
method: column_create
method: column_drop
method: column_rename
method: constraint_create
method: constraint_drop
method: database_create
method: database_drop
method: delete
method: index_create
method: index_drop
method: insert
method: schema_create
method: schema_drop
method: schema_rename
method: select
method: table_create
method: table_drop
method: table_rename
method: transaction
method: update
method: view_create
method: view_drop
method: union

=cut

=synopsis

  use SQL::Engine;

  my $sql = SQL::Engine->new;

  $sql->insert(
    into => {
      table => 'users'
    },
    columns => [
      {
        column => 'id'
      },
      {
        column => 'name'
      }
    ],
    values => [
      {
        value => undef
      },
      {
        value => {
          binding => 'name'
        }
      },
    ]
  );

  # then, e.g.
  #
  # my $dbh = DBI->connect;
  #
  # for my $operation ($sql->operations->list) {
  #   my $statement = $operation->statement;
  #   my @bindings  = $operation->parameters({ name => 'Rob Zombie' });
  #
  #   my $sth = $dbh->prepate($statement);
  #
  #   $sth->execute(@bindings);
  # }
  #
  # $dbh->disconnect;

=cut

=libraries

Types::Standard

=cut

=attributes

grammar: ro, opt, Str
operations: ro, opt, InstanceOf["SQL::Engine::Collection"]
validator: ro, opt, Maybe[InstanceOf["SQL::Validator"]]

=cut

=description

This package provides an interface and builders which generate SQL statements,
by default using a standard SQL syntax or vendor-specific syntax if supported
and provided to the constructor using the I<"grammar"> property. This package
does not require a database connection, by design, which gives users complete
control over how connections and statement handles are managed.

=cut

=scenario validation

This package supports automatic validation of operations using
L<SQL::Validator> which can be passed to the constructor as the value of the
I<"validator"> property. This object will be generated if not provided.
Alternatively, automated validation can be disabled by passing the
I<"undefined"> value to the I<"validator"> property on object construction.
Doing so enhances the performance of SQL generation at the cost of not
verifying that the instructions provided are correct.

=example validation

  use SQL::Engine;

  my $sql = SQL::Engine->new(
    validator => undef
  );

  # faster, no-validation

  $sql->select(
    from => {
      table => 'users'
    },
    columns => [
      {
        column => '*'
      }
    ]
  );

=cut

=method column_change

The column_change method produces SQL operations which changes a table column
definition. The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::ColumnChange>.

=signature column_change

column_change(Any %args) : Object

=example-1 column_change

  # given: synopsis

  $sql->operations->clear;

  $sql->column_change(
    for => {
      table => 'users'
    },
    column => {
      name => 'accessed',
      type => 'datetime',
      nullable => 1
    }
  );

=cut

=method column_create

The column_create method produces SQL operations which create a new table
column. The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::ColumnCreate>.

=signature column_create

column_create(Any %args) : Object

=example-1 column_create

  # given: synopsis

  $sql->operations->clear;

  $sql->column_create(
    for => {
      table => 'users'
    },
    column => {
      name => 'accessed',
      type => 'datetime'
    }
  );

=cut

=method column_drop

The column_drop method produces SQL operations which removes an existing table
column. The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::ColumnDrop>.

=signature column_drop

column_drop(Any %args) : Object

=example-1 column_drop

  # given: synopsis

  $sql->operations->clear;

  $sql->column_drop(
    table => 'users',
    column => 'accessed'
  );

=cut

=method column_rename

The column_rename method produces SQL operations which renames an existing
table column. The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::ColumnRename>.

=signature column_rename

column_rename(Any %args) : Object

=example-1 column_rename

  # given: synopsis

  $sql->operations->clear;

  $sql->column_rename(
    for => {
      table => 'users'
    },
    name => {
      old => 'accessed',
      new => 'accessed_at'
    }
  );

=cut

=method constraint_create

The constraint_create method produces SQL operations which creates a new table
constraint. The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::ConstraintCreate>.

=signature constraint_create

constraint_create(Any %args) : Object

=example-1 constraint_create

  # given: synopsis

  $sql->operations->clear;

  $sql->constraint_create(
    source => {
      table => 'users',
      column => 'profile_id'
    },
    target => {
      table => 'profiles',
      column => 'id'
    }
  );

=cut

=method constraint_drop

The constraint_drop method produces SQL operations which removes an existing
table constraint. The arguments expected are the constructor arguments accepted
by L<SQL::Engine::Builder::ConstraintDrop>.

=signature constraint_drop

constraint_drop(Any %args) : Object

=example-1 constraint_drop

  # given: synopsis

  $sql->operations->clear;

  $sql->constraint_drop(
    source => {
      table => 'users',
      column => 'profile_id'
    },
    target => {
      table => 'profiles',
      column => 'id'
    }
  );

=cut

=method database_create

The database_create method produces SQL operations which creates a new
database. The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::DatabaseCreate>.

=signature database_create

database_create(Any %args) : Object

=example-1 database_create

  # given: synopsis

  $sql->operations->clear;

  $sql->database_create(
    name => 'todoapp'
  );

=cut

=method database_drop

The database_drop method produces SQL operations which removes an existing
database. The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::DatabaseDrop>.

=signature database_drop

database_drop(Any %args) : Object

=example-1 database_drop

  # given: synopsis

  $sql->operations->clear;

  $sql->database_drop(
    name => 'todoapp'
  );

=cut

=method delete

The delete method produces SQL operations which deletes rows from a table. The
arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::Delete>.

=signature delete

delete(Any %args) : Object

=example-1 delete

  # given: synopsis

  $sql->operations->clear;

  $sql->delete(
    from => {
      table => 'tasklists'
    }
  );

=cut

=method index_create

The index_create method produces SQL operations which creates a new table
index. The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::IndexCreate>.

=signature index_create

index_create(Any %args) : Object

=example-1 index_create

  # given: synopsis

  $sql->operations->clear;

  $sql->index_create(
    for => {
      table => 'users'
    },
    columns => [
      {
        column => 'name'
      }
    ]
  );

=cut

=method index_drop

The index_drop method produces SQL operations which removes an existing table
index. The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::IndexDrop>.

=signature index_drop

index_drop(Any %args) : Object

=example-1 index_drop

  # given: synopsis

  $sql->operations->clear;

  $sql->index_drop(
    for => {
      table => 'users'
    },
    columns => [
      {
        column => 'name'
      }
    ]
  );

=cut

=method insert

The insert method produces SQL operations which inserts rows into a table. The
arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::Insert>.

=signature insert

insert(Any %args) : Object

=example-1 insert

  # given: synopsis

  $sql->operations->clear;

  $sql->insert(
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
  );

=cut

=method schema_create

The schema_create method produces SQL operations which creates a new schema.
The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::SchemaCreate>.

=signature schema_create

schema_create(Any %args) : Object

=example-1 schema_create

  # given: synopsis

  $sql->operations->clear;

  $sql->schema_create(
    name => 'private',
  );

=cut

=method schema_drop

The schema_drop method produces SQL operations which removes an existing
schema. The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::SchemaDrop>.

=signature schema_drop

schema_drop(Any %args) : Object

=example-1 schema_drop

  # given: synopsis

  $sql->operations->clear;

  $sql->schema_drop(
    name => 'private',
  );

=cut

=method schema_rename

The schema_rename method produces SQL operations which renames an existing
schema. The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::SchemaRename>.

=signature schema_rename

schema_rename(Any %args) : Object

=example-1 schema_rename

  # given: synopsis

  $sql->operations->clear;

  $sql->schema_rename(
    name => {
      old => 'private',
      new => 'restricted'
    }
  );

=cut

=method select

The select method produces SQL operations which select rows from a table. The
arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::Select>.

=signature select

select(Any %args) : Object

=example-1 select

  # given: synopsis

  $sql->operations->clear;

  $sql->select(
    from => {
      table => 'people'
    },
    columns => [
      { column => 'name' }
    ]
  );

=cut

=method table_create

The table_create method produces SQL operations which creates a new table. The
arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::TableCreate>.

=signature table_create

table_create(Any %args) : Object

=example-1 table_create

  # given: synopsis

  $sql->operations->clear;

  $sql->table_create(
    name => 'users',
    columns => [
      {
        name => 'id',
        type => 'integer',
        primary => 1
      }
    ]
  );

=cut

=method table_drop

The table_drop method produces SQL operations which removes an existing table.
The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::TableDrop>.

=signature table_drop

table_drop(Any %args) : Object

=example-1 table_drop

  # given: synopsis

  $sql->operations->clear;

  $sql->table_drop(
    name => 'people'
  );

=cut

=method table_rename

The table_rename method produces SQL operations which renames an existing
table. The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::TableRename>.

=signature table_rename

table_rename(Any %args) : Object

=example-1 table_rename

  # given: synopsis

  $sql->operations->clear;

  $sql->table_rename(
    name => {
      old => 'peoples',
      new => 'people'
    }
  );

=cut

=method transaction

The transaction method produces SQL operations which represents an atomic
database operation. The arguments expected are the constructor arguments
accepted by L<SQL::Engine::Builder::Transaction>.

=signature transaction

transaction(Any %args) : Object

=example-1 transaction

  # given: synopsis

  $sql->operations->clear;

  $sql->transaction(
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
  );

=cut

=method update

The update method produces SQL operations which update rows in a table. The
arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::Update>.

=signature update

update(Any %args) : Object

=example-1 update

  # given: synopsis

  $sql->operations->clear;

  $sql->update(
    for => {
      table => 'users'
    },
    columns => [
      {
        column => 'updated',
        value => { function => ['now'] }
      }
    ]
  );

=cut

=method view_create

The view_create method produces SQL operations which creates a new table view.
The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::ViewCreate>.

=signature view_create

view_create(Any %args) : Object

=example-1 view_create

  # given: synopsis

  $sql->operations->clear;

  $sql->view_create(
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
  );

=cut

=method view_drop

The view_drop method produces SQL operations which removes an existing table
view. The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::ViewDrop>.

=signature view_drop

view_drop(Any %args) : Object

=example-1 view_drop

  # given: synopsis

  $sql->operations->clear;

  $sql->view_drop(
    name => 'active_users'
  );

=cut

=method union

The union method produces SQL operations which returns a results from two or
more select queries. The arguments expected are the constructor arguments
accepted by L<SQL::Engine::Builder::Union>.

=signature union

union(Any %args) : Object

=example-1 union

  # given: synopsis

  $sql->operations->clear;

  $sql->union(
    queries => [
      {
        select => {
          from => {
            table => 'customers',
          },
          columns => [
            {
              column => 'name',
            }
          ]
        }
      },
      {
        select => {
          from => {
            table => 'employees',
          },
          columns => [
            {
              column => 'name',
            }
          ]
        }
      }
    ]
  );

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->scenario('validation', fun($tryable) {
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

$subs->example(-1, 'column_drop', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'column_rename', 'method', fun($tryable) {
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

$subs->example(-1, 'index_create', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'index_drop', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'insert', 'method', fun($tryable) {
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

$subs->example(-1, 'transaction', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'update', 'method', fun($tryable) {
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

$subs->example(-1, 'union', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
