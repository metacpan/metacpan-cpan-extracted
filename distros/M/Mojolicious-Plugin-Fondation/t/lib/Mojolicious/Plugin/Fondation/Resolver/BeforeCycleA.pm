package Mojolicious::Plugin::Fondation::Resolver::BeforeCycleA;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return {
        dependencies => [],
        before       => ['Fondation::Resolver::BeforeCycleB'],
        defaults     => {},
    };
}

sub register ($self, $app, $config) { return $self; }

1;
