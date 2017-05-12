# NAME

Test::Deep::JSON - Compare JSON with Test::Deep

# SYNOPSIS

    use Test::Deep;
    use Test::Deep::JSON;

    cmp_deeply {
        foo => 'bar',
        payload => '{"a":1}',
    }, {
        foo => 'bar',
        payload => json({ a => ignore() }),
    };

# DESCRIPTION

Test::Deep::JSON provides `json($expected)` function to expect that
target can be parsed as a JSON string and matches (by `cmp_deeply`) with
_$expected_.

# FUNCTIONS

- json($expected)

    Exported by default.

    _$expected_ can be anything that `Test::Deep` recognizes.

    This parses the data as a JSON string, and compares the parsed object
    and _$expected_ by `Test::Deep` functionality.

    Fails if the data cannot be parsed as a JSON.

# AUTHOR

motemen <motemen@gmail.com>

# SEE ALSO

[Test::Deep](http://search.cpan.org/perldoc?Test::Deep)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
