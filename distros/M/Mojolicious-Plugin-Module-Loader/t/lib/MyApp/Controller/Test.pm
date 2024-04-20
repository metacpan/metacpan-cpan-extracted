package MyApp::Controller::Test;
use v5.26;
use warnings;

use Mojo::Base qw(Mojolicious::Controller);

use experimental qw(signatures);

sub hello_world($self) {
  return $self->render(text => 'Hello World');
}

1;
