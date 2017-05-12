package MyRest;
use Mojo::Base 'Mojolicious';

sub startup {
  my $self = shift;
  $self->plugin("RESTful");
  my $routes = $self->routes;
  $routes->restful(name => "Person")->restful(name => "Cat", root => '')->restful(name => 'Food');
}

1
