package SQL::Engine;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

use SQL::Engine::Collection;
use SQL::Validator;

our $VERSION = '0.03'; # VERSION

# ATTRIBUTES

has grammar => (
  is  => 'ro',
  isa => 'Str',
  opt => 1
);

has operations => (
  is  => 'ro',
  isa => 'InstanceOf["SQL::Engine::Collection"]',
  new => 1
);

fun new_operations($self) {

  SQL::Engine::Collection->new;
}

has validator => (
  is => 'ro',
  isa => 'Maybe[InstanceOf["SQL::Validator"]]',
  new => 1
);

fun new_validator($self) {
  SQL::Validator->new(
    $ENV{SQL_ENGINE_SCHEMA}
    ? (schema => $ENV{SQL_ENGINE_SCHEMA})
    : (version => '0.0')
  )
}

# METHODS

method column_change(@args) {
  require SQL::Engine::Builder::ColumnChange;

  my $grammar = SQL::Engine::Builder::ColumnChange->new(@args)->grammar(
    grammar => $self->grammar,
    validator => $self->validator
  );

  $self->operations->push($grammar->execute->operations->list);

  return $self;
}

method column_create(@args) {
  require SQL::Engine::Builder::ColumnCreate;

  my $grammar = SQL::Engine::Builder::ColumnCreate->new(@args)->grammar(
    grammar => $self->grammar,
    validator => $self->validator
  );

  $self->operations->push($grammar->execute->operations->list);

  return $self;
}

method column_drop(@args) {
  require SQL::Engine::Builder::ColumnDrop;

  my $grammar = SQL::Engine::Builder::ColumnDrop->new(@args)->grammar(
    grammar => $self->grammar,
    validator => $self->validator
  );

  $self->operations->push($grammar->execute->operations->list);

  return $self;
}

method column_rename(@args) {
  require SQL::Engine::Builder::ColumnRename;

  my $grammar = SQL::Engine::Builder::ColumnRename->new(@args)->grammar(
    grammar => $self->grammar,
    validator => $self->validator
  );

  $self->operations->push($grammar->execute->operations->list);

  return $self;
}

method constraint_create(@args) {
  require SQL::Engine::Builder::ConstraintCreate;

  my $grammar = SQL::Engine::Builder::ConstraintCreate->new(@args)->grammar(
    grammar => $self->grammar,
    validator => $self->validator
  );

  $self->operations->push($grammar->execute->operations->list);

  return $self;
}

method constraint_drop(@args) {
  require SQL::Engine::Builder::ConstraintDrop;

  my $grammar = SQL::Engine::Builder::ConstraintDrop->new(@args)->grammar(
    grammar => $self->grammar,
    validator => $self->validator
  );

  $self->operations->push($grammar->execute->operations->list);

  return $self;
}

method database_create(@args) {
  require SQL::Engine::Builder::DatabaseCreate;

  my $grammar = SQL::Engine::Builder::DatabaseCreate->new(@args)->grammar(
    grammar => $self->grammar,
    validator => $self->validator
  );

  $self->operations->push($grammar->execute->operations->list);

  return $self;
}

method database_drop(@args) {
  require SQL::Engine::Builder::DatabaseDrop;

  my $grammar = SQL::Engine::Builder::DatabaseDrop->new(@args)->grammar(
    grammar => $self->grammar,
    validator => $self->validator
  );

  $self->operations->push($grammar->execute->operations->list);

  return $self;
}

method delete(@args) {
  require SQL::Engine::Builder::Delete;

  my $grammar = SQL::Engine::Builder::Delete->new(@args)->grammar(
    grammar => $self->grammar,
    validator => $self->validator
  );

  $self->operations->push($grammar->execute->operations->list);

  return $self;
}

method index_create(@args) {
  require SQL::Engine::Builder::IndexCreate;

  my $grammar = SQL::Engine::Builder::IndexCreate->new(@args)->grammar(
    grammar => $self->grammar,
    validator => $self->validator
  );

  $self->operations->push($grammar->execute->operations->list);

  return $self;
}

method index_drop(@args) {
  require SQL::Engine::Builder::IndexDrop;

  my $grammar = SQL::Engine::Builder::IndexDrop->new(@args)->grammar(
    grammar => $self->grammar,
    validator => $self->validator
  );

  $self->operations->push($grammar->execute->operations->list);

  return $self;
}

method insert(@args) {
  require SQL::Engine::Builder::Insert;

  my $grammar = SQL::Engine::Builder::Insert->new(@args)->grammar(
    grammar => $self->grammar,
    validator => $self->validator
  );

  $self->operations->push($grammar->execute->operations->list);

  return $self;
}

