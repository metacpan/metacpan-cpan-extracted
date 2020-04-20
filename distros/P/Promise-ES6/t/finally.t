package t::finally;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use MemoryCheck;
use parent qw(Test::Class);

use Time::HiRes;

use Test::More;
use Test::FailWarnings;

use Promise::ES6;

sub finally_within_then : Tests {
    my @w;

    {
        local $SIG{'__WARN__'} = sub { push @w, @_ };

        Promise::ES6->reject(123)->catch(
            sub {
                Promise::ES6->resolve(123)->finally( sub {} );
                return 123;
            },
        );
    }

    is( "@w", q<>, 'finally() within a callback doesn’t corrupt logic' );
}

sub propagate_success_through : Tests {
    my $p = Promise::ES6->resolve(123);

    my $got;

    my $finally = $p->finally( sub { } );

    my $p2 = $finally->then( sub { $got = shift } );

    is( $got, 123, 'finally() doesn’t affect success propagation' );
}

sub propagate_failure_through : Tests {
    my $p = Promise::ES6->reject(123);

    my $got;

    my $finally = $p->finally( sub { } );

    my $p2 = $finally->catch( sub { $got = shift } );

    is( $got, 123, 'finally() doesn’t affect failure propagation' );
}

sub ignore_returned_resolution : Tests(1) {
    my $p = Promise::ES6->resolve(123);

    my @settled;
    $p->finally( sub { Promise::ES6->resolve(456) } )->then(
        sub { $settled[0] = shift },
        sub { $settled[1] = shift },
    );

    is_deeply( \@settled, [ 123 ], 'returned resolution is thrown away' );
}

sub propagate_returned_rejection : Tests(1) {
    my $p = Promise::ES6->resolve(123);

    my @settled;
    $p->finally( sub { Promise::ES6->reject(666) } )->then(
        sub { $settled[0] = shift },
        sub { $settled[1] = shift },
    );

    is_deeply( \@settled, [ undef, 666 ], 'returned reject is honored' );
}

__PACKAGE__->runtests;
