# 16_hasParameter.t
#
# Tests the traditional usage for backwards compatibility

use Parse::PlainConfig::Legacy;

$|++;
print "1..3\n";

my $test    = 1;
my $conf    = new Parse::PlainConfig::Legacy;
my $testrc  = "./t/v2_testrc";
my ($val, $val2);
$conf->read($testrc);
$conf->property(DEFAULTS => 
  {
  NOT_PRESENT   => 1,
  });

# 1 Test key that exists in the defaults hash
$rv = $conf->hasParameter('NOT_PRESENT');
$rv ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 2 Test present key
$rv = $conf->hasParameter('SCALAR 1');
$rv ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 3 Test invalid key
$rv = ! $conf->hasParameter('NOT_THERE');
$rv ? print "ok $test\n" : print "not ok $test\n";
$test++;

# end 16_hasParameter.t
