package Mojolicious::Plugin::Fondation::Role::Controller::Common;
use Mojo::Base 'Mojolicious::Controller';

# This controller from Role plugin (dependency) should be prioritized

sub index {
    my $c = shift;
    $c->render(text => 'Controller from ROLE plugin (dependency)');
}

1;