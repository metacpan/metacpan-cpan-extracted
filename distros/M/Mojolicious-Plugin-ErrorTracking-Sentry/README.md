# NAME

Mojolicious::Plugin::ErrorTracking::Sentry - error tracking plugin for Mojolicious with Sentry

# SYNOPSIS

    # Mojolicious
    $self->plugin('ErrorTracking::Sentry', sentry_dsn => 'http://<publickey>:<secretkey>@app.getsentry.com/<projectid>');

    # Custom error context handling
    use Sentry::Raven;

    $self->plugin('ErrorTracking::Sentry',
        sentry_dsn => 'http://<publickey>:<secretkey>@app.getsentry.com/<projectid>',
        on_error => sub {
            my $c = shift;
            # Make context you want.
            my %user_context = Sentry::Raven->user_context(
                id => $c->stash->{user}->{id},
            );
            return \%user_context; # Must return HashRef.
        },
    );

# DESCRIPTION

Mojolicious::Plugin::ErrorTracking::Sentry is a Mojolicious plugin to send error reports to Sentry.

# CONFIG

## `sentry_dsn => 'http://<publickey>:<secretkey>@app.getsentry.com/<projectid>'`

The DSN for your sentry service.  Get this from the client configuration page for your project.

## `timeout => 5`

Do not wait longer than this number of seconds when attempting to send an event.

## `on_error`

You can pass custom error context. For example

    $self->plugin('ErrorTracking::Sentry', on_error => sub {
        my $c = shift;
        return +{
            Sentry::Raven->user_context(id => $c->stash->{id}) ,
        };
    });

# SEE ALSO

- [Sentry::Raven](https://metacpan.org/pod/Sentry::Raven)

    This plugin uses Sentry::Raven.

# AUTHORS

Akira Osada <osd.akira@gmail.com>

Andrew Pam <apam@infoxchange.org>

# COPYRIGHT AND LICENSE

Copyright 2017, 2019 Akira Osada and Andrew Pam

Released under the MIT license
http://opensource.org/licenses/mit-license.php
