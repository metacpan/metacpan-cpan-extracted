package MyApp;
use Mojo::Base 'Mojolicious';
#use lib qw (../../lib);
sub startup {
  my $self = shift;
  # Router
  my $r = $self->routes;
  $self->plugin('Mojolicious::Plugin::QuickPg' => {dsn => 'postgresql://sri:123456@localhost/angular',
                                                   debug => 1 } );
  
  # Normal route to controller
  $r->get('/')->to('example#index');
  $r->get('/sort/:order' => {order => 'desc'})->to('example#index');
  $r->get('/insert')->to('example#insert');
  $r->get('/edit/:id' => [id => qr/\d+/])->to('example#edit');
  $r->get('/delete/:id' => [id => qr/\d+/])->to('example#delete');
  
}

1;
