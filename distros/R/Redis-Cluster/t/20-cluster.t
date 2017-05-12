#!/usr/bin/env perl

use strict;
use warnings;

use Redis::Cluster;
use Test::More;
use Test::Exception;

use lib 'lib';

my @nodes = split(m/[\s,;]+/, $ENV{REDIS_CLUSTER} || '');

plan(skip_all => 'Redis Cluster must have ' .
  'at least three nodes; skipping') if @nodes < 3;

my $redis = Redis::Cluster->new(server => \@nodes);

# key slot
my $key = 'test_key_' . int(rand(0x4000));
my $slot = $redis->cluster_keyslot($key);
die('[cluster keyslot] error') unless defined($slot);

ok($slot == $redis->_get_slot_by_key($key), 'key slot');

# set
my $res = $redis->set($key, 1);
ok($res eq 'OK', 'set');

# get
$res = $redis->get($key);
ok($res == 1, 'get');

# watch
$res = $redis->watch($key);
ok($res eq 'OK', 'watch');

# multi
$res = $redis->multi();
ok($res eq 'OK', 'multi');

# incr (queued)
$res = $redis->incr($key);
ok($res eq 'QUEUED', '[queued] incr');

# incrby (queued)
$res = $redis->incrby($key, 2);
ok($res eq 'QUEUED', '[queued] incrby');

# exec
$res = $redis->exec();
is_deeply($res, [ 2, 4 ], 'exec');

# eval
$res = $redis->eval('return redis.call("GET", KEYS[ 1 ])', 1, $key);
ok($res == 4, 'eval');

# watch/unwatch without multi
$res = $redis->watch($key);
die('[watch] error') unless $res && $res eq 'OK';

$res = $redis->decr($key);
ok($res == 3, 'decr');

$res = $redis->unwatch();
ok($res eq 'OK', 'watch/unwatch without multi');

# discard
$res = $redis->multi();
die('[multi] error') unless $res && $res eq 'OK';

$res = $redis->decr($key);
die('[queued] [decr] error') unless $res && $res eq 'QUEUED';

$res = $redis->decrby($key, 2);
die('[queued] [decrby] error') unless $res && $res eq 'QUEUED';

$res = $redis->discard();
die('[discard] error') unless $res && $res eq 'OK';

$res = $redis->get($key);
ok($res eq 3, 'discard');

# wait
$res = $redis->wait(1, 1000);
ok($res == 1, 'wait');

# del
$res = $redis->del($key);
ok($res == 1, 'del');

# multi without key
$res = $redis->multi();
die('[multi] error') unless $res && $res eq 'OK';

$res = $redis->exec();
is_deeply($res, [], 'multi without key');

# unwatch without watch
$res = $redis->unwatch();
ok($res eq 'OK', 'unwatch without watch');

# nested multi
$res = $redis->multi();
die('[multi] error') unless $res && $res eq 'OK';

dies_ok(sub { $redis->multi() }, 'nested multi');

$redis->discard();
die('[discard] error') unless $res && $res eq 'OK';

# queue overflow
$res = $redis->multi();
die('[multi] error') unless $res && $res eq 'OK';

dies_ok(
  sub { $redis->cluster_slots() for 1 .. $redis->{max_queue_size} + 1; },
  'queue overflow',
);

$redis->discard();
die('[discard] error') unless $res && $res eq 'OK';

# watch inside multi
$res = $redis->multi();
die('[multi] error') unless $res && $res eq 'OK';

dies_ok(sub { $redis->watch($key); }, 'watch inside multi');

$redis->discard();
die('[discard] error') unless $res && $res eq 'OK';

# unwatch inside multi
$res = $redis->watch($key);
die('[watch] error') unless $res && $res eq 'OK';

$res = $redis->multi();
die('[multi] error') unless $res && $res eq 'OK';

ok(sub { $redis->unwatch(); }, 'unwatch inside multi');

$redis->discard();
die('[discard] error') unless $res && $res eq 'OK';

# exec without multi
dies_ok(sub { $redis->exec() }, 'exec without multi');

# discard without multi
dies_ok(sub { $redis->discard() }, 'discard without multi');

# get master by key
$res = $redis->get_master_by_key($key);
ok(ref($res) eq 'Redis', 'get master by key');

# get slave by key
$res = $redis->get_slave_by_key($key);
ok(ref($res) eq 'Redis', 'get slave by key');

# get any node by key
$res = $redis->get_node_by_key($key);
ok(ref($res) eq 'Redis', 'get node by key');

# get random master
$res = $redis->get_random_master();
ok(ref($res) eq 'Redis', 'get random master');

# get random slave
$res = $redis->get_random_slave();
ok(ref($res) eq 'Redis', 'get random slave');

# redirects
{
  # Get key (slot range should not include key slot #0)
  while (1) {
    my $slot = $redis->_get_slot_by_key($key); ## no critic
    my $range = $redis->_get_range_by_slot($slot); ## no critic
    last if $range->[0];

    $key = 'test_key_' . int(rand(0x4000));
    die('[randomkey] error') unless defined($key);
  }

  # Return key slot #0 by any key (to get redirect)
  no warnings 'redefine'; ## no critic

  local *Redis::Cluster::_get_slot_by_key = sub {
    my $slot = 0;
    warn("[debug] - slot: $slot\n") if $redis->{debug};

    return $slot;
  };

  # Suppress redirect warnings during test
  local $redis->{_test} = 1;

  # redirect
  $res = $redis->set($key, 1);
  die('[set] error') unless $res && $res eq 'OK';

  $res = $redis->get($key);
  ok($res == 1, 'redirect');

  # redirect inside multi
  $res = $redis->multi();
  die('[multi] error') unless $res && $res eq 'OK';

  dies_ok(sub { $redis->get($key); }, 'redirect inside multi');

  # redirect inside watch
  $res = $redis->watch($key);
  die('[watch] error') unless $res && $res eq 'OK';

  dies_ok(sub { $redis->get($key); }, 'redirect inside watch');
}

$redis->del($key);
die('[del] error') unless $res && $res eq 'OK';

done_testing();
