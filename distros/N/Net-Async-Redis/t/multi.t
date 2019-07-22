use strict;
use warnings;

use Test::More;
use Test::Fatal;

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
    my $multi = $redis->multi(sub {
        my ($tx) = @_;
        $tx->set(x => 123);
        $tx->get('x')->on_ready(sub {
            my $f = shift;
            is(exception {
                my ($data) = $f->get;
                is($data, '123', 'data is correct');
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
    done_testing;
};

done_testing;


