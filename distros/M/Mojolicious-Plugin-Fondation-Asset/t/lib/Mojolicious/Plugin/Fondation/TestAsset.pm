package Mojolicious::Plugin::Fondation::TestAsset;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

# ABSTRACT: Test plugin for Fondation::Asset -- provides assetpack.def fixture

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
