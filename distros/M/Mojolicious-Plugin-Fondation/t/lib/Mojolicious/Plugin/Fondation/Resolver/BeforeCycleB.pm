package Mojolicious::Plugin::Fondation::Resolver::BeforeCycleB;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return {
        dependencies => [],
        before       => ['Fondation::Resolver::BeforeCycleA'],
        defaults     => {},
    };
}

sub register ($self, $app, $config) { return $self; }

1;
