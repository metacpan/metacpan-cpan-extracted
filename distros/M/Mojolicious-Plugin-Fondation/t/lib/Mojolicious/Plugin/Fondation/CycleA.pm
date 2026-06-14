package Mojolicious::Plugin::Fondation::CycleA;

# ABSTRACT: Test plugin for cycle detection -- depends on CycleB

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return {
        dependencies => ['Fondation::CycleB'],
        defaults     => {},
    };
}

sub register ($self, $app, $conf) {
    return $self;
}

1;
