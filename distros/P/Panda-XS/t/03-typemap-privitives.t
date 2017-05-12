use 5.012;
use warnings;
use lib 't/lib';
use PXSTest 'full';

# signed integer
is(Panda::XS::Test::i8(10), 10);
is(Panda::XS::Test::i8(-100), -100);
is(Panda::XS::Test::i8(128), -128);
is(Panda::XS::Test::i16(30000), 30000);
is(Panda::XS::Test::i16(-10000), -10000);
is(Panda::XS::Test::i16(33000), -32536);
is(Panda::XS::Test::i32(2000000000), 2000000000);
is(Panda::XS::Test::i32(-100000000), -100000000);
is(Panda::XS::Test::i32(3000000000), -1294967296);
is(Panda::XS::Test::i64(9223372036854775807), 9223372036854775807);
is(Panda::XS::Test::i64(-5223372036854775807), -5223372036854775807);
is(Panda::XS::Test::i64(9223372036854775808), -9223372036854775808);

# unsigned integers
is(Panda::XS::Test::u8(10), 10);
is(Panda::XS::Test::u8(255), 255);
is(Panda::XS::Test::u8(256), 0);
is(Panda::XS::Test::u8(-10), 246);
is(Panda::XS::Test::u16(10000), 10000);
is(Panda::XS::Test::u16(65535), 65535);
is(Panda::XS::Test::u16(65536), 0);
is(Panda::XS::Test::u16(-10), 65526);
is(Panda::XS::Test::u32(1000000000), 1000000000);
is(Panda::XS::Test::u32(4294967295), 4294967295);
is(Panda::XS::Test::u32(4294967296), 0);
is(Panda::XS::Test::u32(-10), 4294967286);
is(Panda::XS::Test::u64(1000000000000000), 1000000000000000);
is(Panda::XS::Test::u64(18446744073709551615), 18446744073709551615);
is(Panda::XS::Test::u64(-10), 18446744073709551606);

# time_t
if ($Config{ivsize} == 8) {
    is(Panda::XS::Test::time_t(9223372036854775807), 9223372036854775807);
    is(Panda::XS::Test::time_t(9223372036854775808), -9223372036854775808);
} else {
    is(Panda::XS::Test::time_t(2000000000), 2000000000);
    is(Panda::XS::Test::time_t(-100000000), -100000000);
    is(Panda::XS::Test::time_t(3000000000), -1294967296);
}

done_testing();