method schema_create(@args) {
  require SQL::Engine::Builder::SchemaCreate;

  my $grammar = SQL::Engine::Builder::SchemaCreate->new(@args)->grammar(
    grammar => $self->grammar,
    validator => $self->validator
  );

  $self->operations->push($grammar->execute->operations->list);

  return $self;
}

method schema_drop(@args) {
  require SQL::Engine::Builder::SchemaDrop;

  my $grammar = SQL::Engine::Builder::SchemaDrop->new(@args)->grammar(
    grammar => $self->grammar,
    validator => $self->validator
  );

  $self->operations->push($grammar->execute->operations->list);

  return $self;
}

method schema_rename(@args) {
  require SQL::Engine::Builder::SchemaRename;

  my $grammar = SQL::Engine::Builder::SchemaRename->new(@args)->grammar(
    grammar => $self->grammar,
    validator => $self->validator
  );

  $self->operations->push($grammar->execute->operations->list);

  return $self;
}

method select(@args) {
  require SQL::Engine::Builder::Select;

  my $grammar = SQL::Engine::Builder::Select->new(@args)->grammar(
    grammar => $self->grammar,
    validator => $self->validator
  );

  $self->operations->push($grammar->execute->operations->list);

  return $self;
}

method table_create(@args) {
  require SQL::Engine::Builder::TableCreate;

  my $grammar = SQL::Engine::Builder::TableCreate->new(@args)->grammar(
    grammar => $self->grammar,
    validator => $self->validator
  );

  $self->operations->push($grammar->execute->operations->list);

  return $self;
}

method table_drop(@args) {
  require SQL::Engine::Builder::TableDrop;

  my $grammar = SQL::Engine::Builder::TableDrop->new(@args)->grammar(
    grammar => $self->grammar,
    validator => $self->validator
  );

  $self->operations->push($grammar->execute->operations->list);

  return $self;
}

method table_rename(@args) {
  require SQL::Engine::Builder::TableRename;

  my $grammar = SQL::Engine::Builder::TableRename->new(@args)->grammar(
    grammar => $self->grammar,
    validator => $self->validator
  );

  $self->operations->push($grammar->execute->operations->list);

  return $self;
}

method transaction(@args) {
  require SQL::Engine::Builder::Transaction;

  my $grammar = SQL::Engine::Builder::Transaction->new(@args)->grammar(
    grammar => $self->grammar,
    validator => $self->validator
  );

  $self->operations->push($grammar->execute->operations->list);

  return $self;
}

method update(@args) {
  require SQL::Engine::Builder::Update;

  my $grammar = SQL::Engine::Builder::Update->new(@args)->grammar(
    grammar => $self->grammar,
    validator => $self->validator
  );

  $self->operations->push($grammar->execute->operations->list);

  return $self;
}

method view_create(@args) {
  require SQL::Engine::Builder::ViewCreate;

  my $grammar = SQL::Engine::Builder::ViewCreate->new(@args)->grammar(
    grammar => $self->grammar,
    validator => $self->validator
  );

  $self->operations->push($grammar->execute->operations->list);

  return $self;
}

method view_drop(@args) {
  require SQL::Engine::Builder::ViewDrop;

  my $grammar = SQL::Engine::Builder::ViewDrop->new(@args)->grammar(
    grammar => $self->grammar,
    validator => $self->validator
  );

  $self->operations->push($grammar->execute->operations->list);

  return $self;
}

method union(@args) {
  require SQL::Engine::Builder::Union;

  my $grammar = SQL::Engine::Builder::Union->new(@args)->grammar(
    grammar => $self->grammar,
    validator => $self->validator
  );

  $self->operations->push($grammar->execute->operations->list);

  return $self;
}

1;

=encoding utf8

=head1 NAME

SQL::Engine - SQL Generation

=cut

=head1 ABSTRACT

SQL Generation for Perl 5

=cut

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This package provides an interface and builders which generate SQL statements,
by default using a standard SQL syntax or vendor-specific syntax if supported
and provided to the constructor using the I<"grammar"> property. This package
does not require a database connection, by design, which gives users complete
control over how connections and statement handles are managed.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 SCENARIOS

This package supports the following scenarios:

=cut

=head2 validation

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

