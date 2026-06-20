package Mojolicious::Plugin::Fondation::TestDBIxRelation;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

# ABSTRACT: Test plugin providing Result classes for user/group many-to-many

our $VERSION = '0.01';

sub fondation_meta {
    return {
        dependencies => ['Fondation::Model::DBIx::Async'],
        defaults     => {
            models => {
                user       => { source => 'users',      backend => undef },
                group      => { source => 'groups',     backend => undef },
                user_group => { source => 'user_group', backend => undef },
            },
        },
    };
}

sub register ($self, $app, $conf) {
    return $self;
}

1;
