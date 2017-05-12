use strict;
use warnings;

use Test::Tester 0.108;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

check_tests(
    sub {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        do './examples/demo.t' or die $@;
    },
    [
        {
            actual_ok => 1,
            ok => 1,
            diag => '',
            name => 'hi validates as a TypeHi',
            type => '',
        },
        {
            actual_ok => 0,
            ok => 0,
            name => 'hello validates as a TypeHi',
            type => '',
            diag => <<EOM,
Validating \$data->{"greeting"} as a TypeHi type
   got : 'hello' is not a 'hi'
expect : no error
EOM
        },
    ],
    'examples perform as advertised',
);

done_testing;
