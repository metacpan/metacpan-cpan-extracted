BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }
use Test::More;
use Test::Mojo;

use Mojolicious::Lite;
use Mojo::Promise;

plugin 'PromiseActions';

get '/' => sub {
  my $c=shift;

  my $p=Mojo::Promise->new;
  Mojo::IOLoop->timer(0.1,sub { $p->resolve('HI'); });
  $p->then(sub {
    $c->render(text=>'Hello');
  });
};
get '/normal' => sub {
  my $c=shift;
  $c->render(text=>'NO');
  return 1;
};

my $t=Test::Mojo->new;
$t->get_ok('/')->status_is('200')->content_is('Hello');
$t->get_ok('/normal')->status_is('200')->content_is('NO');


done_testing;
