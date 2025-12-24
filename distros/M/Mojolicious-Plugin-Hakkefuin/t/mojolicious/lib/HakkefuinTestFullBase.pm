package HakkefuinTestFullBase;
use Mojo::Base 'Mojolicious';

use Mojo::File 'curfile';

sub backend_label  { die 'backend_label() must be implemented' }
sub backend_config { die 'backend_config() must be implemented' }

sub startup {
  my $self = shift;

 # Keep all migrations under the test tree so they don't leak into the repo root
  my $home = curfile->dirname->child('..')->realpath;
  $self->home->detect($home->to_string);

  my $config_path = $home->child('hakkefuin_test_simple.conf');
  my $secret      = 'th3_3x4mPl3_f0r_s3cR3t';
  if (-f $config_path) {
    my $config = $self->plugin(Config => {file => $config_path->to_string});
    $secret = $config->{secret} if $config->{secret};
  }
  $self->secrets([$secret]);

  my $migrations_dir = 'migrations/full-' . $self->backend_label;
  $home->child($migrations_dir)->make_path;

  my %plugin_conf = (dir => $migrations_dir, %{$self->backend_config});
  $self->plugin('Hakkefuin' => \%plugin_conf);

  my $r = $self->routes;
  $r->namespaces(['HakkefuinTestSimple::Controller']);
  $r->get('/')->to('page#homepage');
  $r->get('/login-page')->to('page#login_page');
  $r->get('/page')->to('page#page');
  $r->post('/login')->to('auth#login')->name('login_action');
  $r->post('/login-custom')
    ->to('auth#login_custom')
    ->name('login_custom_action');
  $r->get('/csrf-reset')->to('auth#csrf_reset');
  $r->get('/auth-update')->to('auth#update');
  $r->get('/auth-update-custom')->to('auth#update_custom');
  $r->get('/stash')->to('auth#stash_check');
  $r->post('/logout')->to('auth#logout');
  $r->post('/lock')->to('auth#lock');
  $r->post('/unlock')->to('auth#unlock');
}

1;
