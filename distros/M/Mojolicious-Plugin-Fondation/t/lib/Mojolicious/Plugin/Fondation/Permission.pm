package Mojolicious::Plugin::Fondation::Permission;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

our $VERSION = '0.01';

sub fondation_meta {
    return {
        dependencies => [],
        defaults => {
            title => 'Permission Management',
        }
    };
}

sub register {
    my ($self, $app, $conf) = @_;


    return $self;
}

1;
