package Vendor::Module;
use Mojo::Base 'Mojolicious::Plugin::Module::Abstract';

sub init_routes {
  my ($self, $app) = @_;
  my $r = $app->routes;
  $r->route('test1')->to(cb => sub { shift->render(text => "Hello test1!") });
  $r->route('test2')->to(cb => sub { shift->render(text => "Hello test2!") });
}

1;