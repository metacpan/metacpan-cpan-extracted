package Mojolicious::Plugin::Fondation::Resolver::CycleX;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return {
        dependencies => ['Fondation::Resolver::CycleY'],
        defaults     => {},
    };
}

1;
