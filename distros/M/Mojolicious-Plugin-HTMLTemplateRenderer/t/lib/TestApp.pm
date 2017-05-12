package TestApp;

use Mojo::Base 'Mojolicious';

sub startup {
   my $self = shift;

   $self->plugin('HTMLTemplateRenderer');

   $r = $self->routes;

   $r->route('/t1')->to('testcontroller#t1');
}
