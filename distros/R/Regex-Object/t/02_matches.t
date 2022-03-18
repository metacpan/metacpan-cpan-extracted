use strict;
use warnings qw/FATAL/;
use utf8;

use Test::Simple tests => 12;
use Regex::Object;

$|=1;

# vars
my ($re, $expected, $result, @result);

# Initial
$re = Regex::Object->new(
    regex  => qr/regex/,
);

## TEST 1
# Test match.

$expected = 'regex';
$result   = $re->match('full regex expression')->match;

ok($result eq $expected,
    sprintf('Returns wrong value: %s, expected: %s',
        $result,
        $expected,
    )
);

## TEST 2
# Test prematch.

$expected = 'full ';
$result   = $re->match('full regex expression')->prematch;

ok($result eq $expected,
    sprintf('Returns wrong value: %s, expected: %s',
        $result,
        $expected,
    )
);

## TEST 3
# Test postmatch.

$expected = ' expression';
$result   = $re->match('full regex expression')->postmatch;

ok($result eq $expected,
    sprintf('Returns wrong value: %s, expected: %s',
        $result,
        $expected,
    )
);

## TEST 4
# Test unmatched.

$result = $re->match('full expression')->match;

ok(!$result,
    'Returns wrong value: string, expected: undef'
);

## TEST 5
# Test global matching with global regex.

$expected = 'John Doe Eric Lide Hans Zimmermann';

while ($expected =~ /(?<name>\w+?) (?<surname>\w+)/g) {
    push @result, @{ $re->collect->captures };
}

$result = join "\040", @result;

ok($result eq $expected,
    sprintf('Returns wrong value: %s, expected: %s',
        $result,
        $expected,
    )
);

## TEST 6
# Test global matching with scoped regex.

$re = Regex::Object->new(
    regex  => qr/(\w+?) (\w+)/,
);

$expected = 'John Doe Eric Lide Hans Zimmermann';
$result   = join "\040", @{ $re->match_all($expected)->match_all };

ok($result eq $expected,
    sprintf('Returns wrong value: %s, expected: %s',
        $result,
        $expected,
    )
);

## TEST 7
# Test global matching with scoped regex with modifiers: match_all method.

$re = Regex::Object->new(
    regex  => qr/([A-Z]+?) ([A-Z]+)/i,
);

$expected = 'John Doe Eric Lide Hans Zimmermann';
$result   = join "\040", @{ $re->match_all($expected)->match_all };

ok($result eq $expected,
    sprintf('Returns wrong value: %s, expected: %s',
        $result,
        $expected,
    )
);

## TEST 8
# Test global matching with scoped regex with modifiers: captures_all.

$re = Regex::Object->new(
    regex  => qr/([A-Z]+?) ([A-Z]+)/i,
);

$expected = 'John Doe Eric Lide Hans Zimmermann';
$result   = join "\040", map { join "\040", @$_ } @{ $re->match_all($expected)->captures_all };

ok($result eq $expected,
    sprintf('Returns wrong value: %s, expected: %s',
        $result,
        $expected,
    )
);

## TEST 9
# Test unsuccessful matching.

$re     = Regex::Object->new(regex => qr/\d+/);
$result = $re->match('foo')->success;

ok(!$result,
    sprintf('Returns wrong value: %s, expected: undef',
        $result,
    )
);


## TEST 10
# Test global matching with scoped regex: count unsuccessfully.

$re = Regex::Object->new(
    regex  => qr/(\d+?) (\d+)/,
);

$expected = 0;
$result   = $re->match_all('John Doe Eric Lide')->count;

ok($result == $expected,
    sprintf('Returns wrong value: %s, expected: %s',
        $result,
        $expected,
    )
);

## TEST 11
# Test global matching with scoped regex: count successfully.

$re = Regex::Object->new(
    regex  => qr/(\w+?) (\w+)/,
);

$expected = 2;
$result   = $re->match_all('John Doe Eric Lide')->count;

ok($result == $expected,
    sprintf('Returns wrong value: %s, expected: %s',
        $result,
        $expected,
    )
);

## TEST 12
# Test global match than Regex::Object unmatch to see what's there with $MATH global var.

'test-string' =~ /test-string/;

$re = Regex::Object->new(
    regex  => qr/nest-string/,
);

$expected = undef;
$result   = $re->match('test-string')->match;

ok(!$result,
    sprintf('Returns wrong value: %s, expected: undef',
        $result || 'undef',
    )
);
