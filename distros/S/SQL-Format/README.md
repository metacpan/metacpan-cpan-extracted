# NAME

SQL::Format - Yet another yet another SQL builder

# SYNOPSIS

    use SQL::Format;

    my ($stmt, @bind) = sqlf 'SELECT %c FROM %t WHERE %w' => (
        [qw/bar baz/], # %c
        'foo',         # %t
        {
            hoge => 'fuga',
            piyo => [qw/100 200 300/],
        },             # %w
    );
    # $stmt: SELECT `bar`, `baz` FROM `foo` WHERE (`hoge` = ?) AND (`piyo` IN (?, ?, ?))
    # @bind: ('fuga', 100, 200, 300);

    ($stmt, @bind) = sqlf 'SELECT %c FROM %t WHERE %w %o' => (
        '*',                # %c
        'foo',              # %t
        { hoge => 'fuga' }, # w
        {
            order_by => { bar => 'DESC' },
            limit    => 100,
            offset   => 10,
        },                  # %o
    );
    # $stmt: SELECT * FROM `foo` WHERE (`hoge` = ?) ORDER BY `bar` DESC LIMIT 100 OFFSET 10
    # @bind: (`fuga`)

    ($stmt, @bind) = sqlf 'UPDATE %t SET %s' => (
        foo => { bar => 'baz', 'hoge => 'fuga' },
    );
    # $stmt: UPDATE `foo` SET `bar` = ?, `hoge` = ?
    # @bind: ('baz', 'fuga')

    my $sqlf = SQL::Format->new(
        quote_char    => '',        # do not quote
        limit_dialect => 'LimitXY', # mysql style limit-offset
    );
    ($stmt, @bind) = $sqlf->select(foo => [qw/bar baz/], {
        hoge => 'fuga',
    }, {
        order_by => 'bar',
        limit    => 100,
        offset   => 10,
    });
    # $stmt: SELECT bar, baz FROM foo WHERE (hoge = ?) ORDER BY bar LIMIT 10, 100
    # @bind: ('fuga')

    ($stmt, @bind) = $sqlf->insert(foo => { bar => 'baz', hoge => 'fuga' });
    # $stmt: INSERT INTO foo (bar, hoge) VALUES (?, ?)
    # @bind: ('baz', 'fuga')

    ($stmt, @bind) = $sqlf->update(foo => { bar => 'xxx' }, { hoge => 'fuga' });
    # $stmt: UPDATE foo SET bar = ? WHERE hoge = ?
    # @bind: ('xxx', 'fuga')

    ($stmt, @bind) = $sqlf->delete(foo => { hoge => 'fuga' });
    # $stmt: DELETE FROM foo WHERE (hoge = ?)
    # @bind: ('fuga')

# DESCRIPTION

SQL::Format is a easy to SQL query building library.

__THIS MODULE IS ALPHA LEVEL INTERFACE!!__

# FUNCTIONS

## sqlf($format, @args)

Generate SQL from formatted output conversion.

    my ($stmt, @bind) = sqlf 'SELECT %c FROM %t WHERE %w' => (
        [qw/bar baz/],   # %c
        'foo',           # %t
        {
            hoge => 'fuga',
            piyo => [100, 200, 300],
        },               # %w
    );
    # $stmt: SELECT `foo` FROM `bar`, `baz WHERE (`hoge` = ?) AND (`piyo` IN (?, ?, ?))
    # @bind: ('fuga', 100, 200, 300)

Currently implemented formatters are:

- %t

    This format is a table name.

        ($stmt, @bind) = sqlf '%t', 'table_name';        # $stmt => `table_name`
        ($stmt, @bind) = sqlf '%t', [qw/tableA tableB/]; # $stmt => `tableA`, `tableB`
        ($stmt, @bind) = sqlf '%t', { tableA => 't1' };  # $stmt => `tableA` `t1`
        ($stmt, @bind) = sqlf '%t', {
            tableA => {
                index => { type => 'force', keys => [qw/key1 key2/] },
                alias => 't1',
        }; # $stmt: `tableA` `t1` FORCE INDEX (`key1`, `key2`)

- %c

    This format is a column name.

        ($stmt, @bind) = sqlf '%c', 'column_name';       # $stmt => `column_name`
        ($stmt, @bind) = sqlf '%c', [qw/colA colB/];     # $stmt => `colA`, `colB`
        ($stmt, @bind) = sqlf '%c', '*';                 # $stmt => *
        ($stmt, @bind) = sqlf '%c', [\'COUNT(*)', colC]; # $stmt => COUNT(*), `colC`

- %w

    This format is a where clause.

        ($stmt, @bind) = sqlf '%w', { foo => 'bar' };
        # $stmt: (`foo` = ?)
        # @bind: ("bar")

        ($stmt, @bind) = sqlf '%w', {
            foo => 'bar',
            baz => [qw/100 200 300/],
        };
        # $stmt: (`baz` IN (?, ?, ?) AND (`foo` = ?)
        # @bind: (100, 200, 300, 'bar')

- %o

    This format is a options. Currently specified are:

    - limit

        This option makes `LIMIT $n` clause.

            ($stmt, @bind) = sqlf '%o', { limit => 100 }; # $stmt => LIMIT 100

    - offset

        This option makes `OFFSET $n` clause. You must be specified both limit option.

            ($stmt, @bind) = sqlf '%o', { limit => 100, offset => 20 }; # $stmt => LIMIT 100 OFFSET 20

        You can change limit dialects from `$SQL::Format::LIMIT_DIALECT`.

    - order\_by

        This option makes `ORDER BY` clause.

            ($stmt, @bind) = sqlf '%o', { order_by => 'foo' };                       # $stmt => ORDER BY `foo`
            ($stmt, @bind) = sqlf '%o', { order_by => { foo => 'DESC' } };           # $stmt => ORDER BY `foo` DESC
            ($stmt, @bind) = sqlf '%o', { order_by => ['foo', { -asc => 'bar' } ] }; # $stmt => ORDER BY `foo`, `bar` ASC

    - group\_by

        This option makes `GROUP BY` clause. Argument value some as `order_by` option.

            ($stmt, @bind) = sqlf '%o', { group_by => { foo => 'DESC' } }; # $stmt => GROUP BY `foo` DESC

    - having

        This option makes `HAVING` clause. Argument value some as `where` clause.

            ($stmt, @bind) = sqlf '%o', { having => { foo => 'bar' } };
            # $stmt: HAVING (`foo` = ?)
            # @bind: ('bar')

- %j

    This format is join clause.

        ($stmt, @bind) = sqlf '%j', { table => 'bar', condition => 'foo.id = bar.id' };
        # $stmt: INNER JOIN `bar` ON (foo.id = bar.id)

        ($stmt, @bind) = sqlf '%j', {
            type      => 'left',
            table     => { bar => 'b' },
            condition => {
                'f.id'         => 'b.id',
                'f.updated_at' => \['UNIX_TIMESTAMP()', '2012-12-12']
                'f.created_at' => { '>' => 'b.created_at' },
            },
        };
        # $stmt: LEFT JOIN `bar` `b` ON (`f`.`id` = `b.id`)

- %s

    This format is set clause.

        ($stmt, @bind) = sqlf '%s', { bar => 'baz' };
        # $stmt: `bar` = ?
        # @bind: ('baz')

        ($stmt, @bind) = sqlf '%s', { bar => 'baz', 'hoge' => \'UNIX_TIMESTAMP()' };
        # $stmt: `bar` = ?, `hoge` = UNIX_TIMESTAMP()
        # @bind: ('baz')

        ($stmt, @bind) = sqlf '%s', {
            bar  => 'baz',
            hoge => \['CONCAT(?, ?)', 'ya', 'ppo'],
        };
        # $stmt: `bar` = ?, `hoge` = CONCAT(?, ?)
        # @bind: ('baz', 'ya', 'ppo')

For more examples, see also [SQL::Format::Spec](https://metacpan.org/pod/SQL::Format::Spec).

You can change the behavior by changing the global variable.

- $SQL::Format::QUOTE\_CHAR : Str

    This is a quote character for table or column name.

    Default value is `` "`" ``.

- $SQL::Format::NAME\_SEP : Str

    This is a separate character for table or column name.

    Default value is `"."`.

- $SQL::Format::DELIMITER Str

    This is a delimiter for between columns.

    Default value is `", "`.

- $SQL::Format::LIMIT\_DIALECT : Str

    This is a types for dialects of limit-offset.

    You can choose are:

        LimitOffset  # LIMIT 100 OFFSET 20  (SQLite / PostgreSQL / MySQL)
        LimitXY      # LIMIT 20, 100        (MySQL / SQLite)
        LimitYX      # LIMIT 100, 20        (other)

    Default value is `LimitOffset"`.

# METHODS

## new(\[%options\])

Create a new instance of `SQL::Format`.

    my $sqlf = SQL::Format->new(
        quote_char    => '',
        limit_dialect => 'LimitXY',
    );

`%options` specify are:

- quote\_char : Str

    Default value is `$SQL::Format::QUOTE_CHAR`.

- name\_sep : Str

    This is a separate character for table or column name.

    Default value is `$SQL::Format::NAME_SEP`.

- delimiter: Str

    This is a delimiter for between columns.

    Default value is `$SQL::Format::DELIMITER`.

- limit\_dialect : Str

    This is a types for dialects of limit-offset.

    Default value is `$SQL::Format::LIMIT_DIALECT`.

## format($format, \\%args)

This method same as `sqlf` function.

    my ($stmt, @bind) = $self->format('SELECT %c FROM %t WHERE %w',
        [qw/bar baz/],
        'foo',
        { hoge => 'fuga' },
    );
    # $stmt: SELECT `bar`, `baz` FROM ` foo` WHERE (`hoge` = ?)
    # @bind: ('fuga')

## select($table|\\@table, $column|\\@columns \[, \\%where, \\%opts \])

This method returns SQL string and bind parameters for `SELECT` statement.

    my ($stmt, @bind) = $sqlf->select(foo => [qw/bar baz/], {
        hoge => 'fuga',
        piyo => [100, 200, 300],
    });
    # $stmt: SELECT `foo` FROM `bar`, `baz` WHERE (`hoge` = ?) AND (`piyo` IN (?, ?, ?))
    # @bind: ('fuga', 100, 200, 300)

Argument details are:

- $table | \\@table

    Same as `%t` format.

- $column | \\@columns

    Same as `%c` format.

- \\%where

    Same as `%w` format.

- \\%opts
    - $opts->{prefix}

        This is prefix for SELECT statement.

            my ($stmt, @bind) = $sqlf->select(foo => '*', { bar => 'baz' }, { prefix => 'SELECT SQL_CALC_FOUND_ROWS' });
            # $stmt: SELECT SQL_CALC_FOUND_ROWS * FROM `foo` WHERE (`bar` = ?)
            # @bind: ('baz')

        Default value is `SELECT`.

    - $opts->{suffix}

        Additional value for after the SELECT statement.

            my ($stmt, @bind) = $sqlf->select(foo => '*', { bar => 'baz' }, { suffix => 'FOR UPDATE' });
            # $stmt: SELECT * FROM `foo` WHERE (bar = ?) FOR UPDATE
            # @bind: ('baz')

        Default value is `''`

    - $opts->{limit}
    - $opts->{offset}
    - $opts->{order\_by}
    - $opts->{group\_by}
    - $opts->{having}
    - $opts->{join}

        See also `%o` format.

## insert($table, \\%values|\\@values \[, \\%opts \])

This method returns SQL string and bind parameters for `INSERT` statement.

    my ($stmt, @bind) = $sqlf->insert(foo => { bar => 'baz', hoge => 'fuga' });
    # $stmt: INSERT INTO `foo` (`bar`, `hoge`) VALUES (?, ?)
    # @bind: ('baz', 'fuga')

    my ($stmt, @bind) = $sqlf->insert(foo => [
        hoge => \'NOW()',
        fuga => \['UNIX_TIMESTAMP()', '2012-12-12 12:12:12'],
    ]);
    # $stmt: INSERT INTO `foo` (`hoge`, `fuga`) VALUES (NOW(), UNIX_TIMESTAMP(?))
    # @bind: ('2012-12-12 12:12:12')

Argument details are:

- $table

    This is a table name for target of INSERT.

- \\%values | \\@values

    This is a VALUES clause INSERT statement.

    Currently supported types are:

        # \%values case
        { foo => 'bar' }
        { foo => \'NOW()' }
        { foo => \['UNIX_TIMESTAMP()', '2012-12-12 12:12:12'] }

        # \@values case
        [ foo => 'bar' ]
        [ foo => \'NOW()' ]
        [ foo => \['UNIX_TIMESTAMP()', '2012-12-12 12:12:12'] ]

- \\%opts
    - $opts->{prefix}

        This is a prefix for INSERT statement.

            my ($stmt, @bind) = $sqlf->insert(foo => { bar => baz }, { prefix => 'INSERT IGNORE' });
            # $stmt: INSERT IGNORE INTO `foo` (`bar`) VALUES (?)
            # @bind: ('baz')

        Default value is `INSERT`.

## update($table, \\%set|\\@set \[, \\%where, \\%opts \])

This method returns SQL string and bind parameters for `UPDATE` statement.

    my ($stmt, @bind) = $sqlf->update(foo => { bar => 'baz' }, { hoge => 'fuga' });
    # $stmt: UPDATE `foo` SET `bar` = ? WHERE (`hoge` = ?)
    # @bind: ('baz', 'fuga')

Argument details are:

- $table

    This is a table name for target of UPDATE.

- \\%set | \\@set

    This is a SET clause for INSERT statement.

    Currently supported types are:

        # \%values case
        { foo => 'bar' }
        { foo => \'NOW()' }
        { foo => \['UNIX_TIMESTAMP()', '2012-12-12 12:12:12'] }

        # \@values case
        [ foo => 'bar' ]
        [ foo => \'NOW()' ]
        [ foo => \['UNIX_TIMESTAMP()', '2012-12-12 12:12:12'] ]

- \\%where

    Same as `%w` format.

- \\%opts
    - $opts->{prefix}

        This is a prefix for UPDATE statement.

            my ($stmt, @bind) = $sqlf->update(
                'foo'                                # table
                { bar    => 'baz' },                 # sets
                { hoge   => 'fuga' },                # where
                { prefix => 'UPDATE LOW_PRIORITY' }, # opts
            );
            # $stmt: UPDATE LOW_PRIORITY `foo` SET `bar` = ? WHERE (`hoge` = ?)
            # @bind: ('baz', 'fuga')

        Default value is `UPDATE`.

    - $opts->{order\_by}
    - $opts->{limit}

        See also `%o` format.

## delete($table \[, \\%where, \\%opts \])

This method returns SQL string and bind parameters for `DELETE` statement.

    my ($stmt, @bind) = $sqlf->delete(foo => { bar => 'baz' });
    # $stmt: DELETE FROM `foo` WHERE (`bar = ?)
    # @bind: ('baz')

Argument details are:

- $table

    This is a table name for target of DELETE.

- \\%where

    Same as `%w` format.

- \\%opts
    - $opts->{prefix}

        This is a prefix for DELETE statement.

            my ($stmt, @bind) = $sqlf->delete(foo => { bar => 'baz' }, { prefix => 'DELETE LOW_PRIORITY' });
            # $stmt: DELETE LOW_PRIORITY FROM `foo` WHERE (`bar` = ?)
            # @bind: ('baz')

        Default value is `DELETE`.

    - $opts->{order\_by}
    - $opts->{limit}

        See also `%o` format.

## insert\_multi($table, \\@cols, \\@values \[, \\%opts\])

This method returns SQL string and bind parameters for bulk insert.

    my ($stmt, @bind) = $self->insert_multi(
        foo => [qw/bar baz/],
        [
            [qw/hoge fuga/],
            [qw/fizz buzz/],
        ],
    );
    # $stmt: INSERT INTO `foo` (`bar`, `baz`) VALUES (?, ?), (?, ?)
    # @bind: (qw/hoge fuga fizz buzz/)

Argument details are:

- $table

    This is a table name for target of INSERT.

- \\@cols

    This is a columns for target of INSERT.

- \\@values

    This is a values parameters. Must be ARRAY within ARRAY.

        my ($stmt, @bind) = $sqlf->insert_multi(
            foo => [qw/bar baz/], [
                [qw/foo bar/],
                [\'NOW()', \['UNIX_TIMESTAMP(?)', '2012-12-12 12:12:12'] ],
            ],
        );
        # $stmt: INSERT INTO `foo` (`bar`, `baz`) VALUES (?, ?), (NOW(), UNIX_TIMESTAMP(?))
        # @bind: (qw/foo bar/, '2012-12-12 12:12:12')

- \\%opts
    - $opts->{prefix}

        This is a prefix for INSERT statement.

            my ($stmt, @bind) = $sqlf->insert_multi(..., { prefix => 'INSERT IGNORE INTO' });
            # $stmt: INSERT IGNORE INTO ...

        Default value is `INSERT INTO`.

    - $opts->{update}

        Some as `%s` format.

        If this value specified then add `ON DUPLICATE KEY UPDATE` statement.

            my ($stmt, @bind) = $sqlf->insert_multi(
                foo => [qw/bar baz/],
                [
                    [qw/hoge fuga/],
                    [qw/fizz buzz/],
                ],
                { update => { bar => 'piyo' } },
            );
            # $stmt: INSERT INTO `foo` (`bar`, `baz`) VALUES (?, ?), (?, ?) ON DUPLICATE KEY UPDATE `bar` = ?
            # @bind: (qw/hoge fuga fizz buzz piyo/)

## insert\_multi\_from\_hash($table, \\@values \[, \\%opts\])

This method is a wrapper for `insert_multi()`.

Argument dialects are:

- $table

    Same as `insert_multi()`

- \\@values

    This is a values parameters. Must be HASH within ARRAY.

        my ($stmt, @bind) = $sqlf->insert_multi_from_hash(foo => [
            { bar => 'hoge', baz => 'fuga' },
            { bar => 'fizz', baz => 'buzz' },
        ]);
        # $stmt: INSERT INTO `foo` (`bar`, `baz`) VALUES (?, ?), (?, ?)
        # @bind: (qw/hoge fuga fizz buzz/)

- \\%opts

    Same as `insert_multi()`

## insert\_on\_duplicate($table, \\%values|\\@values, \\%update\_values|\\@update\_values \[, \\%opts\])

This method generate "INSERT INTO ... ON DUPLICATE KEY UPDATE" query for MySQL.

    my ($stmt, @bind) = $sqlf->insert_on_duplicate(
        foo => {
            bar => 'hoge',
            baz => 'fuga',
        }, {
            bar => \'VALUES(bar)',
            baz => 'piyo',
        },
    );
    # $stmt: INSERT INTO `foo` (`bar`, `baz`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `bar` = VALUES(bar), baz = 'piyo'
    # @bind: (qw/hoge fuga piyo/)

Argument details are:

- $table

    This is a table name for target of INSERT.

- \\%values|\\@values

    This is a values parameters.

- \\%update\_values|\\@update\_values

    This is a ON DUPLICATE KEY UPDATE parameters.

- \\%opts
    - $opts->{prefix}

        This is a prefix for INSERT statement.

            my ($stmt, @bind) = $sqlf->insert_on_duplicate(..., { prefix => 'INSERT IGNORE INTO' });
            # $stmt: INSERT IGNORE INTO ...

# AUTHOR

xaicron <xaicron {at} cpan.org>

# COPYRIGHT

Copyright 2012 - xaicron

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[SQL::Format::Spec](https://metacpan.org/pod/SQL::Format::Spec)

[SQL::Maker](https://metacpan.org/pod/SQL::Maker)

[SQL::Abstract](https://metacpan.org/pod/SQL::Abstract)
