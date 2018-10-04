# NAME

Mojolicious::Plugin::Web::Auth::Site::Strava - Strava OAuth Plugin for Mojolicious::Plugin::Web::Auth

# VERSION

version 0.000001

# SYNOPSIS

    my $client_id     = '9999';
    my $client_secret = 'seekrit';

    # Mojolicious
    $self->plugin(
        'Web::Auth',
        module           => 'Strava',
        key              => $client_id,
        secret           => $client_secret,
        scope       => 'view_private,write',
        on_finished => sub {
            my ( $c, $access_token, $access_secret ) = @_;
            ...;
        },
    );

    # Mojolicious::Lite
    plugin 'Web::Auth',
        module      => 'Strava',
        key         => $client_id,
        secret      => $client_secret,
        scope       => 'view_private,write',
        on_finished => sub {
        my ( $c, $access_token, $access_secret ) = @_;
        ...;
        };

# DESCRIPTION

This module adds [Strava](https://developers.strava.com/docs/authentication/)
support to [Mojolicious::Plugin::Web::Auth](https://metacpan.org/pod/Mojolicious::Plugin::Web::Auth).

# AUTHOR

Olaf Alders <olaf@wundercounter.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
