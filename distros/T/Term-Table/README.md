# NAME

Term::Table - Format a header and rows into a table

# DESCRIPTION

This is used by some failing tests to provide diagnostics about what has gone
wrong. This module is able to format rows of data into tables.

# SYNOPSIS

    use Term::Table;

    my $table = Term::Table->new(
        max_width      => 80,    # Defaults to terminal size
        pad            => 4,     # Extra padding between table and max-width (defaults to 4)
        allow_overflow => 0,     # Default is 0, when off an exception will be thrown if the table is too big
        collapse       => 1,     # Do not show empty columns

        header => ['name', 'age', 'hair color'],
        rows   => [
            ['Fred Flintstone',  2000000, 'black'],
            ['Wilma Flintstone', 1999995, 'red'],
            ...
        ],
    );

    say $_ for $table->render;

This prints a table like this:

    +------------------+---------+------------+
    | name             | age     | hair color |
    +------------------+---------+------------+
    | Fred Flintstone  | 2000000 | black      |
    | Wilma Flintstone | 1999995 | red        |
    | ...              | ...     | ...        |
    +------------------+---------+------------+

# INTERFACE

    use Term::Table;
    my $table = Term::Table->new(...);

## OPTIONS

- header => \[ ... \]

    If you want a header specify it here.
    This takes an arrayref with each columns heading.

- rows => \[ \[...\], \[...\], ... \]

    This should be an arrayref containing an arrayref per row.

- collapse => $bool

    Use this if you want to hide empty columns, that is any column that has no data
    in any row. Having a header for the column will not effect collapse.

- max\_width => $num

    Set the maximum width of the table, the table may not be this big, but it will
    be no bigger. If none is specified it will attempt to find the width of your
    terminal and use that, otherwise it falls back to the terminal width or `80`.

- pad => $num

    Defaults to `4`, extra padding for row width calculations.
    Default is for legacy support.
    Set this to `0` to turn padding off.

- allow\_overflow => $bool

    Defaults to `0`. If this is off then an exception will be thrown if the table
    cannot be made to fit inside the max-width. If this is set to `1` then the
    table will be rendered anyway, larger than max-width, if it is not possible
    to stay within the max-width. In other words this turns max-width from a
    hard-limit to a soft recommendation.

- sanitize => $bool

    This will sanitize all the data in the table such that newlines, control
    characters, and all whitespace except for ASCII 20 `' '` are replaced with
    escape sequences. This prevents newlines, tabs, and similar whitespace from
    disrupting the table.

    **Note:** newlines are marked as `\n`, but a newline is also inserted into the
    data so that it typically displays in a way that is useful to humans.

    Example:

        my $field = "foo\nbar\nbaz\n";

        print join "\n" => table(
            sanitize => 1,
            rows => [
                [$field,      'col2'     ],
                ['row2 col1', 'row2 col2']
            ]
        );

    Prints:

        +-----------------+-----------+
        | foo\n           | col2      |
        | bar\n           |           |
        | baz\n           |           |
        |                 |           |
        | row2 col1       | row2 col2 |
        +-----------------+-----------+

    So it marks the newlines by inserting the escape sequence, but it also shows
    the data across as many lines as it would normally display.

- mark\_tail => $bool

    This will replace the last whitespace character of any trailing whitespace with
    its escape sequence. This makes it easier to notice trailing whitespace when
    comparing values.

- show\_header => $bool

    Set this to false to hide the header. This defaults to true if the header is
    set, false if no header is provided.

- auto\_columns => $bool

    Set this to true to automatically add columns that are not named in the header.
    This defaults to false if a header is provided, and defaults to true when there
    is no header.

- no\_collapse => \[ $col\_num\_a, $col\_num\_b, ... \]
- no\_collapse => \[ $col\_name\_a, $col\_name\_b, ... \]
- no\_collapse => { $col\_num\_a => 1, $col\_num\_b => 1, ... }
- no\_collapse => { $col\_name\_a => 1, $col\_name\_b => 1, ... }

    Specify (by number and/or name) columns that should not be removed when empty.
    The 'name' form only works when a header is specified. There is currently no
    protection to insure that names you specify are actually in the header, invalid
    names are ignored, patches to fix this will be happily accepted.

# NOTE ON UNICODE/WIDE CHARACTERS

Some unicode characters, such as `婧` (`U+5A67`) are wider than others. These
will render just fine if you `use utf8;` as necessary, and
[Unicode::GCString](https://metacpan.org/pod/Unicode%3A%3AGCString) is installed, however if the module is not installed there
will be anomalies in the table:

    +-----+-----+---+
    | a   | b   | c |
    +-----+-----+---+
    | 婧 | x   | y |
    | x   | y   | z |
    | x   | 婧 | z |
    +-----+-----+---+

# SOURCE

The source code repository for `Term-Table` can be found at
[https://github.com/exodist/Term-Table/](https://github.com/exodist/Term-Table/).

# MAINTAINERS

- Chad Granum <exodist@cpan.org>

# AUTHORS

- Chad Granum <exodist@cpan.org>

# COPYRIGHT

Copyright 2016 Chad Granum <exodist@cpan.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See [https://dev.perl.org/licenses/](https://dev.perl.org/licenses/)
