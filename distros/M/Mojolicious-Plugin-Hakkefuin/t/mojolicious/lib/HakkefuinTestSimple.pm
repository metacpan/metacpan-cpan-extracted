package HakkefuinTestSimple;
use Mojo::Base 'Mojolicious';

sub startup {
  my $self = shift;

  # Load configuration from hash returned by config file
  my $config = $self->plugin('Config');

  $self->plugin('Hakkefuin' => {via => 'sqlite'});

  my $r = $self->routes;
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
