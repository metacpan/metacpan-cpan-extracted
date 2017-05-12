BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }   

use Mojo::Base -strict;

use Mojo::IOLoop;
use Mojo::IOLoop::ForkCall;
use Test::More;

subtest 'basic usage' => sub {
  my $tick = 0;
  Mojo::IOLoop->recurring( 0.2 => sub { $tick++ } );

  my $fc = Mojo::IOLoop::ForkCall->new;
  my $pid;
  $fc->on( spawn => sub { (undef, $pid) = @_ } );

  my @res;
  $fc->run( 
    sub { sleep 1; return $$, \@_ },
    ['test',], 
    sub { @res = @_; Mojo::IOLoop->stop },
  );
  Mojo::IOLoop->start;
  ok $tick, 'main process not blocked';
  is_deeply \@res, [ $fc, undef, $pid, ['test']], 'return value correct';
  Mojo::IOLoop->reset;
};

subtest 'child error' => sub {
  my $fc = Mojo::IOLoop::ForkCall->new;
  my $err;
  $fc->run( 
    sub { die "Died!\n" },
    sub { shift; $err = shift; Mojo::IOLoop->stop },
  );
  Mojo::IOLoop->start;
  chomp $err;
  is $err, 'Died!';
};

subtest 'parent callback error' => sub {
  my $fc = Mojo::IOLoop::ForkCall->new;
  my $err;
  $fc->on( error => sub { $err = $_[1]; Mojo::IOLoop->stop } );
  $fc->run(
    sub { return 1 },
    sub { die "Argh\n" },
  );
  Mojo::IOLoop->start;
  chomp $err;
  is $err, 'Argh';
};

subtest 'finish event error' => sub {
  my $fc = Mojo::IOLoop::ForkCall->new;
  my ($err, $ret);
  $fc->on( error  => sub { $err = $_[1]; Mojo::IOLoop->stop } );
  $fc->on( finish => sub { die "Oooof\n" } );
  $fc->run(
    sub { return 1 },
    sub { $ret = pop },
  );
  Mojo::IOLoop->start;
  chomp $err;
  is $err, 'Oooof';
  ok $ret, 'callback completes';
};

done_testing;

