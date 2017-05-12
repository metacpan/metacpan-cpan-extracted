package MyApp;
use Mojo::Base 'Mojolicious';

sub startup {
  my $self = shift;
  # Router
  my $r = $self->routes;
  $self->plugin('Mojolicious::Plugin::QuickMy' => {dsn => 'mysql://sri:123456@localhost/testdb',
                                                   debug => 1 } );
  
  # Normal route to controller
  $r->get('/')->to('example#index');
  $r->get('/sort/:order' => {order => 'desc'})->to('example#index');
  $r->get('/insert')->to('example#insert');
  $r->get('/edit/:id' => [id => qr/\d+/])->to('example#edit');
  $r->get('/delete/:id' => [id => qr/\d+/])->to('example#delete');
  
}

1;
