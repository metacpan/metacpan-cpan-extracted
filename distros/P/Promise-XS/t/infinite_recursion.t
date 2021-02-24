#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::FailWarnings;

use Promise::XS;

plan skip_all => "Ancient perl: $^V" if $^V lt v5.10.0;

my @tests = (
    [ 'then', 'resolved' ],
    [ 'catch', 'rejected', 1 ],
    [ 'finally', 'resolved' ],
);

for my $t_ar (@tests) {
    my ($method, $factory, $throw_yn) = @$t_ar;

    my $promise_cr = sub { Promise::XS->can($factory)->(123) };

    sub foo {
        return $promise_cr->()->$method( sub {
            my $v = bar();
            die $v if $throw_yn;
            return $v;
        } );
    }

    sub bar {
        return $promise_cr->()->$method( sub {
            my $v = foo();
            die $v if $throw_yn;
            return $v;
        } );
    }

    my $err;
    my @warnings;

    my $rejected = do {
        local $SIG{'__WARN__'} = sub { push @warnings, @_ };
        foo()->catch( sub { $err = shift } );
    };

    cmp_deeply(
        \@warnings,
        array_each( re( qr<recurs>i ) ),
        "$method: only warnings are recursion warnings",
    );

    like( $err, qr<recurs>i, "$method: promise rejects as expected" );
}

done_testing;

1;
