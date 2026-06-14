package Mojolicious::Plugin::Fondation::TestClean;

# ABSTRACT: Test plugin providing fondation_clean targets

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return {
        dependencies => [],
        defaults     => {
            fondation_clean => ['test_clean_dir/', 'test_clean_file.txt'],
        },
    };
}

sub register ($self, $app, $conf) {
    return $self;
}

1;
