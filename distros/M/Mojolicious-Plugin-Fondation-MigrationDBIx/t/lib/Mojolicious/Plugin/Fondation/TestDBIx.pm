package Mojolicious::Plugin::Fondation::TestDBIx;

# ABSTRACT: Minimal test plugin providing DBIx::Class migrations + fixtures

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return {
        dependencies => ['Fondation::Model::DBIx::Async'],
        defaults     => {
            models => {
                foo => { source => 'Foo', backend => 'test' },
            },
        },
    };
}

sub register ($self, $app, $conf) {
    return $self;
}

1;
