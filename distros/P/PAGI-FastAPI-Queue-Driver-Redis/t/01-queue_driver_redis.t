#!/usr/bin/env perl

use v5.38;
use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;
use Future::AsyncAwait;

use Test::FakeAsyncRedis;
use PAGI::FastAPI::Queue::Driver::Redis;

subtest 'isa PAGI::FastAPI::Queue::Driver' => sub {
    my $driver = PAGI::FastAPI::Queue::Driver::Redis->new(
        redis => Test::FakeAsyncRedis->new,
    );
    isa_ok $driver, 'PAGI::FastAPI::Queue::Driver::Redis';
    isa_ok $driver, 'PAGI::FastAPI::Queue::Driver';
};

subtest 'push/pop is FIFO order, via RPUSH/LPOP' => sub {
    my $fake   = Test::FakeAsyncRedis->new;
    my $driver = PAGI::FastAPI::Queue::Driver::Redis->new(redis => $fake);

    $driver->push('jobs', 'first')->get;
    $driver->push('jobs', 'second')->get;
    $driver->push('jobs', 'third')->get;

    is $driver->pop('jobs')->get, 'first',  'first pushed is first popped';
    is $driver->pop('jobs')->get, 'second', 'second pushed is second popped';
    is $driver->pop('jobs')->get, 'third',  'third pushed is third popped';
};

subtest 'push() returns true' => sub {
    my $driver = PAGI::FastAPI::Queue::Driver::Redis->new(
        redis => Test::FakeAsyncRedis->new,
    );
    is $driver->push('jobs', 'x')->get, 1, 'push() resolves true';
};

subtest 'pop() on an unknown/empty topic returns undef' => sub {
    my $driver = PAGI::FastAPI::Queue::Driver::Redis->new(
        redis => Test::FakeAsyncRedis->new,
    );
    is $driver->pop('never_pushed')->get, undef,
        'popping a topic that was never pushed to returns undef';
};

subtest 'payloads round-trip through JSON, including refs and falsy values' => sub {
    my $driver = PAGI::FastAPI::Queue::Driver::Redis->new(
        redis => Test::FakeAsyncRedis->new,
    );

    $driver->push('mixed', 0)->get;
    $driver->push('mixed', '')->get;
    $driver->push('mixed', { a => 1, b => [1, 2, 3] })->get;

    is $driver->pop('mixed')->get, 0, 'falsy numeric 0 payload survives round-trip';
    is $driver->pop('mixed')->get, '', 'empty-string payload survives round-trip';
    is_deeply $driver->pop('mixed')->get, { a => 1, b => [1, 2, 3] },
        'nested hashref/arrayref payload survives round-trip';
};

subtest 'keys are namespaced under the configured prefix' => sub {
    my $fake   = Test::FakeAsyncRedis->new;
    my $driver = PAGI::FastAPI::Queue::Driver::Redis->new(
        redis  => $fake,
        prefix => 'myapp:queue:',
    );

    $driver->push('emails', 'x')->get;

    is_deeply $fake->keys_in_store, ['myapp:queue:emails'],
        'the Redis key includes the configured prefix and topic';
};

subtest 'default prefix is pagi:queue:' => sub {
    my $fake   = Test::FakeAsyncRedis->new;
    my $driver = PAGI::FastAPI::Queue::Driver::Redis->new(redis => $fake);

    $driver->push('emails', 'x')->get;

    is_deeply $fake->keys_in_store, ['pagi:queue:emails'],
        'default prefix is "pagi:queue:"';
};

subtest 'topics are independent of one another' => sub {
    my $driver = PAGI::FastAPI::Queue::Driver::Redis->new(
        redis => Test::FakeAsyncRedis->new,
    );

    $driver->push('a', 'a1')->get;
    $driver->push('b', 'b1')->get;
    $driver->push('b', 'b2')->get;

    is $driver->size('a')->get, 1, 'topic a has its own count';
    is $driver->size('b')->get, 2, 'topic b has its own count';
    is $driver->pop('a')->get, 'a1', 'popping a does not touch b';
    is $driver->size('b')->get, 2, 'topic b is unaffected by popping topic a';
};

