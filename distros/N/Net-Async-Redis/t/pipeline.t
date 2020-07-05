use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Syntax::Keyword::Try;
use Future::AsyncAwait;
use Net::Async::Redis;
use IO::Async::Loop;

plan skip_all => 'set NET_ASYNC_REDIS_HOST or NET_ASYNC_REDIS_URI env var to test' unless exists $ENV{NET_ASYNC_REDIS_HOST} or exists $ENV{NET_ASYNC_REDIS_URI};

# If we have ::TAP, use it - but no need to list it as a dependency
eval {
    require Log::Any::Adapter;
    Log::Any::Adapter->import(qw(TAP));
};

my $loop = IO::Async::Loop->new;
sub redis {
    my ($msg, %args) = @_;
    $loop->add(my $redis = Net::Async::Redis->new(%args));
    is(exception {
        Future->needs_any(
            $redis->connect(
                host => $ENV{NET_ASYNC_REDIS_HOST} // '127.0.0.1',
                port => $ENV{NET_ASYNC_REDIS_PORT} // '6379',
            ),
            $loop->timeout_future(after => 5)
        )->get
    }, undef, 'can connect' . ($msg ? " for $msg" : ''));
    return $redis;
}

my $main = redis(
    'main connection',
    pipeline_depth => 5
);

(async sub {
    try {
        my $f = Future->needs_all(
            map $main->get('key::' . $_), 1..100
        );
        ok(!$f->is_ready, 'initial GET requests start out pending');
        ok(@{$main->{awaiting_pipeline}}, 'have some requests queued for pipelining');
        await $f;
        ok(!@{$main->{awaiting_pipeline}}, 'no more requests queued for pipelining');
        await Future->needs_all(
            map { $main->set('key::' . $_, 'xx' . $_) } 1..100
        );
        my @expected = map { "xx$_" } 1..100;
        is_deeply(
            [ (await Future->needs_all(
                map { $main->get('key::' . $_) } 1..100
            )) ],
            \@expected,
            'after pipelined SET, pipelined GET works'
        );
    } catch {
        fail('error - ' . $@);
    }
})->()->get;
done_testing;

