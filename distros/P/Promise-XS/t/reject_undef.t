#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::FailWarnings;

use Promise::XS;

my $FILE = __FILE__;

{
    my $deferred = Promise::XS::Deferred::create();

    my @warnings;
    local $SIG{'__WARN__'} = sub { push @warnings, @_ };

    $deferred->reject();

    cmp_deeply(
        \@warnings,
        [
            all(
                re( qr<Promise::XS::Deferred> ),
                re( qr<reject\(> ),
                re( qr<\Q$FILE\E> ),
            ),
        ],
        'empty reject(): warning as expected',
    );

    $deferred->promise()->catch(sub {});
}

{
    for my $count ( 1 .. 2 ) {
        my @warnings;
        local $SIG{'__WARN__'} = sub { push @warnings, @_ };

        my $deferred = Promise::XS::Deferred::create();

        $deferred->reject((undef) x $count);

        cmp_deeply(
            \@warnings,
            [
                all(
                    re( qr<Promise::XS::Deferred> ),
                    re( qr<reject\(> ),
                    re( qr<uninitialized>i ),
                    re( qr<$count> ),
                    re( qr<\Q$FILE\E> ),
                ),
            ],
            "reject(undef x $count): warning as expected",
        );

        $deferred->promise()->catch(sub {});
    }
}

{
    my @warnings;
    local $SIG{'__WARN__'} = sub { push @warnings, @_ };

    my $p = Promise::XS::rejected();

    cmp_deeply(
        \@warnings,
        [
            all(
                re( qr<Promise::XS> ),
                re( qr<rejected> ),
                re( qr<\Q$FILE\E> ),
            ),
        ],
        'rejected(): warning as expected',
    );

    $p->catch(sub {});
}

{
    for my $count ( 1 .. 2 ) {
        my @warnings;
        local $SIG{'__WARN__'} = sub { push @warnings, @_ };

        my $p = Promise::XS::rejected((undef) x $count);

        cmp_deeply(
            \@warnings,
            [
                all(
                    re( qr<Promise::XS::Deferred> ),
                    re( qr<rejected> ),
                    re( qr<uninitialized>i ),
                    re( qr<$count> ),
                    re( qr<\Q$FILE\E> ),
                ),
            ],
            "rejected(undef x $count): warning as expected",
        );

        $p->catch(sub {});
    }
}

done_testing;

1;
