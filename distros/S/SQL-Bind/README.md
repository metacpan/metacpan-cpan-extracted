# NAME

SQL::Bind - SQL flexible placeholders

# SYNOPSIS

    use SQL::Bind qw(sql);

    # Scalars
    my ($sql, @bind) =
      sql 'SELECT foo FROM bar WHERE id=:id AND status=:status',
      id     => 1,
      status => 'active';

    # Arrays
    my ($sql, @bind) = sql 'SELECT foo FROM bar WHERE id IN (:id)', id => [1, 2, 3];

    # Hashes
    my ($sql, @bind) = sql 'UPDATE bar SET :columns', columns => {foo => 'bar'};

    # Raw values (!)
    my ($sql, @bind) = sql 'INSERT INTO bar (:keys!) VALUES (:values)',
      keys   => [qw/foo/],
      values => [qw/bar/];

    # Recursive binding (*)
    my ($sql, @bind) =
      sql 'SELECT foo FROM bar WHERE :recursive_query*',
      recursive_query => 'name = :name',
      name            => 'hello';

# DESCRIPTION

[SQL::Bind](https://metacpan.org/pod/SQL%3A%3ABind) simplifies SQL queries maintenance by introducing placeholders. The behavior of the replacement depends on
the type of the value. Scalars, Arrays and Hashes are supported.

## `Configuration`

### `$PlaceholderPrefix`

Placeholder prefix (`:` by default) can be changed by setting the `$PlaceholderPrefix` global variable:

    local $SQL::Bind::PlaceholderPrefix = '@';

    my ($sql, @bind) =
      sql 'SELECT foo FROM bar WHERE id=@id',
      id => 1;

## `Placeholders`

A placeholders is an alphanumeric sequence that is prefixed with `:` (by default) and can end with `!` for raw values
or `*` for recursive binding. Some examples:

    :name
    :status
    :CamelCase
    :Value_123
    :ThisWillBeInsertedAsIs!
    :recursive*

## `Scalar values`

Every value is replaced with a `?`.

    my ($sql, @bind) =
      sql 'SELECT foo FROM bar WHERE id=:id AND status=:status',
      id     => 1,
      status => 'active';

    # SELECT foo FROM bar WHERE id=? AND status=?
    # [1, 'active']

## `Array values`

Arrays are replaced with a sequence of `?, ?, ...`.

    my ($sql, @bind) = sql 'SELECT foo FROM bar WHERE id IN (:id)', id => [1, 2, 3];

    # SELECT foo FROM bar WHERE id IN (?, ?, ?)
    # [1, 2, 3]

## `Hash values`

Hahes are replaced with a sequence of `key1=?, key2=?, ...`.

    my ($sql, @bind) = sql 'UPDATE bar SET :columns', columns => {foo => 'bar'};

    # UPDATE bar SET foo=?
    # ['bar']

## `Raw values`

Sometimes raw values are needed be it another identifier, or a list of columns (e.g. `INSERT, UPDATE`). For this case
a placeholder should be suffixed with a `!`.

    my ($sql, @bind) = sql 'INSERT INTO bar (:keys!) VALUES (:values)',
      keys   => [qw/foo/],
      values => [qw/bar/];

    # INSERT INTO bar (foo) VALUES (?)
    # ['bar']

## `Recursive binding`

Recursive binding allows you to recursively parse already replaced values. This helps building complex subqueries.

    my ($sql, @bind) =
      sql 'SELECT foo FROM bar WHERE :recursive_query*',
      recursive_query => 'name = :name',
      name            => 'hello';

    # 'SELECT foo FROM bar WHERE name = ?
    # ['hello']

# DEVELOPMENT

## Repository

    http://github.com/vti/sql-bind

# CREDITS

# AUTHOR

Viacheslav Tykhanovskyi, `vti@cpan.org`.

# COPYRIGHT AND LICENSE

Copyright (C) 2020, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.
