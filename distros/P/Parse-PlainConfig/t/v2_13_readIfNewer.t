# 13_readIfNewer.t
#
# Tests the readIfNewer method

use Parse::PlainConfig::Legacy;

$|++;
print "1..8\n";

my $test    = 1;
my $conf1   = new Parse::PlainConfig::Legacy;
my $conf2   = new Parse::PlainConfig::Legacy;
my $testrc  = "./t/v2_testrc-tmp";
my $rv;

# 1 & 2 Load & write to temp file
$rv = $conf1->read("./t/v2_testrc");
$rv ? print "ok $test\n" : print "not ok $test\n";
$test++;
$rv = $conf1->write($testrc);
$rv ? print "ok $test\n" : print "not ok $test\n";
$test++;
$conf1->property(FILE => $testrc);

# 3 Load conf2 w/temp file
$rv = $conf2->read($testrc);
$rv ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 4 Write new value w/conf1
sleep 3;
$conf1->parameter("FOO" => "BAR");
$rv = $conf1->write;
$rv ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 5 Reread w/conf2
sleep 3;
$rv = $conf2->readIfNewer;
$rv == 1 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 6 Make sure new value is there
grep(/^FOO$/, $conf2->parameters) ? print "ok $test\n" :
  print "not ok $test\n";
$test++;

# 7 Reread once more
sleep 1;
$rv = $conf2->readIfNewer;
$rv == 2 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 8 Unlink file and reread
unlink $testrc;
$rv = $conf2->readIfNewer;
$rv ? print "not ok $test\n" : print "ok $test\n";
$test++;

# end 13_readIfNewer.t
