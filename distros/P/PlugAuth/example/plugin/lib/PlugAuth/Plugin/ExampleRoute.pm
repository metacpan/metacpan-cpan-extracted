package PlugAuth::Plugin::ExampleRoute;

use strict;
use warnings;
use Role::Tiny::With;

with 'PlugAuth::Role::Plugin';

sub init
{
  my($self) = @_;
  
  $self->app->routes->under('/hello')->get(sub {
    my($c) = @_;
    $c->render(text => 'hello world!');
  });
}

1;
