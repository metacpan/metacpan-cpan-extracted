use strict;
use warnings;
use utf8;
use Test::More;
use Module::Spy;

use FindBin;
use lib "$FindBin::Bin/lib";
use X;

subtest 'calls_any', sub {
    my $spy = spy_on('X', 'y');
    ok !$spy->calls_any;

    X->y;
    ok $spy->calls_any;
};

subtest 'calls_count', sub {
    my $spy = spy_on('X', 'y');
    is $spy->calls_count, 0;

    X->y;
    is $spy->calls_count, 1;

    X->y;

    is $spy->calls_count, 2;
};

subtest 'calls_all', sub {
    my $spy = spy_on('X', 'y');
    X->y(123);
    X->y(456, 'baz');
    is_deeply scalar($spy->calls_all), [
        ['X', 123],
        ['X', 456, 'baz'],
    ];
};

subtest 'calls_most_recent', sub {
    my $spy = spy_on('X', 'y');
    X->y(123);
    X->y(456, 'baz');
    is_deeply scalar($spy->calls_most_recent), [
        'X', 456, 'baz',
    ];
};

subtest 'calls_first', sub {
    my $spy = spy_on('X', 'y');
    is scalar($spy->calls_first), undef;

    X->y(123);
    X->y(456, 'baz');
    is_deeply scalar($spy->calls_first), [
        'X', 123,
    ];
};

subtest 'calls_reset', sub {
    my $spy = spy_on('X', 'y');

    ok !$spy->calls_any;
    X->y();
    ok $spy->calls_any;
    $spy->calls_reset;

    ok !$spy->calls_any;
};

done_testing;

