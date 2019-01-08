# NAME

Mojolicious::Plugin::PromiseActions - Automatic async and error handling for Promises

# SYNOPSIS

    plugin 'PromiseActions';

    get '/' => sub {
      my $c=shift;
      app->ua->get_p('ifconfig.me/all.json')->then(sub {
        $c->render(text=>shift->res->json('/ip_addr'));
      });
    };

# METHODS

## register

Sets up a around\_dispatch hook to disable automatic rendering and
add a default catch callback to render an exception page when
actions return a [Mojo::Promise](https://metacpan.org/pod/Mojo::Promise)

# COPYRIGHT AND LICENSE

Copyright (C) 2019, Marcus Ramberg.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

# AUTHORS

Joel Berger, `jberger@mojolicious.org`

Marcus Ramberg, `marcus@mojolicious.org`

# SEE ALSO

[https://github.com/kraih/mojo](https://github.com/kraih/mojo), [Mojolicious::Guides](https://metacpan.org/pod/Mojolicious::Guides),
[Mojo::Promise](https://metacpan.org/pod/Mojo::Promise), [Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious::Plugin)
