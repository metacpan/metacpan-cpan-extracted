# 11_order.t
#
# Tests the order method

use Parse::PlainConfig::Legacy;

$|++;
print "1..2\n";

my $test    = 1;
my $conf    = new Parse::PlainConfig::Legacy;
my $nconf   = new Parse::PlainConfig::Legacy;
my $testrc  = "./t/v2_testrc";
$conf->coerce('string', 'SCALAR 5');
$conf->read($testrc);

# 1 change order and write w/smart
$conf->property("SMART_PARSER", 1);
$conf->coerce('string', 'SCALAR 1', 'SCALAR 2', 'SCALAR 3', 'SCALAR 4',
  'SCALAR 5');
$conf->coerce('list', 'LIST 1', 'LIST 2', 'LIST 3');
$conf->coerce('hash', 'HASH 1');
$conf->order('HASH 1', 'LIST 3', 'SCALAR 5');
$rv = $conf->write("${testrc}_order");
$rv ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 2 read and compare order
$nconf->property("SMART_PARSER", 1);
$nconf->coerce('string', 'SCALAR 1', 'SCALAR 2', 'SCALAR 3', 'SCALAR 4',
  'SCALAR 5');
$nconf->coerce('list', 'LIST 1', 'LIST 2', 'LIST 3');
$nconf->coerce('hash', 'HASH 1');
$nconf->read("${testrc}_order");
($nconf->order)[0] eq 'HASH 1' ? print "ok $test\n" : print "not ok $test\n";
unlink "${testrc}_order";
$test++;

# end 11_order.t
