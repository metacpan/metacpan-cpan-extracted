#!/usr/bin/perl

package t::unhandled_rejection;

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::FailWarnings;

use Promise::XS;

sub _unwrap {
    my $p = shift;

    my @got;
    $p->then(
        sub { $got[0] = [@_] },
        sub { $got[1] = [@_] },
    );

    @got;
}

{
    my $d = Promise::XS::deferred();

    $d->resolve(123);

    my @got = _unwrap( $d->promise()->then( sub { (234, 345) } ) );
    is_deeply(
        \@got,
        [ [234, 345] ],
        'multiple returns from callback',
    );
}

{
    my $d1 = Promise::XS::deferred();

    $d1->resolve(123);
    my $p1 = $d1->promise();

    my $d2 = Promise::XS::deferred();
    $d2->resolve();

    my @w;
    local $SIG{'__WARN__'} = sub { push @w, @_ };

    my @got = _unwrap( $d2->promise()->then( sub { ($p1, 234, 345) } ) );
    is_deeply(
        \@got,
        [ [$p1, 234, 345] ],
        'promise given in multi-return is left alone',
    );

    cmp_deeply(
        \@w,
        [ all(
            re( qr<promise> ),
            re( qr<return> ),
        ) ],
        'warning on extra returns after promise',
    );
}

done_testing;
