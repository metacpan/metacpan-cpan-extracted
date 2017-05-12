[![Build Status](https://travis-ci.org/sixapart/Mojolicious-Plugin-ClientIP.svg?branch=master)](https://travis-ci.org/sixapart/Mojolicious-Plugin-ClientIP)
# NAME

Mojolicious::Plugin::ClientIP - Get client's IP address from X-Forwarded-For

# SYNOPSIS

    use Mojolicious::Lite;

    plugin 'ClientIP';

    get '/' => sub {
        my $c = shift;
        $c->render(text => $c->client_ip);
    };

    app->start;

# DESCRIPTION

Mojolicious::Plugin::ClientIP is a Mojolicious plugin to get an IP address looks like client, not proxy, from X-Forwarded-For header.

# METHODS

## client\_ip

Find a client IP address from X-Forwarded-For. Private network addresses in XFF are ignored by default. If the good IP address is not found, it returns Mojo::Transaction#remote\_address.

# OPTIONS

## ignore

Specify IP list to be ignored with ArrayRef.

    plugin 'ClientIP', ignore => [qw(192.0.2.1 192.0.2.16/28)];

# LICENSE

Copyright (C) Six Apart, Ltd. <sixapart@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ziguzagu <ziguzagu@cpan.org>
