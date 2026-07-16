package Mojolicious::Plugin::Fondation::User;

# ABSTRACT: Minimal test plugin — declares the user model for Auth tests

use Mojo::Base 'Mojolicious::Plugin', -signatures;

our $VERSION = '0.01';

sub fondation_meta {
    return {
        dependencies => ['Fondation::Model::DBIx::Async'],
        defaults     => {
            models => {
                user => {
                    source  => 'User',
                    backend => undef,    # resolved via default_backend or first backend
                },
            },
        },
    };
}

sub register ($self, $app, $config) {
    # Model declaration is in fondation_meta defaults — nothing else needed.
    return $self;
}

1;
