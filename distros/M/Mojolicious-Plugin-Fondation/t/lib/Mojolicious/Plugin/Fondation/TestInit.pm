package Mojolicious::Plugin::Fondation::TestInit;

# ABSTRACT: Test plugin providing fondation_init steps

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return {
        dependencies => [],
        defaults     => {
            fondation_init => [
                ['test_init', 'setup'],
                ['test_init', 'seed'],
            ],
        },
    };
}

sub register ($self, $app, $conf) {
    return $self;
}

1;
