#!perl -T

use Test::More tests => 27;

use_ok('Number::Bytes::Human', 'format_bytes', 'parse_bytes');

our @TESTS = (
  '0' => '0',
  '1' => '1.0',   #'1', wrong with the default being precision 1 with cutoff digits 1
  '-1' => '-1.0', #'-1', wrong with the default being precision 1 with cutoff digits 1
  '10' => '10',
  '100' => '100',
  '400' => '400',
  '1000' => '1000',
  '2000' => '2000',
  '1_000_000' => '1000000',
  '1_024_000' => '1.0M',
  '1_126_400' => '1.1M',
#  '1.44*1_024_001' => '1.44M', # TODO - Mafoo, only if you did format_bytes( 1.44 * 1_024_001, bs => 1_024_000, precision => 2, precision_cutoff => -1, round_style => 'round' )
  '1_024_000*1_024_000' => '1.0T',
);

is(format_bytes(undef), undef, "undef is undef");
is(parse_bytes(undef), undef, "undef is undef");

while (my ($exp, $expected) = splice @TESTS, 0, 2) {
  $num = eval $exp;
  is(format_bytes($num, bs => 1_024_000), $expected, "$exp is '$expected'");
  is(parse_bytes($expected, bs => 1_024_000), $num, "'$expected' is $num");
}
