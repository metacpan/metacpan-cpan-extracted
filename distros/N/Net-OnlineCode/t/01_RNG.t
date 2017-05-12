# -*- Perl -*-

use Test::More tests => 21;

BEGIN { use_ok('Net::OnlineCode::RNG') }

my ($rng1,$rng2);
my ($str1,$str2,$str3);


$rng1 = new Net::OnlineCode::RNG();
$rng2 = new Net::OnlineCode::RNG();

ok(ref($rng1), "RNG new returns an object");

ok ($str1 = $rng1->get_seed, "get_seed returns defined, non-zero value");
ok ($str2 = $rng1->current, "current returns defined, non-zero value");
ok ($str3 = $rng1->as_string(), "as_string returns defined, non-zero value");

ok ((($str1 eq $str2) and ($str1 eq $str3)), "get_seed, current, as_string agree after new");

# the new() constructor always creates a deterministic seed value if
# we don't pass a seed. Rather than copy the default value from the
# code (which may be different in classes that inherit from it), check
# whether two invocations produce the same seed.
ok ($str1 eq $rng2->current, "RNGs seeded deterministically");

# Skip new_random() tests if we don't have /dev/urandom
SKIP: {

  skip "We don't have a /dev/urandom on this machine", 7
    unless -f "/dev/urandom";

  $str1 = Net::OnlineCode::RNG::random_uuid_160();

  ok(defined($str1), "random_uuid_160 not null");
  ok(length($str1) == 20, "random_uuid_160 returns 20 characters");

  # new_random method also calls random_uuid_160 to set the seed
  my $rng1 = new_random Net::OnlineCode::RNG;
  ok(ref($rng1), "Create RNG with new_random, method 1");

  # rng2 just uses an alternative syntax
  my $rng2 = Net::OnlineCode::RNG::new_random;
  ok(ref($rng2), "Create RNG with new_random, method 2");

  $str1 = $rng1->get_seed;
  $str2 = $rng1->current;
  ok(length($str1) == 20, "new_random seed length == 20");

  # after constructor, seed = current
  ok($str1 eq $str2, "new_random begins with seed eq current");

  # calling rand() method does not modify seed value
  $rng1->rand();
  ok($str1 eq $rng1->get_seed, "Calling rand doesn't modify seed value");

}

# calling rand() method does not modify seed value
$rng1->rand();
ok($str1 eq $rng1->get_seed, "Calling rand doesn't modify seed value");

# setting new seed should also set current and return new seed
ok("$str1$str1" eq $rng1->seed("$str1$str1"), "seed() returns new seed value");
ok("$str1$str1" eq $rng1->get_seed, "seed() updates seed value");
ok("$str1$str1" eq $rng1->current, "seed() updates current value");

# Basic test of rand as coin flip
my ($zeroes, $ones, $outofrange ) = (0,0,0);

# test has 2/2**50 chance of failing
for my $i (1..50) {
  my $val = int($rng1->rand(2));
  if ($val == 0) {
    ++$zeroes;
  } elsif ($val == 1) {
    ++$ones;
  } else {
    ++$outofrange;
  }
}

ok ($zeroes, "int(\$rng->rand(2)) can roll a '0'");
ok ($ones, "int(\$rng->rand(2)) can roll a '1'");
ok ($outofrange == 0, "int(\$rng->rand(2)) only rolls a '0' or '1'");

