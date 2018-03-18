# NAME

Mojolicious::Plugin::Facets - Multiple facets for your app.

# SYNOPSIS

    package MyApp;

    use Mojo::Base 'Mojolicious';

    sub startup {
        my $app = shift;

        # set default static/renderer paths, routes and namespaces

        $app->plugin('Facets',
            backoffice => {
                host   => 'backoffice.example.com',
                setup  => \&_setup_backoffice
            }
            # or a path-based facet
            # request URL gets rebased to the facet path (for that path only)
            # backoffice => {
            #     path   => '/backoffice',
            #     setup  => \&_setup_backoffice
            # }
        );
    }

    sub _setup_backoffice {
        my $app = shift;

        # set default static/renderer paths, routes and namespaces
        @{$app->static->paths} = ($app->home->child('backoffice/static')->to_string);
        @{$app->renderer->paths} = ($app->home->child('backoffice/template')->to_string);

        # setup session
        $app->sessions->cookie_name('backoffice');
        $app->sessions->default_expiration(60 * 10); # 10 min

        # setup routes
        my $r = $app->routes;
        @{$r->namespaces} = ('MyApp::Backoffice');
        $r->get(...);
    }

# DESCRIPTION

Mojolicious::Plugin::Facets allows you to declare multiple facets on a Mojolicious app.
A Facet is a way to organize your app as if it were multiple apps. Each facet can
declare its own routes, namespaces, static paths and renderer paths.

A common use case is to create a facet for the backoffice application.

# HELPERS

## facet\_do

Run a subroutine in the context of a facet. Any code related to sessions,
routes, template rendering and static files works as if you were on that facet.

    # Example: get backoffice facet session when the facet shares the same host (i.e. path-based facet)
    my $backoffice_session = $c->facet_do(backoffice => sub { shift->session });

# LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Carlos Fernando Avila Gratz <cafe@kreato.com.br>
