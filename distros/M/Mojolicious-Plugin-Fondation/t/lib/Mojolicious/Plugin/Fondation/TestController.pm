package Mojolicious::Plugin::Fondation::TestController;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

our $VERSION = '0.01';

sub fondation_meta {
    return {
        dependencies => [],
        defaults     => {},
    };
}

sub register ($self, $app, $conf) {
    return $self;
}

1;
