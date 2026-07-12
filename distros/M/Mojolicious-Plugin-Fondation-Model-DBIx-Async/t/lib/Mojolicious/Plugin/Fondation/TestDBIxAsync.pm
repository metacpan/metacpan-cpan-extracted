package Mojolicious::Plugin::Fondation::TestDBIxAsync;

# ABSTRACT: Test plugin wrapping TestDBIxAsyncSchema so Action::DBIx
# discovers and registers its Result classes automatically.

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return {
        dependencies => ['Fondation::Model::DBIx::Async'],
        defaults     => {
            models => {
                user    => { source => 'User' },
                article => { source => 'Article' },
            },
        },
    };
}

sub register ($self, $app, $conf) { return $self }

1;
