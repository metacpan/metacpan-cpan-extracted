# NAME

Test::Deep::URI - Easier testing of URIs for Test::Deep

[![Build Status](https://travis-ci.org/nfg/Test-Deep-URI.svg?branch=master)](https://travis-ci.org/nfg/Test-Deep-URI)

# SYNOPSIS

```perl
use Test::Deep;
use Test::Deep::URI;

$testing_url = "http://site.com/path?a=1&b=2";
cmp_deeply(
    $testing_url,
    all(
        uri("http://site.com/path?a=1&b=2"),
        # or
        uri("//site.com/path?a=1&b=2"),
        # or
        uri("/path?b=2&a=1"),
    )
);

cmp_deeply(
    $testing_url,
    uri_qf("/path", { a => 1, b => ignore() }),
);
```

# DESCRIPTION

Test::Deep::URI provides the functions `uri($expected)` and
`uri_qf($expected, $query_form)` for [Test::Deep](https://metacpan.org/pod/Test%3A%3ADeep).
Use it in combination with `cmp_deeply` to test against partial URIs.

In particular I wrote this because I was tired of stumbling across unit
tests that failed because `http://site.com/?foo=1&bar=2` didn't match
`http://site.com/?bar=2&foo=1`. This helper is smart enough to compare
query\_form parameters separately, while still enforcing the order of values
for duplicate parameters.

# FUNCTIONS

- uri($expected)

    Exported by default.

    _$expected_ should be a string that can be passed to `URI->new()`.

- uri\_qf($expected, $query\_form)

    Exported by default.

    _$expected_ should be a string that can be passed to `URI->new()`.

    _$query\_form_ should be whatever structure you want to check the query
    form against.

# ERRATA

I've mostly been using this with URLs, but it's built around [URI](https://metacpan.org/pod/URI)
and should work with all types. Let me know if something doesn't work.

# AUTHOR

Nigel Gregoire <nigelgregoire@gmail.com>

# COPYRIGHT

Copyright 2016 - Nigel Gregoire

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

- [Test::Deep](https://metacpan.org/pod/Test%3A%3ADeep)
- [Test::Deep::JSON](https://metacpan.org/pod/Test%3A%3ADeep%3A%3AJSON)
- [Test::Deep::Filter](https://metacpan.org/pod/Test%3A%3ADeep%3A%3AFilter)
- [Test2::Tools::URL](https://metacpan.org/pod/Test2%3A%3ATools%3A%3AURL)
