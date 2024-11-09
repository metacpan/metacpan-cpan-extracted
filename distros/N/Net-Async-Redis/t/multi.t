use strict;
use warnings;
use experimental qw(signatures);

use Test::More;
use Test::Fatal;
use Future::AsyncAwait;
use Future::Utils qw(fmap_void);

use Net::Async::Redis;
use IO::Async::Loop;

plan skip_all => 'set NET_ASYNC_REDIS_HOST env var to test' unless exists $ENV{NET_ASYNC_REDIS_HOST};

# If we have ::TAP, use it - but no need to list it as a dependency
eval {
    require Log::Any::Adapter;
    Log::Any::Adapter->import(qw(TAP));
};

my $loop = IO::Async::Loop->new;
$loop->add(my $redis = Net::Async::Redis->new);
$redis->connect(
    host => $ENV{NET_ASYNC_REDIS_HOST} // '127.0.0.1',
    port => $ENV{NET_ASYNC_REDIS_PORT} // '6379',
)->get;

subtest 'basic MULTI' => sub {
    $redis->multi(sub {
        my ($tx) = @_;
        $tx->set(x => 123);
        $tx->get('x')->on_ready(sub {
            my $f = shift;
            is(exception {
                my ($data) = $f->get;
                is($data, '123', 'data is correct');
            }, undef, 'no exception on ->get');
        });
    })->get;
    done_testing;
};

subtest 'MULTI combined with regular requests' => sub {
    my $data;
    my $multi = $redis->multi(sub {
        my ($tx) = @_;
        $tx->set(x => 123);
        $tx->get('x')->on_ready(sub {
            my $f = shift;
            is(exception {
                ($data) = $f->get;
                is($data, '123', 'data is correct inside MULTI');
            }, undef, 'no exception on ->get');
        });
    });
    my $f = $redis->get('x')->on_ready(sub {
        my $f = shift;
        is(exception {
            my ($data) = $f->get;
            is($data, '123', 'data is correct in regular ->get');
        }, undef, 'no exception on ->get outside MULTI');
    });
    Future->needs_all(
        $multi,
        $f
    )->get;
    is($data, '123', 'data is correct after multi');
    done_testing;
};

subtest 'MULTI while existing MULTI is active' => sub { (async sub {
    my $data;
    my $k = "multi.key";
    await $redis->hset($k, x => "y");
    await $redis->expire($k, 60);
    my %result;
    my $target = $ENV{AUTHOR_TESTING} ? 1000 : 20;
    await fmap_void(async sub ($item) {
        await $redis->multi(sub ($tx) {
            $tx->hset($k, $item => '' . reverse $item);
            $tx->hget($k, $item)->on_ready(sub {
                my $f = shift;
                is(exception {
                    ($data) = $f->get;
                    $result{$item} = $data;
                    is($data, '' . reverse($item), 'data is correct inside MULTI');
                }, undef, 'no exception on ->get');
            });
            return;
        });
    }, concurrent => 64, foreach => [1 .. $target]);
    done_testing;
})->()->get };

subtest 'MULTI interspersed with regular Redis calls' => sub { (async sub {
    my $data;
    my $k = "multi.key";
    await $redis->unlink($k);
    await $redis->hset($k, x => "y");
    await $redis->expire($k, 300);
    my %result;
    my $target = $ENV{AUTHOR_TESTING} ? 1000 : 20;
    await $redis->unlink($k . '.count');
    await fmap_void(async sub ($item) {
        await $redis->multi(sub ($tx) {
            my $v = '' . reverse $item;
            $tx->hset($k, $item => $v);
            $redis->hget($k, $item)->on_ready(sub {
                my $f = shift;
                is(exception {
                    ($data) = $f->get;
                    is($data, $result{$item}, 'data is correct inside regular HGET');
                }, undef, 'no exception on ->get');
            });
            $redis->incr($k . '.count')->retain;
            $tx->hget($k, $item)->on_ready(sub {
                my $f = shift;
                is(exception {
                    ($data) = $f->get;
                    $result{$item} = $data;
                    is($data, $v, 'data is correct inside MULTI');
                }, undef, 'no exception on ->get');
            });
            return;
        });
    }, concurrent => 64, foreach => [1..$target]);
    is(await $redis->get($k . '.count'), $target, 'count matches afterwards');
    done_testing;
})->()->get };

done_testing;


