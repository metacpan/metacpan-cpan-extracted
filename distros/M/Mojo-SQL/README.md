
# Mojo::SQL

  Safely generate and compose SQL statements from [Perl](https://perl.org).

```perl
use Mojo::SQL qw(sql);

# {text => 'SELECT * FROM users WHERE name = $1', values => ['sebastian']}
my $query = sql('SELECT * FROM users WHERE name = ?', 'sebastian')->to_query;
```

To prevent SQL injection attacks, every `?` in the input becomes a placeholder in the generated query, with the
corresponding value bound to it. Partial statements can even be used recursively to build more complex queries.

Literal question marks can be escaped with `??`.

```perl
# {text => 'SELECT ? AS literal, $1 AS bound', values => ['value']}
my $query = sql('SELECT ?? AS literal, ? AS bound', 'value')->to_query;
```

```perl
my $role    = 'admin';
my $partial = sql('AND role = ?', $role);
my $name    = 'root';

# {text => 'SELECT * FROM users WHERE name = $1 AND role = $2', values => ['root', 'admin']}
my $query = sql('SELECT * FROM users WHERE name = ? ?', $name, $partial)->to_query;
```

Make partial statements optional to dynamically generate `WHERE` clauses.

```perl
my $optional = $foo ? sql('AND foo IS NOT NULL') : sql('');
my $query    = sql('SELECT * FROM users WHERE name = ? ?', 'sebastian', $optional)->to_query;
```

And if you need a little more control over the generated SQL query, you can also bypass safety features with
`sql_unsafe`. But make sure to handle unsafe values yourself with appropriate escaping functions for your database. For
PostgreSQL there are `escape_literal` and `escape_identifier` functions included with this module.

```perl
use Mojo::SQL qw(sql sql_unsafe escape_literal);

my $role    = 'role = ' . escape_literal('power user');
my $partial = sql_unsafe('AND ?', $role);
my $name    = 'root';

# {text => "SELECT * FROM users WHERE name = $1 AND role = 'power user'", values => ['root']}
my $query = sql('SELECT * FROM users WHERE name = ? ?', $name, $partial)->to_query;
```

For databases that do not support numbered placeholders like `$1` and `$2`, you can set a custom character with the
`placeholder` option.

```perl
# {text => 'SELECT * FROM users WHERE name = ?', values => ['root']}
my $query = sql('SELECT * FROM users WHERE name = ?', 'root')->to_query({placeholder => '?'});
```

## Installation

  All you need is Perl 5.20 or newer.

    $ cpanm -n Mojo::SQL

  We recommend the use of a [Perlbrew](http://perlbrew.pl) environment.

