# NAME

Plack::Middleware::Antibot - Prevent bots from submitting forms

# SYNOPSIS

    use Plack::Builder;

    my $app = { ... };

    builder {
        enable 'Antibot', filters => [qw/FakeField TooFast/];
        $app;
    };

# DESCRIPTION

Plack::Middleware::Antibot is a [Plack](https://metacpan.org/pod/Plack) middleware that prevents bots from
submitting forms. Every filter implements its own checks, so see their
documentation.

Plack::Middleware::Antibot uses scoring system (0 to 1) to determine if the
client is a bot. Thus it can be configured to match any needs.

## `$env`

Some filters set additional `$env` keys all prefixed with `antibot.`. For
example `TextCaptcha` filter sets `antibot.text_captcha` to be shown to the
user.

## Options

### **max\_score**

When accumulated score reaches this amount, no more filters are run and bot is
detected. `0.8` by default.

### **filters**

    enable 'Antibot', filters => ['FakeField'];

To specify filter arguments instead of a filter name pass an array references:

    enable 'Antibot', filters => [['FakeField', field_name => 'my_fake_field']];

### **fall\_through**

    enable 'Antibot', filters => ['FakeField'], fall_through => 1;

Sometimes it is needed to process detected bot yourself. This way in case of
detection `$env`'s key `antibot.detected` will be set.

## Available filters

- [Plack::Middleware::Antibot::FakeField](https://metacpan.org/pod/Plack::Middleware::Antibot::FakeField) (requires [Plack::Session](https://metacpan.org/pod/Plack::Session))

    Check if an invisible or hidden field is submitted.

- [Plack::Middleware::Antibot::Static](https://metacpan.org/pod/Plack::Middleware::Antibot::Static) (requires [Plack::Session](https://metacpan.org/pod/Plack::Session))

    Check if a static file was fetched before form submission.

- [Plack::Middleware::Antibot::TextCaptcha](https://metacpan.org/pod/Plack::Middleware::Antibot::TextCaptcha) (requires [Plack::Session](https://metacpan.org/pod/Plack::Session))

    Check if correct random text captcha is submitted.

- [Plack::Middleware::Antibot::TooFast](https://metacpan.org/pod/Plack::Middleware::Antibot::TooFast)

    Check if form is submitted too fast.

- [Plack::Middleware::Antibot::TooSlow](https://metacpan.org/pod/Plack::Middleware::Antibot::TooSlow)

    Check if form is submitted too slow.

# ISA

[Plack::Middleware](https://metacpan.org/pod/Plack::Middleware)

# METHODS

## `prepare_app`

## `call($env)`

# INHERITED METHODS

## `wrap($app, @args)`

# AUTHOR

Viacheslav Tykhanovskyi, <viacheslav.t@gmail.com>

# COPYRIGHT AND LICENSE

Copyright (C) 2015, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

This program is distributed in the hope that it will be useful, but without any
warranty; without even the implied warranty of merchantability or fitness for
a particular purpose.
