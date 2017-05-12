# NAME

Mojolicious::Plugin::Web::Auth::Site::Fitbit - Fitbit OAuth Plugin for Mojolicious::Plugin::Web::Auth

# VERSION

version 0.000002

# SYNOPSIS

    use URI::FromHash qw( uri );
    my $key = 'foo';
    my $secret = 'seekrit';

    my $access_token_url = uri(
        scheme   => 'https',
        username => $key,
        password => $secret,
        host     => 'api.fitbit.com',
        path     => 'oauth2/token',
    );

    my $authorize_url = uri(
        scheme   => 'https',
        username => $key,
        password => $secret,
        host     => 'www.fitbit.com',
        path     => 'oauth2/authorize',
    );

    # Mojolicious
    $self->plugin(
        'Web::Auth',
        module           => 'Fitbit',
        authorize_url    => $authorize_url,
        access_token_url => $access_token_url,
        key              => $key,
        scope =>
            'activity heartrate location nutrition profile sleep social weight',
        on_finished => sub {
            my ( $c, $access_token, $access_secret ) = @_;
            ...;
        },
    );

    # Mojolicious::Lite
    plugin 'Web::Auth',
        module           => 'Fitbit',
        authorize_url    => $authorize_url,
        access_token_url => $access_token_url,
        key              => $key,
        scope =>
        'activity heartrate location nutrition profile sleep social weight',
        on_finished => sub {
        my ( $c, $access_token, $access_secret ) = @_;
        ...;
        };

    # default authentication endpoint: /auth/fitbit/authenticate
    # default callback endpoint: /auth/fitbit/callback

# DESCRIPTION

This module adds [Fitbit](https://dev.fitbit.com/docs/) support to
[Mojolicious::Plugin::Web::Auth](https://metacpan.org/pod/Mojolicious::Plugin::Web::Auth).

# AUTHOR

Olaf Alders <olaf@wundercounter.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
