package mojo::Controller::Example;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Carp 'croak';
use Mojo::UserAgent;

# This action will render a template
sub welcome ($self) {

  Mojo::UserAgent->new->get('https://example.com');
  Mojo::UserAgent->new->get('https://google.com');
  Mojo::UserAgent->new->get('https://heise.de/forum/');

  # Render template "example/welcome.html.ep" with message
  $self->render(msg => 'Welcome to the Mojolicious real-time web framework!');
}

sub bla ($self) {
  $self->render(text => 'ok');
}

sub dies ($self) {
  die 'ohoh2!';
}

1;
