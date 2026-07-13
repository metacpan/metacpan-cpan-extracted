package Mojolicious::Plugin::Fondation::Resolver::BeforeAfterRoot;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return {
        dependencies => [
            'Fondation::Resolver::BeforeTest',
            'Fondation::Resolver::AfterTest',
            'Fondation::Resolver::Leaf',
        ],
        defaults => {},
    };
}

sub register ($self, $app, $config) { return $self; }

1;
