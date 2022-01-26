use strict;
use warnings;
use Test::More;
use Sodium::FFI qw(
    sodium_add sodium_bin2hex sodium_compare sodium_hex2bin sodium_increment
    sodium_library_minimal sodium_pad sodium_sub sodium_unpad sodium_bin2base64
    sodium_base642bin sodium_memcmp sodium_is_zero
);

# diag("SIZE_MAX is: " . Sodium::FFI::SIZE_MAX);

# hex2bin
is(sodium_hex2bin("414243", ignore => ': '), "ABC", "hex2bin: ignore ': ': 414243 = ABC");
is(sodium_hex2bin("41 42 43", ignore => ': '), "ABC", "hex2bin: ignore ': ': 41 42 43 = ABC");
is(sodium_hex2bin("41:4243", ignore => ': '), "ABC", "hex2bin: ignore ': ': 41:4243 = ABC");

is(sodium_hex2bin("414243", max_len => 2), "AB", "hex2bin: maxlen 2: 414243 = AB");
is(sodium_hex2bin("41:42:43", max_len => 2, ignore => ':'), "AB", "hex2bin: maxlen 2, ignore ':': 414243 = AB");
is(sodium_hex2bin("41 42 43", max_len => 1), "A", "hex2bin: maxlen 2: 41 42 43 = A");

my $hex = "Cafe : 6942";
my $bin = sodium_hex2bin($hex, max_len => 4, ignore => ': ');
my $readable = '';
$readable .= sprintf('%02x', ord($_)) for split //, $bin;
is($readable, 'cafe6942', "hex2bin: maxlen 4, ignore ': ': readable; Cafe : 6942 = cafe6942");

# hex2bin - bin2hex round trip
{
    my $hex = '414243';
    my $bin = sodium_hex2bin($hex);
    is($bin, 'ABC', 'hex2bin: first leg ok');
    my $new_hex = sodium_bin2hex($bin);
    is($new_hex, $hex, 'bin2hex: second leg ok. YAY');
}

# sodium_add, sodium_increment
{
    my $left = "\xFF\xFF\x80\x01\x02\x03\x04\x05\x06\x07\x08";
    is(sodium_bin2hex($left), 'ffff800102030405060708', 'bin2hex: Got the right answer');
    $left = sodium_increment($left);
    is(sodium_bin2hex($left), '0000810102030405060708', 'increment, bin2hex: Got the right answer');
    my $right = "\x01\x02\x03\x04\x05\x06\x07\x08\xFA\xFB\xFC";
    $left = sodium_add($left, $right);
    is(sodium_bin2hex($left), '0102840507090b0d000305', 'add, bin2hex: Got the right answer');
    my $foo = 111;
    is(sodium_add($foo, "111"), "bbb", 'add: non-lvalue test');
    is($foo, 111, 'left side was unaltered');
    $foo = sodium_add($foo, 111);
    is($foo, 'bbb', 'sodium_add: right value');
    $foo = "\x01";
    is(sodium_increment($foo), "\x02", 'sodium_increment: 01 -> 02');
}

# sodium_sub
SKIP: {
    skip('sodium_sub implemented in libsodium >= v1.0.17', 1) unless Sodium::FFI::_version_or_better(1, 0, 17);
    my $x = "\x02";
    my $y = "\x01";
    my $z = sodium_sub($x, $y);
    is($z, "\x01", 'sodium_sub: got the right answer');
};

# sodium_compare
SKIP: {
    skip('sodium_compare implemented in libsodium >= v1.0.4', 3) unless Sodium::FFI::_version_or_better(1, 0, 4);
    my $v1 = "\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0B\x0C\x0D\x0E\x0F\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1A\x1B\x1C\x1D\x1E\x1F";
    my $v2 = "\x02\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0B\x0C\x0D\x0E\x0F\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1A\x1B\x1C\x1D\x1E\x1F";
    is(sodium_compare($v1, $v2), -1, 'sodium_compare: v1 < v2');
    $v1 = sodium_increment($v1);
    is(sodium_compare($v1, $v2), 0, 'sodium_compare: increment sets v1 == v2');
    $v1 = sodium_increment($v1);
    is(sodium_compare($v1, $v2), 1, 'sodium_compare: increment sets v1 > v2');
};

# sodium_pad
SKIP: {
    skip('sodium_pad implemented in libsodium >= v1.0.14', 2) unless Sodium::FFI::_version_or_better(1, 0, 14);
    my $str = 'xyz';
    my $str_padded = sodium_pad($str, 16);
    is(sodium_bin2hex($str_padded), '78797a80000000000000000000000000', 'sodium_pad: looks right');
    is(sodium_unpad($str_padded, 16), $str, 'sodium_unpad: round trip is good');
};

# sodium_library_minimal
SKIP: {
    skip('sodium_library_minimal implemented in libsodium >= v1.0.12', 1) unless Sodium::FFI::_version_or_better(1, 0, 12);
    is(sodium_library_minimal, Sodium::FFI::SODIUM_LIBRARY_MINIMAL, 'sodium_library_minimal: Got the right answer');
};

