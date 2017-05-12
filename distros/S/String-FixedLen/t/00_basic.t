use strict;

use Test::More tests => 13;

use String::FixedLen;

my $Unchanged = 'The scalar remains the same';
$_ = $Unchanged;

tie my $str, 'String::FixedLen', 4;

is( ref(tied $str), 'String::FixedLen', 'a String::FixedLen object' );

$str = 'b';
is( $str, 'b', 'small assign' );

$str = 'a' . $str;
is( $str, 'ab', 'prepend to small' );

$str .= 'cdef';
is( $str, 'abcd', 'append to small' );

$str .= 'g';
is( $str, 'abcd', 'append to full' );

$str = "hello, world\n";
is( $str, 'hell', 'big assign' );

$str = "wis$str";
is( $str, 'wish', 'prepend to big' );

$str = $str . "bone";
is( $str, 'wish', 'append to big' );

$str = 9999 + 12;
is( $str, '1001', 'integer assign trunc' );

$str = sqrt(2);
is( $str, '1.41', 'float assign trunc' );

SKIP: {
    skip( 'Test::Pod not installed on this system', 1 )
        unless do {
            eval "use Test::Pod";
            $@ ? 0 : 1;
        };

    pod_file_ok( 'FixedLen.pm' );
}

SKIP: {
    skip( 'Test::Pod::Coverage not installed on this system', 1 )
        unless do {
            eval "use Test::Pod::Coverage";
            $@ ? 0 : 1;
        };
    pod_coverage_ok( 'String::FixedLen', 'POD coverage is go!' );
}

cmp_ok( $_, 'eq', $Unchanged, '$_ has not been altered' );
