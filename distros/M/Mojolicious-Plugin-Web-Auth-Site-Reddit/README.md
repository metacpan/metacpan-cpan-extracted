# NAME

Mojolicious::Plugin::Web::Auth::Site::Reddit - Reddit OAuth Plugin for Mojolicious::Plugin::Web::Auth

# VERSION

version 0.000004

# SYNOPSIS

    use URI::FromHash qw( uri );
    my $key = 'foo';
    my $secret = 'seekrit';

    my $access_token_url = uri(
        scheme   => 'https',
        username => $key,
        password => $secret,
        host     => 'www.reddit.com',
        path     => '/api/v1/access_token',
    );

    my $scope = 'identity,edit,flair,history,modconfig,modflair,modlog,modposts,modwiki,mysubreddits,privatemessages,read,report,save,submit,subscribe,vote,wikiedit,wikiread';

    # Mojolicious
    $self->plugin(
        'Web::Auth',
        module           => 'Reddit',
        access_token_url => $access_token_url,
        authorize_url =>
            'https://www.reddit.com/api/v1/authorize?duration=permanent',
        key         => 'Reddit consumer key',
        secret      => 'Reddit consumer secret',
        scope       => $scope,
        on_finished => sub {
            my ( $c, $access_token, $access_secret, $extra ) = @_;
            ...;
        },
    );

    # Mojolicious::Lite
    plugin 'Web::Auth',
        module      => 'Reddit',
        access_token_url => $access_token_url,
        authorize_url =>
            'https://www.reddit.com/api/v1/authorize?duration=permanent',
        key         => 'Reddit consumer key',
        secret      => 'Reddit consumer secret',
        scope       => $scope,
        on_finished => sub {
            my ( $c, $access_token, $access_secret, $extra ) = @_;
            ...
        };

    # default authentication endpoint: /auth/reddit/authenticate
    # default callback endpoint: /auth/reddit/callback

# DESCRIPTION

This module adds [Reddit](https://www.reddit.com/dev/api/) support to
[Mojolicious::Plugin::Web::Auth](https://metacpan.org/pod/Mojolicious::Plugin::Web::Auth).

The default `authorize_url` allows only for temporary tokens.  If you require
a refresh token, set your own `authorize_url` as in the example in the
SYNOPSIS.  Your `refresh_token` will be included in the `$extra` arg as seen
above.  For example, `$extra` may look like the following:

    {
        expires_in    => 3600,
        refresh_token => 'seekrit_token',
        scope =>
            'edit flair history identity modconfig modflair modlog modposts modwiki mysubreddits privatemessages read report save submit subscribe vote wikiedit wikiread',
        token_type => 'bearer',
    },

# AUTHOR

Olaf Alders <olaf@wundercounter.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
