use strict;
use warnings;

use Test::Needs 'MooseX::Types::Moose';
use Test::Tester 0.108;
use MooseX::Types::Moose 'Str';

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;

use Test::Deep::Type;

my @results = check_tests(
    sub {
        cmp_deeply(
            { message => 'ack I am slain' },
            { message => is_type(Str) },
            'message is a string',
        );
        cmp_deeply(
            { message => { foo => 1 } },
            { message => is_type(Str) },
            'message is a string',
        );
    },
    [
        {
            actual_ok => 1,
            ok => 1,
            diag => '',
            name => 'message is a string',
            type => '',
        },
        {
            actual_ok => 0,
            ok => 0,
            name => 'message is a string',
            type => '',
            # see diag check below
        },
    ],
    'success and failure with a MooseX::Types type',
);

# we don't know if Devel::PartialDump is installed, which changes how the
# value is dumped
like(
    $results[-1]->{diag},
    qr/\A^Validating \$data->\{"message"\} as a Str type$
^   got : Validation failed for 'Str' with value [^\n]+$
^expect : no error$/ms,
    'diag failure message',
);

done_testing;
