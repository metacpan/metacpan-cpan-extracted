package Mojolicious::Plugin::Fondation::Authorization::Controller::Common;
use Mojo::Base 'Mojolicious::Controller';

# This controller from Authorization plugin (parent) should NOT be used

sub index {
    my $c = shift;
    $c->render(text => 'Controller from AUTHORIZATION plugin (parent)');
}

1;