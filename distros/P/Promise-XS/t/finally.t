#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::FailWarnings;

use Promise::XS;

my $def = Promise::XS::deferred();

$def->resolve(234, 567);

my $p = $def->promise();

my ($args, $wantarray);

my $finally = $p->finally( sub {
    $args = [@_];
    $wantarray = wantarray;
} );

is_deeply( $args, [], 'no args given to finally() callback' );
isnt( $wantarray, undef, 'finally() callback is not called in void context' );

my $got;
$finally->then( sub { $got = \@_ } );

is_deeply( $got, [234, 567], 'args to then() after a finally()' );

#----------------------------------------------------------------------

{
    my $def = Promise::XS::deferred();
    $def->resolve(234, 567);

    my @got;
    $def->promise()->finally( sub { return (666, 666) } )->then(
        sub { $got[0] = [@_] },
        sub { $got[1] = [@_] },
    );

    is_deeply(
        \@got => [ [234, 567] ],
        'finally() callback - normal return is ignored',
    );
}

{
    my $def = Promise::XS::deferred();
    $def->resolve(234, 567);

    my @got;
    $def->promise()->finally( sub { die 666 } )->then(
        sub { $got[0] = [@_] },
        sub { $got[1] = [@_] },
    );

    cmp_deeply(
        \@got => [ undef, [ re( qr<\A666> ) ] ],
        'finally() callback throws',
    );
}

{
    my $def = Promise::XS::deferred();
    $def->resolve(234, 567);

    my @got;
    $def->promise()->finally( sub { Promise::XS::resolved(666, 666) } )->then(
        sub { $got[0] = [@_] },
        sub { $got[1] = [@_] },
    );

    is_deeply(
        \@got => [ [234, 567] ],
        'finally() callback returns a resolved promise',
    );
}

{
    my $def = Promise::XS::deferred();
    $def->resolve(234, 567);

    my @got;
    $def->promise()->finally( sub { Promise::XS::rejected(666, 666) } )->then(
        sub { $got[0] = [@_] },
        sub { $got[1] = [@_] },
    );

    is_deeply(
        \@got => [ undef, [666, 666] ],
        'finally() callback returns a rejected promise',
    );
}

{
    my $def = Promise::XS::deferred();
    $def->resolve(234, 567);

    my @w;
    local $SIG{'__WARN__'} = sub { push @w, @_ };

    my @got;
    $def->promise()->finally(
        sub { return (Promise::XS::rejected(666), 'haha'); }
    )->then(
        sub { $got[0] = [@_] },
        sub { $got[1] = [@_] },
    );

    is_deeply(
        \@got => [ [234, 567] ],
        'finally() callback returns rejected promise plus junk',
    ) or diag explain \@got;

    cmp_bag(
        \@w,
        [
            re( qr<666> ),
            all(
                re( qr<return> ),
                re( qr<promise> ),
            ),
        ],
        'warnings for unhandled rejection and junk return',
    ) or diag explain \@w;
}

done_testing;

1;
