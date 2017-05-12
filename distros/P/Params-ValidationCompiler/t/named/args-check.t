use strict;
use warnings;

use Test2::Bundle::Extended;
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
        qr/\QExpected a hash or hash reference but got a single non-reference argument/,
        'dies when given a single non-ref argument'
    );

    like(
        dies { $sub->( [] ) },
        qr/\QExpected a hash or hash reference but got a single ARRAY reference argument/,
        'dies when given a single arrayref argument'
    );

    like(
        dies { $sub->( foo => 42, 'bar' ) },
        qr/\QExpected a hash or hash reference but got an odd number of arguments/,
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
        qr/Expected a hash or hash reference but got a single object argument/,
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
