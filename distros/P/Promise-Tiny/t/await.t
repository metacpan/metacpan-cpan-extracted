package t::await;
use strict;
use warnings;

use parent qw(Test::Class);
use Test::Fatal qw(exception);
use Test::More;

use Promise::Tiny::AnyEvent qw(promise);

sub await : Tests {
    my $promise = promise(sub {
        my ($resolve, $reject) = @_;
        $resolve->(123);
    });

    isa_ok $promise, 'Promise::Tiny::AnyEvent';
    is $promise->await(), 123, 'get resolved value';
}

sub reject_await : Tests {
    my $promise = promise(sub {
        my ($resolve, $reject) = @_;
        $reject->({ message => 'oh my god' });
    });

    isa_ok $promise, 'Promise::Tiny::AnyEvent';
    is_deeply exception { $promise->await() }, { message => 'oh my god' };
}

sub exception_await : Tests {
    my $promise = promise(sub {
        my ($resolve, $reject) = @_;
        die { message => 'oh my god' };
    });

    isa_ok $promise, 'Promise::Tiny::AnyEvent';
    is_deeply exception { $promise->await() }, { message => 'oh my god' };
}

sub then_await : Tests {
    my $promise = promise(sub {
        my ($resolve, $reject) = @_;
        $resolve->(123);
    })->then(sub {
        my ($value) = @_;
        return $value * 2;
    });

    isa_ok $promise, 'Promise::Tiny::AnyEvent';
    is $promise->await(), 123 * 2, 'get resolved value';
}

sub await_with_async : Tests {
    my $promise = promise(sub {
        my ($resolve, $reject) = @_;
        my $w; $w = AnyEvent->timer(
            after => 0.1,
            cb => sub {
                undef $w;
                $resolve->(123);
            },
        );
    });

    isa_ok $promise, 'Promise::Tiny::AnyEvent';
    is $promise->await(), 123, 'get resolved value';
}

sub then_await_with_async : Tests {
    my $promise = promise(sub {
        my ($resolve, $reject) = @_;
        my $w; $w = AnyEvent->timer(
            after => 0.1,
            cb => sub {
                undef $w;
                $resolve->(123);
            },
        );
    })->then(sub {
        my ($value) = @_;
        return promise(sub {
            my ($resolve, $reject) = @_;
            my $w; $w = AnyEvent->timer(
                after => 0.1,
                cb => sub {
                    undef $w;
                    $resolve->($value * 2);
                },
            );
        });
    });

    isa_ok $promise, 'Promise::Tiny::AnyEvent';
    is $promise->await(), 123 * 2;
}

__PACKAGE__->runtests;
