BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Mojo::Base -strict;

use Mojo::IOLoop::ForkCall;

use Test::More;

my $job = sub{'Lived'};

{
  my ($err, $res);
  my $fc = Mojo::IOLoop::ForkCall->new;
  $fc->on(error  => sub { $err = $_[1] }); 
  $fc->on(finish => sub { my $fc = shift; $err = shift; $res = shift; $fc->ioloop->stop });
  $fc->run($job);
  $fc->ioloop->start;

  ok ! $err;
  is $res, 'Lived';
}

{
  my ($err, $res);
  my $fc = Mojo::IOLoop::ForkCall->new;
  $fc->on(error  => sub { $err = $_[1] });
  $fc->on(finish => sub { $res = $_[2] });
  $fc->deserializer(sub{ die "Died\n" });
  $fc->run($job);
  $fc->ioloop->start;

  chomp $err;
  is $err, 'Died';
  ok ! $res;
}

done_testing;

