[![Build Status](https://travis-ci.org/hkoba/perl-SQL-Concat.svg?branch=master)](https://travis-ci.org/hkoba/perl-SQL-Concat)
# NAME

SQL::Concat - SQL concatenator, only cares about bind-vars, to write SQL generator

# SYNOPSIS

```perl
#
# Functional interface
#
use SQL::Concat qw/SQL/;

$q = SQL("SELECT uid FROM authors"); # Just single fixed SQL

$q = SQL("SELECT uid FROM authors"   # Fixed SQL fragment

        , ["WHERE name = ?", 'foo']  # Pair of placeholder(s) and value(s)

        , "ORDER BY uid"             # Fixed SQL fragment (again)

        , ($reverse ? "desc" : ())   # Conditional Fixed SQL fragment
      );

$q = SQL($q                          # SQL(SQL(SQL(...), SQL(..))) is ok
         , "LIMIT 10"
         , ["OFFSET ?", 30]
      );

# Extract concatenated SQL and bind vars.
#
($sql, @binds) = $q->as_sql_bind;
# ==>
# SQL: SELECT uid FROM authors WHERE name = ? ORDER BY uid LIMIT 10 OFFSET ?
# BIND: ('foo', 30)

#
# SQL() doesn't care about composed SQL syntax. It just concat given args.
#
$q = SQL("SELECT uid", "FROM authors");
$q = SQL("SELECT uid FROM", "authors");
$q = SQL(SELECT => uid => FROM => 'authors');

#
# OO Interface
#
my $comp = SQL::Concat->new(sep => ' ')
  ->concat(SELECT => foo => FROM => 'bar');
```

# DESCRIPTION

SQL::Concat is **NOT** a _SQL generator_, but a minimalistic **SQL
fragments concatenator** with **safe bind-variable handling**.  SQL::Concat
doesn't care anything about SQL syntax but _placeholder_ and
_bind-variables_. Other important topics to generate correct SQL
such as SQL syntaxes, SQL keywords, quotes, or even parens are
all remained your-side.

This module only focuses on correctly concatenating SQL fragments
with keeping their corresponding bind variables.

## Motivation

To run complex queries on RDBs, you must compose complex SQLs.
There are many feature-rich SQL generators on CPAN to help these tasks
(e.g. [SQL::Abstract](https://metacpan.org/pod/SQL::Abstract), [SQL::Maker](https://metacpan.org/pod/SQL::Maker), [SQL::QueryMaker](https://metacpan.org/pod/SQL::QueryMaker), ...).
Unfortunately, they themselves come with their own syntax and semantics
and have significant learning cost.
And anyway, when you want to generate complex SQL at some level,
you can't avoid learning target SQL anymore.
Eventually, you may realize you doubled complexity and learning cost.

So, this module is written not for SQL refusers
but for dynamic SQL programmers who really want to write precisely controlled SQL,
who already know SQL enough and just want to handle _placeholders_
and _bind-variables_ safely.

## Concatenate STRING, BIND\_ARRAY and SQL::Concat

SQL::Concat can concatenate following four kind of values
into single SQL::Concat object.

```
SQL("SELECT uid FROM authors"   # STRING

  , ["WHERE name = ?", 'foo']   # BIND_ARRAY

  , SQL("ORDER BY uid")         # SQL::Concat object

  , undef                       # undef is ok and silently disappears.
);
```

In other words, SQL::Concat is `join($SEP, @ITEMS)` with special handling for pairs of **placeholders** and **bind variables**.

Default $SEP is a space character `' '` but you can give it as [sep => $sep](#sep) option
for [new()](#new)
or constructor argument like [SQL::Concat->concat\_by($SEP)](#concat_by).

- STRING

    Non-reference values are used just as resulting SQL as-is.
    This means each given strings are treated as **RAW** SQL fragment.
    If you want to use foreign values, you must use next ["BIND\_ARRAY"](#bind_array).

    ```perl
    use SQL::Concat qw/SQL/;

    SQL("SELECT 1")->as_sql_bind;
    # SQL: "SELECT 1"
    # BIND: ()

    SQL("SELECT foo, bar" => FROM => 'baz', "\nORDER BY bar")->as_sql_bind;
    # SQL: "SELECT foo, bar FROM baz
    #       ORDER BY bar"
    # BIND: ()
    ```

    Note: `SQL()` is just a shorthand of `SQL::Concat->new(sep => ' ')->concat( @ITEMS... )`.

- BIND\_ARRAY \[$RAW\_SQL, @BIND\]


    If item is ARRAY reference, it is treated as BIND\_ARRAY.
    The first element of BIND\_ARRAY is treated as RAW SQL.
    The rest of the elements are pushed into `->bind` array.
    This SQL fragment must contain **same number of SQL-placeholders**(`?`)
    with corresponding @BIND variables.

    ```
    SQL(["city = ?", 'tokyo'])->as_sql_bind
    # SQL: "city = ?"
    # BIND: ('tokyo')

    SQL(["age BETWEEN ? AND ?", 20, 65])->as_sql_bind
    # SQL: "age BETWEEN ? AND ?"
    # BIND: (20, 65)
    ```

- SQL::Concat


    Finally, concat() can accept SQL::Concat instances. In this case, `->sql` and `->bind` are extracted and treated just like ["BIND\_ARRAY"](#bind_array)

    ```perl
    SQL("SELECT * FROM members WHERE" =>
        SQL(["city = ?", "tokyo"]),
        AND =>
        SQL(["age BETWEEN ? AND ?", 20, 65])
    )->as_sql_bind;
    # SQL: "SELECT * FROM members WHERE city = ? AND age BETWEEN ? AND ?"
    # BIND: ('tokyo', 20, 65)
    ```

# TUTORIAL

## Hide WHERE clause if $name is empty

Suppose you have a sql statement
`select * from artists where name = ? order by age`
and you want to make `where name = ?` part conditional.
It can be achieved via [SQL()](#sql).

```perl
use SQL::Concat qw/SQL/;

$q = SQL("select * from artists"
        , ($name ? ["where name = ?", $name] : ())
        , "order by age"
     );
($sql, @bind) = $q->as_sql_bind;
```

## Add more conditions with parens

Then, you want to add `age = ?` to where clause.
So you may want to put "WHERE" only if $name or $age is present.
You can achieve it via [PFX($STR, @OTHER)](#pfx).
PFX() prefixes `@OTHER` with `$STR`.
If `@OTHER` is empty, whole PFX() is also empty.

```perl
use SQL::Concat qw/PFX/;

$q = SQL("select * from artists"
        , PFX("WHERE"
             , ($name ? ["name = ?", $name] : ())
             , ($age  ? ["age = ?", $age] : ())
          )
        , "order by age"
     );
# (Wrong)
# select * from artists WHERE name = ? age = ? order by age
```

Unfortunately, this doesn't work if **both** $name and $age is given.
You must decide conjunction or disjunction.
Suppose this time you want to put `OR` between them (oh, really?;-).
You can achieve it via [CAT()](#cat). CAT() behaves like
[Perl's join($SEP, @ITEM)](https://metacpan.org/pod/perlfunc#join) but keeps bind-variables safely.

```perl
use SQL::Concat qw/CAT/;

$q = SQL("select * from artists"
        , PFX("WHERE" =>
             CAT("OR"
                , ($name ? ["name = ?", $name] : ())
                , ($age  ? ["age = ?", $age] : ())
             )
          )
        , "order by age"
     );
# select * from artists WHERE name = ? OR age = ? order by age
```

Then, you may feel above is bit complicated and factorize it out.

```perl
$c = CAT("OR"
        , ($name ? ["name = ?", $name] : ())
        , ($age  ? ["age = ?", $age] : ())
     );
$q = SQL("select * from artists"
        , PFX(WHERE => $c)
        , "order by age"
     );
```

Then, you want to add another condtion `AND address = ?`.
You will nest CAT().

```
$c = CAT("AND"
        , CAT("OR"
             , ($name ? ["name = ?", $name] : ())
             , ($age  ? ["age = ?", $age] : ())
          )
        , ($address ? ["address = ?", $address] : ())
     );
#..
# (Wrong)
# select * from artists WHERE name = ? OR age = ? AND address = ? order by age
```

Unfortunately, this doesn't work as expected because of the lack of paren.
To put paren around "OR" clause, you can use [->paren()](#paren) method.

```
$c = CAT("AND"
        , CAT("OR"
             , ($name ? ["name = ?", $name] : ())
             , ($age  ? ["age = ?", $age] : ())
          )->paren                                   # <<----- THIS
        , ($address ? ["address = ?", $address] : ())
     );
# select * from artists WHERE (name = ? OR age = ?) AND address = ? order by age
```

# FUNCTIONS

## `SQL( @ITEMS... )`


Equiv. of

- `SQL::Concat->concat( @ITEMS... )`
- `SQL::Concat->concat_by(' ', @ITEMS... )`
- `SQL::Concat->new(sep => ' ')->concat( @ITEMS... )`

## `CAT($SEP, @ITEMS... )`


Equiv. of `SQL::Concat->concat_by($SEP, @ITEMS... )`, except
`$SEP` is wrapped by whitespace when necessary.

```perl
CAT(UNION =>
    , SQL("select * from foo")
    , SQL("select * from bar")
)
```

If `@ITEMS` are empty, this returns empty result:

```perl
CAT(AND =>
    , ($name ? ["name = ?", $name] : ())
    , ($age  ? ["age = ?", $age]   : ())
)
```

## `PFX($ITEM, @OTHER_ITEMS...)`


Prefix `$ITEM` only when `@OTHER_ITEMS` are not empty.

```perl
PFX(WHERE =>
    ($name ? ["name = ?", $name] : ())
)
```

Usually used with `CAT()` like following:

```perl
PFX(WHERE =>
    CAT('AND'
        , ($name ? ["name = ?", $name] : ())
        , ($age  ? ["age = ?", $age]   : ())
    )
)
```

## `OPT(RAW_SQL, VALUE, @OTHER...)`


If VALUE is defined, `(SQL([$RAW_SQL, $VALUE]), @OTHER_ITEMS)` are returned. Otherwise empty list is returned.

This is designed to help generating `"LIMIT ? OFFSET ?"`.

```
OPT("limit ?", $limit, OPT("offset ?", $offset));
```

is shorthand version of:

```
SQL(defined $limit
   ? (["limit ?", $limit]
     , SQL(defined $offset
          ? ["offset ?", $offset]
          : ()
       )
     )
   : ()
)
```

## `PAR( @ITEMS... )`


Equiv. of `SQL( ITEMS...)->paren`

## `CSV( @ITEMS... )`


Equiv. of `CAT(', ', @ITEMS... )`

Note: you can use "," anywhere in concat() items. For example,
you can write `SQL(SELECT => "x, y, z")` instead of `SQL(SELECT => CSV(qw/x y z/))`.

# METHODS

## `SQL::Concat->new(%args)`


Constructor, inherited from [MOP4Import::Base::Configure](https://metacpan.org/pod/MOP4Import::Base::Configure).

### Options

Following options has their getter.
To set these options after new,
use ["configure" in MOP4Import::Base::Configure](https://metacpan.org/pod/MOP4Import::Base::Configure#configure) method.

- sep


    Separator, used in [concat()](#concat).

- sql


    SQL, constructed when [concat()](#concat) is called.
    Once set, you are not allowed to call ["concat"](#concat) again.

- bind


    Bind variables, constructed when ["BIND\_ARRAY"](#bind_array) is given to [concat()](#concat).

## `SQL::Concat->concat( @ITEMS... )`


Central operation of SQL::Concat. It basically does:

```perl
$self->{bind} = [];
foreach my MY $item (@_) {
  next unless defined $item;
  if (not ref $item) {
    push @sql, $item;
  } else {
    $item = SQL::Concat->of_bind_array($item)
      if ref $item eq 'ARRAY';

    $item->validate_placeholders;

    push @sql, $item->{sql};
    push @{$self->{bind}}, @{$item->{bind}};
  }
}
$self->{sql} = join($self->{sep}, @sql);
```

## `SQL::Concat->concat_by($SEP, @I..)`


Equiv. of `SQL::Concat->new(sep => $SEP)->concat( @ITEMS... )`

## `->is_empty()`


Test whether `$obj->sql` doesn't contain `/\S/` or not.

## `->paren()`


Equiv. of `$obj->is_empty ? () : $obj->format_by('(%s)')`.

## `->paren_nl_indent()`


Indenting version of [->paren()](#paren) method.

```perl
$q = SQL("select * from artists where aid in"
         => SQL(["select aid from records where release_year = ?", $year])
            ->paren_nl_indent
     );
```

Above generates following:

```
select * from artists where aid in (
  select aid from records where release_year = ?
)
```

## `->format_by($FMT, ?$INDENT?)`


Apply `sprintf($FMT, $self->sql)`.
This will create a clone of $self.

If optional integer argument `$INDENT` is given, `sql` is indented
before formatting.

## `->as_sql_bind()`


```perl
my ($sql, @bind) = SQL(...)->as_sql_bind;
```

Extract `$self->sql` and `@{$self->bind}`.
If caller is scalar context, wrap them with `[]`.

## `->sql_bind_pair()`


```perl
my ($sql, $bind) = SQL(...)->sql_bind_pair;
```

Extract `[$self->sql, $self->bind]`.
If caller is scalar context, wrap them with `[]`.

# MISC

## Complex example

```perl
use SQL::Concat qw/SQL CAT OPT/;

my ($tags, $limit, $offset, $reverse) = @_;

my $pager = OPT("limit ?", $limit, OPT("offset ?", $offset));

my ($sql, @bind)
  = SQL("SELECT datetime(ts, 'unixepoch', 'localtime') as dt, eid, path"
        , "FROM entrytext"
        , ($tags
           ? SQL("WHERE eid IN"
                 , SQL("SELECT eid FROM"
                       => CAT("\nINTERSECT\n"
                              => map {
                                SQL("SELECT DISTINCT eid, ts FROM entry_tag"
                                    , "WHERE tid IN"
                                    => SQL("SELECT tid FROM tag WHERE"
                                           , ["tag glob ?", lc($_)])
                                    ->paren_nl_indent
                                  )
                              } @$tags
                            )->paren_nl_indent
                       , "\nORDER BY"
                       , "ts desc, eid desc"
                       , $pager)->paren_nl_indent
               )
           : ())
        , "\nORDER BY"
        , "fid desc, feno desc"
        , ($tags ? () : $pager)
      )->as_sql_bind;
```

Generated SQL example:

```
SELECT datetime(ts, 'unixepoch', 'localtime') as dt, eid, path FROM entrytext WHERE eid IN (
  SELECT eid FROM (
    SELECT DISTINCT eid, ts FROM entry_tag WHERE tid IN (
      SELECT tid FROM tag WHERE tag glob ?
    )
    INTERSECT
    SELECT DISTINCT eid, ts FROM entry_tag WHERE tid IN (
      SELECT tid FROM tag WHERE tag glob ?
    )
  )
  ORDER BY ts desc, eid desc limit ? offset ?
)
ORDER BY fid desc, feno desc
```

# SEE ALSO

[SQL::Object](https://metacpan.org/pod/SQL::Object), [SQL::Maker](https://metacpan.org/pod/SQL::Maker), [SQL::QueryMaker](https://metacpan.org/pod/SQL::QueryMaker)

# LICENSE

Copyright (C) Kobayasi, Hiroaki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kobayasi, Hiroaki &lt;hkoba @ cpan.org>
