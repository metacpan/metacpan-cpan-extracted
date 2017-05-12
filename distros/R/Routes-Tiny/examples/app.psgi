#!/usr/bin/env perl

use strict;
use warnings;

use Routes::Tiny;

my $routes = build_routes();

sub {
    my $env = shift;

    my $path   = $env->{PATH_INFO};
    my $method = $env->{REQUEST_METHOD};

    if (my $match = $routes->match($path, method => $method)) {
        my $action = $match->params->{action};

        return [200, [], ['Hello from ' . $action]];
    }

    return [404, [], ['Not Found']];
};

sub build_routes {

    my $routes = Routes::Tiny->new;

    $routes->add_route('/:action');

    return $routes;
}
