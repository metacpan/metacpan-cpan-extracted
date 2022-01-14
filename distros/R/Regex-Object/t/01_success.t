use strict;
use warnings qw/FATAL/;
use utf8;

use Test::Simple tests => 2;
use Regex::Object;

$|=1;

# vars
my ($re, $expected, $result);

# Initial
$re = Regex::Object->new(
    regex  => qr/^word\040$/,
);

## TEST 1
# Test success match

$expected = 1;
$result = $re->match('word ')->success;

ok($result == $expected,
    sprintf('Returns wrong value: %s, expected: %s',
        $result,
        $expected,
    )
);

## TEST 2
# Test failed match

$expected = 0;
$result = $re->match('word')->success;

ok($result == $expected,
    sprintf('Returns wrong value: %s, expected: %s',
        $result,
        $expected,
    )
);
