[![Build Status](https://travis-ci.org/yowcow/p5-MojoX-Session-Simple.svg?branch=master)](https://travis-ci.org/yowcow/p5-MojoX-Session-Simple)
# NAME

MojoX::Session::Simple - Plack::Middleware::Session::Simple adapter for Mojolicious

# SYNOPSIS

    use MojoX::Session::Simple;

    # Replace default session manager
    $mojo_app->sessions(
        MojoX::Session::Simple->new({
            default_expiration => 24 * 60 * 60, # 24 hours
        })
    );

    # In app.psgi, build mojo app to enable Plack::Middleware::Session::Simple.
    use Plack::Builder;

    build {
        enable 'Session::Simple',
            store => Cache::Memcached::Fast->new( ... ),
            cookie_name => 'my-test-app-session';

        $mojo_app->start;
    };

# DESCRIPTION

MojoX::Session::Simple provides compatibility to your [Mojolicious](https://metacpan.org/pod/Mojolicious) app to
transparently use [Plack::Middleware::Session::Simple](https://metacpan.org/pod/Plack::Middleware::Session::Simple) for session management
with no, or little, changes to existing controllers.

# ATTRIBUTES

[MojoX::Session::Simple](https://metacpan.org/pod/MojoX::Session::Simple) uses the following attributes implemented to [Mojolicious::Sessions](https://metacpan.org/pod/Mojolicious::Sessions).

## default\_expiration

For details, see [Mojolicious::Sessions](https://metacpan.org/pod/Mojolicious::Sessions).

# METHODS

## load

Load session data from `$env->{'psgix.session'}` into `$c->stash->{'mojo.session'}`.
Session data will be deleted if the session is expired.

## store

Store session data from `$c->stash->{'mojo.session'}` into `$env->{'psgix.session'}`.
You may regenerate session ID by setting the following flag in session data:

- regenerate

    [MojoX::Session::Simple](https://metacpan.org/pod/MojoX::Session::Simple) sets `$env->{'psgix.option'}{change_id} = 1` when:

        $c->session({ regenerate => 1 });

# LICENSE

Copyright (C) yowcow.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

yowcow <yowcow@cpan.org>
