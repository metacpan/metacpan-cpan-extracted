use strict;
use warnings;

use Test::Mojo;
use Test::More;

use Mojolicious::Lite;

plugin 'Model' => {namespaces => ['Local'], default => 'MyModel'};

get '/' => sub {
  my $c = shift();
  ok ref($c->model) eq 'Local::MyModel';
  $c->rendered(201);
};

my $t = Test::Mojo->new;

$t->get_ok('/');

done_testing;

package Local::MyModel;

use base 'MojoX::Model';

1;
