# mojo-loco
Mojolicious plugin that launches a local GUI via default web browser

This is one way to create low-effort desktop applications using [Mojolicious](https://metacpan.org/pod/Mojolicious) (cross-platform if your code is sufficiently portable).

On server start, [Mojolicious::Plugin::Loco](https://metacpan.org/pod/Mojolicious::Plugin::Loco) this opens a dedicated window in your default internet browser, assuming an available desktop and default internet browser that [Browser::Open](https://metacpan.org/pod/Browser::Open) knows how to deal with.  The application server then listens on a loopback/localhost port, shutting down once the browser window and all descendants thereof are subsequently closed.

[Module documentation](lib/Mojolicious/Plugin/Loco.pod).

[Installation directions](INSTALL.md).

[Getting started with Mojolicious](https://metacpan.org/pod/Mojolicious)

## author

Roger Crew <wrog@cpan.org>

## copyright and license

This software is copyright (c) 2018 by Roger Crew.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
