package t::all;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use parent qw(PromiseTest);

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

    is_deeply( $self->await( $all ), [1, 2, 3] );
}

sub all_async : Tests {
    my ($self) = @_;

    my ($resolve1, $resolve2);

    my $p1 = Promise::ES6->new(sub {
        ($resolve1) = @_;
    });

    my $p2 = Promise::ES6->new(sub {
        ($resolve2) = @_;
    });

    local $SIG{'USR1'} = sub { $resolve1->(1) };
    local $SIG{'USR2'} = sub { $resolve2->(2) };

    local $SIG{'CHLD'} = 'IGNORE';
    fork or do {
        kill 'USR2', getppid();
        Time::HiRes::sleep(0.1);
        kill 'USR1', getppid();
        exit;
    };

    my $all = Promise::ES6->all([$p1, $p2, 3]);
    is_deeply( $self->await($all), [1,2,3] );
}

sub all_values : Tests {
    my ($self) = @_;

    my $all = Promise::ES6->all([1, 2]);
    is_deeply( $self->await($all), [1,2] );
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
        exception { $self->await($all) },
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
        exception { $self->await($all) },
        { message => 'oh my god' },
    );
}

__PACKAGE__->runtests;
