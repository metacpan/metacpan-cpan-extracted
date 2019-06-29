# Mojolicious-Plugin-GetSentry [![Build Status](https://travis-ci.org/crlcu/Mojolicious-Plugin-GetSentry.svg?branch=master)](https://travis-ci.org/crlcu/Mojolicious-Plugin-GetSentry)
Sentry client for Mojolicious

# Intialization

```perl
$self->plugin('GetSentry', {
    sentry_dsn => '...',
    log_levels => ['error', 'fatal'],
    tags_context => sub {
        my ($plugin, $controller) = @_;

        $plugin->raven->merge_tags(
            account => $controller->current_user->account_id,
        );
    },
    user_context => {
        my ($plugin, $controller) = @_;

        $plugin->raven->add_context(
            $plugin->raven->user_context(
                id          => 1,
                ip_address  => '10.10.10.1',
            )
        );
    },
    request_context => {
        my ($plugin, $controller) = @_;

        $plugin->raven->add_context(
            $plugin->raven->request_context('https://custom.domain/profile', method => 'GET', headers => { ... });
        );
    },
});
```

# Defaults

- `tags_context` - nothing is captured by default
- `user_context` - this plugin is trying to capture the `user id` and the `ip address`
- `request_context` - this plugin is trying to capture the `url`, `request method` and the `headers`
