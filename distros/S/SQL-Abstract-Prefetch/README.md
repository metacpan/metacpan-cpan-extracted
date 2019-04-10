# NAME

SQL::Abstract::Prefetch - implement "prefetch" for DBI RDBMS

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.com/mohawk2/SQL-Abstract-Prefetch.svg?branch=master)](https://travis-ci.com/mohawk2/SQL-Abstract-Prefetch) |

[![CPAN version](https://badge.fury.io/pl/SQL-Abstract-Prefetch.svg)](https://metacpan.org/pod/SQL::Abstract::Prefetch) [![Coverage Status](https://coveralls.io/repos/github/mohawk2/SQL-Abstract-Prefetch/badge.svg?branch=master)](https://coveralls.io/github/mohawk2/SQL-Abstract-Prefetch?branch=master)

# SYNOPSIS

    my $queryspec = {
      table => 'blog',
      fields => [
        'html',
        'id',
        'is_published',
        'markdown',
        'slug',
        'title',
        'user_id',
      ],
      keys => [ 'id' ],
      multi => {
        comments => {
          table => 'comment',
          fields => [ 'blog_id', 'html', 'id', 'markdown', 'user_id' ],
          keys => [ 'id' ],
        },
      },
      single => {
        user => {
          table => 'user',
          fields => [ 'access', 'age', 'email', 'id', 'password', 'username' ],
          keys => [ 'id' ],
        },
      },
    };
    my $abstract = SQL::Abstract::Pg->new( name_sep => '.', quote_char => '"' );
    my $dbh = DBI->connect( "dbi:SQLite:dbname=filename.db", '', '' );
    my $prefetch = SQL::Abstract::Prefetch->new(
      abstract => $abstract,
      dbhgetter => sub { $dbh },
      dbcatalog => undef, # for SQLite
      dbschema => undef,
      filter_table => sub { $_[0] !~ /^sqlite_/ },
    );
    my ( $sql, @bind ) = $prefetch->select_from_queryspec(
      $queryspec,
      { id => $items{blog}[0]{id} },
    );
    my ( $extractspec ) = $prefetch->extractspec_from_queryspec( $queryspec );
    my $sth = $dbh->prepare( $sql );
    $sth->execute( @bind );
    my ( $got ) = $prefetch->extract_from_query( $extractspec, $sth );

# DESCRIPTION

This class implements "prefetch" in the style of [DBIx::Class](https://metacpan.org/pod/DBIx::Class). Stages
of operation:

- Generate a "query spec" that describes what you want back from the
database - which fields from which tables, and what relations to join.
- Generate SQL (and bind parameters) from that "query spec".
- Pass the SQL and parameters to a [DBI](https://metacpan.org/pod/DBI) `$dbh` to prepare and execute.
- Pass the `$sth` when ready (this allows for asynchronous operation)
to the extractor method to turn the returned rows into the hash-refs
represented, including array-ref values for any "has many" relationships.

# ATTRIBUTES

## abstract

Currently, must be a [SQL::Abstract::Pg](https://metacpan.org/pod/SQL::Abstract::Pg) object.

## dbhgetter

A code-ref that returns a [DBI](https://metacpan.org/pod/DBI) `$dbh`.

## dbcatalog

The [DBI](https://metacpan.org/pod/DBI) "catalog" argument for e.g. ["column\_info" in DBI](https://metacpan.org/pod/DBI#column_info).

## dbschema

The [DBI](https://metacpan.org/pod/DBI) "schema" argument for e.g. ["column\_info" in DBI](https://metacpan.org/pod/DBI#column_info).

## filter\_table

Coderef called with a table name, returns a boolean of true to keep, false
to discard - typically for a system table.

## multi\_namer

Coderef called with a table name, returns a suitable name for the relation
to that table. Defaults to ["to\_PL" in Lingua::EN::Inflect::Number](https://metacpan.org/pod/Lingua::EN::Inflect::Number#to_PL).

## dbspec

By default, will be calculated from the supplied `$dbh`, using the
supplied `dbhgetter`, `dbcatalog`, `dbschema`, `filter_table`,
and `multi_namer`. May however be supplied, in which case those other
attributes are not needed.

A "database spec"; a hash-ref mapping tables to maps of the
relation-name (a string) to a further hash-ref with keys:

- type

    either `single` or `multi`

- fromkey

    the column name in the "from" table

- fromtable

    the name of the "from" table

- tokey

    the column name in the "to" table

- totable

    the name of the "to" table

The relation-name for "multi" will be calculated using
the `multi_namer` on the remote table name.

# METHODS

## select\_from\_queryspec

Parameters:

- a "query spec"; a hash-ref with these keys:
    - table
    - keys

        array-ref of fields that are primary keys on this table

    - fields

        array-ref of fields that are primitive types to show in result,
        including PKs if wanted. If not wanted, the joins still function.

    - single

        hash-ref mapping relation-names to "query specs" - a recursive data
        structure; the relation is "has one"

    - multi

        hash-ref mapping relation-names to "relate specs" as above; the relation is
        "has many"
- an [SQL::Abstract](https://metacpan.org/pod/SQL::Abstract) "where" specification
- an [SQL::Abstract](https://metacpan.org/pod/SQL::Abstract) "options" specification, including `order_by`,
`limit`, and `offset`

Returns the generated SQL, then a list of parameters to bind.

## extractspec\_from\_queryspec

Parameters: a "query spec" as above.

Returns an opaque "extract spec": data to be used by
["extract\_from\_query"](#extract_from_query) to interpret results generated from the
["select\_from\_queryspec"](#select_from_queryspec) query.

## extract\_from\_query

Parameters: an opaque "extract spec" created by
["extractspec\_from\_queryspec"](#extractspec_from_queryspec), and a [DBI](https://metacpan.org/pod/DBI) `$sth`.

Returns a list of hash-refs of items as reconstructed according to the spec.

# SEE ALSO

[Yancy::Backend](https://metacpan.org/pod/Yancy::Backend), [DBI](https://metacpan.org/pod/DBI), [DBIx::Class](https://metacpan.org/pod/DBIx::Class)
