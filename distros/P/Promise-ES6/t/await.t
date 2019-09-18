package t::await;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use MemoryCheck;
use PromiseTest;

use parent qw(Test::Class);

use Time::HiRes;

use Test::Fatal qw(exception);
use Test::More;
use Test::FailWarnings;

use Promise::ES6;

sub await_func : Tests {
    my ($self) = @_;

    my $promise = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(123);
    });

    isa_ok $promise, 'Promise::ES6';
    is PromiseTest::await($promise), 123, 'get resolved value';
}

sub reject_await : Tests {
    my ($self) = @_;

    my $promise = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $reject->({ message => 'oh my god' });
    });

    isa_ok $promise, 'Promise::ES6';
    is_deeply exception { PromiseTest::await($promise) }, { message => 'oh my god' };
}

sub exception_await : Tests {
    my ($self) = @_;

    my $promise = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        die { message => 'oh my god' };
    });

    isa_ok $promise, 'Promise::ES6';
    is_deeply exception { PromiseTest::await($promise) }, { message => 'oh my god' };
}

sub then_await : Tests {
    my ($self) = @_;

    my $promise = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(123);
    })->then(sub {
        my ($value) = @_;
        return $value * 2;
    });

    isa_ok $promise, 'Promise::ES6';
    is PromiseTest::await($promise), 123 * 2, 'get resolved value';
}

__PACKAGE__->new()->runtests;
