package t::await;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use parent qw(PromiseTest);

use Time::HiRes;

use Test::Fatal qw(exception);
use Test::More;

use Promise::ES6;

sub await_func : Tests {
    my ($self) = @_;

    my $promise = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(123);
    });

    isa_ok $promise, 'Promise::ES6';
    is $self->await($promise), 123, 'get resolved value';
}

sub reject_await : Tests {
    my ($self) = @_;

    my $promise = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $reject->({ message => 'oh my god' });
    });

    isa_ok $promise, 'Promise::ES6';
    is_deeply exception { $self->await($promise) }, { message => 'oh my god' };
}

sub exception_await : Tests {
    my ($self) = @_;

    my $promise = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        die { message => 'oh my god' };
    });

    isa_ok $promise, 'Promise::ES6';
    is_deeply exception { $self->await($promise) }, { message => 'oh my god' };
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
    is $self->await($promise), 123 * 2, 'get resolved value';
}

sub await_with_async : Tests {
    my ($self) = @_;

    my $resolve;

    local $SIG{'USR1'} = sub {
        $resolve->(123);
    };

    my $promise = Promise::ES6->new(sub {
        ($resolve) = @_;

        local $SIG{'CHLD'} = 'IGNORE';
        fork or do {
            Time::HiRes::sleep(0.1);
            kill 'USR1', getppid();
            exit;
        };
    });

    isa_ok $promise, 'Promise::ES6';
    is $self->await($promise), 123, 'get resolved value';
}

sub then_await_with_async : Tests {
    my ($self) = @_;

    my @resolves;

    local $SIG{'USR1'} = sub {
       (shift @resolves)->(); 
    };

    my $promise = Promise::ES6->new(sub {
        my ($resolve) = @_;

        push @resolves, sub { $resolve->(123) };
    })->then(sub {
        my ($value) = @_;

        return Promise::ES6->new(sub {
            my ($resolve, $reject) = @_;

            push @resolves, sub { $resolve->($value * 2) };
        });
    });

    local $SIG{'CHLD'} = 'IGNORE';
    fork or do {
        Time::HiRes::sleep(0.1);
        kill 'USR1', getppid();

        Time::HiRes::sleep(0.1);
        kill 'USR1', getppid();

        exit;
    };

    isa_ok $promise, 'Promise::ES6';
    is $self->await($promise), 123 * 2;
}

__PACKAGE__->runtests;
