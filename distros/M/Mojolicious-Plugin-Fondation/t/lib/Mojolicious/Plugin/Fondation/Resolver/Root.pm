package Mojolicious::Plugin::Fondation::Resolver::Root;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return {
        dependencies => ['Fondation::Resolver::Mid'],
        defaults     => { level => 'root', key_test => 'root_default' },
    };
}

1;
