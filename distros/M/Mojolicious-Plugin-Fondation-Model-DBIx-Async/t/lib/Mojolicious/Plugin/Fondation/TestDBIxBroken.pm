package Mojolicious::Plugin::Fondation::TestDBIxBroken;

# ABSTRACT: Test plugin with a Result class that FAILS to load — used to
# verify that Action::DBIx dies loudly (instead of failing silently) when
# a Result class cannot be loaded or registered.

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return {
        dependencies => ['Fondation::Model::DBIx::Async'],
        defaults     => {
            models => {},
        },
    };
}

sub register ($self, $app, $conf) { return $self }

1;
