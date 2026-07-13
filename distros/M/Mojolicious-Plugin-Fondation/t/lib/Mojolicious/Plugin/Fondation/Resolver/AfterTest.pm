package Mojolicious::Plugin::Fondation::Resolver::AfterTest;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return {
        dependencies => [],
        after        => ['Fondation::Resolver::Leaf'],
        defaults     => { label => 'after-test' },
    };
}

sub register ($self, $app, $config) { return $self; }

1;
