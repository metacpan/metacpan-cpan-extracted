package mojo;
use Mojo::Base 'Mojolicious', -signatures;

# This method will run once at server start
sub startup ($self) {

  # Load configuration from config file
  my $config = $self->plugin('NotYAMLConfig');

  $self->plugin(
    'Sentry',
    {
      dsn     => 'http://b61a335479ff48529d773343287bcdad@localhost:9000/2',
      release => '1.0.0',
      dist    => '12345',
    }
  );

  # Configure the application
  $self->secrets($config->{secrets});

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('example#welcome');
  $r->get('/things/:id')->to('example#bla');
  $r->get('/dies')->to('example#dies');
}

1;
