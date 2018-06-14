[![MetaCPAN Release](https://badge.fury.io/pl/Mojolicious-Plugin-Prometheus-Shared-FastMmap.svg)](https://metacpan.org/release/Mojolicious-Plugin-Prometheus-Shared-FastMmap)
# NAME

Mojolicious::Plugin::Prometheus::Shared::FastMmap - Mojolicious Plugin

# SYNOPSIS

    # Mojolicious
    $self->plugin('Prometheus::Shared::FastMmap');

    # Mojolicious::Lite
    plugin 'Prometheus::Shared::FastMmap';

    # Mojolicious::Lite, with custom response buckets (seconds)
    plugin 'Prometheus::Shared::FastMmap' => { response_buckets => [qw/4 5 6/] };

# DESCRIPTION

[Mojolicious::Plugin::Prometheus::Shared::FastMmap](https://metacpan.org/pod/Mojolicious::Plugin::Prometheus::Shared::FastMmap) is a [Mojolicious](https://metacpan.org/pod/Mojolicious) plugin that exports Prometheus metrics from Mojolicious, using a shared mmapped file between workers.

It uses [Mojolicious::Plugin::Prometheus](https://metacpan.org/pod/Mojolicious::Plugin::Prometheus) under the hood, and adds a shared cache using [Mojolicious::Plugin::CHI](https://metacpan.org/pod/Mojolicious::Plugin::CHI) + [CHI](https://metacpan.org/pod/CHI) + [Cache::FastMmap](https://metacpan.org/pod/Cache::FastMmap) to provide metrics for all workers under a pre-forking daemon like [Mojo::Server::Hypnotoad](https://metacpan.org/pod/Mojo::Server::Hypnotoad).

See [Mojolicious::Plugin::Prometheus](https://metacpan.org/pod/Mojolicious::Plugin::Prometheus) for more complete documentation.

# METHODS

[Mojolicious::Plugin::Prometheus::Shared::FastMmap](https://metacpan.org/pod/Mojolicious::Plugin::Prometheus::Shared::FastMmap) inherits all methods from
[Mojolicious::Plugin::Prometheus](https://metacpan.org/pod/Mojolicious::Plugin::Prometheus) and implements no new ones.

## register

    $plugin->register($app, \%config);

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application.

`%config` can have all the original values as [Mojolicious::Plugin::Prometheus](https://metacpan.org/pod/Mojolicious::Plugin::Prometheus), and adds the following keys:

- cache\_dir

    The path to store the mmapped file. See [CHI::Driver::FastMmap](https://metacpan.org/pod/CHI::Driver::FastMmap) for details (used as root\_dir).

    Default: ./cache

- cache\_size

    Defaults to '5m'. See [CHI::Driver::FastMmap](https://metacpan.org/pod/CHI::Driver::FastMmap) for details.

# AUTHOR

Vidar Tyldum

# COPYRIGHT AND LICENSE

Copyright (C) 2018, Vidar Tyldum

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

# SEE ALSO

- [Mojolicious::Plugin::Prometheus](https://metacpan.org/pod/Mojolicious::Plugin::Prometheus)
- [CHI::Driver::FastMmap](https://metacpan.org/pod/CHI::Driver::FastMmap)
- [Net::Prometheus](https://metacpan.org/pod/Net::Prometheus)
- [Mojolicious](https://metacpan.org/pod/Mojolicious)
- [Mojolicious::Guides](https://metacpan.org/pod/Mojolicious::Guides)
- [http://mojolicious.org](http://mojolicious.org)
