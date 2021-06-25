use strict;
use warnings;
no warnings 'void';

use Test::More;
use Test::Exception;

use Scalar::Type qw(is_* type);
use B;
use Capture::Tiny qw(capture_stderr);
use Devel::Peek;

select(STDERR); $| = 1;
select(STDOUT); $| = 1;

subtest "is_integer" => sub {
    ok(is_integer(0), '0 is an integer');
    ok(is_integer(-0), '-0 is an integer');
    ok(is_integer(1), '1 is an integer');
    ok(is_integer(-1), '-1 is an integer');
    ok(!is_integer("1"), '"1" is not an integer');
    ok(!is_integer(1.0), '1.0 is not an integer');
    ok(!is_integer(1.1), '1.1 is not an integer');
    ok(!is_integer(0.0), '0.0 is not an integer');

    ok(is_integer(0x12),    '0x12 is an integer');
    ok(!is_integer("0x12"), '"0x12" is not an integer');

    # the IV slot in the SV got filled
    my $foo = "1"; $foo += 0;
    ok(is_integer($foo), '"1" + 0 gets its IV slot filled, is an integer');

    undef $foo;
    ok(!is_integer($foo), "after undef-ing, it's no longer an integer");
};

subtest "is_number" => sub {
    ok(is_number(1), '1 is a number');
    ok(is_number(1.0), '1.0 is a number');
    ok(is_number(1.1), '1.1 is a number');
    ok(is_number(0.0), '0.0 is a number');
    ok(!is_number("1"), '"1" is not a number');
    ok(!is_number("1.0"), '"1.0" is not a number');
    ok(!is_number("0x12"), '"0x12" is not a number');
    my $foo = 0x12;
    ok(is_number($foo), '0x12 is a number');

    my $bar = "12.10";
    ok(!is_number($bar), '"12.10" is not a number');
    $bar + 0;
    ok(!is_number($bar), '"12.10" is still not a number after being used in a numeric context');
    note(capture_stderr { Dump($bar) });
};

subtest "integers written as exponents are weird" => sub {
    # toke.c just assumes that if there's an e it must be a float. At some point it
    # would be nice to correct that, but not at the cost of "correcting" 1.0 into an int.
    # these tests are mostly just placeholders for when we do that.
    subtest "32 bit-friendly exp ints" => sub {
        ok(!is_integer(1e2),  '1e2 is not an integer (but it oughta be!)');
        ok(is_number(1e2),    '... but it is a number');
        ok(!is_integer(-1e2), '-1e2 is not an integer (but it oughta be!)');
        ok(is_number(-1e2),   '... but it is a number');
    
        my $foo = 1e2; $foo += 0;
        ok(is_integer($foo), '1e2 + 0 is an integer');
        $foo = 0; $foo += 1e2;
        ok(is_integer($foo), '0 + 1e2 is an integer');
        $foo = -1e2; $foo += 0;
        ok(is_integer($foo), '-1e2 + 0 is an integer');
    };
    subtest "32 bit-unfriendly, 64 bit-friendly exp ints" => sub {
        ok(!is_integer(1e10),  '1e10 is not an integer (but it oughta be on 64 bit machines!)');
        ok(is_number(1e10),    '... but it is a number');
        ok(!is_integer(-1e10), '-1e10 is not an integer (but it oughta be on 64 bit machines!)');
        ok(is_number(-1e10),   '... but it is a number');
    
        my $foo = 1e10; $foo += 0;
        if(~0 < $foo) { # 32 bit system
            ok(!is_integer($foo), '1e10 + 0 is not an integer because your computer is pathetic');
            $foo = 0; $foo += 1e10;
            ok(!is_integer($foo), '0 + 1e10 is not an integer because your computer is pathetic');
            $foo = -1e10; $foo += 0;
            ok(!is_integer($foo), '-1e10 + 0 is not an integer because your computer is pathetic');
        } else {
            ok(is_integer($foo), '1e10 + 0 is an integer');
            $foo = 0; $foo += 1e10;
            ok(is_integer($foo), '0 + 1e10 is an integer');
            $foo = -1e10; $foo += 0;
            ok(is_integer($foo), '-1e10 + 0 is an integer');
        }
    };
    subtest "64 bit-unfriendly exp ints" => sub {
        ok(!is_integer(1e20),  '1e20 is not an integer');
        ok(is_number(1e20),    '... but it is a number');
        ok(!is_integer(-1e20), '-1e20 is not an integer');
        ok(is_number(-1e20),   '... but it is a number');
    
        my $foo = 1e20; $foo += 0;
        ok(!is_integer($foo), '1e20 + 0 is not an integer');
        ok(is_number($foo),   '... but it is a number');
        $foo = 0; $foo += 1e20;
        ok(!is_integer($foo), '0 + 1e20 is not an integer');
        ok(is_number($foo),   '... but it is a number');
        $foo = -1e20; $foo += 0;
        ok(!is_integer($foo), '-1e20 + 0 is not an integer');
        ok(is_number($foo),   '... but it is a number');
    };
};

