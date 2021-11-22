use strict;
use warnings;

use Test::More;
use Test::Exception;

use Config;

use Scalar::Type qw(sizeof);

subtest "sizeof(integer)" => sub {
    is(sizeof(1), $Config{ivsize}, "sizeof(int) is correct");
};

subtest "sizeof(number)" => sub {
    is(sizeof(1.2), $Config{nvsize}, "sizeof(float) is correct");
};

subtest "sizeof(whatever)" => sub {
    throws_ok(
        sub { sizeof() },
        qr{::sizeof requires an argument at t/sizeof.t line},
        "sizeof() requires an argument"
    );
    throws_ok(
        sub { sizeof("banana") },
        qr{::sizeof: 'banana' isn't numeric: SCALAR},
        "sizeof()'s arg must be plausibly numeric"
    );
};

done_testing;
