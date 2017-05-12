use Mojo::Base -strict;
use Mojo::Redis2;
use Test::More;

plan skip_all => 'Cannot test on Win32' if $^O eq 'Win32';
plan skip_all => $@ unless eval { Mojo::Redis2::Server->start };

my $redis = Mojo::Redis2->new;
my $p = 1;
my (@err, @res, @messages, @redis);

my $subscribe_cb = sub {
  push @res, pop;
  push @err, pop;
  $p += $redis->publish("mojo:redis:test" => "message $p");
  diag "sub+pub: $p";
};
my $psubscribe_cb = sub {
  push @res, pop;
  push @err, pop;
  $p += $redis->publish("mojo:redis:test" => "message $p");
  diag "psub+pub: $p";
  $p += $redis->publish("mojo:redis:channel2" => "message $p");
  diag "psub+pub: $p";
};

$redis->on(message => sub {
  shift;
  push @messages, [message => @_];
  push @redis, $redis->psubscribe(["mojo:redis:ch*"], $psubscribe_cb) if @messages == 1;
  Mojo::IOLoop->stop if @messages == 3;
});
$redis->on(pmessage => sub {
  shift;
  push @messages, [pmessage => @_];
  return unless @messages == 3;
  Mojo::IOLoop->delay(
    sub {
      my ($delay) = @_;
      Mojo::IOLoop->timer(0.1 => $delay->begin);
    },
    sub {
      my ($delay) = @_;
      Mojo::IOLoop->timer(0.1 => $delay->begin);
      $redis->publish("mojo:redis:test" => "message 0.1");
      $redis->publish("mojo:redis:channel2" => "message 0.1");
    },
    sub {
      my ($delay) = @_;
      Mojo::IOLoop->stop;
    },
  );
  $redis->punsubscribe(["mojo:redis:ch*"], sub {});
  $redis->unsubscribe(["mojo:redis:test"], sub {});
});

is $redis->subscribe(["mojo:redis:test"], $subscribe_cb), $redis, 'subscribe()';
Mojo::IOLoop->start;

is_deeply \@redis, [$redis], 'psubscribe()';
is_deeply \@err, ['', ''], 'no subscribe error';
is_deeply(
  \@res,
  [
    [qw( subscribe mojo:redis:test 1 )],
    [qw( psubscribe mojo:redis:ch* 2 )],
  ],
  'subscribed to one channel'
) or diag '2!=' .int @res;

is_deeply(
  \@messages,
  [
    [ message => "message 1", "mojo:redis:test" ],
    [ message => "message 2", "mojo:redis:test" ],
    [ pmessage => "message 3", "mojo:redis:channel2", "mojo:redis:ch*" ],
  ],
  'got message events',
) or diag '3!=' .int @messages;

is $p, 4, 'published messages';

ok $redis->has_subscribers('message'), 'message has_subscribers';
ok $redis->has_subscribers('pmessage'), 'pmessage has_subscribers';
is $redis->unsubscribe('message', sub {}), $redis, 'regular unsubscribe with callback';
is $redis->unsubscribe('message'), $redis, 'regular unsubscribe';
ok !$redis->has_subscribers('message'), 'message has no subscribers';

done_testing;
