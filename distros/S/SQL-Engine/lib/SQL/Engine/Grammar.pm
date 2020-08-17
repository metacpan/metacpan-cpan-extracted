package SQL::Engine::Grammar;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

use SQL::Engine::Collection;
use SQL::Engine::Operation;
use SQL::Validator;

use Scalar::Util ();

our $VERSION = '0.03'; # VERSION

# ATTRIBUTES

has operations => (
  is  => 'ro',
  isa => 'InstanceOf["SQL::Engine::Collection"]',
  new => 1
);

fun new_operations($self) {

  SQL::Engine::Collection->new;
}

has schema => (
  is => 'ro',
  isa => 'HashRef',
  req => 1
);

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

method binding(Str $name) {
  $self->{bindings}{int(keys(%{$self->{bindings}}))} = $name;

  return '?';
}

method column_change(HashRef $data) {
  my $sql = [];

  # alter table
  push @$sql, $self->term(qw(alter table));

  # safe
  push @$sql, $self->term(qw(if exists)) if $data->{safe};

  # for
  push @$sql, $self->table($data->{for});

  # column
  push @$sql, $self->term(qw(alter column));

  # column specification
  push @$sql, $self->column_specification($data->{column});

  # sql statement
  my $result = join ' ', @$sql;

  return $self->operation($result);
}

method column_create(HashRef $data) {
  my $sql = [];

  # alter table
  push @$sql, $self->term(qw(alter table));

  # safe
  push @$sql, $self->term(qw(if exists)) if $data->{safe};

  # for
  push @$sql, $self->table($data->{for});

  # column
  push @$sql, $self->term(qw(add column));

  # column specification
  push @$sql, $self->column_specification($data->{column});

  # sql statement
  my $result = join ' ', @$sql;

  return $self->operation($result);
}

method column_definition(HashRef $data) {
  my $def = {};

  if ($data->{name}) {
    $def->{name} = $self->name($data->{name});
  }

  if ($data->{type}) {
    $def->{type} = $self->type($data);
  }

  if (exists $data->{default}) {
    $def->{default} = join ' ', $self->term('default'),
      $self->expression($data->{default});
  }

  if (exists $data->{nullable}) {
    $def->{nullable}
      = $data->{nullable} ? $self->term('null') : $self->term(qw(not null));
  }

  if ($data->{primary}) {
    $def->{primary} = $self->term(qw(primary key));
  }

  return $def;
}

method column_drop(HashRef $data) {
  my $sql = [];

  # alter table
  push @$sql, $self->term(qw(alter table));

  # safe
  push @$sql, $self->term(qw(if exists)) if $data->{safe};

  # table name
  push @$sql, $self->table($data);

  # drop column
  push @$sql, $self->term(qw(drop column));

  # safe
  push @$sql, $self->term(qw(if exists)) if $data->{safe};

  # column name
  push @$sql, $self->name($data->{column});

  # sql statement
  my $result = join ' ', @$sql;

  return $self->operation($result);
}

method column_specification(HashRef $data) {
  my $sql = [];

  my $column = $self->column_definition($data);

  # name
  push @$sql, $column->{name};

  # type
  push @$sql, $column->{type};

  # nullable
  push @$sql, $column->{nullable} if $column->{nullable};

  # default
  push @$sql, $column->{default} if $column->{default};

  # primary
  push @$sql, $column->{primary} if $column->{primary};

  # increments
  push @$sql, $column->{increment} if $column->{increment};

  # sql statement
  return join ' ', @$sql;
}

method column_rename(HashRef $data) {
  my $sql = [];

  # alter table
  push @$sql, $self->term(qw(alter table));

  # safe
  push @$sql, $self->term(qw(if exists)) if $data->{safe};

  # table name
  push @$sql, $self->table($data->{"for"});

  # rename column
  push @$sql, $self->term(qw(rename column)),
    $self->name($data->{name}{old}),
    $self->term('to'),
    $self->name($data->{name}{new});

  # sql statement
  my $result = join ' ', @$sql;

  return $self->operation($result);
}

method constraint_create(HashRef $data) {
  my $sql = [];

  # alter table
  push @$sql, $self->term(qw(alter table));

  # safe
  push @$sql, $self->term(qw(if exists)) if $data->{safe};

  # table name
  push @$sql, $self->table($data->{source});

  # add constraint
  push @$sql, $self->term(qw(add constraint));

  # constraint name
  push @$sql, $self->name($self->constraint_name($data));

  # foreign key
  push @$sql, $self->term(qw(foreign key));

  # column name
  push @$sql, sprintf('(%s)', $self->name($data->{source}{column}));

  # references
  push @$sql, $self->term('references');

  # foreign table and column name
  push @$sql, sprintf('%s (%s)', $self->table($data->{target}),
    $self->name($data->{target}{column}));

  # reference option (on delete)
  if ($data->{on}{delete}) {
    push @$sql, $self->term(qw(on delete)),
      $self->constraint_option($data->{on}{delete});
  }

  # reference option (on update)
  if ($data->{on}{update}) {
    push @$sql, $self->term(qw(on update)),
      $self->constraint_option($data->{on}{update});
  }

  # sql statement
  my $result = join ' ', @$sql;

  return $self->operation($result);
}

method constraint_drop(HashRef $data) {
  my $sql = [];

  # alter table
  push @$sql, $self->term(qw(alter table));

  # safe
  push @$sql, $self->term(qw(if exists)) if $data->{safe};

  # table name
  push @$sql, $self->table($data->{source});

  # drop constraint
  push @$sql, $self->term(qw(drop constraint));

  # constraint name
  push @$sql, $self->name($self->constraint_name($data));

  # sql statement
  my $result = join ' ', @$sql;

  return $self->operation($result);
}

