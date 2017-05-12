package TestApp::TestController;

use Mojo::Base 'Mojolicious::Controller';

sub t1 {
    my $self = shift;

    $self->render();
}
