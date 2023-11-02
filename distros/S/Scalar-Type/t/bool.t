use strict;
use warnings;

use Test::More;
use Test::Exception;

use Config;

use Scalar::Type qw(:all);

if(Scalar::Type::bool_supported) {
    is(
        type(1 == 1),
        'BOOL',
        'type(1 == 1) is BOOL'
    );
    is(
        type(1 == 0),
        'BOOL',
        'type(1 == 0) is BOOL'
    );
    ok(is_bool(1 == 1), 'is_bool says yes for (1 == 1)');
    ok(is_bool(1 == 0), 'is_bool says yes for (1 == 0)');
    ok(!is_bool(1),     'but it says no for plain old 1  (otherwise indistinguishable from (1 == 1))');
    ok(!is_bool(''),    "and it says no for plain old '' (otherwise indistinguishable from (1 == 0))");
} else {
    # the :all above only included is_bool if bool_supported so we need to use the full name here
    throws_ok(
        sub { Scalar::Type::is_bool(1 == 1) },
        qr/::is_bool not supported on your perl/,
        "is_bool carks it on Ye Olde Perle $]"
    );
    is(
        type(1 == 1),
        'INTEGER',
        'type(1 == 1) is INTEGER'
    );
    is(
        type(1 == 0),
        'SCALAR',
        'type(1 == 0) is SCALAR'
    );

    # finally, test that we can't explicitly import is_bool on Ye Olde Perle
    throws_ok(
        sub { Scalar::Type->import('is_bool') },
        qr/is_bool/,
        "can't import is_bool on Ye Olde Perle $]"
    );
}

done_testing;
