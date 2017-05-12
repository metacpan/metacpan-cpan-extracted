#!perl -T

use Test::More tests => 52;

use_ok('Number::Bytes::Human', 'format_bytes', 'parse_bytes');

our @TESTS_EXACT = (
  '0' => '0',
  '1' => '1.0',   #'1', mafoo - with the default being precision 1 with cutoff digits 1
  '-1' => '-1.0', #'-1', mafoo - with the default being precision 1 with cutoff digits 1
  '10' => '10',
  '100' => '100',
  '400' => '400',
  '500' => '500',
  '600' => '600',
  '900' => '900',
  '1000' => '1000',
  '2**10' => '1.0K',
  '1<<10' => '1.0K',
  '1023' => '1023',
  '1024' => '1.0K',
  '2048' => '2.0K',
  '10*1024' => '10K',
  '500*1024' => '500K',
  '1023*1024' => '1023K',
  '1024*1024' => '1.0M',
  '2**30' => '1.0G',
  '1.5*(2**30)' => '1.5G',
  '2**80' => '1.0Y',
  '1023*2**80' => '1023Y',
  #'1025*2**80' => '1025Y', # TODO
);

our @TESTS_ROUND = (
  '1025' => '1.1K',
  '10*1024+1' => '11K',
  '1023*1024+1' => '1.0M',
);

# Format tests
@TESTS_ALL = (@TESTS_EXACT, @TESTS_ROUND);
is(format_bytes(undef), undef, "undef is undef");
while (my ($exp, $expected) = splice @TESTS_ALL, 0, 2) {
  $num = eval $exp;
  is(format_bytes($num), $expected, "$exp is $expected");
}

# Parse tests
is(parse_bytes(undef), undef, "undef is undef");
while (my ($exp, $expected) = splice @TESTS_EXACT, 0, 2) {
  $num = eval $exp;
  is(parse_bytes($expected), $num, "parsing $expected should result in $num");
}
