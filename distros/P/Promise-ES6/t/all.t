package t::all;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use PromiseTest;

use parent qw(Test::Class);

use Time::HiRes;

use Test::Fatal qw(exception);
use Test::More;

use Promise::ES6;

sub all : Tests {
    my $self = shift;

    my $p1 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(1);
    });
    my $p2 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(2);
    });
    my $all = Promise::ES6->all([$p1, $p2, 3]);

    is_deeply( PromiseTest::await( $all ), [1, 2, 3] );
}

sub all_values : Tests {
    my ($self) = @_;

    my $all = Promise::ES6->all([1, 2]);
    is_deeply( PromiseTest::await($all), [1,2] );
}

sub all_fail : Tests {
    my ($self) = @_;

    my $p1 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(1);
    });
    my $p2 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $reject->({ message => 'oh my god' });
    });

    my $all = Promise::ES6->all([$p1, $p2]);

    is_deeply(
        exception { PromiseTest::await($all) },
        { message => 'oh my god' },
    );
}

sub all_exception : Tests {
    my ($self) = @_;

    my $p1 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(1);
    });
    my $p2 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        die { message => 'oh my god' };
    });

    my $all = Promise::ES6->all([$p1, $p2]);

    is_deeply(
        exception { PromiseTest::await($all) },
        { message => 'oh my god' },
    );
}

__PACKAGE__->new()->runtests;
