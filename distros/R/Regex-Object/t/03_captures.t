use strict;
use warnings qw/FATAL/;
use utf8;

use Test::Simple tests => 4;
use Regex::Object;

$|=1;

# vars
my ($re, $expected, $result);

# Initial
$re = Regex::Object->new(
    regex  => qr/(?<gr1>gr1) (?<gr2>gr2) (?<gr3>gr3)/,
);

## TEST 1
# Test 3 groups match

$expected = 3;
$result = scalar @{ $re->match('gr1 gr2 gr3')->captures };

ok($result == $expected,
    sprintf('Returns wrong value: %s, expected: %s',
        $result,
        $expected,
    )
);

## TEST 2
# Test 0 groups match

$expected = 0;
$result = scalar @{ $re->match('gr1 ngr2 gr3')->captures };

ok($result == $expected,
    sprintf('Returns wrong value: %s, expected: %s',
        $result,
        $expected,
    )
);

## TEST 3
# Test named captures

$expected = 'gr3';
$result = $re->match('gr1 gr2 gr3')->named_captures->{gr3};

ok($result eq $expected,
    sprintf('Returns wrong value: %s, expected: %s',
        $result,
        $expected,
    )
);

## TEST 4
# Test last_paren_match

$re = Regex::Object->new(
    regex  => qr/(gr1)|(gr2)/,
);

$expected = 'gr1';
$result = $re->match('gr1')->last_paren_match;

ok($result eq $expected,
    sprintf('Returns wrong value: %s, expected: %s',
        $result,
        $expected,
    )
);