method constraint_name(HashRef $data) {

  return $data->{name} || join('_', 'foreign',
    join('_', grep {defined} @{$data->{source}}{qw(schema table column)}),
    join('_', grep {defined} @{$data->{target}}{qw(schema table column)})
  );
}

method constraint_option(Str $name) {
  if (lc($name) eq "cascade") {
    return $self->term('cascade');
  }
  elsif (lc($name) eq "no-action") {
    return $self->term(qw(no action));
  }
  elsif (lc($name) eq "restrict") {
    return $self->term('restrict');
  }
  elsif (lc($name) eq "set-default") {
    return $self->term(qw(set default));
  }
  elsif (lc($name) eq "set-null") {
    return $self->term(qw(set null));
  }
  else {
    return $self->term(qw(no action));
  }
}

method criteria(ArrayRef $data) {

  return [map $self->criterion($_), @$data];
}

method criterion(HashRef $data) {
  if (my $cond = $data->{"and"}) {
    return sprintf('(%s)',
      join(sprintf(' %s ', $self->term('and')), @{$self->criteria($cond)}));
  }

  if (my $cond = $data->{"eq"}) {
    return sprintf '%s = %s', map $self->expression($_), @$cond;
  }

  if (my $cond = $data->{"glob"}) {
    return sprintf '%s %s %s', $self->expression($cond->[0]),
      $self->term('glob'), $self->expression($cond->[1]);
  }

  if (my $cond = $data->{"gt"}) {
    return sprintf '%s > %s', map $self->expression($_), @$cond;
  }

  if (my $cond = $data->{"gte"}) {
    return sprintf '%s >= %s', map $self->expression($_), @$cond;
  }

  if (my $cond = $data->{"in"}) {
    return sprintf '%s %s %s', $self->expression($cond->[0]),
      $self->term('in'), join ', ', map $self->expression($_),
      @$cond[1 .. $#$cond];
  }

  if (my $cond = $data->{"is"}) {
    return sprintf '(%s)',
      (ref($cond) eq 'HASH')
        ? $self->expression($cond)
        : join(sprintf(' %s ', $self->term('and')), @{$self->criteria($cond)});
  }

  if (my $cond = $data->{"is-null"}) {
    return sprintf '%s IS NULL', $self->expression($cond);
  }

  if (my $cond = $data->{"like"}) {
    return sprintf '%s %s %s', $self->expression($cond->[0]),
      $self->term('like'), $self->expression($cond->[1]);
  }

  if (my $cond = $data->{"lt"}) {
    return sprintf '%s < %s', map $self->expression($_), @$cond;
  }

  if (my $cond = $data->{"lte"}) {
    return sprintf '%s <= %s', map $self->expression($_), @$cond;
  }

  if (my $cond = $data->{"ne"}) {
    return sprintf '%s != %s', map $self->expression($_), @$cond;
  }

  if (my $cond = $data->{"not"}) {
    return sprintf 'NOT (%s)',
      (ref($cond) eq 'HASH')
        ? $self->expression($cond)
        : join(sprintf(' %s ', $self->term('and')), @{$self->criteria($cond)});
  }

  if (my $cond = $data->{"not-null"}) {
    return sprintf '%s IS NOT NULL', $self->expression($cond);
  }

  if (my $cond = $data->{"or"}) {
    return sprintf('(%s)',
      join(sprintf(' %s ', $self->term('or')), @{$self->criteria($cond)}));
  }

  if (my $cond = $data->{"regexp"}) {
    return sprintf '%s %s %s', $self->expression($cond->[0]),
      $self->term('regexp'), $self->expression($cond->[1]);
  }
}

method delete(HashRef $data) {
  my $sql = [];

  # delete
  push @$sql, $self->term(qw(delete from));

  # from
  push @$sql, $self->table($data->{from});

  # where
  if (my $where = $data->{where}) {
    push @$sql, $self->term('where'),
      join(sprintf(' %s ', $self->term('and')), @{$self->criteria($where)});
  }

  # returning (postgres)
  if (my $returning = $data->{returning}) {
    push @$sql, $self->term('returning'),
      sprintf('(%s)', join(', ', map $self->expression($_), @$returning));
  }

  # sql statement
  my $result = join ' ', @$sql;

  return $self->operation($result);
}

method database_create(HashRef $data) {
  my $sql = [];

  # create database
  push @$sql, $self->term(qw(create database)),
    ($data->{safe} ? $self->term(qw(if not exists)) : ()),
    $self->name($data->{name});

  # sql statement
  my $result = join ' ', @$sql;

  return $self->operation($result);
}

method database_drop(HashRef $data) {
  my $sql = [];

  # drop database
  push @$sql, $self->term(qw(drop database)),
    ($data->{safe} ? $self->term(qw(if exists)) : ()),
    $self->name($data->{name});

  # sql statement
  my $result = join ' ', @$sql;

  return $self->operation($result);
}

method execute() {
  if ($self->validator and not $self->validate) {
    die $self->validator->error;
  }

  return $self->process;
}

method expression(Any $data) {
  if (!ref $data) {
    return $self->value($data); # literal
  }

  if (UNIVERSAL::isa($data, 'SCALAR')) {
    if ($$data eq '1') {
      return $self->term('true');
    }
    if ($$data eq '0') {
      return $self->term('false');
    }
  }

  if (my $expr = $data->{"as"}) {
    my ($alias, $other) = @$expr;
    return sprintf '%s %s %s',
      $self->expression($other),
      $self->term('as'),
      $alias;
  }

  if (my $expr = $data->{"binary"}) {
    if ($expr->{plus}) {
      return sprintf '(%s + %s)',
        map $self->expression($_), @{$expr->{plus}};
    }
    if ($expr->{minus}) {
      return sprintf '(%s - %s)',
        map $self->expression($_), @{$expr->{minus}};
    }
    if ($expr->{multiply}) {
      return sprintf '(%s * %s)',
        map $self->expression($_), @{$expr->{multiply}};
    }
    if ($expr->{divide}) {
      return sprintf '(%s / %s)',
        map $self->expression($_), @{$expr->{divide}};
    }
    if ($expr->{modulo}) {
      return sprintf '(%s % %s)',
        map $self->expression($_), @{$expr->{modulo}};
    }
  }

  if ($data->{"binding"}) {
    return $self->binding($data->{"binding"});
  }

  if (my $expr = $data->{"case"}) {
    return sprintf(
      '%s %s %s %s %s',
      $self->term('case'),
      join(
        ' ',
        map {
          sprintf '%s %s %s %s', $self->term('when'),
            ($self->expression($$_{cond}) || $self->criterion($$_{cond})),
            $self->term('then'), $self->expression($$_{then});
        } @{$expr->{"when"}}
      ),
      $self->term('else'),
      $self->expression($expr->{"else"}),
      $self->term('end')
    );
  }

  if ($data->{"cast"}) {
    return sprintf(
      '%s(%s)',
      $self->term('cast'),
      join(
        sprintf(' %s ', $self->term('as')),
        map $self->expression($_),
        @{$data->{"cast"}}
      )
    );
  }

  if ($data->{"column"}) {
    return $self->name($data->{"alias"}, $data->{"column"});
  }

  if ($data->{"function"}) {
    my ($name, @args) = @{$data->{"function"}};
    return sprintf('%s(%s)',
      $name, join(', ', @args ? (map $self->expression($_), @args) : ''));
  }

  if (my $expr = $data->{"subquery"}) {
    $self->select($expr->{select});
    my $operation = $self->operations->pop;
    $self->{bindings} = $operation->bindings;
    return sprintf('(%s)', $operation->statement);
  }

  if (my $expr = $data->{"unary"}) {
    if ($expr->{"plus"}) {
      return sprintf '+%s', $self->expression($expr->{"plus"});
    }
    if ($expr->{"minus"}) {
      return sprintf '-%s', $self->expression($expr->{"minus"});
    }
  }

  if (my $expr = $data->{"verbatim"}) {
    my @verbatim = @{$data->{"verbatim"}};
    return join(' ', $verbatim[0],
      join(', ', map $self->expression($_), @verbatim[1..$#verbatim]));
  }
}

method join_option(Maybe[Str] $name) {
  if (!$name) {
    return $self->term(qw(join));
  }
  if (lc($name) eq "left-join") {
    return $self->term(qw(left join));
  }
  elsif (lc($name) eq "right-join") {
    return $self->term(qw(right join));
  }
  elsif (lc($name) eq "full-join") {
    return $self->term(qw(full join));
  }
  elsif (lc($name) eq "inner-join") {
    return $self->term(qw(inner join));
  }
  else {
    return $self->term(qw(join));
  }
}

method name(Any @args) {

  return join '.', map { /\W/ ? $_ : $self->wrap($_) } grep {defined} @args;
}

method operation(Str $statement) {
  $self->operations->push(
    my $operation = SQL::Engine::Operation->new(
      bindings => delete $self->{bindings} || {},
      statement => $statement,
    )
  );

  return $operation;
}

method process(HashRef $schema = $self->schema) {
  if ($schema->{"select"}) {
    $self->select($schema->{"select"});

    return $self;
  }

  if ($schema->{"insert"}) {
    $self->insert($schema->{"insert"});

    return $self;
  }

  if ($schema->{"update"}) {
    $self->update($schema->{"update"});

    return $self;
  }

  if ($schema->{"delete"}) {
    $self->delete($schema->{"delete"});

    return $self;
  }

  if ($schema->{"column-change"}) {
    $self->column_change($schema->{"column-change"});

    return $self;
  }

  if ($schema->{"column-create"}) {
    $self->column_create($schema->{"column-create"});

    return $self;
  }

  if ($schema->{"column-drop"}) {
    $self->column_drop($schema->{"column-drop"});

    return $self;
  }

  if ($schema->{"column-rename"}) {
    $self->column_rename($schema->{"column-rename"});

    return $self;
  }

  if ($schema->{"constraint-create"}) {
    $self->constraint_create($schema->{"constraint-create"});

    return $self;
  }

  if ($schema->{"constraint-drop"}) {
    $self->constraint_drop($schema->{"constraint-drop"});

    return $self;
  }

  if ($schema->{"database-create"}) {
    $self->database_create($schema->{"database-create"});

    return $self;
  }

  if ($schema->{"database-drop"}) {
    $self->database_drop($schema->{"database-drop"});

    return $self;
  }

  if ($schema->{"index-create"}) {
    $self->index_create($schema->{"index-create"});

    return $self;
  }

  if ($schema->{"index-drop"}) {
    $self->index_drop($schema->{"index-drop"});

    return $self;
  }

  if ($schema->{"schema-create"}) {
    $self->schema_create($schema->{"schema-create"});

    return $self;
  }

  if ($schema->{"schema-drop"}) {
    $self->schema_drop($schema->{"schema-drop"});

    return $self;
  }

  if ($schema->{"schema-rename"}) {
    $self->schema_rename($schema->{"schema-rename"});

    return $self;
  }

  if ($schema->{"table-create"}) {
    $self->table_create($schema->{"table-create"});

    return $self;
  }

  if ($schema->{"table-drop"}) {
    $self->table_drop($schema->{"table-drop"});

    return $self;
  }

  if ($schema->{"transaction"}) {
    $self->transaction($schema->{"transaction"});

    return $self;
  }

  if ($schema->{"table-rename"}) {
    $self->table_rename($schema->{"table-rename"});

    return $self;
  }

  if ($schema->{"view-create"}) {
    $self->view_create($schema->{"view-create"});

    return $self;
  }

  if ($schema->{"view-drop"}) {
    $self->view_drop($schema->{"view-drop"});

    return $self;
  }

  if ($schema->{"union"}) {
    $self->union($schema->{"union"});

    return $self;
  }

  return $self;
}

method index_create(HashRef $data) {
  my $sql = [];

  # create
  push @$sql, $self->term('create');

  # unique
  push @$sql, $self->term('unique') if $data->{unique};

  # index
  push @$sql, $self->term('index');

  # safe
  push @$sql, $self->term(qw(if not exists)) if $data->{safe};

  # index name
  push @$sql, $self->wrap($self->index_name($data));

  # on table
  push @$sql, $self->term('on'), $self->table($data->{for});

  # columns
  push @$sql, sprintf('(%s)',
    join(', ', map $self->name($$_{alias}, $$_{column}), @{$data->{columns}}));

  # sql statement
  my $result = join ' ', @$sql;

  return $self->operation($result);
}

method index_drop(HashRef $data) {
  my $sql = [];

  # drop
  push @$sql, $self->term('drop');

  # index
  push @$sql, $self->term('index');

  # safe
  push @$sql, $self->term(qw(if exists)) if $data->{safe};

  # index name
  push @$sql, $self->wrap($self->index_name($data));

  # sql statement
  my $result = join ' ', @$sql;

  return $self->operation($result);
}

method index_name(HashRef $data) {
  return $data->{name} || join('_',
    ($data->{unique} ? 'unique' : 'index'),
    grep {defined} $data->{for}{schema}, $data->{for}{table},
      map $$_{column}, @{$data->{columns}}
  );
}

method insert(HashRef $data) {
  my $sql = [];

  # insert
  push @$sql, $self->term('insert');

  # into
  push @$sql, $self->term('into'), $self->table($data->{into});

  # columns
  if (my $columns = $data->{columns}) {
    push @$sql,
      sprintf('(%s)', join(', ', map $self->expression($_), @$columns));
  }

  # values
  if (my $values = $data->{values}) {
    push @$sql,
      sprintf('%s (%s)',
      $self->term('values'),
      join(', ', map $self->expression($$_{value}), @$values));
  }

  # query
  if (my $query = $data->{query}) {
    $self->select($query->{select});
    my $operation = $self->operations->pop;
    $self->{bindings} = $operation->bindings;
    push @$sql, $operation->statement;
  }

  # default
  if ($data->{default} && !$data->{values} && !$data->{values}) {
    push @$sql, $self->term('default'), $self->term('values');
  }

  # returning (postgres)
  if (my $returning = $data->{returning}) {
    push @$sql, $self->term('returning'),
      sprintf('(%s)', join(', ', map $self->expression($_), @$returning));
  }

  # sql statement
  my $result = join ' ', @$sql;

  return $self->operation($result);
}

method schema_create(HashRef $data) {
  my $sql = [];

  # create schema
  push @$sql, $self->term(qw(create schema)),
    ($data->{safe} ? $self->term(qw(if not exists)) : ()),
    $self->name($data->{name});

  # sql statement
  my $result = join ' ', @$sql;

  return $self->operation($result);
}

method schema_drop(HashRef $data) {
  my $sql = [];

  # drop schema
  push @$sql, $self->term(qw(drop schema)),
    ($data->{safe} ? $self->term(qw(if exists)) : ()),
    $self->name($data->{name});

  # sql statement
  my $result = join ' ', @$sql;

  return $self->operation($result);
}

method schema_rename(HashRef $data) {
  my $sql = [];

  # rename schema
  push @$sql, $self->term(qw(alter schema)),
    $self->name($data->{name}{old}),
    $self->term(qw(rename to)),
    $self->name($data->{name}{new});

  # sql statement
  my $result = join ' ', @$sql;

  return $self->operation($result);
}

method select(HashRef $data) {
  my $sql = [];

  # select
  push @$sql, $self->term('select');

  # columns
  if (my $columns = $data->{columns}) {
    push @$sql, join(', ', map $self->expression($_), @$columns);
  }

  # into (mssql)
  if (my $into = $data->{into}) {
    push @$sql, $self->term('into'), $self->name($into);
  }

  # from
  push @$sql, $self->term('from'),
    ref($data->{from}) eq 'ARRAY'
    ? join(', ', map $self->table($_), @{$data->{from}})
    : $self->table($data->{from});

  # joins
  if (my $joins = $data->{joins}) {
    for my $join (@$joins) {
      push @$sql, $self->join_option($join->{type}), $self->table($join->{with});
      push @$sql, $self->term('on'),
        join(
        sprintf(' %s ', $self->term('and')),
        @{$self->criteria($join->{having})}
        );
    }
  }

  # where
  if (my $where = $data->{where}) {
    push @$sql, $self->term('where'),
      join(sprintf(' %s ', $self->term('and')), @{$self->criteria($where)});
  }

  # group-by
  if (my $group_by = $data->{"group-by"}) {
    push @$sql, $self->term(qw(group by));
    push @$sql, join ', ', map $self->expression($_), @$group_by;

    # having
    if (my $having = $data->{"having"}) {
      push @$sql, $self->term('having'),
        join(sprintf(' %s ', $self->term('and')), @{$self->criteria($having)});
    }
  }

  # order-by
  if (my $orders = $data->{"order-by"}) {
    my @orders;
    push @$sql, $self->term(qw(order by));
    for my $order (@$orders) {
      if ($order->{sort}
        && ($order->{sort} eq 'asc' || $order->{sort} eq 'ascending'))
      {
        push @orders, sprintf '%s ASC',
          $self->name($order->{"alias"}, $order->{"column"});
      }
      elsif ($order->{sort}
        && ($order->{sort} eq 'desc' || $order->{sort} eq 'descending'))
      {
        push @orders, sprintf '%s DESC',
          $self->name($order->{"alias"}, $order->{"column"});
      }
      else {
        push @orders, $self->name($order->{"alias"}, $order->{"column"});
      }
    }
    push @$sql, join ', ', @orders;
  }

  # rows
  if (my $rows = $data->{rows}) {
    if ($rows->{limit} && $rows->{offset}) {
      push @$sql, sprintf '%s %d %s %d', $self->term('limit'), $rows->{limit},
        $self->term('offset'), $rows->{offset};
    }
    if ($rows->{limit} && !$rows->{offset}) {
      push @$sql, sprintf '%s %d', $self->term('limit'), $rows->{limit};
    }
  }

  # sql statement
  my $result = join ' ', @$sql;

  return $self->operation($result);
}

method table(HashRef $data) {
  my $name;

  my $table  = $data->{table};
  my $schema = $data->{schema};
  my $alias  = $data->{alias};

  $name = $self->name($schema, $table);
  $name = join ' ', $name, $self->wrap($alias) if $alias;

  return $name;
}

method table_create(HashRef $data) {
  my $sql = [];

  # create
  push @$sql, $self->term('create');

  # temporary
  if ($data->{temp}) {
    push @$sql, $self->term('temporary');
  }

  # table
  push @$sql, $self->term('table'),
    ($data->{safe} ? $self->term(qw(if not exists)) : ()),
    $self->name($data->{name});

  # body
  my $body = [];

  # columns
  if (my $columns = $data->{columns}) {
    push @$body, map $self->column_specification($_), @$columns;
  }

  # constraints
  if (my $constraints = $data->{constraints}) {
    # unique
    for my $constraint (grep {$_->{unique}} @{$constraints}) {
      if (my $unique = $constraint->{unique}) {
        my $name = $self->index_name({
          for => $data->{for},
          name => $unique->{name},
          columns => [map +{column => $_}, @{$unique->{columns}}],
          unique => 1,
        });
        push @$body, join ' ', $self->term('constraint'), $name,
          $self->term('unique'), sprintf '(%s)', join ', ',
          map $self->name($_), @{$unique->{columns}};
      }
    }
    # foreign
    for my $constraint (grep {$_->{foreign}} @{$constraints}) {
      if (my $foreign = $constraint->{foreign}) {
        my $name = $self->constraint_name({
          source => {
            table => $data->{name},
            column => $foreign->{column}
          },
          target => $foreign->{reference},
          name => $foreign->{name}
        });
        push @$body, join ' ', $self->term('constraint'), $name,
          $self->term(qw(foreign key)),
          sprintf('(%s)', $self->name($foreign->{column})),
          $self->term(qw(references)),
          sprintf('%s (%s)',
          $self->table($foreign->{reference}),
          $self->name($foreign->{reference}{column})),
          (
          $foreign->{on}{delete}
          ? (
            $self->term(qw(on delete)),
            $self->constraint_option($foreign->{on}{delete})
            )
          : ()
          ),
          (
          $foreign->{on}{update}
          ? (
            $self->term(qw(on update)),
            $self->constraint_option($foreign->{on}{update})
            )
          : ()
          );
      }
    }
  }

  # definition
  if (@$body) {
    push @$sql, sprintf('(%s)', join ', ', @$body);
  }

  # query
  if (my $query = $data->{query}) {
    $self->select($query->{select});
    my $operation = $self->operations->pop;
    $self->{bindings} = $operation->bindings;
    push @$sql, $self->term('as');
    push @$sql, $operation->statement;
  }

  # sql statement
  my $result = join ' ', @$sql;

  return $self->operation($result);
}

method table_drop(HashRef $data) {
  my $sql = [];

  # drop table
  push @$sql, $self->term(qw(drop table)),
    ($data->{safe} ? $self->term(qw(if exists)) : ()),
    $self->name($data->{name});

  # with condition
  if (my $condition = $data->{condition}) {
    push @$sql, $self->term($data->{condition});
  }

  # sql statement
  my $result = join ' ', @$sql;

  return $self->operation($result);
}

method table_rename(HashRef $data) {
  my $sql = [];

  # rename table
  push @$sql, $self->term(qw(alter table)),
    $self->name($data->{name}{old}),
    $self->term(qw(rename to)),
    $self->name($data->{name}{new});

  # sql statement
  my $result = join ' ', @$sql;

  return $self->operation($result);
}

method term(Str @args) {
  my $method = join '_', 'term', map lc, map {split /\s/} @args;

  if ($self->can($method)) {
    return $self->$method;
  }
  else {
    return join ' ', map uc, @args;
  }
}

method transaction(HashRef $data) {
  $self->operation($self->term('begin', 'transaction'));
  $self->process($_) for @{$data->{queries}};
  $self->operation($self->term('commit'));

  return $self;
}

method type(HashRef $data) {
  if ($data->{type} eq 'binary') {
    return $self->type_binary($data);
  }

  if ($data->{type} eq 'boolean') {
    return $self->type_boolean($data);
  }

  if ($data->{type} eq 'char') {
    return $self->type_char($data);
  }

  if ($data->{type} eq 'date') {
    return $self->type_date($data);
  }

  if ($data->{type} eq 'datetime') {
    return $self->type_datetime($data);
  }

  if ($data->{type} eq 'datetime-wtz') {
    return $self->type_datetime_wtz($data);
  }

  if ($data->{type} eq 'decimal') {
    return $self->type_decimal($data);
  }

  if ($data->{type} eq 'double') {
    return $self->type_double($data);
  }

  if ($data->{type} eq 'enum') {
    return $self->type_enum($data);
  }

  if ($data->{type} eq 'float') {
    return $self->type_float($data);
  }

  if ($data->{type} eq 'integer') {
    return $self->type_integer($data);
  }

  if ($data->{type} eq 'integer-big') {
    return $self->type_integer_big($data);
  }

  if ($data->{type} eq 'integer-big-unsigned') {
    return $self->type_integer_big_unsigned($data);
  }

  if ($data->{type} eq 'integer-medium') {
    return $self->type_integer_medium($data);
  }

  if ($data->{type} eq 'integer-medium-unsigned') {
    return $self->type_integer_medium_unsigned($data);
  }

  if ($data->{type} eq 'integer-small') {
    return $self->type_integer_small($data);
  }

  if ($data->{type} eq 'integer-small-unsigned') {
    return $self->type_integer_small_unsigned($data);
  }

  if ($data->{type} eq 'integer-tiny') {
    return $self->type_integer_tiny($data);
  }

  if ($data->{type} eq 'integer-tiny-unsigned') {
    return $self->type_integer_tiny_unsigned($data);
  }

  if ($data->{type} eq 'integer-unsigned') {
    return $self->type_integer_unsigned($data);
  }

  if ($data->{type} eq 'json') {
    return $self->type_json($data);
  }

  if ($data->{type} eq 'number') {
    return $self->type_number($data);
  }

  if ($data->{type} eq 'string') {
    return $self->type_string($data);
  }

  if ($data->{type} eq 'text') {
    return $self->type_text($data);
  }

  if ($data->{type} eq 'text-long') {
    return $self->type_text_long($data);
  }

  if ($data->{type} eq 'text-medium') {
    return $self->type_text_medium($data);
  }

  if ($data->{type} eq 'time') {
    return $self->type_time($data);
  }

  if ($data->{type} eq 'time-wtz') {
    return $self->type_time_wtz($data);
  }

  if ($data->{type} eq 'timestamp') {
    return $self->type_timestamp($data);
  }

  if ($data->{type} eq 'timestamp-wtz') {
    return $self->type_timestamp_wtz($data);
  }

  if ($data->{type} eq 'uuid') {
    return $self->type_uuid($data);
  }

  return $data->{type};
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

  return 'integer';
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

method update(HashRef $data) {
  my $sql = [];

  # update
  push @$sql, $self->term('update');

  # for
  push @$sql, $self->table($data->{for});

  # columns
  if (my $columns = $data->{columns}) {
    push @$sql, $self->term('set');
    push @$sql, join(
      ', ',
      map {
        sprintf('%s = %s',
          $self->name($$_{alias}, $$_{column}),
          $self->expression($$_{value}))
      } @$columns
    );
  }

  # where
  if (my $where = $data->{where}) {
    push @$sql, $self->term('where'),
      join(sprintf(' %s ', $self->term('and')), @{$self->criteria($where)});
  }

  # returning (postgres)
  if (my $returning = $data->{returning}) {
    push @$sql, $self->term('returning'),
      sprintf('(%s)', join(', ', map $self->expression($_), @$returning));
  }

  # sql statement
  my $result = join ' ', @$sql;

  return $self->operation($result);
}

method validate() {

  return $self->validator->validate($self->schema);
}

method value(Any $value) {

  return !defined $value ? $self->term('null') : (
    Scalar::Util::looks_like_number($value) ? $value : do {
      $value =~ s/\'/\\'/g;
      "'$value'"
    }
  );
}

method view_create(HashRef $data) {
  my $sql = [];

  # create
  push @$sql, $self->term('create');

  # temporary
  if ($data->{temp}) {
    push @$sql, $self->term('temporary');
  }

  # view
  push @$sql, $self->term('view');

  # safe
  if ($data->{safe}) {
    push @$sql, $self->term(qw(if not exists));
  }

  # view name
  push @$sql, $self->name($data->{name});

  # columns
  if (my $columns = $data->{columns}) {
    push @$sql,
      sprintf('(%s)', join(', ', map $self->expression($_), @$columns));
  }

  # query
  if (my $query = $data->{query}) {
    $self->select($query->{select});
    my $operation = $self->operations->pop;
    $self->{bindings} = $operation->bindings;
    push @$sql, $self->term('as');
    push @$sql, $operation->statement;
  }

  # sql statement
  my $result = join ' ', @$sql;

  return $self->operation($result);
}

method view_drop(HashRef $data) {
  my $sql = [];

  # drop view
  push @$sql, $self->term(qw(drop view)),
    ($data->{safe} ? $self->term(qw(if exists)) : ()),
    $self->name($data->{name});

  # sql statement
  my $result = join ' ', @$sql;

  return $self->operation($result);
}

method union(HashRef $data) {
  my $sql = [];

  # union
  my $type = $self->term('union');

  # union type
  if ($data->{type}) {
    $type = join ' ', $type, $self->term($data->{type});
  }

  # union queries
  for my $query (@{$data->{queries}}) {
    $self->process($query);
    my $operation = $self->operations->pop;
    $self->{bindings} = $operation->bindings;
    push @$sql, sprintf('(%s)', $operation->statement);
  }

  # sql statement
  my $result = join " $type ", @$sql;

  return $self->operation($result);
}

method wrap(Str $name) {

  return qq("$name");
}

1;

=encoding utf8

=head1 NAME

SQL::Engine::Grammar - Standard Grammar

=cut

=head1 ABSTRACT

SQL::Engine Standard Grammar

=cut

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This package provides methods for converting
L<json-sql|https://github.com/iamalnewkirk/json-sql> data structures into
SQL statements.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 operations

  operations(InstanceOf["SQL::Engine::Collection"])

This attribute is read-only, accepts C<(InstanceOf["SQL::Engine::Collection"])> values, and is optional.

=cut

=head2 schema

  schema(HashRef)

This attribute is read-only, accepts C<(HashRef)> values, and is required.

=cut

=head2 validator

  validator(Maybe[InstanceOf["SQL::Validator"]])

This attribute is read-only, accepts C<(Maybe[InstanceOf["SQL::Validator"]])> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 binding

  binding(Str $name) : Str

The binding method registers a SQL statement binding (or placeholder).

=over 4

=item binding example #1

  # given: synopsis

  $grammar->binding('user_id');
  $grammar->binding('user_id');
  $grammar->binding('user_id');
  $grammar->binding('user_id');
  $grammar->binding('user_id');

=back

=cut

=head2 column_change

  column_change(HashRef $data) : Object

The column_change method generates SQL statements to change a column
definition.

=over 4

=item column_change example #1

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

=back

=cut

=head2 column_create

  column_create(HashRef $data) : Object

The column_create method generates SQL statements to add a new table column.

=over 4

=item column_create example #1

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

=back

=cut

=head2 column_definition

  column_definition(HashRef $data) : HashRef

The column_definition method column definition SQL statement fragments.

=over 4

=item column_definition example #1

  # given: synopsis

  my $column_definition = $grammar->column_definition({
    name => 'id',
    type => 'number',
    primary => 1
  });

=back

=cut

=head2 column_drop

  column_drop(HashRef $data) : Object

The column_drop method generates SQL statements to remove a table column.

=over 4

=item column_drop example #1

  # given: synopsis

  $grammar->column_drop({
    table => 'users',
    column => 'accessed'
  });

=back

=cut

=head2 column_rename

  column_rename(HashRef $data) : Object

The column_rename method generates SQL statements to rename a table column.

=over 4

=item column_rename example #1

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

=back

=cut

=head2 column_specification

  column_specification(HashRef $data) : Str

The column_specification method a column definition SQL statment partial.

=over 4

=item column_specification example #1

  # given: synopsis

  my $column_specification = $grammar->column_specification({
    name => 'id',
    type => 'number',
    primary => 1
  });

=back

=cut

=head2 constraint_create

  constraint_create(HashRef $data) : Object

The constraint_create method generates SQL statements to create a table
constraint.

=over 4

=item constraint_create example #1

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

=back

=cut

=head2 constraint_drop

  constraint_drop(HashRef $data) : Object

The constraint_drop method generates SQL statements to remove a table
constraint.

=over 4

=item constraint_drop example #1

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

=back

=cut

=head2 constraint_name

  constraint_name(HashRef $data) : Str

The constraint_name method returns the generated constraint name.

=over 4

=item constraint_name example #1

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

=back

=cut

=head2 constraint_option

  constraint_option(Str $name) : Str

The constraint_option method returns a SQL expression for the constraint option
provided.

=over 4

=item constraint_option example #1

  # given: synopsis

  $grammar->constraint_option('no-action');

=back

=cut

=head2 criteria

  criteria(ArrayRef $data) : ArrayRef[Str]

The criteria method returns a list of SQL expressions.

=over 4

=item criteria example #1

  # given: synopsis

  my $criteria = $grammar->criteria([
    {
      eq => [{ column => 'id' }, 123]
    },
    {
      'not-null' => { column => 'deleted' }
    }
  ]);

=back

=cut

=head2 criterion

  criterion(HashRef $data) : Str

The criterion method returns a SQL expression.

=over 4

=item criterion example #1

  # given: synopsis

  my $criterion = $grammar->criterion({
    in => [{ column => 'theme' }, 'light', 'dark']
  });

=back

=cut

=head2 database_create

  database_create(HashRef $data) : Object

The database_create method generates SQL statements to create a database.

=over 4

=item database_create example #1

  # given: synopsis

  $grammar->database_create({
    name => 'todoapp'
  });

=back

=cut

=head2 database_drop

  database_drop(HashRef $data) : Object

The database_drop method generates SQL statements to remove a database.

=over 4

=item database_drop example #1

  # given: synopsis

  $grammar->database_drop({
    name => 'todoapp'
  });

=back

=cut

=head2 delete

  delete(HashRef $data) : Object

The delete method generates SQL statements to delete table rows.

=over 4

=item delete example #1

  # given: synopsis

  $grammar->delete({
    from => {
      table => 'tasklists'
    }
  });

=back

=cut

=head2 execute

  execute() : Object

The execute method validates and processes the object instruction.

=over 4

=item execute example #1

  # given: synopsis

  $grammar->operations->clear;

  $grammar->execute;

=back

=cut

=head2 expression

  expression(Any $data) : Any

The expression method returns a SQL expression representing the data provided.

=over 4

=item expression example #1

  # given: synopsis

  $grammar->expression(undef);

  # NULL

=back

=cut

=head2 index_create

  index_create(HashRef $data) : Object

The index_create method generates SQL statements to create a table index.

=over 4

=item index_create example #1

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

=back

=cut

=head2 index_drop

  index_drop(HashRef $data) : Object

The index_drop method generates SQL statements to remove a table index.

=over 4

=item index_drop example #1

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

=back

=cut

=head2 index_name

  index_name(HashRef $data) : Str

The index_name method returns the generated index name.

=over 4

=item index_name example #1

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

=back

=cut

=head2 insert

  insert(HashRef $data) : Object

The insert method generates SQL statements to insert table rows.

=over 4

=item insert example #1

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

=back

=cut

=head2 name

  name(Any @args) : Str

The name method returns a qualified quoted object name.

=over 4

=item name example #1

  # given: synopsis

  my $name = $grammar->name(undef, 'public', 'users');

  # "public"."users"

=back

=cut

=head2 operation

  operation(Str $statement) : InstanceOf["SQL::Engine::Operation"]

The operation method creates and appends an operation to the I<"operations">
collection.

=over 4

=item operation example #1

  # given: synopsis

  $grammar->operation('SELECT TRUE');

=back

=cut

=head2 process

  process(Mayb[HashRef] $schema) : Object

The process method processes the object instructions.

=over 4

=item process example #1

  # given: synopsis

  $grammar->process;

=back

=cut

=head2 schema_create

  schema_create(HashRef $data) : Object

The schema_create method generates SQL statements to create a schema.

=over 4

=item schema_create example #1

  # given: synopsis

  $grammar->schema_create({
    name => 'private',
  });

=back

=cut

=head2 schema_drop

  schema_drop(HashRef $data) : Object

The schema_drop method generates SQL statements to remove a schema.

=over 4

=item schema_drop example #1

  # given: synopsis

  $grammar->schema_drop({
    name => 'private',
  });

=back

=cut

=head2 schema_rename

  schema_rename(HashRef $data) : Object

The schema_rename method generates SQL statements to rename a schema.

=over 4

=item schema_rename example #1

  # given: synopsis

  $grammar->schema_rename({
    name => {
      old => 'private',
      new => 'restricted'
    }
  });

=back

=cut

=head2 select

  select(HashRef $data) : Object

The select method generates SQL statements to select table rows.

=over 4

=item select example #1

  # given: synopsis

  $grammar->select({
    from => {
      table => 'people'
    },
    columns => [
      { column => 'name' }
    ]
  });

=back

=cut

=head2 table

  table(HashRef $data) : Str

The table method returns a qualified quoted table name.

=over 4

=item table example #1

  # given: synopsis

  my $table = $grammar->table({
    schema => 'public',
    table => 'users',
    alias => 'u'
  });

=back

=cut

=head2 table_create

  table_create(HashRef $data) : Object

The table_create method generates SQL statements to create a table.

=over 4

=item table_create example #1

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

=back

=cut

=head2 table_drop

  table_drop(HashRef $data) : Object

The table_drop method generates SQL statements to remove a table.

=over 4

=item table_drop example #1

  # given: synopsis

  $grammar->table_drop({
    name => 'people'
  });

=back

=cut

=head2 table_rename

  table_rename(HashRef $data) : Object

The table_rename method generates SQL statements to rename a table.

=over 4

=item table_rename example #1

  # given: synopsis

  $grammar->table_rename({
    name => {
      old => 'peoples',
      new => 'people'
    }
  });

=back

=cut

=head2 term

  term(Str @args) : Str

The term method returns a SQL keyword.

=over 4

=item term example #1

  # given: synopsis

  $grammar->term('end');

=back

=cut

=head2 transaction

  transaction(HashRef $data) : Object

The transaction method generates SQL statements to commit an atomic database
transaction.

=over 4

=item transaction example #1

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

=back

=cut

=head2 type

  type(HashRef $data) : Str

The type method return the SQL representation for a data type.

=over 4

=item type example #1

  # given: synopsis

  $grammar->type({
    type => 'datetime-wtz'
  });

  # datetime

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

The type_boolean method returns the SQL expression representing a boolean data
type.

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

  $grammar->type_enum({});

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

=head2 update

  update(HashRef $data) : Object

The update method generates SQL statements to update table rows.

=over 4

=item update example #1

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

=back

=cut

=head2 validate

  validate() : Bool

The validate method validates the data structure defined in the I<"schema">
property.

=over 4

=item validate example #1

  # given: synopsis

  my $valid = $grammar->validate;

=back

=cut

=head2 value

  value(Any $value) : Str

The value method returns the SQL representation of a value.

=over 4

=item value example #1

  # given: synopsis

  $grammar->value(undef);

  # NULL

=back

=cut

=head2 view_create

  view_create(HashRef $data) : Object

The view_create method generates SQL statements to create a table view.

=over 4

=item view_create example #1

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

=back

=cut

=head2 view_drop

  view_drop(HashRef $data) : Object

The view_drop method generates SQL statements to remove a table view.

=over 4

=item view_drop example #1

  # given: synopsis

  $grammar->view_drop({
    name => 'active_users'
  });

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