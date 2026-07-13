package Mojolicious::Plugin::Fondation::Resolver::BeforeGhost;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return {
        dependencies => [],
        before       => ['Fondation::Resolver::NonExistent'],
        defaults     => {},
    };
}

sub register ($self, $app, $config) { return $self; }

1;
