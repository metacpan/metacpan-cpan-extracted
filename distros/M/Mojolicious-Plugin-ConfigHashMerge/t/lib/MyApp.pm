package MyApp;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
  my $self = shift;

  # Load configuration from hash returned by "my_app.conf"
  my $config
    = $self->plugin('ConfigHashMerge',
    {default => {watch_dirs => {downloads => '/a/b/c/downloads'}}},
    );

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer') if $config->{perldoc};

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to(
    cb => sub {
      my $self = shift;
      my $dirs = $self->config('watch_dirs');
      $self->render(json => $dirs);
    }
  );
}

1;
