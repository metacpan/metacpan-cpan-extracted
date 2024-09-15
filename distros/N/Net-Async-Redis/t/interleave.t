use Full::Script qw(:v1);
use Test::More;
use Test::Fatal;

use Net::Async::Redis;
use IO::Async::Loop;
use Math::Random::Secure;
use List::Util qw(shuffle);

plan skip_all => 'set NET_ASYNC_REDIS_HOST env var to test' unless exists $ENV{NET_ASYNC_REDIS_HOST};

# If we have ::TAP, use it - but no need to list it as a dependency
eval {
    require Log::Any::Adapter;
    Log::Any::Adapter->import(qw(TAP));
};

sub uuid {
    # UUIDv4 (random)
    my @rand = map { Math::Random::Secure::irand(2**32) } 1..4;
    return sprintf '%08x-%04x-%04x-%04x-%04x%08x',
        $rand[0],
        $rand[1] & 0xFFFF,
        (($rand[1] & 0x0FFF0000) >> 16) | 0x4000,
        $rand[2] & 0xBFFF,
        ($rand[2] & 0xFFFF0000) >> 16,
        $rand[3];
}

my $loop = IO::Async::Loop->new;
$loop->add(my $redis = Net::Async::Redis->new);
await $redis->connect(
    host => $ENV{NET_ASYNC_REDIS_HOST} // '127.0.0.1',
    port => $ENV{NET_ASYNC_REDIS_PORT} // '6379',
);
note 'Connected to Redis server';

package local::CancelledCommand {
    use Full::Class qw(:v1);
    field $method : param : reader;
    sub throw ($class, $method) { die $class->new(method => $method) }
}

# Randomly cancel occasional requests
my $run = async sub ($method, @args) {
    my $f = $redis->$method(@args);
    if(rand > 0.95) {
        $f->cancel;
        return local::CancelledCommand->throw($method);
    }
    return await $f;
};

# Some typical Redis access patterns
my %handler = (
    get => async sub ($k) {
        my $v = rand;
        await $run->(set => $k => $v);
        await $run->(expire => $k, 30);
        is(await $run->(get => $k), $v, 'value matches for ' . $k);
        return;
    },
    list => async sub ($k) {
        await $run->(lpush => $k, rand);
        await $run->(expire => $k, 30);
        is(await $run->(llen => $k), 1, 'list only has one item');
        await $run->(rpush => $k, rand);
        is(await $run->(llen => $k), 2, 'list has another item');
        await $run->(lpop => $k);
        is(await $run->(llen => $k), 1, 'down to 1 after pop');
        return;
    },
    stream => async sub ($k) {
        await $run->(xadd => $k, '*', random => rand);
        await $run->(expire => $k, 30);
        my $info = async sub {
            my $data = await $run->(xinfo => qw(stream), $k);
            return +{ $data->@* };
        };
        is((await $info->())->{length}, 1, 'xadd has length 1');
        await $run->(xadd => $k, '*', random => rand);
        is((await $info->())->{length}, 2, 'xadd has length 2 after adding another');
        await $run->(xtrim => $k, qw(maxlen = 1));
        is((await $info->())->{length}, 1, 'xadd has length 1 after trim');
        await $run->(xadd => $k, '*', random => rand);
        is((await $info->())->{length}, 2, 'xadd has length 2 after adding another');
        await $run->(xadd => $k, '*', random => rand);
        is((await $info->())->{length}, 3, 'xadd has length 3 after adding another');
        await $run->(xgroup_create => $k => qw(x 0));
        {
            my $read = await $run->(xreadgroup => qw(group x y count 2 noack streams), $k, '>');
#           note explain $read;
            is(0 + $read->[0][1]->@*, 2, 'read 2 items');
        }
        await Future->needs_all(
            map { $run->(xadd => $k, '*', random => rand) } 1..50
        );
        {
            my $read = await $run->(xreadgroup => qw(group x y count 50 noack streams), $k, '>');
#           note explain $read;
            is(0 + $read->[0][1]->@*, 50, 'read 50 items');
        }
        return;
    },
    error => async sub ($k) {
        try {
            await $redis->execute_command(qw(invalid command for testing));
            fail('should not succeed after invalid command');
        } catch ($e) {
            like($e, qr/unknown command/, 'had expected error for invalid command');
        }
    },
);

my @keys = List::Util::shuffle(keys %handler);
await fmap_void(async sub {
    my $method = $keys[rand @keys];
    my $k = uuid();
    try {
        await $handler{$method}->($k);
        pass("successful $method");
        await $redis->unlink($k);
    } catch ($e isa local::CancelledCommand) {
        note "Cancelled $e->method, ignoring";
    } catch ($e) {
        fail("problem with $method - $e");
        await $redis->unlink($k);
    }
}, foreach => [1..($ENV{AUTHOR_TESTING} ? 10000 : 100)], concurrent => 64);

done_testing;

