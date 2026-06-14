package Mojolicious::Plugin::Fondation::Resolver::Mid;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return {
        dependencies => ['Fondation::Resolver::Leaf'],
        defaults     => { level => 'mid', key_test => 'mid_default' },
    };
}

1;
