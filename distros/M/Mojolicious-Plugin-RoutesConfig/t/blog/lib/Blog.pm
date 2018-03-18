package Blog;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
  my $self = shift;
  $self->plugin('RoutesConfig',
                {file => $self->home->child('etc/routes_missing.conf')});

  # Load configuration from hash returned by "my_app.conf"
  my $config = $self->plugin('Config');

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('example#welcome');

  $self->plugin('RoutesConfig', $config);

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer') if $config->{perldoc};
  $self->plugin('RoutesConfig',
                {file => $self->home->child('etc/routes_not_ARRAY.conf')});
  $self->plugin('RoutesConfig',
                {file => $self->home->child('etc/complex_routes.conf')});
}

1;
