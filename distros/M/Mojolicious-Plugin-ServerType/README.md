# NAME

Mojolicious::Plugin::ServerType - A Mojolicious Plugin that provides a helper
that identifies the server type

# SYNOPSIS

    use Mojo::Base -strict;

    use Mojolicious::Lite;

    plugin 'ServerType';

    get '/' => sub {
        my $c = shift;

        $c->render( json => {"serverType" => $c->app->server_type } );
    };

    app->start;

# DESCRIPTION

Mojolicious::Plugin::ServerType is a Mojolicious Plugin that provides a helper
which can be used to identify the type of server that Mojolicious is
running in (e.g. `Mojo::Server::Daemon`, `Mojo::Server::Prefork`)

# HELPERS

- `server_type`

    Mojolicious::Plugin::ServerType adds the `server_type` helper which simply
    returns the Class of the server that it's running under.  If not running under
    a server or the server doesn't support the `before_server_start` hook then
    `undef` will be returned.

# LICENSE

Copyright (C) Jason Cooper.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Jason Cooper <JLCOOPER@cpan.org>