This package supports automatic validation of operations using
L<SQL::Validator> which can be passed to the constructor as the value of the
I<"validator"> property. This object will be generated if not provided.
Alternatively, automated validation can be disabled by passing the
I<"undefined"> value to the I<"validator"> property on object construction.
Doing so enhances the performance of SQL generation at the cost of not
verifying that the instructions provided are correct.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 grammar

  grammar(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 operations

  operations(InstanceOf["SQL::Engine::Collection"])

This attribute is read-only, accepts C<(InstanceOf["SQL::Engine::Collection"])> values, and is optional.

=cut

=head2 validator

  validator(Maybe[InstanceOf["SQL::Validator"]])

This attribute is read-only, accepts C<(Maybe[InstanceOf["SQL::Validator"]])> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 column_change

  column_change(Any %args) : Object

The column_change method produces SQL operations which changes a table column
definition. The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::ColumnChange>.

=over 4

=item column_change example #1

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

=back

=cut

=head2 column_create

  column_create(Any %args) : Object

The column_create method produces SQL operations which create a new table
column. The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::ColumnCreate>.

=over 4

=item column_create example #1

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

=back

=cut

=head2 column_drop

  column_drop(Any %args) : Object

The column_drop method produces SQL operations which removes an existing table
column. The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::ColumnDrop>.

=over 4

=item column_drop example #1

  # given: synopsis

  $sql->operations->clear;

  $sql->column_drop(
    table => 'users',
    column => 'accessed'
  );

=back

=cut

=head2 column_rename

  column_rename(Any %args) : Object

The column_rename method produces SQL operations which renames an existing
table column. The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::ColumnRename>.

=over 4

=item column_rename example #1

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

=back

=cut

=head2 constraint_create

  constraint_create(Any %args) : Object

The constraint_create method produces SQL operations which creates a new table
constraint. The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::ConstraintCreate>.

=over 4

=item constraint_create example #1

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

=back

=cut

=head2 constraint_drop

  constraint_drop(Any %args) : Object

The constraint_drop method produces SQL operations which removes an existing
table constraint. The arguments expected are the constructor arguments accepted
by L<SQL::Engine::Builder::ConstraintDrop>.

=over 4

=item constraint_drop example #1

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

=back

=cut

=head2 database_create

  database_create(Any %args) : Object

The database_create method produces SQL operations which creates a new
database. The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::DatabaseCreate>.

=over 4

=item database_create example #1

  # given: synopsis

  $sql->operations->clear;

  $sql->database_create(
    name => 'todoapp'
  );

=back

=cut

=head2 database_drop

  database_drop(Any %args) : Object

The database_drop method produces SQL operations which removes an existing
database. The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::DatabaseDrop>.

=over 4

=item database_drop example #1

  # given: synopsis

  $sql->operations->clear;

  $sql->database_drop(
    name => 'todoapp'
  );

=back

=cut

=head2 delete

  delete(Any %args) : Object

The delete method produces SQL operations which deletes rows from a table. The
arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::Delete>.

=over 4

=item delete example #1

  # given: synopsis

  $sql->operations->clear;

  $sql->delete(
    from => {
      table => 'tasklists'
    }
  );

=back

=cut

=head2 index_create

  index_create(Any %args) : Object

The index_create method produces SQL operations which creates a new table
index. The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::IndexCreate>.

=over 4

=item index_create example #1

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

=back

=cut

=head2 index_drop

  index_drop(Any %args) : Object

The index_drop method produces SQL operations which removes an existing table
index. The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::IndexDrop>.

=over 4

=item index_drop example #1

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

=back

=cut

=head2 insert

  insert(Any %args) : Object

The insert method produces SQL operations which inserts rows into a table. The
arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::Insert>.

=over 4

=item insert example #1

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

=back

=cut

=head2 schema_create

  schema_create(Any %args) : Object

The schema_create method produces SQL operations which creates a new schema.
The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::SchemaCreate>.

=over 4

=item schema_create example #1

  # given: synopsis

  $sql->operations->clear;

  $sql->schema_create(
    name => 'private',
  );

=back

=cut

=head2 schema_drop

  schema_drop(Any %args) : Object

The schema_drop method produces SQL operations which removes an existing
schema. The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::SchemaDrop>.

=over 4

=item schema_drop example #1

  # given: synopsis

  $sql->operations->clear;

  $sql->schema_drop(
    name => 'private',
  );

=back

=cut

=head2 schema_rename

  schema_rename(Any %args) : Object

The schema_rename method produces SQL operations which renames an existing
schema. The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::SchemaRename>.

=over 4

=item schema_rename example #1

  # given: synopsis

  $sql->operations->clear;

  $sql->schema_rename(
    name => {
      old => 'private',
      new => 'restricted'
    }
  );

=back

=cut

=head2 select

  select(Any %args) : Object

The select method produces SQL operations which select rows from a table. The
arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::Select>.

=over 4

=item select example #1

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

=back

=cut

=head2 table_create

  table_create(Any %args) : Object

The table_create method produces SQL operations which creates a new table. The
arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::TableCreate>.

=over 4

=item table_create example #1

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

=back

=cut

=head2 table_drop

  table_drop(Any %args) : Object

The table_drop method produces SQL operations which removes an existing table.
The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::TableDrop>.

=over 4

=item table_drop example #1

  # given: synopsis

  $sql->operations->clear;

  $sql->table_drop(
    name => 'people'
  );

=back

=cut

=head2 table_rename

  table_rename(Any %args) : Object

The table_rename method produces SQL operations which renames an existing
table. The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::TableRename>.

=over 4

=item table_rename example #1

  # given: synopsis

  $sql->operations->clear;

  $sql->table_rename(
    name => {
      old => 'peoples',
      new => 'people'
    }
  );

=back

=cut

=head2 transaction

  transaction(Any %args) : Object

The transaction method produces SQL operations which represents an atomic
database operation. The arguments expected are the constructor arguments
accepted by L<SQL::Engine::Builder::Transaction>.

=over 4

=item transaction example #1

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

=back

=cut

=head2 union

  union(Any %args) : Object

The union method produces SQL operations which returns a results from two or
more select queries. The arguments expected are the constructor arguments
accepted by L<SQL::Engine::Builder::Union>.

=over 4

=item union example #1

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

=back

=cut

=head2 update

  update(Any %args) : Object

The update method produces SQL operations which update rows in a table. The
arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::Update>.

=over 4

=item update example #1

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

=back

=cut

=head2 view_create

  view_create(Any %args) : Object

The view_create method produces SQL operations which creates a new table view.
The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::ViewCreate>.

=over 4

=item view_create example #1

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

=back

=cut

=head2 view_drop

  view_drop(Any %args) : Object

The view_drop method produces SQL operations which removes an existing table
view. The arguments expected are the constructor arguments accepted by
L<SQL::Engine::Builder::ViewDrop>.

=over 4

=item view_drop example #1

  # given: synopsis

  $sql->operations->clear;

  $sql->view_drop(
    name => 'active_users'
  );

=back

=cut

=head1 EXAMPLES

This distribution supports generating SQL statements using standard syntax or
using database-specific syntax if a I<grammar> is specified. The following is a
collection of examples covering the most common operations (using PostgreSQL
syntax):

=cut

=head2 setup

  use SQL::Engine;

  my $sql = SQL::Engine->new(
    grammar => 'postgres'
  );

  $sql->select(
    from => {
      table => 'people'
    },
    columns => [
      { column => 'name' }
    ]
  );

  $sql->operations->first->statement;

  # SELECT "name" FROM "people"

=cut

=head2 select

=over 4

=item select example #1

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

=item select example #1 output

  # SELECT * FROM "users"

=item select example #2

  $sql->select(
    from => {
      table => 'users'
    },
    columns => [
      {
        column => 'id'
      },
      {
        column => 'name'
      }
    ]
  );

=item select example #2 output

  # SELECT "id", "name" FROM "users"

=item select example #3

  $sql->select(
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
        eq => [{column => 'id'}, {binding => 'id'}]
      }
    ]
  );

