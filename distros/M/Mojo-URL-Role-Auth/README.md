[![Actions Status](https://github.com/vague666/Mojo-URL-Role-Auth/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/vague666/Mojo-URL-Role-Auth/actions?workflow=test)
# NAME

Mojo::URL::Role::Auth - Use 2-arg function to add userinfo to url

# SYNOPSIS

    my $url = Mojo::URL->new('https://example.com')->with_roles('+Auth');
    $url->auth('u53rn4m3', 'p455w0rd');
    say $url->to_unsafe_string; # gives https://u53rn4m3:p455w0rd@example.com

# DESCRIPTION

This role adds a new method that takes two arguments to set userinfo for a url

# METHODS

## auth

    my $url = Mojo::URL->new->with_roles('+Auth');
    $url->auth('u53rn4m3', 'p455w0rd');

# LICENSE

Copyright (C) Jari Matilainen.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

vague <vague@cpan.org>
