package t::allsettled;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use MemoryCheck;

use PromiseTest;

use parent qw(Test::Class);

use Time::HiRes;

use Test::Fatal qw(exception);
use Test::FailWarnings;
use Test::More;
use Test::Deep;

use Promise::ES6;

sub test_all_success : Tests {
    my $self = shift;

    my $p1 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(1);
    });
    my $p2 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(2);
    });
    my $all = Promise::ES6->allSettled([$p1, $p2, 3]);

    is_deeply(
        PromiseTest::await( $all ),
        [
            { status => 'fulfilled', value => 1 },
            { status => 'fulfilled', value => 2 },
            { status => 'fulfilled', value => 3 },
        ],
        'expected resolution',
    );
}

sub all_fail_then_succeed : Tests {
    my ($self) = @_;

    my $p1 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $reject->({ message => 'oh my god' });
    });
    my $p2 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(1);
    });

    my $all = Promise::ES6->allSettled([$p1, $p2]);

    my $res = PromiseTest::await( $all );

    is_deeply(
        $res,
        [
            { status => 'rejected', reason => { message => 'oh my god' } },
            { status => 'fulfilled', value => 1 },
        ],
        'expected resolution',
    ) or diag explain $res;
}


sub empty : Tests {
    my $foo;

    Promise::ES6->allSettled([])->then( sub { $foo = 42 } );

    is( $foo, 42, 'resolves immediately when given an empty list' );
}

__PACKAGE__->new()->runtests;
