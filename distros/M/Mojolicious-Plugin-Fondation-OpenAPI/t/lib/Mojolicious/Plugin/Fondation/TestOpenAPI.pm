package Mojolicious::Plugin::Fondation::TestOpenAPI;

# ABSTRACT: Test plugin providing DBIx::Class Result classes for OpenAPI tests

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return {
        dependencies     => ['Fondation::Model::DBIx::Async'],
        defaults     => {
            openapi_exclude => ['Baz'],
            models          => {
                foo => {source => 'Foo', backend => 'test'},
                bar => {source => 'Bar', backend => 'test'},
                baz => {source => 'Baz', backend => 'test'},
            },
        },
    };
}

sub register ($self, $app, $conf) {
    return $self;
}

1;
