package Mojolicious::Plugin::Fondation::TestController::Controller::List;

use Mojo::Base 'Mojolicious::Controller', -signatures;

sub index ($c) {
    $c->render(text => "TestController list");
}

1;
