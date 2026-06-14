package Mojolicious::Plugin::Fondation::Role;

# ABSTRACT: Mojolicious plugin for role management with Fondation

use Mojo::Base 'Mojolicious::Plugin', -signatures;

our $VERSION = '0.01';

sub fondation_meta {
    return {
        dependencies => [],
        defaults => {
            title => 'Group Management',
            key_test => 'role_default'
        }
    };
}


sub register {
    my ($self, $app, $conf) = @_;

    $app->routes->get('/groups')->to(
        controller => 'Group',
        action     => 'list'
        );

    return $self;
}

sub fondation_finalyze ($self, $app, $long_name) {
    push @{$app->{_finalyze_calls} ||= []}, $long_name;
}

1;
