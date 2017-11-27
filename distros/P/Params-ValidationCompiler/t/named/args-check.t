use strict;
use warnings;

use Test2::V0;
use Test2::Plugin::NoWarnings;

use Params::ValidationCompiler qw( validation_for );

{
    my $sub = validation_for(
        params => {
            foo => 1,
        },
    );

    like(
        dies { $sub->(42) },
        qr/\QExpected a hash or hash reference but a single non-reference argument was passed/,
        'dies when given a single non-ref argument'
    );

    like(
        dies { $sub->( [] ) },
        qr/\QExpected a hash or hash reference but a single ARRAY reference argument was passed/,
        'dies when given a single arrayref argument'
    );

    like(
        dies { $sub->( foo => 42, 'bar' ) },
        qr/\QExpected a hash or hash reference but an odd number of arguments was passed/,
        'dies when given three arguments'
    );

    is(
        dies { $sub->( foo => 42 ) },
        undef,
        'lives when given two arguments'
    );

    is(
        dies { $sub->( { foo => 42 } ) },
        undef,
        'lives when given a single hashref argument'
    );

    like(
        dies { $sub->( bless { foo => 42 }, 'anything' ) },
        qr/Expected a hash or hash reference but a single object argument was passed/,
        'dies when passed a blessed object',
    );

    {
        package OverloadsHash;
        use overload '%{}' => sub { return { foo => 42 } };
    }

    is(
        dies { $sub->( bless [], 'OverloadsHash' ) },
        undef,
        'lives when given a single object that overloads hash dereferencing'
    );
}

done_testing();
