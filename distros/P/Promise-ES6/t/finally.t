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

sub propagate_success_through : Tests {
    my $p = Promise::ES6->resolve(123);

    my $got;

    my $finally = $p->finally( sub { } );

    my $p2 = $finally->then( sub { $got = shift } );

    is( $got, 123, 'finally() doesn’t affect success propgation' );
}

sub propagate_failure_through : Tests {
    my $p = Promise::ES6->reject(123);

    my $got;

    my $finally = $p->finally( sub { } );

    my $p2 = $finally->catch( sub { $got = shift } );

    is( $got, 123, 'finally() doesn’t affect failure propgation' );
}

__PACKAGE__->runtests;
