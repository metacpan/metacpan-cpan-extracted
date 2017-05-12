# 07_list.t
#
# Tests for proper extraction of scalar values

use Parse::PlainConfig::Legacy;

$|++;
print "1..10\n";

my $test   = 1;
my $rcfile = './t/v2_testrc';
my $conf   = Parse::PlainConfig::Legacy->new(FILE => $rcfile);

# First series with smart parser off
#
# 1 list 1
$conf->read($rcfile);
($conf->parameter("LIST 1"))[2] eq "value3" ? print "ok $test\n" : 
	print "not ok $test\n";
$test++;

# 2 list 2
($conf->parameter("LIST 2"))[1] eq "two, parts" ? print "ok $test\n" : 
  print "not ok $test\n";
$test++;

# 3 list 3
($conf->parameter("LIST 3"))[2] eq "two => parts" ? print "ok $test\n" : 
  print "not ok $test\n";
$test++;

# Second series with smart parser on
#
# 4 list 1
$conf->property(SMART_PARSER => 1);
$conf->property(AUTOPURGE => 1);
$conf->read("${rcfile}_smart");
($conf->parameter("LIST 1"))[2] eq "value3" ? print "ok $test\n" : 
	print "not ok $test\n";
$test++;

# 5 list 2
($conf->parameter("LIST 2"))[1] eq "two, parts" ? print "ok $test\n" : 
  print "not ok $test\n";
$test++;

# 6 list 3 with list coercion set and smart parsing
$conf->coerce("list", "LIST 3");
$conf->read;
($conf->parameter("LIST 3"))[2] eq "two => parts" ? print "ok $test\n" : 
  print "not ok $test\n";
$test++;

# Set tests
#
# 7 new list 1
$conf->parameter("NEW LIST 1", [qw(this is a new list)]);
($conf->parameter("NEW LIST 1"))[2] eq "a" ? print "ok $test\n" : 
  print "not ok $test\n";
$test++;

# 8 new list 2 with coercion set
$conf->coerce("list", "NEW LIST 2");
$conf->parameter("NEW LIST 2", [qw(this is a new list)]);
($conf->parameter("NEW LIST 2"))[2] eq "a" ? print "ok $test\n" : 
  print "not ok $test\n";
$test++;

# 9 new list 2 with string value
$conf->parameter("NEW LIST 2", "this is new");
($conf->parameter("NEW LIST 2"))[0] eq "this is new" ? print "ok $test\n" : 
  print "not ok $test\n";
$test++;

# 10 new list 2 with hash value
$conf->parameter("NEW LIST 2", { 'this' => 'is', 'also' => 'new' });
($conf->parameter("NEW LIST 2"))[2] eq "this" ? print "ok $test\n" : 
  print "not ok $test\n";
$test++;

# end 07_list.t
