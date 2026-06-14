package Mojolicious::Plugin::Fondation::CycleB;

# ABSTRACT: Test plugin for cycle detection -- depends on CycleA (creates a cycle)

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return {
        dependencies => ['Fondation::CycleA'],
        defaults     => {},
    };
}

sub register ($self, $app, $conf) {
    return $self;
}

1;
