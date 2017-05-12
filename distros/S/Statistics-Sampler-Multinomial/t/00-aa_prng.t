#  do we get the same PRNG values given a starting seed?
#  for cpan testers checking

use strict;
use warnings;
use 5.010;
use English qw /-no_match_vars/;

use rlib;
use Test::Most tests => 1;
use Math::Random::MT::Auto;

my $prng = Math::Random::MT::Auto->new(seed => 2345);

my @rand_vals = map {$prng->irand} (1..10);

say join "\n", @rand_vals;

my $exp_str = <<'END_RAND_VALS'
9482288807513358836
2145556640521815095
14476684180298955877
10279728588562551049
8862642890840504786
11719663146631850874
2847934137399092496
13995847755534032356
1293850571664071823
6604147041762322118
END_RAND_VALS
  ;

my @expected = split "\n", $exp_str;

SKIP: {
    use Config;
    skip 'PRNG sequence is for 64 bit ints', 1
      if $Config{ivsize} == 4;
    is_deeply (\@rand_vals, \@expected, 'got expected PRNG sequence');
}

done_testing();
