# NAME

Mojolicious::Plugin::ConfigAny - Mojolicious Plugin for Config::Any support

# VERSION

version 0.1.3

# SYNOPSIS

    # Mojolicious
    $self->plugin('ConfigAny');
    $self->plugin(ConfigAny => {
        identifier => 'foo' # identifier for config directories
        prefix => 'bar'     # config files prefix
        extensions => [     # file extensions to search
          qw(json yml perl)
        ]
      }
    );

    # Mojolicious::Lite
    plugin 'ConfigAny';

# DESCRIPTION

[Mojolicious::Plugin::ConfigAny](https://metacpan.org/pod/Mojolicious::Plugin::ConfigAny) is a [Mojolicious](https://metacpan.org/pod/Mojolicious) plugin.

# CONFIGRATION

The plugin configration options listed as following:

- identifier

    Should be a string or not setted - plugin will use `$app->moniker`
    as default.

- prefix

    Config file prefix, default is `$app->moniker` too.

- extensions

    This is an TODO option, an array reference that used as file extension,
    by default we use `Config::Any->extensions` in direct.
    If you want to set the `extensions` option, you could
    only use subset of them.

# METHODS

[Mojolicious::Plugin::ConfigAny](https://metacpan.org/pod/Mojolicious::Plugin::ConfigAny) inherits all methods from
[Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious::Plugin) and implements the following new ones.

## config\_dirs

[Mojolicious::Plugin::ConfigAny](https://metacpan.org/pod/Mojolicious::Plugin::ConfigAny) will generate a helper listing
all avaliable config directories.

## config\_files

[Mojolicious::Plugin::ConfigAny](https://metacpan.org/pod/Mojolicious::Plugin::ConfigAny) will generate a helper listing
all avaliable config files.

## register

    $plugin->register(Mojolicious->new);

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application.

# SEE ALSO

[Config::Any](https://metacpan.org/pod/Config::Any), [File::ConfigDir](https://metacpan.org/pod/File::ConfigDir),
[Mojolicious](https://metacpan.org/pod/Mojolicious), [Mojolicious::Guides](https://metacpan.org/pod/Mojolicious::Guides), [http://mojolicio.us](http://mojolicio.us).

# AUTHOR

Huo Linhe &lt;huolinhe@berrygenomics.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Berry Genomics.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
