#!/usr/bin/env perl
 
use Mojolicious::Lite;
use Mojo::IOLoop::ForkCall;
 
any '/' => sub { 
  my $c = shift;
  $c->render_later;
  my $tick = 0;
  my $r = Mojo::IOLoop->recurring( 1 => sub { $tick++ });
  my $fc = Mojo::IOLoop::ForkCall->new;
  $fc->run(
    sub {
      sleep 3;
      return 'Hello from child', $$;
    },
    sub {
      my ($fc, $err, $msg, $pid) = @_;
      Mojo::IOLoop->remove($r);
      $c->render(text => "$msg $pid after $tick ticks");
    }
  );
};
 
app->start;
