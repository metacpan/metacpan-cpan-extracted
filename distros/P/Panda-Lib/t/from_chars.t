use 5.012;
use warnings;
use lib 't/lib';
use PLTest 'full';

subtest 'from_chars_i8',  \&test_integer, \&Panda::Lib::Test::from_chars_i8,                  -128,                 127,                 "-129",                 "128";
subtest 'from_chars_i16', \&test_integer, \&Panda::Lib::Test::from_chars_i16,               -32768,               32767,               "-32769",               "32768";
subtest 'from_chars_i32', \&test_integer, \&Panda::Lib::Test::from_chars_i32,          -2147483648,          2147483647,          "-2147483649",          "2147483648";
subtest 'from_chars_i64', \&test_integer, \&Panda::Lib::Test::from_chars_i64, -9223372036854775808, 9223372036854775807, "-9223372036854775809", "9223372036854775808";

subtest 'from_chars_u8',  \&test_integer, \&Panda::Lib::Test::from_chars_u8,  0,                  255, undef,                  "256";
subtest 'from_chars_u16', \&test_integer, \&Panda::Lib::Test::from_chars_u16, 0,                65535, undef,                "65536";
subtest 'from_chars_u32', \&test_integer, \&Panda::Lib::Test::from_chars_u32, 0,           4294967295, undef,           "4294967296";
subtest 'from_chars_u64', \&test_integer, \&Panda::Lib::Test::from_chars_u64, 0, 18446744073709551615, undef, "18446744073709551616";

sub test_integer {
    my ($sub, $min, $max, $under_min, $above_max) = @_;

    my ($r, $pos);
    
    $r = $sub->("12", $pos);
    cmp_deeply([$r,$pos], [12,2], "just number");

    $r = $sub->("+55", $pos);
    cmp_deeply([$r,$pos], [undef,0], "+ sign not supported");

    $r = $sub->("-65", $pos);
    cmp_deeply([$r,$pos], [$min < 0 ? (-65, 3) : (undef, 0)], "negative number");
    
    $r = $sub->("14abc", $pos);
    cmp_deeply([$r,$pos], [14,2], "junk after number");
    
    $r = $sub->("     32epta", $pos);
    cmp_deeply([$r,$pos], [32,7], "spaces before number");
    
    $r = $sub->(" 65.3", $pos);
    cmp_deeply([$r,$pos], [65,3], "floating point");
    
    $r = $sub->("asdff", $pos);
    cmp_deeply([$r,$pos], [undef,0], "junk only");
    
    $r = $sub->("", $pos);
    cmp_deeply([$r,$pos], [undef,0], "empty");

    $r = $sub->("  -", $pos);
    cmp_deeply([$r,$pos], [undef,0], "non-digits only");

    $r = $sub->("$max", $pos);
    cmp_deeply([$r,$pos], [$max,length($max)], "max");
    
    $r = $sub->("$above_max", $pos);
    cmp_deeply([$r,$pos], [undef,length($above_max)], "more than max");

    $r = $sub->("     123456789012345678901234567890123456789012345678901234567890", $pos);
    cmp_deeply([$r,$pos], [undef,65], "dohuya");
    
    $r = $sub->("$min", $pos);
    cmp_deeply([$r,$pos], [$min,length($min)], "min");

    if ($min < 0) {
        $r = $sub->("$under_min", $pos);
        cmp_deeply([$r,$pos], [undef,length($under_min)], "less than min");
        
        $r = $sub->("    -123456789012345678901234567890123456789012345678901234567890", $pos);
        cmp_deeply([$r,$pos], [undef,65], "-dohuya");
    }
    
    # base 8
    $r = $sub->("10", $pos, 8);
    cmp_deeply([$r,$pos], [8,2], "8-base");
    $r = $sub->("010", $pos, 8);
    cmp_deeply([$r,$pos], [8,3], "8-base");
    if ($min < 0) {
        $r = $sub->(" -0012", $pos, 8);
        cmp_deeply([$r,$pos], [-10,6], "8-base");
    }
    
    # base 16
    $r = $sub->("10", $pos, 16);
    cmp_deeply([$r,$pos], [16,2], "16-base");
    $r = $sub->("0x10", $pos, 16);
    cmp_deeply([$r,$pos], [0,1], "0x not supported for 16-base");
    $r = $sub->("0F", $pos, 16);
    cmp_deeply([$r,$pos], [15,2], "16-base");
    if ($min < 0) {
        $r = $sub->("  -0Dqwe", $pos, 16);
        cmp_deeply([$r,$pos], [-13,5], "16-base");
    }
    
    # invalid base
    
    $r = $sub->("12", $pos, 0);
    cmp_deeply([$r,$pos], [12,2], "0-base = 10 base");
    $r = $sub->("13", $pos, 1);
    cmp_deeply([$r,$pos], [13,2], "1-base = 10 base");
    $r = $sub->("13", $pos, 36);
    cmp_deeply([$r,$pos], [39,2], "36-base");
    $r = $sub->("13", $pos, 37);
    cmp_deeply([$r,$pos], [13,2], ">36-base = 10 base");
}

done_testing();