=item select example #3 output

  # SELECT * FROM "users" WHERE "id" = ?

=item select example #4

  $sql->select(
    from => {
      table => 'users',
      alias => 'u'
    },
    columns => [
      {
        column => '*',
        alias => 'u'
      }
    ],
    joins => [
      {
        with => {
          table => 'tasklists',
          alias => 't'
        },
        having => [
          {
            eq => [
              {
                column => 'id',
                alias => 'u'
              },
              {
                column => 'user_id',
                alias => 't'
              }
            ]
          }
        ]
      }
    ],
    where => [
      {
        eq => [
          {
            column => 'id',
            alias => 'u'
          },
          {
            binding => 'id'
          }
        ]
      }
    ]
  );

=item select example #4 output

  # SELECT "u".* FROM "users" "u"
  # JOIN "tasklists" "t" ON "u"."id" = "t"."user_id" WHERE "u"."id" = ?

=item select example #5

  $sql->select(
    from => {
      table => 'tasklists'
    },
    columns => [
      {
        function => ['count', { column => 'user_id' }]
      }
    ],
    group_by => [
      {
        column => 'user_id'
      }
    ]
  );

=item select example #5 output

  # SELECT count("user_id") FROM "tasklists" GROUP BY "user_id"

=item select example #6

  $sql->select(
    from => {
      table => 'tasklists'
    },
    columns => [
      {
        function => ['count', { column => 'user_id' }]
      }
    ],
    group_by => [
      {
        column => 'user_id'
      }
    ],
    having => [
      {
        gt => [
          {
            function => ['count', { column => 'user_id' }]
          },
          1
        ]
      }
    ]
  );

