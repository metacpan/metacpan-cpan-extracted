package Mojolicious::Plugin::Fondation::LogTest;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return { dependencies => [], defaults => {} };
}

sub register ($self, $app, $conf) {
    $self->log->debug("[register] log from register works");
    return $self;
}

sub fondation_finalyze ($self, $app, $long) {
    $self->log->info("[finalyze] log from finalyze works");
}

1;
