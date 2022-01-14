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
    throws_ok(
        sub { is_bool(1 == 1) },
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
}

done_testing;
