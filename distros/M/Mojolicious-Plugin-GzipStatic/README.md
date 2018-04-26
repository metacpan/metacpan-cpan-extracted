# NAME

Mojolicious::Plugin::GzipStatic - Mojolicious Plugin to compress the static files before serving them.

# SYNOPSIS

    # Mojolicious
    $self->plugin('GzipStatic');

    # Mojolicious::Lite
    plugin 'GzipStatic';

# DESCRIPTION

[Mojolicious::Plugin::GzipStatic](https://metacpan.org/pod/Mojolicious::Plugin::GzipStatic) is a [Mojolicious](https://metacpan.org/pod/Mojolicious) plugin to compress the static files before serving them.

See [https://en.wikipedia.org/wiki/HTTP\_compression](https://en.wikipedia.org/wiki/HTTP_compression) and
[http://mojolicious.org/perldoc/Mojolicious/Guides/Rendering#Post-processing-dynamic-content](http://mojolicious.org/perldoc/Mojolicious/Guides/Rendering#Post-processing-dynamic-content).

# METHODS

[Mojolicious::Plugin::GzipStatic](https://metacpan.org/pod/Mojolicious::Plugin::GzipStatic) inherits all methods from
[Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious::Plugin) and implements the following new ones.

## register

    $plugin->register(Mojolicious->new);

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application.

# SEE ALSO

[Mojolicious](https://metacpan.org/pod/Mojolicious), [Mojolicious::Guides](https://metacpan.org/pod/Mojolicious::Guides), [http://mojolicious.org](http://mojolicious.org), [Mojolicious::Static](https://metacpan.org/pod/Mojolicious::Static), [IO::Compress::Gzip](https://metacpan.org/pod/IO::Compress::Gzip).