subtest "string subsequently used as an int or float" => sub {
    subtest "'007'" => sub {
        my $foo = '007';
        $foo < 8;
        ok($foo eq '007', "after being treated as an int it still has its original value");
        is(type($foo), 'SCALAR', "and it's not become an integer as far as we're concerned");
        note(capture_stderr { Dump($foo) });
    };

    subtest "'007.5'" => sub {
        my $foo = "007.5";
        $foo + 0.5;
        ok($foo eq '007.5', "after being treated as a float it still has its original value");
        is(type($foo), 'SCALAR', "and it's not become a float as far as we're concerned");
        note(capture_stderr { Dump($foo) });
    };

    subtest "'7'" => sub {
        my $foo = '7';
        $foo < 8;
        is(type($foo), 'INTEGER', "this does become an int after a numeric operation");
        note(capture_stderr { Dump($foo) });
    };

    subtest "'7.5'" => sub {
        my $foo = '7.5';
        $foo < 8;
        is(type($foo), 'NUMBER', "this does become a float after a numeric operation");
        note(capture_stderr { Dump($foo) });
    };

    subtest "'[MAXINT]'" => sub {
        my $foo = ''.~0;
        $foo + 0;
        is(type($foo), 'INTEGER', "this becomes an integer after a numeric operation, even though the value is a UV (unsigned int), not an IV");
        note(capture_stderr { Dump($foo) });
    };
};

subtest "int subsequently used as a float" => sub {
    my $foo = 7;
    $foo + 0.5;
    ok($foo == 7, "after being treated as a float the variable still has its original value 7");
    ok(is_integer($foo), "7 is still an integer after being numerically compared to a float");
};

subtest "are we checking the flags, not just the contents of the IV/NV slots?" => sub {
    my $foo = 42;
    ok(is_integer($foo), 'variable containing 42 is an integer');
    ok(is_number($foo),  "... and so of course it's also a number");
    $foo = 'forty two';
    ok(!is_integer($foo), 'variable is no longer an int after a string was assigned to it');
    ok(!is_number($foo),  '... no longer a number either');
    note("still says 42 in the IV slot, but IOK isn't set");
    note(capture_stderr { Dump($foo) });

    $foo = 3.14;
    ok(!is_integer($foo), 'variable containing 3.14 is not an integer');
    ok(is_number($foo),   '... but it is a number');
    $foo = 'delicious pie';
    ok(!is_integer($foo), 'still not an integer after value changed to "delicious pie"');
    ok(!is_number($foo),  '... no longer a number either');
};

subtest "references" => sub {
    ok(!is_integer(\1), '\\1 is not an integer');
    is(type(\1), 'REF_TO_SCALAR', '\\1 is of type REF_TO_SCALAR');
    is(type(\"1"), 'REF_TO_SCALAR', '\\"1" is of type REF_TO_SCALAR');
    is(type({}), 'REF_TO_HASH', '{} is of type REF_TO_HASH');
    is(type(B::svref_2object(\1)), 'B::IV', 'blessed scalars return their class');
};

subtest "type returns the documented values for non-reference types" => sub {
    is(type(1), 'INTEGER', '1 is of type INTEGER');
    is(type(1.0), 'NUMBER', '1.0 is of type NUMBER');
    is(type(1.1), 'NUMBER', '1.1 is of type NUMBER');
    is(type("1"), 'SCALAR', '"1" is of type SCALAR');
    is(type("1.0"), 'SCALAR', '"1.0" is of type SCALAR');
    is(type("1.1"), 'SCALAR', '"1.1" is of type SCALAR');
    is(type(undef), 'UNDEF', 'undef is of type UNDEF');
};

throws_ok(
    sub { type() },
    qr{::type requires an argument at t/all.t line},
    "type() requires an argument"
);
throws_ok(
    sub { is_number() },
    qr{::is_number requires an argument at t/all.t line},
    "is_number() requires an argument"
);
throws_ok(
    sub { is_integer() },
    qr{::is_integer requires an argument at t/all.t line},
    "is_integer() requires an argument"
);

done_testing;
