BEGIN {
    $ENV{PV_TEST_PERL} = 1;
}

use strict;
use warnings;
use Test::More;

use Params::Validate qw( validate SCALAR );

{
    my $p = { foo => 1 };

    val($p);

    is_deeply(
        $p, { foo => 1 },
        'validate does not alter hashref passed to val'
    );

    val2($p);

    is_deeply(
        $p, { foo => 1 },
        'validate does not alter hashref passed to val, even with defaults being supplied'
    );
}

sub val {
    validate(
        @_, {
            foo => { optional => 1 },
            bar => { optional => 1 },
            baz => { optional => 1 },
            buz => { optional => 1 },
        },
    );

    return;
}

sub val2 {
    validate(
        @_, {
            foo => { optional => 1 },
            bar => { default  => 42 },
            baz => { optional => 1 },
            buz => { optional => 1 },
        },
    );

    return;
}

done_testing();

