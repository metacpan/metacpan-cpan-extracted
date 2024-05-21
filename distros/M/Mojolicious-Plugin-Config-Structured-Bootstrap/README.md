# NAME

Mojolicious::Plugin::Config::Structured::Bootstrap - an extremely opinionated plugin for initializing a full-featured Mojolicious application

# SYNOPSIS

    # in app startup
    $self->plugin('Config::Structured::Bootstrap'); 

    $self->plugin('Config::Structured::Bootstrap' => {
      $plugin_name => \%plugin_config, ...
    });

# DESCRIPTION

This plugin loads and initializes a specific set of other mojo plugins based on 
a predefined (though overridable) configuration structure:

- [Mojolicious::Plugin::Config::Structured](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AConfig%3A%3AStructured)
- [Mojolicious::Plugin::Authentication::OIDC](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AAuthentication%3A%3AOIDC)
- [Mojolicious::Plugin::Authorization::AccessControl](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AAuthorization%3A%3AAccessControl)
- [Mojolicious::Plugin::Cron::Scheduler](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ACron%3A%3AScheduler)
- [Mojolicious::Plugin::Data::Transfigure](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AData%3A%3ATransfigure)
- [Mojolicious::Plugin::Migration::Sqitch](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AMigration%3A%3ASqitch)
- [Mojolicious::Plugin::Module::Loader](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AModule%3A%3ALoader)
- [Mojolicious::Plugin::OpenAPI](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AOpenAPI)
- [Mojolicious::Plugin::ORM::DBIx](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AORM%3A%3ADBIx)
- [Mojolicious::Plugin::SendEmail](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ASendEmail)
- [Mojolicious::Plugin::Sessionless](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ASessionless)

Any plugin that is not installed is silently skipped; you can also disable any
plugin by setting it to an undefined configuration during initialization, e.g.,:

    $self->plugin('Config::Structured::Bootstrap' => {
      Sessionless => undef
    });

Further documentation on how to manually/automatically configure these plugins
is forthcoming...

# METHODS

[Mojolicious::Plugin::Data::Transfigure](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AData%3A%3ATransfigure) inherits all methods from 
[Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious%3A%3APlugin) and implements the following new ones

## register

Register the plugin in a Mojolicious application. Takes a HashRef as its 
configuration argument. Each key of the HashRef is the name of a sub-plugin
(e.g., `Migration::Sqitch`, with or without its `Mojolicious::Plugin::`) 
prefix. Setting the config value for a plugin to `undef` prevents loading that
plugin.

# AUTHOR

Mark Tyrrell `<mark@tyrrminal.dev>`

# LICENSE

Copyright (c) 2024 Mark Tyrrell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
