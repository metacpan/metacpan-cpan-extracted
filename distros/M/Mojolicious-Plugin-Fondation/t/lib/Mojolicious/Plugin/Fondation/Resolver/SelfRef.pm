package Mojolicious::Plugin::Fondation::Resolver::SelfRef;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return {
        dependencies => ['Fondation::Resolver::SelfRef'],
        defaults     => {},
    };
}

1;
