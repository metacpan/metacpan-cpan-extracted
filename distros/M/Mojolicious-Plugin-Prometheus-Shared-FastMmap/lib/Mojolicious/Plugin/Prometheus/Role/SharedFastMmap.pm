package Mojolicious::Plugin::Prometheus::Role::SharedFastMmap;
use Role::Tiny;

after register => sub {
  my ($self, $app, $config) = @_;

  $app->plugin(
    'CHI' => {
      Prometheus_plugin => {
        driver        => 'FastMmap',
        root_dir      => $config->{cache_dir} // 'cache',
        cache_size    => $config->{cache_size} // '5m',        # Can be tuned for less memory usagerbitrary default
        empty_on_exit => 1,            # Start fresh after upgrades
      }
    }
  );

  $app->hook(
    after_render => sub {
      my ($c) = @_;
      $app->chi('Prometheus_plugin')->set($$ => $app->prometheus->render);
    }
  );

  $self->route->to(
    cb => sub {
      my ($c) = @_;
      $c->render( text => join ("\n", map { ($app->chi('Prometheus_plugin')->get($_)) } $app->chi('Prometheus_plugin')->get_keys()), format => 'txt' );
    }
  );

};
1;
