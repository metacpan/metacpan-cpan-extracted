use strict;
use warnings;

BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Test::More;
use Test::Mojo;
use Mojo::IOLoop;
use Scalar::Util 'weaken';

use Mojolicious::Lite;
plugin 'Future';

my $err;
get '/test1' => sub {
  my $c = shift;
  my $f = $c->future->on_done(sub { $c->render(text => shift()) })
    ->on_fail(sub { $err = shift });
  weaken(my $weak_f = $f);
  Mojo::IOLoop->next_tick(sub { $weak_f->done('success!') });
  $c->adopt_future($f);
};

get '/test2' => sub {
  my $c = shift;
  my $f = $c->future->on_done(sub { $c->render(text => shift()) })
    ->on_fail(sub { $err = shift });
  weaken(my $weak_f = $f);
  Mojo::IOLoop->next_tick(sub { $weak_f->fail('failure!') });
  $c->adopt_future($f);
};

my $t = Test::Mojo->new;

$t->get_ok('/test1')->status_is(200)->content_is('success!');
is $err, undef, 'no error';

undef $err;
$t->get_ok('/test2')->status_is(500);
is $err, 'failure!', 'right error';

done_testing;
