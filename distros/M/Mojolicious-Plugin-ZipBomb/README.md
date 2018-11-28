# NAME

Mojolicious::Plugin::ZipBomb - Mojolicious Plugin to serve a zip bomb on configured routes.

# SYNOPSIS

    # Mojolicious
    $self->plugin('ZipBomb', { routes => ['/wp-admin.php'], methods => ['get'] });

    # Mojolicious::Lite
    plugin 'ZipBomb', { routes => ['/wp-admin.php'], methods => ['get'] } };

# DESCRIPTION

[Mojolicious::Plugin::ZipBomb](https://metacpan.org/pod/Mojolicious::Plugin::ZipBomb) is a [Mojolicious](https://metacpan.org/pod/Mojolicious) plugin to serve a zip bomb on configured routes.

# CONFIGURATION

When registering the plugin, `routes` is required, but `methods` is optional.
Per default, the routes leading to the zip bomb use any method.

# METHODS

[Mojolicious::Plugin::ZipBomb](https://metacpan.org/pod/Mojolicious::Plugin::ZipBomb) inherits all methods from
[Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious::Plugin) and implements the following new ones.

## register

    $plugin->register(Mojolicious->new);

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application.

# SEE ALSO

[Mojolicious](https://metacpan.org/pod/Mojolicious), [Mojolicious::Guides](https://metacpan.org/pod/Mojolicious::Guides), [https://mojolicious.org](https://mojolicious.org).
