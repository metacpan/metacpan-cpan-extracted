package Mojolicious::Plugin::Fondation::Authorization;


# ABSTRACT: Mojolicious plugin for authorization management with Fondation

use Mojo::Base 'Mojolicious::Plugin', -signatures;

our $VERSION = '0.01';

sub fondation_meta {
    return {
        dependencies => ['Fondation::Role', 'Fondation::Permission'],
        defaults => {
            title => 'Authorization Management',
        }
    };
}


sub register {
    my ($self, $app, $conf) = @_;

    return $self;
}

sub fondation_finalyze ($self, $app, $long_name) {
    push @{$app->{_finalyze_calls} ||= []}, $long_name;
}

1;
