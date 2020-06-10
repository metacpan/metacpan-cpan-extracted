# NAME

Mojolicious::Command::proxy - Proxy web requests elsewhere

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.org/mohawk2/Mojolicious-Command-proxy.svg?branch=master)](https://travis-ci.org/mohawk2/Mojolicious-Command-proxy) |

[![CPAN version](https://badge.fury.io/pl/Mojolicious-Command-proxy.svg)](https://metacpan.org/pod/Mojolicious::Command::proxy)

# SYNOPSIS

    Usage: APPLICATION proxy [--from route_prefix] to_url

      mojo proxy http://example.com/subdir daemon -l http://*:3000
      mojo proxy -f /proxy http://example.com/subdir get /proxy/hi

    Options:
      -f, --from                  Proxying route prefix

# DESCRIPTION

[Mojolicious::Command::proxy](https://metacpan.org/pod/Mojolicious::Command::proxy) is a command line interface for
making an app that proxies some or all incoming requests elsewhere.
Having done so, it then passes the rest of its arguments to the app's
`start` method, as illustrated in the synopsis above.

One major reason for this is to be able to point your browser at
e.g. `localhost:3000` (see first example in synopsis). This relaxes
restrictions on e.g. Service Workers and push notifications, which
normally demand TLS, so you can test functionality even if your real
development server is running elsewhere.

# ATTRIBUTES

## description

    $str = $self->description;

## usage

    $str = $self->usage;

# METHODS

## run

    $get->run(@ARGV);

Run this command. It will add a ["proxy"](#proxy) route as below. If not supplied,
the `$from` will be empty-string.

Command-line arguments will only be parsed at the start of the
command-line. This allows you to pass option through to e.g. `daemon`.

As a special case, if the `app` attribute is exactly a
[Mojo::HelloWorld](https://metacpan.org/pod/Mojo::HelloWorld) app, it will replace its `routes` attribute with an
empty one first, since the `whatever` route clashes with the proxy route,
being also a match-everything wildcard route. This makes the `mojo proxy`
invocation function as expected.

## proxy

    Mojolicious::Command::proxy->proxy($app, $from_prefix, $to_prefix);

Add a route to the given app, with the given prefix, named `proxy`. It
will transparently proxy all matching requests to the give `$to`,
with all the same headers both ways.

It operates by simply appending everything after the `$from_prefix`,
which _can_ be an empty string (which is treated the same as solitary
`/`, doing what you'd expect), to the `$to_prefix`. E.g.:

    $cmd->proxy($app, '', '/subdir'); # /2 -> /subdir/2, / -> /subdir/ i.e. all
    $cmd->proxy($app, '/proxy', '/subdir'); # /proxy/2 -> /subdir/2

`$to` can be a path as well as a full URL, so you can also use this to
route internally. However, the author can see no good reason to do this
outside of testing.

It uses ["proxy->start\_p" in Mojolicious::Plugin::DefaultHelpers](https://metacpan.org/pod/Mojolicious::Plugin::DefaultHelpers#proxy-start_p) but
adds the full header-proxying behaviour.

# AUTHOR

Ed J

# COPYRIGHT AND LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