# sodium_bin2base64
{
    # no variant defaults to sodium_base64_VARIANT_ORIGINAL
    is(sodium_bin2base64("\377\000"), '/wA=', 'bin2base64: no variant - \377\000');
    is(sodium_bin2base64("\000"), 'AA==', 'bin2base64: no variant - \000');
    is(sodium_bin2base64('aaa'), 'YWFh', 'bin2base64: no variant - aaa');
    # explicit variant
    my $variant = Sodium::FFI::sodium_base64_VARIANT_ORIGINAL;
    is(sodium_bin2base64("\377\000", $variant), '/wA=', 'bin2base64: VARIANT_ORIGINAL - \377\000');
    is(sodium_bin2base64("\000", $variant), 'AA==', 'bin2base64: VARIANT_ORIGINAL - \000');
    is(sodium_bin2base64('aaa', $variant), 'YWFh', 'bin2base64: VARIANT_ORIGINAL - aaa');
    $variant = Sodium::FFI::sodium_base64_VARIANT_ORIGINAL_NO_PADDING;
    is(sodium_bin2base64("\377\000", $variant), '/wA', 'bin2base64: VARIANT_ORIGINAL_NO_PADDING - \377\000');
    is(sodium_bin2base64("\000", $variant), 'AA', 'bin2base64: VARIANT_ORIGINAL_NO_PADDING - \000');
    is(sodium_bin2base64('aaa', $variant), 'YWFh', 'bin2base64: VARIANT_ORIGINAL_NO_PADDING - aaa');
    $variant = Sodium::FFI::sodium_base64_VARIANT_URLSAFE;
    is(sodium_bin2base64("\377\000", $variant), '_wA=', 'bin2base64: VARIANT_URLSAFE - \377\000');
    is(sodium_bin2base64("\000", $variant), 'AA==', 'bin2base64: VARIANT_ORIGINAL - \000');
    is(sodium_bin2base64('aaa', $variant), 'YWFh', 'bin2base64: VARIANT_URLSAFE - aaa');
    $variant = Sodium::FFI::sodium_base64_VARIANT_URLSAFE_NO_PADDING;
    is(sodium_bin2base64("\377\000", $variant), '_wA', 'bin2base64: VARIANT_URLSAFE_NO_PADDING - \377\000');
    is(sodium_bin2base64("\000", $variant), 'AA', 'bin2base64: VARIANT_URLSAFE_NO_PADDING - \000');
    is(sodium_bin2base64('aaa', $variant), 'YWFh', 'bin2base64: VARIANT_URLSAFE_NO_PADDING - aaa');
}

# sodium_base642bin
{
    # no variant defaults to sodium_base64_VARIANT_ORIGINAL
    is(sodium_base642bin('/wA='), "\377\000", 'base642bin: no variant - /wA=');
    is(sodium_base642bin('AA=='), "\000", 'base642bin: no variant - AA==');
    is(sodium_base642bin('YWFh'), 'aaa', 'base642bin: no variant - YWFh');
    # explicit variant
    my $variant = Sodium::FFI::sodium_base64_VARIANT_ORIGINAL;
    is(sodium_base642bin('/wA=', $variant), "\377\000", 'base642bin: VARIANT_ORIGINAL - /wA=');
    is(sodium_base642bin('AA==', $variant), "\000", 'base642bin: VARIANT_ORIGINAL - AA==');
    is(sodium_base642bin('YWFh', $variant), 'aaa', 'base642bin: VARIANT_ORIGINAL - YWFh');
    $variant = Sodium::FFI::sodium_base64_VARIANT_ORIGINAL_NO_PADDING;
    is(sodium_base642bin('/wA', $variant), "\377\000", 'base642bin: VARIANT_ORIGINAL_NO_PADDING - /wA');
    is(sodium_base642bin('AA', $variant), "\000", 'base642bin: VARIANT_ORIGINAL_NO_PADDING - AA');
    is(sodium_base642bin('YWFh', $variant), 'aaa', 'base642bin: VARIANT_ORIGINAL_NO_PADDING - YWFh');
    $variant = Sodium::FFI::sodium_base64_VARIANT_URLSAFE;
    is(sodium_base642bin('_wA=', $variant), "\377\000", 'base642bin: VARIANT_URLSAFE - _wA=');
    is(sodium_base642bin('AA==', $variant), "\000", 'base642bin: VARIANT_ORIGINAL - AA==');
    is(sodium_base642bin('YWFh', $variant), 'aaa', 'base642bin: VARIANT_URLSAFE - YWFh');
    $variant = Sodium::FFI::sodium_base64_VARIANT_URLSAFE_NO_PADDING;
    is(sodium_base642bin('_wA', $variant), "\377\000", 'base642bin: VARIANT_URLSAFE_NO_PADDING - _wA');
    is(sodium_base642bin('AA', $variant), "\000", 'base642bin: VARIANT_URLSAFE_NO_PADDING - AA');
    is(sodium_base642bin('YWFh', $variant), 'aaa', 'base642bin: VARIANT_URLSAFE_NO_PADDING - YWFh');
}

# sodium_memcmp
{
    is(sodium_memcmp("abc", "abc"), 0, 'memcmp: strings equal');
    is(sodium_memcmp("abcdefg", "abc", 3), 0, 'memcmp: strings equal for first 3');
    is(sodium_memcmp("abcdefg", "abc", 4), -1, 'memcmp: strings not equal for first 4');
}

# sodium_is_zero
{
    is(sodium_is_zero("abc"), 0, 'is_zero: not zeros');
    is(sodium_is_zero(""), 1, 'is_zero: empty string');
    is(sodium_is_zero("\0"), 1, 'is_zero: null string zero');
    is(sodium_is_zero("\0\0\0"), 1, 'is_zero: longer null string zero');
    is(sodium_is_zero("000"), 0, 'is_zero: string of zeros not zero');
    is(sodium_is_zero("\x00\x00"), 1, 'is_zero: binary string of zeros zero');
    is(sodium_is_zero("\x00\x01"), 0, 'is_zero: binary string 01 not zero');
    is(sodium_is_zero("\x00\x01", 1), 1, 'is_zero: binary string 01 checking length 1 zero');
    is(sodium_is_zero(0), 0, 'is_zero: number zero not zero');
    is(sodium_is_zero(0, 0), 1, 'is_zero: setting length to check at zero is zero');
}

done_testing;
