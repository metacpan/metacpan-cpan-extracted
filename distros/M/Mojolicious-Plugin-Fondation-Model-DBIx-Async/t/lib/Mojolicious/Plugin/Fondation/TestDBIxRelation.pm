package Mojolicious::Plugin::Fondation::TestDBIxRelation;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

# ABSTRACT: Test plugin providing Result classes for user/group many-to-many

our $VERSION = '0.01';

sub fondation_meta {
    return {
        dependencies => ['Fondation::Model::DBIx::Async'],
        defaults     => {
            models => {
                user       => { source => 'User',      backend => undef },
                group      => { source => 'Group',     backend => undef },
                user_group => { source => 'UserGroup', backend => undef },
            },
        },
    };
}

sub register ($self, $app, $conf) {
    return $self;
}

1;
