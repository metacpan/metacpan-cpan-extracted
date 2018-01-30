use Mojo::Base -strict;
use Mojo::IOLoop::Subprocess;
use Mojo::Redis2;
use Test::More;

# Logic of the test is following:
# 1. client subscribes to channel
# 2. client pushes channel name inside queue-array
# 3. server brpop's channel name, and publishes a message there
# 4. client recieves message on a channel
# All counters should be the same

use constant {TEST_MESSAGES => 500, TIMEOUT => 3, REDIS_QUEUE_NAME => 'queue'};

plan skip_all => 'Cannot test on Win32' if $^O eq 'MSWin32';

# not sure if setting requirepass and path matter,
# but adding it for the sake of complexity
plan skip_all => $@ unless eval { Mojo::Redis2::Server->start(requirepass => 's3cret') };
my $url = Mojo::URL->new($ENV{MOJO_REDIS_URL})->path(3);
my $redis = Mojo::Redis2->new(url => $url);

my ($got_messages, $subscribed);

sub server {
  my $c;
  while (my $r = $redis->brpop(REDIS_QUEUE_NAME, 0)) {
    my $key = $r->[1];
    $redis->publish($key, $key);
    return 0 if ++$c == TEST_MESSAGES;
  }
}

sub stress {
  $redis->on(
    message => sub {
      my ($self, $msg, $channel) = @_;
      $got_messages++ if $msg eq $channel;
    }
  );
  for my $channel (1 .. TEST_MESSAGES) {
    $redis->subscribe(
      [$channel],
      sub {
        $subscribed++;
        my ($self, $err) = @_;
        $self->lpush(REDIS_QUEUE_NAME, $channel);
      }
    );
  }
}

# run server in a separate process,
# and stop processing if all requests are finished
Mojo::IOLoop::Subprocess->new->run(\&server, sub { Mojo::IOLoop->stop });
Mojo::IOLoop->timer(0.1 => \&stress);
Mojo::IOLoop->timer(TIMEOUT() => sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;

is $subscribed, TEST_MESSAGES, 'all subscribtions were successfull';
is $got_messages, $subscribed, 'number of sent messages is equal to the number of received';

done_testing;
