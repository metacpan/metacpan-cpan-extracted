package MyApp;
use Mojo::Base 'Mojolicious';

sub startup {
  my $app = shift;

  $app->plugin('Mojolicious::Plugin::ServerInfo');
  
  my $routes = $app->routes;
  $routes->any('/' => sub { shift->render(text => 'Hello World.') } );
  #$routes->any('/serverinfo' => sub { shift->render } );
}

1;
