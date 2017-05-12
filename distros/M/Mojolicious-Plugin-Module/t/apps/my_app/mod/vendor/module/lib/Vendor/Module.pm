package Vendor::Module;
use Mojo::Base 'Mojolicious::Plugin::Module::Abstract';

sub init_routes {
  my ($self, $app) = @_;
  my $r = $app->routes;
  $r->route('test1')->to(cb => sub { shift->render(text => "Hello test1!") });
  $r->route('test2')->to(cb => sub { shift->render(text => "Hello test2!") });
  $r->route('mods')->to(cb => sub {
    my $self = shift;
    my $msg = $self->module->get('Vendor::Module') ? 'ok' : 'fail';
    $self->render(text => $msg);
  });
  $r->route('mods_fail')->to(cb => sub {
    my $self = shift;
    my $msg = $self->module->get('Vendor::Module1') ? 'ok' : 'fail';
    $self->render(text => $msg);
  });
}

1;