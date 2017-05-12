# NAME

Plack::Middleware::HubSignature - Validating payloads from GitHub

# SYNOPSIS

    use Plack::Builder;
    my $app = sub { ... };
    builder {
        enable "Plack::Middleware::HubSignature",
            secret => 'YOUR SECRET';
        $app;
    };

# DESCRIPTION

Plack::Middleware::HubSignature is for validating payloads from GitHub Webhooks.

# CONFIGURATION

## `secret`

Secret token set at GitHub Webhook setting. See [https://developer.github.com/webhooks/securing/](https://developer.github.com/webhooks/securing/) for more details.

# SEE ALSO

See [Github::Hooks::Receiver](https://metacpan.org/pod/Github::Hooks::Receiver) and [Plack::App::GitHub::WebHook](https://metacpan.org/pod/Plack::App::GitHub::WebHook) for apps to
receive GitHub Webhooks.

# LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Songmu <y.songmu@gmail.com>

# CONTRIBUTORS

Jakob Voﬂ <jako.voss@gbv.de>
