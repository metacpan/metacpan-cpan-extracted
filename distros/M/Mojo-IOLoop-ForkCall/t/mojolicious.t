#!/usr/bin/env perl
 
use Mojolicious::Lite;
use Mojo::IOLoop::ForkCall;
 
any '/' => sub { 
  my $c = shift;
  $c->render_later;
  my $tick = 0;
  my $r = Mojo::IOLoop->recurring( 0.25 => sub { $tick++ });
  my $fc = Mojo::IOLoop::ForkCall->new;
  $fc->run(
    sub {
      sleep 1;
      return 'Hello from child', $$;
    },
    sub {
      my ($fc, $err, $msg, $pid) = @_;
      Mojo::IOLoop->remove($r);
      $c->render( json => {
         msg   => $msg,
         pid   => $pid,
         ticks => $tick,
      });
    }
  );
};

use Test::More;
use Test::Mojo;

my $t  = Test::Mojo->new;
$t->get_ok('/')
  ->json_is('/msg' => 'Hello from child');

my $json = $t->tx->res->json;
ok $json->{ticks}, 'Does not block app';
ok $json->{pid}, 'child pid returned (non-zero)';

done_testing;

