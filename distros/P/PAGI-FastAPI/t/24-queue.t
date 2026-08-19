#!/usr/bin/env perl

use v5.38;
use Test::More;
use Future::AsyncAwait;
use Scalar::Util qw(blessed);

use PAGI::FastAPI::Queue;
use PAGI::FastAPI::Queue::Driver::Memory;

subtest 'defaults to the Memory driver' => sub {
    my $q = PAGI::FastAPI::Queue->new;
    isa_ok $q, 'PAGI::FastAPI::Queue';

    $q->push('t', 'payload')->get;
    is $q->pop('t')->get, 'payload', 'default driver actually stores/retrieves data';
};

subtest 'driver can be selected by short name' => sub {
    my $q = PAGI::FastAPI::Queue->new(driver => 'Memory');
    $q->push('t', 'x')->get;
    is $q->size('t')->get, 1, 'short driver name "Memory" resolves and works';
};

subtest 'driver can be selected by fully-qualified class name' => sub {
    my $q = PAGI::FastAPI::Queue->new(
        driver => 'PAGI::FastAPI::Queue::Driver::Memory',
    );
    $q->push('t', 'x')->get;
    is $q->size('t')->get, 1, 'fully-qualified driver name resolves and works';
};

subtest 'options are passed through to the driver constructor' => sub {
    my $q = PAGI::FastAPI::Queue->new(
        driver  => 'Memory',
        options => {},
    );
    isa_ok $q, 'PAGI::FastAPI::Queue';
};

subtest 'unknown driver name dies with a helpful message' => sub {
    my $err = eval {
        PAGI::FastAPI::Queue->new(driver => 'NoSuchDriver');
        1;
    } ? undef : $@;

    ok $err, 'construction dies for a nonexistent driver';
    like $err, qr/Failed to load queue driver/,
        'error explains that driver loading failed';
    like $err, qr/PAGI::FastAPI::Queue::Driver::NoSuchDriver/,
        'error names the fully-qualified class it tried to load';
};

subtest 'push/pop/size delegate to the underlying driver' => sub {
    my $q = PAGI::FastAPI::Queue->new;

    $q->push('orders', 'order-1')->get;
    $q->push('orders', 'order-2')->get;

    is $q->size('orders')->get, 2, 'size() reflects pushes made through the facade';
    is $q->pop('orders')->get, 'order-1', 'pop() returns items in FIFO order';
    is $q->size('orders')->get, 1, 'size() drops after a pop';
};

subtest 'size() with no topic aggregates, like the driver does' => sub {
    my $q = PAGI::FastAPI::Queue->new;

    $q->push('a', 1)->get;
    $q->push('b', 2)->get;
    $q->push('b', 3)->get;

    is $q->size->get, 3, 'facade size() with no args sums across topics';
};

subtest 'dep() returns a zero-arg closure suitable for Depends()' => sub {
    my $q = PAGI::FastAPI::Queue->new;
    my $dep = $q->dep;

    is ref($dep), 'CODE', 'dep() returns a CODE ref';
    is $dep->(), $q, 'invoking the closure returns the same Queue instance';

    is $dep->('some $c context arg'), $q,
        'closure ignores any arguments passed to it (e.g. the route context)';
};

subtest 'two Queue instances do not share driver state' => sub {
    my $q1 = PAGI::FastAPI::Queue->new;
    my $q2 = PAGI::FastAPI::Queue->new;

    $q1->push('t', 'only-in-q1')->get;

    is $q1->size('t')->get, 1, 'q1 sees its own pushed item';
    is $q2->size('t')->get, 0, 'q2 has independent, empty storage';
};

subtest 'an explicit driver object option is rejected (string name expected)' => sub {
    my $prebuilt = PAGI::FastAPI::Queue::Driver::Memory->new;

    my $err = eval {
        PAGI::FastAPI::Queue->new(driver => $prebuilt);
        1;
    } ? undef : $@;

    ok $err, 'passing an already-built driver object does not work like Middleware::RateLimit';
};

done_testing;
