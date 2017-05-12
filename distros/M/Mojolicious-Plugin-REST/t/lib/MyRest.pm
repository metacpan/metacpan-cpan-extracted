package MyRest;
use Mojo::Base 'Mojolicious';

sub startup {
    my $self = shift;
    $self->plugin( REST => { prefix => 'api', version => 'v1' } );
    $self->routes->rest_routes( name => 'Dog' );
}

1;
