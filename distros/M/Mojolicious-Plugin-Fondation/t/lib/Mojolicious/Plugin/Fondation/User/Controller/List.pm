package Mojolicious::Plugin::Fondation::User::Controller::List;
use Mojo::Base 'Mojolicious::Controller';

sub index {
    my $c = shift;
    $c->render(text => 'User list from LIST controller');
}

1;
