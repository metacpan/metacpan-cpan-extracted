# 12_purge.t
#
# Tests the purge and autopurge functionality

use Parse::PlainConfig::Legacy;

$|++;
print "1..5\n";

my $test    = 1;
my $conf    = new Parse::PlainConfig::Legacy;
my $testrc  = "./t/v2_testrc";
my ($val, $val2, @params);
$conf->read($testrc);

# 1 & 2 Test purge
@params = $conf->parameters();
@params ? print "ok $test\n" : print "not ok $test\n";
$test++;
$conf->purge();
@params = $conf->parameters();
@params ? print "not ok $test\n" : print "ok $test\n";
$test++;

# 3 .. 5 Test autopurge
$conf->read;
$conf->parameter("FOO" => "BAR");
@params = $conf->parameters();
grep(/^FOO$/, @params) ? print "ok $test\n" : print "not ok $test\n";
$test++;
$conf->property("AUTOPURGE" => 1);
$conf->read;
@params = $conf->parameters();
grep(/^FOO$/, @params) ? print "not ok $test\n" : print "ok $test\n";
$test++;
@params ? print "ok $test\n" : print "not ok $test\n";
$test++;

# end 12_purge.t
