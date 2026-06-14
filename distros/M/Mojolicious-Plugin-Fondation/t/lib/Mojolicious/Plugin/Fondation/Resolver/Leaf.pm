package Mojolicious::Plugin::Fondation::Resolver::Leaf;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return {
        dependencies => [],
        defaults     => { level => 'leaf', key_test => 'leaf_default' },
    };
}

1;
