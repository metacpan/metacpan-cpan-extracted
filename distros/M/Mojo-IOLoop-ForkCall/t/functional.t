BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }   

use Mojo::Base -strict;

use Mojo::IOLoop;
use Mojo::IOLoop::ForkCall qw/fork_call/;
use Test::More;

my $tick = 0;
my $recurring = Mojo::IOLoop->recurring( 0.25 => sub { $tick++ } );

my @res;
fork_call { sleep 1; return 'good', @_ } ['test'], sub { @res = @_; Mojo::IOLoop->stop };
Mojo::IOLoop->start;
ok $tick, 'main process not blocked';
is_deeply \@res, ['good', ['test']], 'return value correct';
Mojo::IOLoop->remove($recurring);

{
  my $err;
  fork_call { die "Died!\n" } sub { $err = $@; Mojo::IOLoop->stop };
  Mojo::IOLoop->start;
  chomp $err;
  is $err, 'Died!';
}

SKIP: {
  skip 'Perl versions < 5.14 handle errors in parent callback badly', 1 if $^V < v5.14.0;
  my $err;
  Mojo::IOLoop->singleton->reactor->unsubscribe('error')->on( error => sub { $err = $_[1]; Mojo::IOLoop->stop } );
  fork_call { return 'ok' } sub { die "Argh\n" };
  Mojo::IOLoop->start;
  chomp $err;
  like $err, qr/Argh/, 'parent callback error goes to reactor error handler';
}

done_testing;

