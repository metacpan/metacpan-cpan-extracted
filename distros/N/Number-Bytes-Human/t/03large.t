#!perl -T

use Test::More;

if (eval 'require bignum') {
  plan tests => 5;
} else {
  plan skip_all => 'bignum is not available';
}

# this script tests format_bytes() with large (very large) numbers


use_ok('Number::Bytes::Human', 'format_bytes', 'parse_bytes');

our @TESTS = (
  '2**80', 2**80, '1.0Y',
  '1023*(2**80)', 1023*(2**80), '1023Y',
  #'1024*(2**80)', 1024*(2**80), '1024Y' # should fail number is to large
);


#  is(format_bytes(2**80), '1.0Y', '2**80 is 1.0Y (yottabyte)');

while (my ($exp, $num, $expected) = splice @TESTS, 0, 3) {
  is(format_bytes($num), $expected, "$exp is $expected");
  is(parse_bytes($expected), $num, "parsing $expected should result in $num");
}
