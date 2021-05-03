use strict;
use warnings;

use Test::More;

use Scalar::Type qw(is_* type);
use B;
use Capture::Tiny qw(capture_stderr);
use Devel::Peek;

subtest "is_integer" => sub {
    ok(is_integer(1), '1 is an integer');
    ok(is_integer(-1), '-1 is an integer');
    ok(!is_integer("1"), '"1" is not an integer');
    ok(!is_integer(1.0), '1.0 is not an integer');
    ok(!is_integer(1.1), '1.1 is not an integer');

    ok(is_integer(0x12),    '0x12 is an integer');
    ok(!is_integer("0x12"), '"0x12" is not an integer');

    # the IV slot in the SV got filled
    my $foo = "1"; $foo += 0;
    ok(is_integer($foo), '"1" + 0 gets its IV slot filled, is an integer');
};

subtest "is_number" => sub {
    ok(is_number(1), '1 is a number');
    ok(is_number(1.0), '1.0 is a number');
    ok(is_number(1.1), '1.1 is a number');
    ok(!is_number("1"), '"1" is not a number');
    ok(!is_number("1.0"), '"1.0" is not a number');
    ok(is_number(0x12),    '0x12 is a number');
    ok(!is_number("0x12"), '"0x12" is not a number');
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

subtest "type returns the documented values" => sub {
    is(type(1), 'INTEGER', '1 is of type INTEGER');
    is(type(1.0), 'NUMBER', '1.0 is of type NUMBER');
    is(type(1.1), 'NUMBER', '1.1 is of type NUMBER');
    is(type("1"), 'SCALAR', '"1" is of type SCALAR');
    is(type("1.0"), 'SCALAR', '"1.0" is of type SCALAR');
    is(type("1.1"), 'SCALAR', '"1.1" is of type SCALAR');
};

done_testing;
