BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }   

use Mojo::Base -strict;

use lib 'lib';
use Mojo::IOLoop::ForkCall;
use Storable ();
use Test::More;

# This test is helpful for debugging connectivity between child and parent
# enable the env var to see the actual messages sent.

use constant DEBUG => $ENV{FORKCALL_TEST_DEBUG};

my $job = sub{'Lived'};
my $fc  = Mojo::IOLoop::ForkCall->new;

my $received;
$fc->serializer(sub{my $f = Storable::freeze($_[0]); diag "sending: $f" if DEBUG; $f});
$fc->deserializer(sub{$received = $_[0]; Storable::thaw($_[0])});

my ($err, @res);
$fc->on(finish => sub{
  my $fc = shift;
  $err = shift;
  @res = @_;
  $fc->ioloop->stop;
});

$fc->run($job);
$fc->ioloop->start;

ok $received, 'received something from child';
diag "got: $received" if DEBUG;
is_deeply \@res, ['Lived'] or diag 'error: '.$err;

done_testing;

