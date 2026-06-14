package Mojolicious::Plugin::Fondation::Resolver::CycleY;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return {
        dependencies => ['Fondation::Resolver::CycleX'],
        defaults     => {},
    };
}

1;
