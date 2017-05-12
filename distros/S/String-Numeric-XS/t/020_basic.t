#!perl -w

use strict;

use lib 't/lib', 'lib';
use myconfig;

use Test::More tests => 586;

BEGIN {
    use_ok('String::Numeric', ':all');
}

sub TRUE  () { !!1 }
sub FALSE () { !!0 }

my @NBITS = (8, 16, 32, 64, 128);

my @INT_MIN = qw(
    -128
    -32768
    -2147483648
    -9223372036854775808
    -170141183460469231731687303715884105728
);

my @INT_MAX = qw(
    127
    32767
    2147483647
    9223372036854775807
    170141183460469231731687303715884105727
);

my @INT_OVERFLOW = qw(
    128
    32768
    2147483648
    9223372036854775808
    170141183460469231731687303715884105728
);

my @UINT_MAX = qw(
    255
    65535
    4294967295
    18446744073709551615
    340282366920938463463374607431768211455
);

my @UINT_OVERFLOW = qw(
    256
    65536
    4294967296
    18446744073709551616
    340282366920938463463374607431768211456
);

my @SUBNAMES = qw(
    is_float
    is_decimal
    is_int
    is_int8
    is_int16
    is_int32
    is_int64
    is_int128
    is_uint
    is_uint8
    is_uint16
    is_uint32
    is_uint64
    is_uint128
);

sub test_subname ($$$) {
    my ($subname, $test, $expected) = @_;
    my $name = defined($test) ? "$subname('$test')" : "$subname(undef)";
    my $code = __PACKAGE__->can($subname) || die(qq/No such subname '$subname'/);
    is $code->($test), $expected, $name;
}

foreach my $subname (@SUBNAMES) {
    test_subname($subname, $_, TRUE)  for qw(0 1 10 100);
    test_subname($subname, $_, FALSE) for (undef, qw(00 01 +1));
}

foreach my $num (@INT_MIN, @INT_MAX, @UINT_MAX) {
    test_subname($_, $num, TRUE) for qw(is_float is_decimal is_int);
}

foreach my $i (0..$#NBITS) {

    foreach my $j (0..$#NBITS) {
        my $decimal = $INT_MIN[$i] . '.' . $INT_MAX[$j];
        test_subname($_, $decimal, TRUE) for qw(is_float is_decimal);

        for my $e ($INT_MIN[$i], $INT_MAX[$i], '-' . $INT_MAX[$i]) {
            my $float = $decimal . 'e' . $e;
            test_subname('is_float',   $float, TRUE);
            test_subname('is_decimal', $float, FALSE);
        }
    }

    foreach my $j (0..$#NBITS) {
        my $decimal = $INT_MAX[$i] . '.' . $INT_MAX[$j];
        test_subname($_, $decimal, TRUE) for qw(is_float is_decimal);
    }
}

foreach my $i (0..$#NBITS) {
    my $subname = 'is_int' . $NBITS[$i];

    foreach my $j (0..$#NBITS) {
        test_subname($subname, $INT_MIN[$j],  $i >= $j);
        test_subname($subname, $INT_MAX[$j],  $i >= $j);
        test_subname($subname, $UINT_MAX[$j], $i >  $j);
    }

    test_subname($subname, $INT_OVERFLOW[$i], FALSE);
}

test_subname('is_uint', $_, TRUE)  for (@INT_MAX, @UINT_MAX);
test_subname('is_uint', $_, FALSE) for (@INT_MIN);

foreach my $i (0..$#NBITS) {
    my $subname = 'is_uint' . $NBITS[$i];

    foreach my $j (0..$#NBITS) {
        test_subname($subname, $INT_MIN[$j],  FALSE);
        test_subname($subname, $INT_MAX[$j],  $i >= $j);
        test_subname($subname, $UINT_MAX[$j], $i >= $j);
    }

    test_subname($subname, $UINT_OVERFLOW[$i], FALSE);
}

{
    my @I129 = qw(
        -340282366920938463463374607431768211456 
         340282366920938463463374607431768211455
    );

    test_subname('is_int128', $_, FALSE) for @I129;
    test_subname('is_uint128', '680564733841876926926749214863536422911', FALSE);
}


