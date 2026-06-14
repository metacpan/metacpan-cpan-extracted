package Mojolicious::Plugin::Fondation::CustomAction;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return {
        dependencies     => [],
        provides_actions => ['MyAction'],
        defaults         => { title => 'Custom Action Plugin' },
    };
}

sub register ($self, $app, $conf) {
    return $self;
}

1;