=item select example #6 output

  # SELECT count("user_id") FROM "tasklists" GROUP BY "user_id" HAVING
  # count("user_id") > 1

=item select example #7

  $sql->select(
    from => {
      table => 'tasklists'
    },
    columns => [
      {
        column => '*'
      }
    ],
    order_by => [
      {
        column => 'user_id'
      }
    ]
  );

=item select example #7 output

  # SELECT * FROM "tasklists" ORDER BY "user_id"

=item select example #8

  $sql->select(
    from => {
      table => 'tasklists'
    },
    columns => [
      {
        column => '*'
      }
    ],
    order_by => [
      {
        column => 'user_id'
      },
      {
        column => 'id',
        sort => 'desc'
      }
    ]
  );

=item select example #8 output

  # SELECT * FROM "tasklists" ORDER BY "user_id", "id" DESC

=item select example #9

  $sql->select(
    from => {
      table => 'tasks'
    },
    columns => [
      {
        column => '*'
      }
    ],
    rows => {
      limit => 5
    }
  );

=item select example #9 output

  # SELECT * FROM "tasks" LIMIT 5

=item select example #10

  $sql->select(
    from => {
      table => 'tasks'
    },
    columns => [
      {
        column => '*'
      }
    ],
    rows => {
      limit => 5,
      offset => 1
    }
  );

=item select example #10 output

  # SELECT * FROM "tasks" LIMIT 5, OFFSET 1

=item select example #11

  $sql->select(
    from => [
      {
        table => 'tasklists',
        alias => 't1'
      },
      {
        table => 'tasks',
        alias => 't2'
      }
    ],
    columns => [
      {
        column => '*',
        alias => 't1'
      },
      {
        column => '*',
        alias => 't1'
      }
    ],
    where => [
      {
        eq => [
          {
            column => 'tasklist_id',
            alias => 't2'
          },
          {
            column => 'id',
            alias => 't1'
          }
        ]
      }
    ]
  );

=item select example #11 output

  # SELECT "t1".*, "t1".* FROM "tasklists" "t1", "tasks" "t2"
  # WHERE "t2"."tasklist_id" = "t1"."id"

=back

=cut

=head2 insert

=over 4

=item insert example #1

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

=item insert example #1 output

  # INSERT INTO "users" VALUES (NULL, 'Rob Zombie', now(), now(), now())

=item insert example #2

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
      },
      {
        column => 'created'
      },
      {
        column => 'updated'
      },
      {
        column => 'deleted'
      }
    ],
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

=item insert example #2 output

  # INSERT INTO "users" ("id", "name", "created", "updated", "deleted")
  # VALUES (NULL, 'Rob Zombie', now(), now(), now())

=item insert example #3

  $sql->insert(
    into => {
      table => 'users'
    },
    default => 1
  );

=item insert example #3 output

  # INSERT INTO "users" DEFAULT VALUES

=item insert example #4

  $sql->insert(
    into => {
      table => 'users'
    },
    columns => [
      {
        column => 'name'
      },
      {
        column => 'user_id'
      }
    ],
    query => {
      select => {
        from => {
          table => 'users'
        },
        columns => [
          {
            column => 'name'
          },
          {
            column => 'id'
          }
        ]
      }
    }
  );

=item insert example #4 output

  # INSERT INTO "users" ("name", "user_id") SELECT "name", "id" FROM "users"

