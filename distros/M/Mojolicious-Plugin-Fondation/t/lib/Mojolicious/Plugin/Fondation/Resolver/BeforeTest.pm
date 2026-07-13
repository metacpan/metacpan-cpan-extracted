package Mojolicious::Plugin::Fondation::Resolver::BeforeTest;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return {
        dependencies => [],
        before       => ['Fondation::Resolver::Leaf'],
        defaults     => { label => 'before-test' },
    };
}

sub register ($self, $app, $config) { return $self; }

1;
