#!/usr/bin/env perl

use v5.38;
use Test::More;
use Future::AsyncAwait;

use PAGI::FastAPI::Queue::Driver::Memory;

subtest 'isa PAGI::FastAPI::Queue::Driver' => sub {
    my $driver = PAGI::FastAPI::Queue::Driver::Memory->new;
    isa_ok $driver, 'PAGI::FastAPI::Queue::Driver::Memory';
    isa_ok $driver, 'PAGI::FastAPI::Queue::Driver';
};

subtest 'push/pop is FIFO order' => sub {
    my $driver = PAGI::FastAPI::Queue::Driver::Memory->new;

    $driver->push('jobs', 'first')->get;
    $driver->push('jobs', 'second')->get;
    $driver->push('jobs', 'third')->get;

    is $driver->pop('jobs')->get, 'first',  'first pushed is first popped';
    is $driver->pop('jobs')->get, 'second', 'second pushed is second popped';
    is $driver->pop('jobs')->get, 'third',  'third pushed is third popped';
};

subtest 'push() returns a truthy Future result' => sub {
    my $driver = PAGI::FastAPI::Queue::Driver::Memory->new;
    is $driver->push('jobs', 'x')->get, 1, 'push() resolves true';
};

subtest 'pop() on an unknown topic returns undef, not an error' => sub {
    my $driver = PAGI::FastAPI::Queue::Driver::Memory->new;
    is $driver->pop('never_pushed')->get, undef,
        'popping a topic that was never pushed to returns undef';
};

subtest 'pop() on a drained topic returns undef' => sub {
    my $driver = PAGI::FastAPI::Queue::Driver::Memory->new;

    $driver->push('jobs', 'only')->get;
    $driver->pop('jobs')->get;

    is $driver->pop('jobs')->get, undef, 'popping an emptied topic returns undef';
};

subtest 'payloads can be any scalar, including refs and falsy values' => sub {
    my $driver = PAGI::FastAPI::Queue::Driver::Memory->new;

    $driver->push('mixed', 0)->get;
    $driver->push('mixed', '')->get;
    $driver->push('mixed', { a => 1 })->get;

    is $driver->pop('mixed')->get, 0, 'falsy numeric 0 payload survives round-trip';
    is $driver->pop('mixed')->get, '', 'empty-string payload survives round-trip';
    is_deeply $driver->pop('mixed')->get, { a => 1 }, 'hashref payload survives round-trip';
};

subtest 'topics are independent of one another' => sub {
    my $driver = PAGI::FastAPI::Queue::Driver::Memory->new;

    $driver->push('a', 'a1')->get;
    $driver->push('b', 'b1')->get;
    $driver->push('b', 'b2')->get;

    is $driver->size('a')->get, 1, 'topic a has its own count';
    is $driver->size('b')->get, 2, 'topic b has its own count';
    is $driver->pop('a')->get, 'a1', 'popping a does not touch b';
    is $driver->size('b')->get, 2, 'topic b is unaffected by popping topic a';
};

subtest 'size(topic) counts only that topic' => sub {
    my $driver = PAGI::FastAPI::Queue::Driver::Memory->new;

    is $driver->size('empty')->get, 0, 'size of an unknown topic is 0';

    $driver->push('t', $_)->get for 1 .. 3;
    is $driver->size('t')->get, 3, 'size reflects number of pending items';

    $driver->pop('t')->get;
    is $driver->size('t')->get, 2, 'size decreases after a pop';
};

subtest 'size() with no topic sums across all topics' => sub {
    my $driver = PAGI::FastAPI::Queue::Driver::Memory->new;

    is $driver->size->get, 0, 'total size is 0 for a fresh driver';

    $driver->push('a', 'x')->get;
    $driver->push('a', 'y')->get;
    $driver->push('b', 'z')->get;

    is $driver->size->get, 3, 'total size sums every topic';
    is $driver->size(undef)->get, 3, 'explicit undef topic behaves like no argument';
};

subtest 'clear(topic) empties a single topic only' => sub {
    my $driver = PAGI::FastAPI::Queue::Driver::Memory->new;

    $driver->push('a', 'x')->get;
    $driver->push('b', 'y')->get;

    my $ret = $driver->clear('a');
    is $ret, $driver, 'clear() returns $self for chaining';
    is $driver->size('a')->get, 0, 'cleared topic is empty';
    is $driver->size('b')->get, 1, 'other topics are untouched';
};

subtest 'clear() with no topic empties every topic' => sub {
    my $driver = PAGI::FastAPI::Queue::Driver::Memory->new;

    $driver->push('a', 'x')->get;
    $driver->push('b', 'y')->get;

    $driver->clear;

    is $driver->size->get, 0, 'all topics emptied';
    is $driver->pop('a')->get, undef, 'topic a is empty after global clear';
    is $driver->pop('b')->get, undef, 'topic b is empty after global clear';
};

subtest 'each driver instance has isolated storage' => sub {
    my $d1 = PAGI::FastAPI::Queue::Driver::Memory->new;
    my $d2 = PAGI::FastAPI::Queue::Driver::Memory->new;

    $d1->push('t', 'only-in-d1')->get;

    is $d1->size('t')->get, 1, 'd1 has the pushed item';
    is $d2->size('t')->get, 0, 'd2 does not see d1 state (no shared class storage)';
};

done_testing;
