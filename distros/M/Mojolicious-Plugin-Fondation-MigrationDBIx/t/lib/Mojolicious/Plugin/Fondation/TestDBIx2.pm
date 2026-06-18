package Mojolicious::Plugin::Fondation::TestDBIx2;

# ABSTRACT: Second test plugin providing fixtures for 'bars' table

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return {
        dependencies => ['Fondation::Model::DBIx::Async'],
        defaults     => {
            models => {
                bar => { source => 'bars', backend => 'test' },
            },
        },
    };
}

sub register ($self, $app, $conf) {
    return $self;
}

1;
