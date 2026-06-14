package Mojolicious::Plugin::Fondation::User;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

# ABSTRACT: User management plugin for Fondation

our $VERSION = '0.01';

sub fondation_meta {
    return {
        dependencies => [],
        defaults => {
            title => 'User Management',
            key_test => 'plugin_default',
        }
    };
}

sub register ($self, $app, $conf) {

    $app->routes->get('/users')->to(
        controller => 'User',
        action     => 'list'
        );

    return $self;
}

1;
