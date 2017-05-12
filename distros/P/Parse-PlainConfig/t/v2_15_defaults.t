# 15_defaults.t
#
# Test the defaults capability

use Parse::PlainConfig::Legacy;

$|++;
print "1..2\n";

my $test    = 1;
my $conf    = new Parse::PlainConfig::Legacy;
my $testrc  = "./t/v2_testrc";
my ($val, $val2);
$conf->read($testrc);
$conf->property(DEFAULTS => 
  {
  NOT_PRESENT   => 1,
  });

# 1 Test defaults
$val = $conf->parameter('NOT_PRESENT');
$val == 1 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 2 Test present key
$val = $conf->parameter('SCALAR 1');
$val eq 'value1' ? print "ok $test\n" : print "not ok $test\n";
$test++;

# end 15_defaults.t
