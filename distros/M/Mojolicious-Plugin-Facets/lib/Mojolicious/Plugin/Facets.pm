package Mojolicious::Plugin::Facets;

use Mojo::Base 'Mojolicious::Plugin';
use Mojolicious::Routes;
use Mojolicious::Static;
use Mojolicious::Sessions;
use Mojo::Cache;
use Mojo::Path;

our $VERSION = "0.05";

my @facets;

sub register {
    my ($self, $app, $config) = @_;

    $app->hook(around_dispatch => \&_detect_facet);
    $app->helper(facet_do => \&_facet_do);

    my @default_static_paths = @{ $app->static->paths };
    my @default_renderer_paths = @{ $app->renderer->paths };
    my @default_routes_namespaces = @{ $app->routes->namespaces };

    foreach my $facet_name (keys %$config) {

        my $facet_config = $config->{$facet_name};
        die "Missing 'setup' key on facet '$facet_name' config." unless $facet_config->{setup};
        die "Missing 'host' or 'path' key on facet '$facet_name' config."
            unless $facet_config->{host} || $facet_config->{path};

        my $facet = {
            name => $facet_name,
            host => $facet_config->{host},
            routes => Mojolicious::Routes->new(namespaces => [@default_routes_namespaces]),
            static => Mojolicious::Static->new,
            sessions => Mojolicious::Sessions->new,
            renderer_paths => [@default_renderer_paths],
            renderer_cache => Mojo::Cache->new,
            $facet_config->{path} ? ( path => Mojo::Path->new($facet_config->{path})->leading_slash(1)->trailing_slash(0) ) : (),
        };

        # localize
        local $app->{routes} = $facet->{routes};
        local $app->{static} = $facet->{static};
        local $app->{sessions} = $facet->{sessions};
        local $app->renderer->{paths} = $facet->{renderer_paths};
        local $app->renderer->{cache} = $facet->{renderer_cache};

        # setup
        $facet_config->{setup}->($app);

        # store
        push @facets, $facet;
    }

}

sub _detect_facet {
    my ($next, $c) = @_;

    # detect facet
    my $active_facet;
    my $req_host = $c->req->headers->host;
    $req_host =~ s/:\d+$//;

    foreach my $facet (@facets) {

        my $match = 0;

        if ($facet->{host}) {
            $match = 1 if $req_host eq $facet->{host};
        }

        if ($facet->{path}) {

            if ($c->req->url->path->contains($facet->{path})) {
                $match = 1;

                # rebase
                my $path_length = scalar @{$facet->{path}};
                my $base_path = $c->req->url->base->path->trailing_slash(1);
                my $req_path = $c->req->url->path->leading_slash(0);

                while ($path_length--) {
                    push @$base_path, shift @$req_path;
                }
            }
            else {
                $match = 0;
            }
        }

        if ($match) {
            $active_facet = $facet;
            last
        }
    }

    # localize relevant data and continue dispatch chain
    if ($active_facet) {
        $c->app->log->debug(qq/Dispatching facet "$active_facet->{name}"/);

        $c->stash->{'mojox.facet'} = $active_facet->{name};

        local $c->app->{routes} = $active_facet->{routes};
        local $c->app->{static} = $active_facet->{static};
        local $c->app->{sessions} = $active_facet->{sessions};
        local $c->app->renderer->{paths} = $active_facet->{renderer_paths};
        local $c->app->renderer->{cache} = $active_facet->{renderer_cache};
        $next->();
    }
    else {
        # no facet, continue dispatch
        $next->();
    }
}


sub _facet_do {
    my ($c, $facet_name, $code) = @_;

    my ($facet) = grep { $_->{name} eq $facet_name } @facets;
    die "Facet '$facet_name' do not exist." unless $facet;

    local $c->app->{routes} = $facet->{routes};
    local $c->app->{static} = $facet->{static};
    local $c->app->{sessions} = $facet->{sessions};
    local $c->app->renderer->{paths} = $facet->{renderer_paths};
    local $c->app->renderer->{cache} = $facet->{renderer_cache};
    local $c->{stash} = {};
    $code->($c);
}





1;
__END__

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::Facets - Multiple facets for your app.

=head1 SYNOPSIS

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


=head1 DESCRIPTION

Mojolicious::Plugin::Facets allows you to declare multiple facets on a Mojolicious app.
A Facet is a way to organize your app as if it were multiple apps. Each facet can
declare its own routes, namespaces, static paths and renderer paths.

A common use case is to create a facet for the backoffice application.


=head1 HELPERS

=head2 facet_do

Run a subroutine in the context of a facet. Any code related to sessions,
routes, template rendering and static files works as if you were on that facet.

    # Example: get backoffice facet session when the facet shares the same host (i.e. path-based facet)
    my $backoffice_session = $c->facet_do(backoffice => sub { shift->session });


=head1 LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Carlos Fernando Avila Gratz E<lt>cafe@kreato.com.brE<gt>

=cut
