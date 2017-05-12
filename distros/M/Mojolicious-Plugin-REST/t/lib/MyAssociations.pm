package MyAssociations;
use Mojo::Base 'Mojolicious';

sub startup {
    my $self = shift;
    $self->plugin( REST => { prefix => 'api', version => 'v1' } );
    $self->routes->rest_routes( name => 'Feature', under => 'User' );
}

1;
