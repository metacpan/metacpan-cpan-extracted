package MyApp;

use 5.012;
use warnings;

# Application
use Mojo::Base 'Mojolicious';

# Route
sub startup {
    my $self = shift;

    $self->routes->get('/')->to('foo#hello');
}

1;
