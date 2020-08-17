package SQL::Engine::Grammar::Mssql;

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
  $self->operation($self->term(qw(begin transaction)));

  my $def = $self->column_definition($data->{column});

  # column type
  $self->operation(do {
    my $sql = [];

    # alter table
    push @$sql, $self->term(qw(alter table));

    # safe
    push @$sql, $self->term(qw(if exists)) if $data->{safe};

    # for
    push @$sql, $self->table($data->{for});

    # alter column
    push @$sql, $self->term(qw(alter column));

    # column name
    push @$sql, $self->name($data->{column}{name});

    # column type
    push @$sql, $def->{type};

    # column (set | drop) not null
    push @$sql,
      (exists $data->{column}{nullable})
      ? (
          $data->{column}{nullable}
          ? $self->term(qw(null))
          : $self->term(qw(not null))
        )
      : $self->term(qw(null));

    # sql statement
    join ' ', @$sql
  });

  # drop any column default
  $self->operation(do {
    my $sql = [];

    my $tsql = q{
      DECLARE @schema_name nvarchar(256);
      DECLARE @table_name nvarchar(256);
      DECLARE @col_name nvarchar(256);
      DECLARE @Command  nvarchar(1000);

      SET @schema_name = DB_NAME();
      SET @table_name = N'{TABLE_NAME}';
      SET @col_name = N'{COLUMN_NAME}';

      SELECT @Command = 'ALTER TABLE ' + @schema_name + '.[' + @table_name + '] DROP CONSTRAINT ' + d.name
       FROM sys.tables t
        JOIN sys.default_constraints d on d.parent_object_id = t.object_id
        JOIN sys.columns c on c.object_id = t.object_id and c.column_id = d.parent_column_id
       WHERE t.name = @table_name
        AND t.schema_id = schema_id(@schema_name)
        AND c.name = @col_name;

      EXECUTE (@Command)
    };

    my $table_name = $self->table($data->{"for"});
    my $column_name = $self->name($data->{column}{name});

    $tsql =~ s/\{TABLE_NAME\}/$table_name/;
    $tsql =~ s/\{COLUMN_NAME\}/$column_name/;
    $tsql =~ s/\s+/ /g;
    $tsql =~ s/\n+//g;

    push @$sql, $tsql;

    # sql statement
    join ' ', @$sql
  });

  # column set default
  if ($data->{column}{default}) {
    $self->operation(do {
      my $sql = [];

      # alter table
      push @$sql, $self->term(qw(alter table));

      # safe
      push @$sql, $self->term(qw(if exists)) if $data->{safe};

      # for
      push @$sql, $self->table($data->{for});

      # default constraint name
      push @$sql, $self->term(qw(add constraint)),
        join '_', 'DF', $data->{column}{name};

      # default
      push @$sql, $def->{default};

      # column name
      push @$sql, $self->term(qw(for)), $self->name($data->{column}{name});

      # sql statement
      join ' ', @$sql
    });
  }

  $self->operation($self->term('commit'));

  return $self;
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
  push @$sql, $self->term(qw(add));

  # column specification
  push @$sql, $self->column_specification($data->{column});

  # sql statement
  my $result = join ' ', @$sql;

  return $self->operation($result);
}

method column_definition(HashRef $data) {
  my $def = $self->next::method($data);

  if (exists $data->{default}) {
    $def->{default} = join ' ', $self->term('default'),
      sprintf '(%s)', $self->expression($data->{default});
  }

  if ($data->{increment}) {
    $def->{increment} = $self->term('identity');
  }

  return $def;
}

method column_rename(HashRef $data) {
  my $sql = [];

  # table name
  my $table = join '.', $self->table($data->{"for"}), $self->name($data->{name}{old});

  # rename column
  push @$sql, $self->term(qw(exec)),
    'sp_rename',
    join ', ',
    $self->value($table),
    $self->value($self->name($data->{name}{new})),
    $self->value(uc('column'));

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

  # table
  push @$sql, $self->term('on'), $self->table($data->{for});

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
      push @$sql, sprintf '%s %d %s',
        $self->term('offset'),
        $rows->{offset},
        $self->term(qw(rows));
      push @$sql, sprintf '%s %d %s',
        $self->term(qw(fetch next)),
        $rows->{limit},
        $self->term(qw(rows only));
    }
    if ($rows->{limit} && !$rows->{offset}) {
      push @$sql, sprintf '%s %d %s',
        $self->term('offset'),
        0,
        $self->term(qw(rows));
      push @$sql, sprintf '%s %d %s',
        $self->term(qw(fetch next)),
        $rows->{limit},
        $self->term(qw(rows only));
    }
  }

  # sql statement
  my $result = join ' ', @$sql;

  return $self->operation($result);
}

method table_create(HashRef $data) {
  my $sql = [];

  # create
  push @$sql, $self->term('create');

  # temporary
  my $name;
  if ($data->{temp}) {
    $name = "#".$data->{name};
  }
  else {
    $name = $data->{name};
  }

  # table
  push @$sql, $self->term('table'),
    ($data->{safe} ? $self->term(qw(if not exists)) : ()),
    $self->name($name);

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
    $sql = [];
    $self->select({%{$query->{select}}, into => $name});
    my $operation = $self->operations->pop;
    $self->{bindings} = $operation->bindings;
    push @$sql, $operation->statement;
  }

  # sql statement
  my $result = join ' ', @$sql;

  return $self->operation($result);
}

