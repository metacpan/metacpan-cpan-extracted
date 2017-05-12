# -*- perl -*-

###########################################################################

use strict;
use Test::More;

use Redis;
use Redis::Queue;

###########################################################################

# Try to get a working redis handle
my $redis = eval { Redis->new() };
if ($redis) {
    plan tests => 19;
}
else {
    plan skip_all => "Running instance of Redis is required for tests";
}

ok $redis, 'Redis instantiation';

ok my $info = $redis->info(), 'Redis server info';
my ($v_maj) = $info->{redis_version} =~ /^(\d+)\./;

ok ($v_maj > 0 && $v_maj <= 2), "Redis server is $v_maj.x";

ok my $queue = Redis::Queue->new(redis => $redis, queue => "Test$$", timeout => 2), 'Redis::Queue instantiation';

is_deeply [ $queue->receiveMessage() ], [ ], 'receive from empty';

ok my $key1 = $queue->sendMessage("foo"), 'send foo';
is_deeply [ $queue->receiveMessage() ], [ $key1, "foo" ], 'receive foo';
is_deeply [ $queue->receiveMessage() ], [ ], 'receive while working foo';
sleep 3;
is_deeply [ $queue->receiveMessage() ], [ $key1, "foo" ], 'receive foo 2';
$queue->deleteMessage($key1);
sleep 3;
is_deeply [ $queue->receiveMessage() ], [ ], 'receive after delete foo';

ok my $key2 = $queue->sendMessage("bar"), 'send bar';
ok my $key3 = $queue->sendMessage("baz"), 'send baz';
is_deeply [ $queue->receiveMessage() ], [ $key2, "bar" ], 'receive bar';
is_deeply [ $queue->receiveMessage() ], [ $key3, "baz" ], 'receive baz';
is_deeply [ $queue->receiveMessage() ], [ ], 'receive while working bar and baz';
$queue->deleteMessage($key3);
sleep 3;
is_deeply [ $queue->receiveMessage() ], [ $key2, "bar" ], 'receive bar 2';
is_deeply [ $queue->receiveMessage() ], [ ], 'receive while working bar';
$queue->deleteMessage($key2);
sleep 3;
is_deeply [ $queue->receiveMessage() ], [ ], 'receive after delete bar and baz';

my @keys = $redis->keys("queue:Test$$:*");
if ($v_maj == 1) {
    is_deeply [ @keys ], [ "queue:Test$$:primary" ], 'keys left after testing';
    for my $key (@keys) {
        $redis->del($key);
    }
}
else {
    is_deeply [ @keys ], [ ], 'keys left after testing';
}
