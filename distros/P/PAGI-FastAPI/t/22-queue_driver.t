#!/usr/bin/env perl

use v5.38;
use Test::More;
use Future::AsyncAwait;

use PAGI::FastAPI::Queue::Driver;

subtest 'base driver can be instantiated directly' => sub {
    my $driver = PAGI::FastAPI::Queue::Driver->new;
    isa_ok $driver, 'PAGI::FastAPI::Queue::Driver';
};

subtest 'push() is abstract and must be overridden' => sub {
    my $driver = PAGI::FastAPI::Queue::Driver->new;

    my $f = $driver->push('topic', 'payload');
    ok $f->is_ready, 'push() returns an already-failed Future rather than hanging';
    ok $f->failure, 'push() future is a failure';
    like $f->failure, qr/must implement push\(\)/,
        'failure message names the offending class and method';
    like $f->failure, qr/\QPAGI::FastAPI::Queue::Driver\E/,
        'failure message identifies the class';
};

subtest 'pop() is abstract and must be overridden' => sub {
    my $driver = PAGI::FastAPI::Queue::Driver->new;

    my $f = $driver->pop('topic');
    ok $f->failure, 'pop() future is a failure';
    like $f->failure, qr/must implement pop\(\)/, 'failure message names pop()';
};

subtest 'size() is abstract and must be overridden' => sub {
    my $driver = PAGI::FastAPI::Queue::Driver->new;

    my $f = $driver->size;
    ok $f->failure, 'size() future is a failure';
    like $f->failure, qr/must implement size\(\)/, 'failure message names size()';
};

subtest 'a subclass that implements the contract is not affected' => sub {
    # Guards against accidentally breaking subclassing while iterating on
    # the abstract base (e.g. via method resolution order issues).
    package PAGI::FastAPI::Queue::Driver::_TestStub {
        use v5.38;
        use experimental 'class';
        use Future::AsyncAwait;
        use PAGI::FastAPI::Queue::Driver;

        class PAGI::FastAPI::Queue::Driver::_TestStub
            :isa(PAGI::FastAPI::Queue::Driver) {

            async method push ($topic, $payload) { return 1 }
            async method pop  ($topic)           { return 'stub' }
            async method size ($topic = undef)   { return 0 }
        }
    }

    my $stub = PAGI::FastAPI::Queue::Driver::_TestStub->new;
    isa_ok $stub, 'PAGI::FastAPI::Queue::Driver';
    is $stub->push('t', 'p')->get, 1, 'overridden push() runs instead of dying';
    is $stub->pop('t')->get, 'stub', 'overridden pop() runs instead of dying';
    is $stub->size->get, 0, 'overridden size() runs instead of dying';
};

done_testing;
