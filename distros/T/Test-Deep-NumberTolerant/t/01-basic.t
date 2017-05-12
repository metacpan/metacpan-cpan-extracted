use strict;
use warnings;

use Test::Tester 0.108;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Number::Tolerant;
use Test::Deep::NumberTolerant;

ok(
    ( 11 == tolerance(10, plus_or_minus => 2) ),
    'passing vanilla tolerance test',
);

ok(
    ( 13 != tolerance(10, plus_or_minus => 2) ),
    'failing vanilla tolerance test',
);

check_tests(
    sub {
        cmp_deeply(
            { number => 11 },
            { number => within_tolerance(10, plus_or_minus => 2) },
            'passing tolerance test using our wrapper',
        );
    },
    [ +{
        actual_ok => 1,
        ok => 1,
        diag => '',
        name => 'passing tolerance test using our wrapper',
        type => '',
    } ],
    'validation successful',
);

check_tests(
    sub {
        cmp_deeply(
            { number => 15 },
            { number => within_tolerance(10, plus_or_minus => 2) },
            'failing tolerance test using our wrapper',
        );
    },
    [ +{
        actual_ok => 0,
        ok => 0,
        diag => '',
        name => 'failing tolerance test using our wrapper',
        type => '',
        diag => <<EOM,
Checking \$data->{"number"} against 10 +/- 2
   got : failed
expect : no error
EOM
    } ],
    'validation successful',
);

done_testing;
