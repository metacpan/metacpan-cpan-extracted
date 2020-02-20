package t::race;
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
use Test::Deep;
use Test::FailWarnings;

use Promise::ES6;

sub race_with_value : Tests {
    my ($self) = @_;

    my $resolve_cr;

    # This will never resolve.
    my $p1 = Promise::ES6->new(sub {});

    my $p2 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(2);
    });

    my $value = PromiseTest::await( Promise::ES6->race([$p1, $p2]) );

    is $value, 2, 'got raw value instantly';
}

sub everything_fails : Tests {
    my ($self) = @_;

    my $p1 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $reject->(1);
    });

    my $p2 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $reject->({ message => 'oh my god' });
    });

    my $p3 = Promise::ES6->race([$p1, $p2]);

    cmp_deeply(
        exception { PromiseTest::await($p3) },
        re( qr<\A1 > ),
    );
}

__PACKAGE__->new()->runtests;
