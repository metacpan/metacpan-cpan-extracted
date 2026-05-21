#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Promise::XS;

my $p1 = Promise::XS::resolved(2, 3);
my $p2 = Promise::XS::resolved(4);

$p1->all($p1, $p2)->then( sub {
    my (@got)  = @_;

    is_deeply(
        \@got,
        [
            [ 2, 3 ],
            [ 4 ],
        ],
        'all() works as a method of the promise object',
    );
} );

$p1->all($p1, 'bar')->then( sub {
    my (@got)  = @_;

    is_deeply(
        \@got,
        [
            [ 2, 3 ],
            [ 'bar' ],
        ],
        'all() works as a method of the promise object and string',
    );
} );


Promise::XS::Promise->all($p1, $p2)->then( sub {
    my (@got)  = @_;

    is_deeply(
        \@got,
        [
            [ 2, 3 ],
            [ 4 ],
        ],
        'all() works as a class method',
    );
} );

#----------------------------------------------------------------------
# all() - empty input resolves immediately with empty list

{
    my @got;
    my $called = 0;
    Promise::XS::Promise->all()->then( sub {
        @got = @_;
        $called = 1;
    });

    is( $called,  1,  'all() with no args calls then-handler synchronously' );
    is_deeply( \@got, [], 'all() with no args resolves with empty list' );
}

#----------------------------------------------------------------------
# all() - all-scalar inputs (no promises)

{
    my @got;
    Promise::XS::Promise->all('x', 'y', 'z')->then( sub { @got = @_ });

    is_deeply(
        \@got,
        [ ['x'], ['y'], ['z'] ],
        'all() with only plain scalars resolves correctly',
    );
}

#----------------------------------------------------------------------
# all() - order preservation: second resolves before first

{
    my $d1 = Promise::XS::deferred();
    my $d2 = Promise::XS::deferred();

    my @got;
    Promise::XS::Promise->all($d1->promise(), $d2->promise())->then( sub { @got = @_ });

    $d2->resolve('second');
    $d1->resolve('first');

    is_deeply(
        \@got,
        [ ['first'], ['second'] ],
        'all() preserves input order regardless of resolution order',
    );
}

#----------------------------------------------------------------------
# all() - rejection propagates with correct value

{
    my $d1 = Promise::XS::deferred();
    my $d2 = Promise::XS::deferred();

    my $reason;
    Promise::XS::Promise->all($d1->promise(), $d2->promise())->catch( sub { $reason = shift });

    $d1->reject('boom');
    $d2->resolve('ok');

    is( $reason, 'boom', 'all() rejection propagates the correct reason' );
}

#----------------------------------------------------------------------
# all() - first rejection wins when multiple promises reject

{
    my $d1 = Promise::XS::deferred();
    my $d2 = Promise::XS::deferred();

    my $reason;
    Promise::XS::Promise->all($d1->promise(), $d2->promise())->catch( sub { $reason = shift });

    $d1->reject('first');
    $d2->reject('second');

    is( $reason, 'first', 'all() uses the first rejection reason' );
}

#----------------------------------------------------------------------
# all() - pre-rejected promise rejects immediately

{
    my $rejected = Promise::XS::rejected('pre-rejected');
    my $d        = Promise::XS::deferred();

    my $reason;
    Promise::XS::Promise->all($rejected, $d->promise())->catch( sub { $reason = shift });

    is( $reason, 'pre-rejected', 'all() rejects immediately when given an already-rejected promise' );
}

#----------------------------------------------------------------------
# all() - single promise

{
    my $d = Promise::XS::deferred();

    my @got;
    Promise::XS::Promise->all($d->promise())->then( sub { @got = @_ });

    $d->resolve('solo', 'multi');

    is_deeply( \@got, [ ['solo', 'multi'] ], 'all() with single promise wraps multi-value resolve' );
}

#----------------------------------------------------------------------

$p1->race($p1, $p2)->then( sub {
    my (@got)  = @_;

    is_deeply(
        \@got,
        [ 2, 3 ],
        'race() works as a method of the promise object',
    );
} );

Promise::XS::Promise->race($p1, $p2)->then( sub {
    my (@got)  = @_;

    is_deeply(
        \@got,
        [ 2, 3 ],
        'race() works as a class method',
    );
} );

done_testing();

1;
