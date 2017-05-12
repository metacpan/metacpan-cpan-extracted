use 5.012;
use warnings;
use lib 't/lib';
use PLTest 'full';

subtest 'to_chars_i8',  \&test_integer, \&Panda::Lib::Test::to_chars_i8,                  -128,                 127;
subtest 'to_chars_i16', \&test_integer, \&Panda::Lib::Test::to_chars_i16,               -32768,               32767;
subtest 'to_chars_i32', \&test_integer, \&Panda::Lib::Test::to_chars_i32,          -2147483648,          2147483647;
subtest 'to_chars_i64', \&test_integer, \&Panda::Lib::Test::to_chars_i64, -9223372036854775808, 9223372036854775807;

subtest 'to_chars_u8',  \&test_integer, \&Panda::Lib::Test::to_chars_u8,  0,                  255;
subtest 'to_chars_u16', \&test_integer, \&Panda::Lib::Test::to_chars_u16, 0,                65535;
subtest 'to_chars_u32', \&test_integer, \&Panda::Lib::Test::to_chars_u32, 0,           4294967295;
subtest 'to_chars_u64', \&test_integer, \&Panda::Lib::Test::to_chars_u64, 0, 18446744073709551615;

sub test_integer {
    my ($sub, $min, $max) = @_;

    my ($r, $pos);
    
    is($sub->(12), "12", "positive number");
    is($sub->(0), "0", "zero");
    is($sub->($max), "$max", "max");
    is($sub->(10, 8), "12", "8-base");
    is($sub->(10, 16), "a", "16-base");
    is($sub->(123, 10, 2), undef, "no space");
    
    if ($min < 0) {
        is($sub->(-99), "-99", "negative number");
        is($sub->(-123, 10, 3), undef, "no space");
        is($sub->($min), "$min", "min");
    }

}

done_testing();