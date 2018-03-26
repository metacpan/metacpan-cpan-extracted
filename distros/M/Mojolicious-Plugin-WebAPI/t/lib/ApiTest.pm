package
     ApiTest;
use Mojo::Base 'Mojolicious';

use ApiTest::Schema;
use File::Basename;
use File::Copy;

# This method will run once at server start
sub startup {
  my $self = shift;

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer');

  # Router
  my $r = $self->routes;

  my $db     = dirname(__FILE__) . '/../test.db';
  my $db_new = dirname(__FILE__) . '/../unittest.' . $$ . '.db';
  copy $db, $db_new;

  my $schema = ApiTest::Schema->connect('DBI:SQLite:' . $db_new);

  # Normal route to controller
  $r->get('/')->to( cb => sub {
      shift->render( text => 'Mojolicious::Plugin::WebAPI test app' );
  });

  my $auth  = $self->routes->under('/'); #->to( 'auth#test' );
  my $route = $auth->route('/api/v0/');

  $self->plugin('WebAPI' => {
    schema => $schema,
    route  => $route,
    #debug  => 1,

    resource_opts => {
      resource_default_args => {
        http_auth_type => 'disabled',
        writable       => 1,
        #base_uri       => $route->to_string,
      },
    },
  });
}

sub DESTROY {
  unlink dirname(__FILE__) . '/../unittest.' . $$ . '.db';
}

1;
