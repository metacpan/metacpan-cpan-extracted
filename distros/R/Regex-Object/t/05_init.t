use strict;
use warnings qw/FATAL/;
use utf8;

use Test::Simple tests => 2;
use Regex::Object;

$|=1;

# vars
my ($re, $expected, $result);

## TEST 1
# Test returned regex

$re       = Regex::Object->new(regex  => qr/^word\040$/);
$expected = qr/^word\040$/;
$result   = $re->regex;

ok($result eq $expected,
    sprintf('Returns wrong value: %s, expected: %s',
        $result,
        $expected,
    )
);

## TEST 2
# Test empty constructor and undef regex
$re = Regex::Object->new;

ok(!$re->regex,
    'Returns wrong value: string, expected: undef',
);
