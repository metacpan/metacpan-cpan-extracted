# NAME

PHP::ParseStr - Implements PHP's parse\_str function

[![Build Status](https://travis-ci.org/abayliss/php-parsestr.svg?branch=master)](https://travis-ci.org/abayliss/php-parsestr)

# SYNOPSIS

    use PHP::ParseStr qw(php_parse_str);
    my $hr = php_parse_str("stuff[0]=things&stuff[1]=otherthings&widgit[name]=thing&widgit[id]=123");

# DESCRIPTION

A simple implementation of PHP's `parse_str` function. The inverse of
`http_build_query` (implemented by [PHP::HTTPBuildQuery](https://metacpan.org/pod/PHP::HTTPBuildQuery)).

# USAGE

Pass your query string into `php_parse_str` and get a hash ref back.

    my $hr = php_parse_str("stuff[0]=things&stuff[1]=otherthings&widgit[name]=thing&widgit[id]=123");
    # {
    #     stuff => [ 'things', 'otherthings' ],
    #     widgit => {
    #         id => '123',
    #         name => 'thing'
    #     }
    # }

Note that unlike PHP's `parse_str`, we return a hash ref, rather than
automagically creating variables in the passing scope, or filling a hash passed
in by reference. This is A Good Thing.

# BUGS / LIMITATIONS

Currently I assume that anything where the "key" is numeric will be an array.
This will cause problems if you get structures with mixed numeric and
alphanumeric keys if a numeric one is encountered first.

This module worked well enough for my purposes. YMMV. Patches welcome.

# SEE ALSO

[PHP::HTTPBuildQuery](https://metacpan.org/pod/PHP::HTTPBuildQuery) does the inverse of this module.

# AUTHOR

Andrew Bayliss &lt;abayliss@gmail.com>

# COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.
