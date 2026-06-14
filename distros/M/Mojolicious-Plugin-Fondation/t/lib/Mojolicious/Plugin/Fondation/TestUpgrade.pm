package Mojolicious::Plugin::Fondation::TestUpgrade;

# ABSTRACT: Test plugin providing fondation_upgrade steps

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return {
        dependencies => [],
        defaults     => {
            fondation_upgrade => [
                ['test_upgrade', 'migrate'],
            ],
        },
    };
}

sub register ($self, $app, $conf) {
    return $self;
}

1;
