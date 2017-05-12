package MyApp;
use Mojo::Base 'Mojolicious';

use MyApp::Controller::Example;

# This method will run once at server start
sub startup {
    my $self = shift;

    # our plugin
    $self->plugin('ExposeControllerMethod');

    # Router
    my $r = $self->routes;
    $r->get('/')->to('example#welcome');
}

1;
