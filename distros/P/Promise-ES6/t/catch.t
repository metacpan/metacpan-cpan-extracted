package t::catch;
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

sub reject_catch : Tests {
    my ($self) = @_;

    my $p = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $reject->('oh my god!');
    })->catch(sub {
        my ($reason) = @_;
        return $reason;
    });
    is PromiseTest::await($p), 'oh my god!';
}

sub then_reject_catch : Tests {
    my ($self) = @_;

    my $p = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(123);
    })->then(sub {
        my ($value) = @_;
        return Promise::ES6->new(sub {
            my ($resolve, $reject) = @_;
            die { message => 'oh my god', value => $value };
        });
    })->catch(sub {
        my ($reason) = @_;
        return $reason;
    });
    is_deeply PromiseTest::await($p), { message => 'oh my god', value => 123 };
}

sub exception_catch : Tests {
    my ($self) = @_;

    my $p = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        die { message => 'oh my god!!' };
    });
    is_deeply exception {
        PromiseTest::await($p);
    }, { message => 'oh my god!!' };
}

sub then_exception_await : Tests {
    my ($self) = @_;

    my $p = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(123);
    })->then(sub {
        my ($value) = @_;
        die { message => $value };
    });
    is_deeply exception { PromiseTest::await($p) }, { message => 123 };
}

sub exception_then_await : Tests {
    my ($self) = @_;

    my $p = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        die { message => 'oh my god!!!' }
    })->then(sub {
        my ($value) = @_;
        #
    }, sub {
        my ($reason) = @_;
        return { reason => $reason };
    });
    is_deeply PromiseTest::await($p), { reason => { message => 'oh my god!!!' } };
}

sub exception_catch_then_await : Tests {
    my ($self) = @_;

    my $p = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        die { message => 'oh my god!!!' }
    })->catch(sub {
        my ($reason) = @_;
        return { recover => 1, reason => $reason };
    })->then(sub {
        my ($value) = @_;
        return $value;
    });
    is_deeply PromiseTest::await($p), { recover => 1, reason => { message => 'oh my god!!!' } };
}

__PACKAGE__->new()->runtests;
