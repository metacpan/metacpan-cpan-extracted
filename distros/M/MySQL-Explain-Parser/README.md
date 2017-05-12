[![Build Status](https://travis-ci.org/moznion/MySQL-Explain-Parser.png?branch=master)](https://travis-ci.org/moznion/MySQL-Explain-Parser) [![Coverage Status](https://coveralls.io/repos/moznion/MySQL-Explain-Parser/badge.png?branch=master)](https://coveralls.io/r/moznion/MySQL-Explain-Parser?branch=master)
# NAME

MySQL::Explain::Parser - Parser for result of EXPLAIN of MySQL

# SYNOPSIS

    use utf8;
    use MySQL::Explain::Parser qw/parse/;

    my $explain = <<'...';
    +----+-------------+-------+-------+---------------+---------+---------+------+------+----------+-------------+
    | id | select_type | table | type  | possible_keys | key     | key_len | ref  | rows | filtered | Extra       |
    +----+-------------+-------+-------+---------------+---------+---------+------+------+----------+-------------+
    |  1 | PRIMARY     | t1    | index | NULL          | PRIMARY | 4       | NULL | 4    | 100.00   |             |
    |  2 | SUBQUERY    | t2    | index | a             | a       | 5       | NULL | 3    | 100.00   | Using index |
    +----+-------------+-------+-------+---------------+---------+---------+------+------+----------+-------------+
    ...

    my $parsed = parse($explain);
    # =>
    #    [
    #        {
    #            'id'            => '1',
    #            'select_type'   => 'PRIMARY',
    #            'table'         => 't1',
    #            'type'          => 'index',
    #            'possible_keys' => undef,
    #            'key'           => 'PRIMARY',
    #            'key_len'       => '4',
    #            'ref'           => undef
    #            'rows'          => '4',
    #            'filtered'      => '100.00',
    #            'Extra'         => '',
    #        },
    #        {
    #            'id'            => '2',
    #            'select_type'   => 'SUBQUERY',
    #            'table'         => 't2',
    #            'type'          => 'index',
    #            'possible_keys' => 'a',
    #            'key'           => 'a',
    #            'key_len'       => '5',
    #            'ref'           => undef
    #            'rows'          => '3',
    #            'filtered'      => '100.00',
    #            'Extra'         => 'Using index',
    #        }
    #    ]

# DESCRIPTION

MySQL::Explain::Parser is the parser for result of EXPLAIN of MySQL.

This module provides `parse()` and `parse_vertical()` function.
These function receive the result of EXPLAIN or EXPLAIN EXTENDED, and return the parsed result as array reference that contains hash reference.

This module treat SQL's `NULL` as Perl's `undef`.

Please refer to the following pages to get information about format of EXPLAIN;

- [http://dev.mysql.com/doc/en/explain-output.html](http://dev.mysql.com/doc/en/explain-output.html)
- [http://dev.mysql.com/doc/en/explain-extended.html](http://dev.mysql.com/doc/en/explain-extended.html)

# FUNCTIONS

- `parse($explain : Str)`

    Returns the parsed result of EXPLAIN as ArrayRef\[HashRef\]. This function can be exported.

- `parse_vertical($explain : Str)`

    Returns the parsed result of EXPLAIN which is formatted vertical as ArrayRef\[HashRef\]. This function can be exported.

    e.g.

        use utf8;
        use MySQL::Explain::Parser qw/parse_vertical/;

        my $explain = <<'...';
        *************************** 1. row ***************************
                   id: 1
          select_type: PRIMARY
                table: t1
                 type: index
        possible_keys: NULL
                  key: PRIMARY
              key_len: 4
                  ref: NULL
                 rows: 4
             filtered: 100.00
                Extra:
        *************************** 2. row ***************************
                   id: 2
          select_type: SUBQUERY
                table: t2
                 type: index
        possible_keys: a
                  key: a
              key_len: 5
                  ref: NULL
                 rows: 3
             filtered: 100.00
                Extra: Using index
        ...

        my $parsed = parse_vertical($explain);

# LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

moznion <moznion@gmail.com>