=item insert example #5

  $sql->insert(
    into => {
      table => 'users'
    },
    columns => [
      {
        column => 'name'
      },
      {
        column => 'user_id'
      }
    ],
    query => {
      select => {
        from => {
          table => 'users'
        },
        columns => [
          {
            column => 'name'
          },
          {
            column => 'id'
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

=item insert example #5 output

  # INSERT INTO "users" ("name", "user_id") SELECT "name", "id" FROM "users"
  # WHERE "deleted" IS NOT NULL

=back

=cut

=head2 update

=over 4

=item update example #1

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

=item update example #1 output

  # UPDATE "users" SET "updated" = now()

=item update example #2

  $sql->update(
    for => {
      table => 'users'
    },
    columns => [
      {
        column => 'name',
        value => { function => ['concat', '[deleted]', ' ', { column => 'name' }] }
      }
    ],
    where => [
      {
        'not-null' => {
          column => 'deleted'
        }
      }
    ]
  );

=item update example #2 output

  # UPDATE "users" SET "name" = concat('[deleted]', ' ', "name") WHERE
  # "deleted" IS NOT NULL

=item update example #3

  $sql->update(
    for => {
      table => 'users',
      alias => 'u1'
    },
    columns => [
      {
        column => 'updated',
        alias => 'u1',
        value => { function => ['now'] }
      }
    ],
    where => [
      {
        in => [
          {
            column => 'id',
            alias => 'u1'
          },
          {
            subquery => {
              select => {
                from => {
                  table => 'users',
                  alias => 'u2'
                },
                columns => [
                  {
                    column => 'id',
                    alias => 'u2'
                  }
                ],
                joins => [
                  {
                    with => {
                      table => 'tasklists',
                      alias => 't1'
                    },
                    having => [
                      {
                        eq => [
                          {
                            column => 'id',
                            alias => 'u2'
                          },
                          {
                            column => 'user_id',
                            alias => 't1'
                          }
                        ]
                      }
                    ]
                  }
                ],
                where => [
                  {
                    eq => [
                      {
                        column => 'id',
                        alias => 'u2'
                      },
                      {
                        binding => 'user_id'
                      }
                    ]
                  }
                ]
              }
            }
          }
        ]
      }
    ]
  );

=item update example #3 output

  # UPDATE "users" "u1" SET "u1"."updated" = now() WHERE "u1"."id" IN (SELECT
  # "u2"."id" FROM "users" "u2" JOIN "tasklists" "t1" ON "u2"."id" =
  # "t1"."user_id" WHERE "u2"."id" = ?)

=back

=cut

=head2 delete

=over 4

=item delete example #1

  $sql->delete(
    from => {
      table => 'tasklists'
    }
  );

=item delete example #1 output

  # DELETE FROM "tasklists"

=item delete example #2

  $sql->delete(
    from => {
      table => 'tasklists'
    },
    where => [
      {
        'not-null' => {
          column => 'deleted'
        }
      }
    ]
  );

=item delete example #2 output

  # DELETE FROM "tasklists" WHERE "deleted" IS NOT NULL

=back

=cut

=head2 table-create

=over 4

=item table-create example #1

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

=item table-create example #1 output

  # CREATE TABLE "users" ("id" integer PRIMARY KEY)

=item table-create example #2

  $sql->table_create(
    name => 'users',
    columns => [
      {
        name => 'id',
        type => 'integer',
        primary => 1
      },
      {
        name => 'name',
        type => 'text',
      },
      {
        name => 'created',
        type => 'datetime',
      },
      {
        name => 'updated',
        type => 'datetime',
      },
      {
        name => 'deleted',
        type => 'datetime',
      },
    ]
  );

=item table-create example #2 output

  # CREATE TABLE "users" ("id" integer PRIMARY KEY, "name" text, "created"
  # timestamp(0) without time zone, "updated" timestamp(0) without time zone,
  # "deleted" timestamp(0) without time zone)

=item table-create example #3

  $sql->table_create(
    name => 'users',
    columns => [
      {
        name => 'id',
        type => 'integer',
        primary => 1
      },
      {
        name => 'name',
        type => 'text',
      },
      {
        name => 'created',
        type => 'datetime',
      },
      {
        name => 'updated',
        type => 'datetime',
      },
      {
        name => 'deleted',
        type => 'datetime',
      },
    ],
    temp => 1
  );

=item table-create example #3 output

  # CREATE TEMPORARY TABLE "users" ("id" integer PRIMARY KEY, "name" text,
  # "created" timestamp(0) without time zone, "updated" timestamp(0) without
  # time zone, "deleted" timestamp(0) without time zone)

=item table-create example #4

  $sql->table_create(
    name => 'people',
    query => {
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

=item table-create example #4 output

  # CREATE TABLE "people" AS SELECT * FROM "users"

=back

=cut

=head2 table-drop

=over 4

=item table-drop example #1

  $sql->table_drop(
    name => 'people'
  );

=item table-drop example #1 output

  # DROP TABLE "people"

=item table-drop example #2

  $sql->table_drop(
    name => 'people',
    condition => 'cascade'
  );

=item table-drop example #2 output

  # DROP TABLE "people" CASCADE

=back

=cut

=head2 table-rename

=over 4

=item table-rename example #1

  $sql->table_rename(
    name => {
      old => 'peoples',
      new => 'people'
    }
  );

=item table-rename example #1 output

  # ALTER TABLE "peoples" RENAME TO "people"

=back

=cut

=head2 index-create

=over 4

=item index-create example #1

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

=item index-create example #1 output

  # CREATE INDEX "index_users_name" ON "users" ("name")

=item index-create example #2

  $sql->index_create(
    for => {
      table => 'users'
    },
    columns => [
      {
        column => 'email'
      }
    ],
    unique => 1
  );

=item index-create example #2 output

  # CREATE UNIQUE INDEX "unique_users_email" ON "users" ("email")

=item index-create example #3

  $sql->index_create(
    for => {
      table => 'users'
    },
    columns => [
      {
        column => 'name'
      }
    ],
    name => 'user_name_index'
  );

=item index-create example #3 output

  # CREATE INDEX "user_name_index" ON "users" ("name")

=item index-create example #4

  $sql->index_create(
    for => {
      table => 'users'
    },
    columns => [
      {
        column => 'email'
      }
    ],
    name => 'user_email_unique',
    unique => 1
  );

=item index-create example #4 output

  # CREATE UNIQUE INDEX "user_email_unique" ON "users" ("email")

=item index-create example #5

  $sql->index_create(
    for => {
      table => 'users'
    },
    columns => [
      {
        column => 'login'
      },
      {
        column => 'email'
      }
    ]
  );

=item index-create example #5 output

  # CREATE INDEX "index_users_login_email" ON "users" ("login", "email")

=back

=cut

=head2 index-drop

=over 4

=item index-drop example #1

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

=item index-drop example #1 output

  # DROP INDEX "index_users_name"

=item index-drop example #2

  $sql->index_drop(
    for => {
      table => 'users'
    },
    columns => [
      {
        column => 'email'
      }
    ],
    unique => 1
  );

=item index-drop example #2 output

  # DROP INDEX "unique_users_email"

=item index-drop example #3

  $sql->index_drop(
    for => {
      table => 'users'
    },
    columns => [
      {
        column => 'name'
      }
    ],
    name => 'user_email_unique'
  );

=item index-drop example #3 output

  # DROP INDEX "user_email_unique"

=back

=cut

=head2 column-change

=over 4

=item column-change example #1

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

=item column-change example #1 output

  # BEGIN TRANSACTION
  # ALTER TABLE "users" ALTER "accessed" TYPE timestamp(0) without time zone
  # ALTER TABLE "users" ALTER "accessed" DROP NOT NULL
  # ALTER TABLE "users" ALTER "accessed" DROP DEFAULT
  # COMMIT

=item column-change example #2

  $sql->column_change(
    for => {
      table => 'users'
    },
    column => {
      name => 'accessed',
      type => 'datetime',
      default => { function => ['now'] }
    }
  );

=item column-change example #2 output

  # BEGIN TRANSACTION
  # ALTER TABLE "users" ALTER "accessed" TYPE timestamp(0) without time zone
  # ALTER TABLE "users" ALTER "accessed" SET DEFAULT now()
  # COMMIT

=item column-change example #3

  $sql->column_change(
    for => {
      table => 'users'
    },
    column => {
      name => 'accessed',
      type => 'datetime',
      default => { function => ['now'] },
      nullable => 1,
    }
  );

=item column-change example #3 output

  # BEGIN TRANSACTION
  # ALTER TABLE "users" ALTER "accessed" TYPE timestamp(0) without time zone
  # ALTER TABLE "users" ALTER "accessed" DROP NOT NULL
  # ALTER TABLE "users" ALTER "accessed" SET DEFAULT now()
  # COMMIT

=back

=cut

=head2 column-create

=over 4

=item column-create example #1

  $sql->column_create(
    for => {
      table => 'users'
    },
    column => {
      name => 'accessed',
      type => 'datetime'
    }
  );

=item column-create example #1 output

  # ALTER TABLE "users" ADD COLUMN "accessed" timestamp(0) without time zone

=item column-create example #2

  $sql->column_create(
    for => {
      table => 'users'
    },
    column => {
      name => 'accessed',
      type => 'datetime',
      nullable => 1
    }
  );

=item column-create example #2 output

  # ALTER TABLE "users" ADD COLUMN "accessed" timestamp(0) without time zone
  # NULL

=item column-create example #3

  $sql->column_create(
    for => {
      table => 'users'
    },
    column => {
      name => 'accessed',
      type => 'datetime',
      nullable => 1,
      default => {
        function => ['now']
      }
    }
  );

=item column-create example #3 output

  # ALTER TABLE "users" ADD COLUMN "accessed" timestamp(0) without time zone
  # NULL DEFAULT now()

=item column-create example #4

  $sql->column_create(
    for => {
      table => 'users'
    },
    column => {
      name => 'ref',
      type => 'uuid',
      primary => 1
    }
  );

=item column-create example #4 output

  # ALTER TABLE "users" ADD COLUMN "ref" uuid PRIMARY KEY

=back

=cut

=head2 column-drop

=over 4

=item column-drop example #1

  $sql->column_drop(
    table => 'users',
    column => 'accessed'
  );

=item column-drop example #1 output

  # ALTER TABLE "users" DROP COLUMN "accessed"

=back

=cut

=head2 column-rename

=over 4

=item column-rename example #1

  $sql->column_rename(
    for => {
      table => 'users'
    },
    name => {
      old => 'accessed',
      new => 'accessed_at'
    }
  );

=item column-rename example #1 output

  # ALTER TABLE "users" RENAME COLUMN "accessed" TO "accessed_at"

=back

=cut

=head2 constraint-create

=over 4

=item constraint-create example #1

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

=item constraint-create example #1 output

  # ALTER TABLE "users" ADD CONSTRAINT "foreign_users_profile_id_profiles_id"
  # FOREIGN KEY ("profile_id") REFERENCES "profiles" ("id")

=item constraint-create example #2

  $sql->constraint_create(
    source => {
      table => 'users',
      column => 'profile_id'
    },
    target => {
      table => 'profiles',
      column => 'id'
    },
    name => 'user_profile_id'
  );

=item constraint-create example #2 output

  # ALTER TABLE "users" ADD CONSTRAINT "user_profile_id" FOREIGN KEY
  # ("profile_id") REFERENCES "profiles" ("id")

=item constraint-create example #3

  $sql->constraint_create(
    on => {
      update => 'cascade',
      delete => 'cascade'
    },
    source => {
      table => 'users',
      column => 'profile_id'
    },
    target => {
      table => 'profiles',
      column => 'id'
    },
    name => 'user_profile_id'
  );

=item constraint-create example #3 output

  # ALTER TABLE "users" ADD CONSTRAINT "user_profile_id" FOREIGN KEY
  # ("profile_id") REFERENCES "profiles" ("id") ON DELETE CASCADE ON UPDATE
  # CASCADE

=back

=cut

=head2 constraint-drop

=over 4

=item constraint-drop example #1

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

=item constraint-drop example #1 output

  # ALTER TABLE "users" DROP CONSTRAINT "foreign_users_profile_id_profiles_id"

=item constraint-drop example #2

  $sql->constraint_drop(
    source => {
      table => 'users',
      column => 'profile_id'
    },
    target => {
      table => 'profiles',
      column => 'id'
    },
    name => 'user_profile_id'
  );

=item constraint-drop example #2 output

  # ALTER TABLE "users" DROP CONSTRAINT "user_profile_id"

=back

=cut

=head2 database-create

=over 4

=item database-create example #1

  $sql->database_create(
    name => 'todoapp'
  );

=item database-create example #1 output

  # CREATE DATABASE "todoapp"

=back

=cut

=head2 database-drop

=over 4

=item database-drop example #1

  $sql->database_drop(
    name => 'todoapp'
  );

=item database-drop example #1 output

  # DROP DATABASE "todoapp"

=back

=cut

=head2 schema-create

=over 4

=item schema-create example #1

  $sql->schema_create(
    name => 'private',
  );

=item schema-create example #1 output

  # CREATE SCHEMA "private"

=back

=cut

=head2 schema-drop

=over 4

=item schema-drop example #1

  $sql->schema_drop(
    name => 'private',
  );

=item schema-drop example #1 output

  # DROP SCHEMA "private"

=back

=cut

=head2 schema-rename

=over 4

=item schema-rename example #1

  $sql->schema_rename(
    name => {
      old => 'private',
      new => 'restricted'
    }
  );

=item schema-rename example #1 output

  # ALTER SCHEMA "private" RENAME TO "restricted"

=back

=cut

=head2 transaction

=over 4

=item transaction example #1

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

=item transaction example #1 output

  # BEGIN TRANSACTION
  # CREATE TABLE "users" ("id" integer PRIMARY KEY)
  # COMMIT

=item transaction example #2

  $sql->transaction(
    mode => [
      'exclusive'
    ],
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

=item transaction example #2 output

  # BEGIN TRANSACTION EXCLUSIVE
  # CREATE TABLE "users" ("id" integer PRIMARY KEY)
  # COMMIT

=back

=cut

=head2 view-create

=over 4

=item view-create example #1

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

=item view-create example #1 output

  # CREATE VIEW "active_users" AS SELECT * FROM "users" WHERE "deleted" IS NOT
  # NULL

=item view-create example #2

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
    },
    temp => 1
  );

=item view-create example #2 output

  # CREATE TEMPORARY VIEW "active_users" AS SELECT * FROM "users" WHERE
  # "deleted" IS NOT NULL

=back

=cut

=head2 view-drop

=over 4

=item view-drop example #1

  $sql->view_drop(
    name => 'active_users'
  );

=item view-drop example #1 output

  # DROP VIEW "active_users"

=back

=cut

=head2 union

=over 4

=item union example #1

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

=item union example #1 output

  # (SELECT "name" FROM "customers") UNION (SELECT "name" FROM "employees")

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
