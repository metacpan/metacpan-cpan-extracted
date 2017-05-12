BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }   

use Mojo::Base -strict;
use Mojo::IOLoop::ForkCall;

use Test::More;

sub generate {
  my ($weaken, $cb) = @_;
  my $fc = Mojo::IOLoop::ForkCall->new(weaken => $weaken);
  my $ioloop = $fc->ioloop;

  $fc->run(sub{ return shift }, ['Done'], sub {
    $cb->(@_);
    $ioloop->stop;
  });
  return $ioloop;
};

subtest 'Strong' => sub {
  my ($fc, $res);
  my $ioloop = generate(0, sub { 
    my ($f, $e, $r) = @_;
    $fc = $f;
    $res = $r;
  });
  $ioloop->start;
  ok $fc, 'ForkCall survived';
  is $res, 'Done', 'correct response';
};

subtest 'Weak' => sub {
  my ($fc, $res);
  my $ioloop = generate(1, sub { $fc = shift; shift; $res = shift; });
  my $loop_err = 0;
  $ioloop->reactor->unsubscribe('error');
  $ioloop->reactor->on( error => sub { $loop_err++ } );
  $ioloop->start;

  ok ! $loop_err, 'No error thrown by ioloop (at emit)';
  ok ! $fc, 'ForkCall was weakened correctly';
  is $res, 'Done', 'correct response';
};


done_testing;

