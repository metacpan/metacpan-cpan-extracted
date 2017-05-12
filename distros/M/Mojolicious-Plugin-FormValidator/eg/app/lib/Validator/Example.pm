package Validator::Example;

use Mojo::Base 'Mojolicious::Controller';

sub welcome {
    my $self = shift;

    $self->render();
}

sub unchecked {
    my $self = shift;

    $self->stash(username => $self->param("username") // "");
    $self->stash(email => $self->param("email") // "");

    $self->render("unchecked");
}

1;
