package Tester::Controller::Example;
use Mojo::Base 'Mojolicious::Controller', -signatures;
sub Tester ($self) {
    $self->render( text => 'OK' );
}

1;
