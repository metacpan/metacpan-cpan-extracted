use strict;
use warnings;

use Test::Mojo;
use Test::More;

use Mojolicious::Lite;

my $v;

plugin 'Model' => {namespaces => ['Local'], params => {MyModel => {var => \$v}}};

get '/' => sub {
  my $c = shift();
  $c->model('MyModel');
  $c->rendered(201);
};

my $t = Test::Mojo->new;

$t->get_ok('/');
ok $v == 42;

done_testing;

package Local::MyModel;

use base 'MojoX::Model';

sub new {
  shift();
  my %args = @_;
  ${$args{var}} = 42;
}

1;
