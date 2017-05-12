# NAME

Mojolicious::Plugin::DebugDumperHelper - Mojolicious Plugin

# DESCRIPTION

[Mojolicious::Plugin::DebugDumperHelper](https://metacpan.org/pod/Mojolicious::Plugin::DebugDumperHelper) is a [Mojolicious](https://metacpan.org/pod/Mojolicious) plugin which provides a helper which dumps its arguments to the debug log level (no effect in production mode).

# SYNOPSIS

    # Mojolicious
    $self->plugin('DebugDumperHelper');

    # Mojolicious::Lite
    plugin 'DebugDumperHelper';

    # Use in controller
    $c->debug(qw<Bite my shiny ass!>);
    # In your development.log
    [Wed Jun 10 19:32:01 2015] [debug] VAR DUMP
    [
      "Bite",
      "my",
      "shiny",
      "ass!"
    ]

# METHODS

[Mojolicious::Plugin::DebugDumperHelper](https://metacpan.org/pod/Mojolicious::Plugin::DebugDumperHelper) inherits all methods from
[Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious::Plugin) and implements the following new ones.

## register

    $plugin->register(Mojolicious->new);

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application.

# BUGS and SUPPORT

The latest source code can be browsed and fetched at:

    https://framagit.org/luc/mojolicious-plugin-debugdumperhelper
    git clone https://framagit.org/luc/mojolicious-plugin-debugdumperhelper.git

Bugs and feature requests will be tracked at:

    https://framagit.org/luc/mojolicious-plugin-debugdumperhelper/issues

# AUTHOR

    Luc DIDRY
    CPAN ID: LDIDRY
    ldidry@cpan.org
    https://fiat-tux.fr/

# COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

# SEE ALSO

[Mojolicious](https://metacpan.org/pod/Mojolicious), [Mojolicious::Guides](https://metacpan.org/pod/Mojolicious::Guides), [http://mojolicio.us](http://mojolicio.us).
