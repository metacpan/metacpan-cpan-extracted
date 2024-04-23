use Test2::V0;

use Config;

use Scalar::Type qw(sizeof);

subtest "sizeof(integer)" => sub {
    is(sizeof(1), $Config{ivsize}, "sizeof(int) is correct");
};

subtest "sizeof(number)" => sub {
    is(sizeof(1.2), $Config{nvsize}, "sizeof(float) is correct");
};

subtest "sizeof(whatever)" => sub {
    like
        dies { sizeof() },
        qr{::sizeof requires an argument at t/sizeof.t line},
        "sizeof() requires an argument";
    like
        dies { sizeof("banana") },
        qr{::sizeof: 'banana' isn't numeric: SCALAR},
        "sizeof()'s arg must be plausibly numeric";
};

done_testing;