subtest 'size(topic) uses LLEN on the single key' => sub {
    my $driver = PAGI::FastAPI::Queue::Driver::Redis->new(
        redis => Test::FakeAsyncRedis->new,
    );

    is $driver->size('empty')->get, 0, 'size of an unknown topic is 0';

    $driver->push('t', $_)->get for 1 .. 3;
    is $driver->size('t')->get, 3, 'size reflects number of pending items';

    $driver->pop('t')->get;
    is $driver->size('t')->get, 2, 'size decreases after a pop';
};

subtest 'aggregate size() sums LLEN across every key under the prefix (single SCAN page)' => sub {
    my $driver = PAGI::FastAPI::Queue::Driver::Redis->new(
        redis => Test::FakeAsyncRedis->new,
    );

    is $driver->size->get, 0, 'total size is 0 for a fresh driver';

    $driver->push('a', 'x')->get;
    $driver->push('a', 'y')->get;
    $driver->push('b', 'z')->get;

    is $driver->size->get, 3, 'total size sums every topic under the prefix';
};

subtest 'aggregate size() correctly walks a multi-page SCAN cursor' => sub {
    my $fake = Test::FakeAsyncRedis->new(scan_page_size => 1);
    my $driver = PAGI::FastAPI::Queue::Driver::Redis->new(redis => $fake);

    $driver->push($_, 'x')->get for qw(a b c d e);

    is $driver->size->get, 5,
        'aggregate size is correct even when SCAN returns one key per page';
};

subtest 'aggregate size() only counts keys under this prefix, not other apps sharing Redis' => sub {
    my $fake = Test::FakeAsyncRedis->new;

    my $mine    = PAGI::FastAPI::Queue::Driver::Redis->new(redis => $fake, prefix => 'app-a:');
    my $theirs  = PAGI::FastAPI::Queue::Driver::Redis->new(redis => $fake, prefix => 'app-b:');

    $mine->push('t', 'x')->get;
    $mine->push('t', 'y')->get;
    $theirs->push('t', 'z')->get;

    is $mine->size->get, 2, 'this app only sees its own prefixed keys';
    is $theirs->size->get, 1, 'the other app only sees its own prefixed keys';
};

subtest 'connects lazily and only once per driver instance' => sub {
    my $fake   = Test::FakeAsyncRedis->new;
    my $driver = PAGI::FastAPI::Queue::Driver::Redis->new(redis => $fake);

    is $fake->connect_calls, 0, 'no connection attempt happens at construction time';

    $driver->push('t', 'x')->get;
    is $fake->connect_calls, 1, 'first operation triggers exactly one connect';

    $driver->push('t', 'y')->get;
    $driver->pop('t')->get;
    $driver->size('t')->get;
    is $fake->connect_calls, 1, 'subsequent operations reuse the existing connection';
};

subtest 'each driver instance with its own client has isolated storage' => sub {
    my $d1 = PAGI::FastAPI::Queue::Driver::Redis->new(redis => Test::FakeAsyncRedis->new);
    my $d2 = PAGI::FastAPI::Queue::Driver::Redis->new(redis => Test::FakeAsyncRedis->new);

    $d1->push('t', 'only-in-d1')->get;

    is $d1->size('t')->get, 1, 'd1 sees its own pushed item';
    is $d2->size('t')->get, 0, 'd2 has independent storage (separate fake clients)';
};

subtest 'disconnect() delegates to the underlying client' => sub {
    my $fake   = Test::FakeAsyncRedis->new;
    my $driver = PAGI::FastAPI::Queue::Driver::Redis->new(redis => $fake);

    is $fake->disconnected, 0, 'not disconnected yet';
    $driver->disconnect;
    is $fake->disconnected, 1, 'disconnect() is forwarded to the client exactly once';
};

subtest 'auto-building a client without redis requires Async::Redis' => sub {
    # We don't have Async::Redis installed in this environment (and the
    # driver only requires it when the caller doesn't inject their own
    # client), so constructing without `redis` should fail cleanly rather
    # than hang or produce a confusing error.
    my $err = eval {
        PAGI::FastAPI::Queue::Driver::Redis->new(host => '127.0.0.1', port => 6379);
        1;
    } ? undef : $@;

    if ($err) {
        like $err, qr/Async::Redis/, 'failure clearly names the missing Async::Redis dependency';
    }
    else {
        pass 'Async::Redis is installed in this environment; construction succeeded';
    }
};

done_testing;
