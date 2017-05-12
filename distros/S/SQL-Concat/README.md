# NAME

SQL::Concat - SQL concatenator, only cares about bind-vars, to write SQL generator. [![Build Status](https://travis-ci.org/hkoba/perl-SQL-Concat.svg?branch=master)](https://travis-ci.org/hkoba/perl-SQL-Concat)


# SYNOPSIS

```perl
    # Functional interface
    use SQL::Concat qw/SQL PAR/;

    my $composed = SQL(SELECT => "*" =>
                       FROM   => entries =>
                       WHERE  => ("uid =" =>
                                  PAR(SQL(SELECT => uid => FROM => authors =>
                                          WHERE => ["name = ?", 'foo'])))
                     );

    my ($sql, @bind) = $composed->as_sql_bind;
    # ==>
    # SQL: SELECT * FROM entries WHERE uid = (SELECT uid FROM authors WHERE name = ?)
    # BIND: foo

    # OO Interface
    my $comp = SQL::Concat->new(sep => ' ')
      ->concat(SELECT => foo => FROM => 'bar');
```

# DESCRIPTION

SQL::Concat is **NOT** a _SQL generator_, but a minimalistic
_SQL fragments concatenator_ with safe bind-variable handling.
See [lib/SQL/Concat.pod](lib/SQL/Concat.pod) for details.

# LICENSE

Copyright (C) KOBAYASI, Hiroaki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

KOBAYASI, Hiroaki &lt;buribullet@gmail.com>
