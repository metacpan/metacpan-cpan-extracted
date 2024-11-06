[![Actions Status](https://github.com/karjala/mojo-useragent-role-total_timeout/actions/workflows/test.yml/badge.svg)](https://github.com/karjala/mojo-useragent-role-total_timeout/actions)
# NAME

Mojo::UserAgent::Role::TotalTimeout - Role for Mojo::UserAgent that enables setting total timeout including redirects

# SYNOPSIS

    use Mojo::UserAgent;

    my $class = Mojo::UserAgent->with_roles('+TotalTimeout');
    my $ua = $class->max_redirects(5)->total_timeout(10);

# DESCRIPTION

Mojo::UserAgent::Role::TotalTimeout is a role for LMojo::UserAgent> that simply allows setting a total timeout to
the useragent that includes redirects.

# ATTRIBUTES

Mojo::UserAgent::Role::Timeout adds the following attribute to the [Mojo::UserAgent](https://metacpan.org/pod/Mojo%3A%3AUserAgent) object:

## total\_timeout

    my $ua = $class->new;
    $ua->total_timeout(10);

The number of seconds the whole request (including redirections) will timeout at.

Defaults to 0, which disables the time limit.

[Mojo::UserAgent](https://metacpan.org/pod/Mojo%3A%3AUserAgent)'s other timeouts (like `request_timeout`) still apply regardless of this attribute's value.

# TODO

- Write tests

# LICENSE

Copyright (C) Alexander Karelas.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Alexander Karelas <karjala@cpan.org>
