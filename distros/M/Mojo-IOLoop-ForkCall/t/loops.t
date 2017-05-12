BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Mojo::Base -strict;

use Mojo::IOLoop;
use Mojo::IOLoop::ForkCall;
use Test::More;

subtest 'singleton' => sub {
  my $fc = Mojo::IOLoop::ForkCall->new;
  my ($err, $res);
  $fc->run(
    sub{
      my $i = 0;
      Mojo::IOLoop->next_tick(sub{$i++; Mojo::IOLoop->stop});
      Mojo::IOLoop->start;
      return $i;
    },
    sub{
      (undef, $err, $res) = @_;
      Mojo::IOLoop->stop;
    }
  );

  Mojo::IOLoop->start;
  ok ! $err, 'no error';
  ok $res, 'child loop ran';
};

subtest 'non-singleton' => sub {
  my $loop = Mojo::IOLoop->new;
  my $fc = Mojo::IOLoop::ForkCall->new(ioloop => $loop);
  my ($err, $res);
  $fc->run(
    sub{
      my $i = 0;
      $loop->next_tick(sub{$i++; $loop->stop});
      $loop->start;
      return $i;
    },
    sub{
      (undef, $err, $res) = @_;
      $loop->stop;
    }
  );

  $loop->start;
  ok ! $err, 'no error';
  ok $res, 'child loop ran';
};

done_testing;