method table_rename(HashRef $data) {
  my $sql = [];

  # rename table
  push @$sql, $self->term(qw(exec)), 'sp_rename',
    join ', ', $self->name($data->{name}{old}), $self->name($data->{name}{new});

  # sql statement
  my $result = join ' ', @$sql;

  return $self->operation($result);
}

method transaction(HashRef $data) {
  my @mode;
  if ($data->{mode}) {
    @mode = map $self->term($_), @{$data->{mode}};
  }
  if (@mode) {
    $self->operation($self->term(qw(set transaction isolation level), @mode));
  }
  $self->operation($self->term('begin', 'transaction'));
  $self->process($_) for @{$data->{queries}};
  $self->operation($self->term('commit'));

  return $self;
}

method type_binary(HashRef $data) {

  return 'varbinary(max)';
}

method type_boolean(HashRef $data) {

  return 'bit';
}

method type_char(HashRef $data) {
  my $options = $data->{options} || [];

  return sprintf('nchar(%s)', $self->value($options->[0] || 1));
}

method type_date(HashRef $data) {

  return 'date';
}

method type_datetime(HashRef $data) {

  return 'datetime';
}

method type_datetime_wtz(HashRef $data) {

  return 'datetimeoffset(0)';
}

method type_decimal(HashRef $data) {
  my $options = $data->{options} || [];

  return sprintf(
    'decimal(%s)',
    join(', ',
      $self->value($options->[0]) || 5,
      $self->value($options->[1]) || 2)
  );
}

method type_double(HashRef $data) {

  return 'float';
}

method type_enum(HashRef $data) {

  return 'nvarchar(255)';
}

method type_float(HashRef $data) {

  return 'float';
}

method type_integer(HashRef $data) {

  return 'int';
}

method type_integer_big(HashRef $data) {

  return 'bigint';
}

method type_integer_big_unsigned(HashRef $data) {

  return $self->type_integer_big($data);
}

method type_integer_medium(HashRef $data) {

  return 'int';
}

method type_integer_medium_unsigned(HashRef $data) {

  return $self->type_integer_medium($data);
}

method type_integer_small(HashRef $data) {

  return 'smallint';
}

method type_integer_small_unsigned(HashRef $data) {

  return $self->type_integer_small($data);
}

method type_integer_tiny(HashRef $data) {

  return 'tinyint';
}

method type_integer_tiny_unsigned(HashRef $data) {

  return $self->type_integer_tiny($data);
}

method type_integer_unsigned(HashRef $data) {

  return $self->type_integer($data);
}

method type_json(HashRef $data) {

  return 'nvarchar(max)';
}

method type_number(HashRef $data) {

  return $self->type_integer($data);
}

method type_string(HashRef $data) {
  my $options = $data->{options} || [];

  return sprintf('nvarchar(%s)', $options->[0] || 255);
}

method type_text(HashRef $data) {

  return 'nvarchar(max)';
}

method type_text_long(HashRef $data) {

  return 'nvarchar(max)';
}

method type_text_medium(HashRef $data) {

  return 'nvarchar(max)';
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

  return 'datetimeoffset(0)';
}

method type_uuid(HashRef $data) {

  return 'uniqueidentifier';
}

method wrap(Str $name) {

  return qq([$name]);
}

1;

=encoding utf8

=head1 NAME

SQL::Engine::Grammar::Mssql - Grammar For MSSQL

=cut

=head1 ABSTRACT

SQL::Engine Grammar For MSSQL

=cut

=head1 SYNOPSIS

  use SQL::Engine::Grammar::Mssql;

  my $grammar = SQL::Engine::Grammar::Mssql->new(
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
MSSQL statements.

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

  my $grammar = SQL::Engine::Grammar::Mssql->new(
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

  my $grammar = SQL::Engine::Grammar::Mssql->new(
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

  # varbinary(max)

=back

=cut

=head2 type_boolean

  type_boolean(HashRef $data) : Str

The type_boolean method returns the SQL expression representing a boolean data type.

=over 4

=item type_boolean example #1

  # given: synopsis

  $grammar->type_boolean({});

  # bit

=back

=cut

=head2 type_char

  type_char(HashRef $data) : Str

The type_char method returns the SQL expression representing a char data type.

=over 4

=item type_char example #1

  # given: synopsis

  $grammar->type_char({});

  # nchar(1)

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

  # datetimeoffset(0)

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

  # decimal(5, 2)

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

  # nvarchar(255)

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

  # int

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

  # bigint

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

  # bigint

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

  # int

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

  # int

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

  # smallint

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

  # smallint

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

  # tinyint

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

  # tinyint

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

  # int

=back

=cut

=head2 type_json

  type_json(HashRef $data) : Str

The type_json method returns the SQL expression representing a json data type.

=over 4

=item type_json example #1

  # given: synopsis

  $grammar->type_json({});

  # nvarchar(max)

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

  # int

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

  # nvarchar(255)

=back

=cut

=head2 type_text

  type_text(HashRef $data) : Str

The type_text method returns the SQL expression representing a text data type.

=over 4

=item type_text example #1

  # given: synopsis

  $grammar->type_text({});

  # nvarchar(max)

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

  # nvarchar(max)

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

  # nvarchar(max)

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

  # datetimeoffset(0)

=back

=cut

=head2 type_uuid

  type_uuid(HashRef $data) : Str

The type_uuid method returns the SQL expression representing a uuid data type.

=over 4

=item type_uuid example #1

  # given: synopsis

  $grammar->type_uuid({});

  # uniqueidentifier

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