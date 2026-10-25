
# SQL::Abstract::Pg [![](https://github.com/mojolicious/sql-abstract-pg/workflows/linux/badge.svg)](https://github.com/mojolicious/sql-abstract-pg/actions)

  [PostgreSQL](https://www.postgresql.org) features for [SQL::Abstract](https://metacpan.org/pod/SQL::Abstract).

```perl
use SQL::Abstract::Pg;

my $abstract = SQL::Abstract::Pg->new;
say $abstract->select('some_table');
```

## Installation

  All you need is a one-liner, it takes less than a minute.

    $ curl -L https://cpanmin.us | perl - -M https://cpan.metacpan.org -n SQL::Abstract::Pg

  We recommend the use of a [Perlbrew](http://perlbrew.pl) environment.

## Want to know more?

  Take a look at our excellent [documentation](https://mojolicious.org/perldoc/SQL/Abstract/Pg)!
