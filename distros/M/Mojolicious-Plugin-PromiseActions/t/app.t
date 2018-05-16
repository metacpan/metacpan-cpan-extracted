BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }
use Test::More;
use Test::Mojo;

use Mojolicious::Lite;

plugin 'PromiseActions';

get '/' => sub {
  my $c=shift;

  my $p=Mojo::Promise->new;
  Mojo::IOLoop->timer(0.1,sub { $p->resolve('HI'); });
  $p->then(sub {
    $c->render(text=>'Hello');
  });
};

my $t=Test::Mojo->new;
$t->get_ok('/')->status_is('200')->content_is('Hello');

done_testing;
