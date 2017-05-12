use Mojo::Base -strict;

use Mojolicious::Lite;
use Test::Mojo;
use Test::More;

use lib 't/lib';
plugin Model => {namespaces => ['Lite::Model']};

get '/' => sub {
  my $c = shift;

  $_ = 'test';
  $c->render(text => $c->model('users')->name($_));
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is('test');

done_testing;
