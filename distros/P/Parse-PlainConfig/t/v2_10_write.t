# 10_write.t
#
# Tests the write method

use Parse::PlainConfig::Legacy;

$|++;
print "1..6\n";

my $test    = 1;
my $conf    = new Parse::PlainConfig::Legacy;
my $nconf   = new Parse::PlainConfig::Legacy;
my $testrc  = "./t/v2_testrc";
$conf->coerce('string', 'SCALAR 5');
$conf->read($testrc);

# 1 write w/o smart
$rv = $conf->write("${testrc}_write");
$rv ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 2 verify worthiness of new file
$rv = $nconf->read("${testrc}_write");
$rv ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 3 compare values in both
$conf->parameter('SCALAR 5') eq $nconf->parameter('SCALAR 5') ?
  print "ok $test\n" : print "not ok $test\n";
unlink "${testrc}_write";
$test++;

# 4 write w/smart
$conf->property("SMART_PARSER", 1);
$conf->coerce('string', 'SCALAR 1', 'SCALAR 2', 'SCALAR 3', 'SCALAR 4',
  'SCALAR 5');
$conf->coerce('list', 'LIST 1', 'LIST 2', 'LIST 3');
$conf->coerce('hash', 'HASH 1');
$rv = $conf->write("${testrc}_write_smart");
$rv ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 5 verify worthiness of new file
$nconf->purge;
$nconf->property("SMART_PARSER", 1);
$nconf->coerce('string', 'SCALAR 1', 'SCALAR 2', 'SCALAR 3', 'SCALAR 4',
  'SCALAR 5');
$nconf->coerce('list', 'LIST 1', 'LIST 2', 'LIST 3');
$nconf->coerce('hash', 'HASH 1');
$nconf->read("${testrc}_write_smart");
$rv ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 6 compare values in both
$conf->parameter('SCALAR 5') eq $nconf->parameter('SCALAR 5') ?
  print "ok $test\n" : print "not ok $test\n";
unlink "${testrc}_write_smart";
$test++;

# end 10_write.t
