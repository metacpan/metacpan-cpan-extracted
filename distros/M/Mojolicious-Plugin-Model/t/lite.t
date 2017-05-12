use Mojo::Base -strict;

use Mojolicious::Lite;
use Scalar::Util 'refaddr';
use Test::Mojo;
use Test::More;

use lib 't/lib';
plugin 'model';

app->defaults(users => ['u1', 'u2']);

get '/' => sub {
  my $c = shift;

  my $name = $c->req->param('name') // '';

  my $allow = $c->model('users')->check($name);
  $c->render(text => $allow ? "Hi $name!" : 'Hi');
};

my $t = Test::Mojo->new;
$t->get_ok('/?name=u1')->status_is(200)->content_is('Hi u1!');
$t->get_ok('/?name=qq')->status_is(200)->content_is('Hi');

my ($user1, $user2);
$user1 = app->model('users')->get({a => 1});
isa_ok $user1->app, 'Mojolicious::Lite';
$user2 = app->model('users')->get(a => 1);
isa_ok $user2->app, 'Mojolicious::Lite';

isnt refaddr $user1, refaddr $user2, 'Different objects';
is refaddr app->model('users'), refaddr app->model('users'), 'Same objects';

done_testing;
