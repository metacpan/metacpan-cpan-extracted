# 06_scalar.t
#
# Tests for proper extraction of scalar values

use Parse::PlainConfig::Legacy;

$|++;
print "1..13\n";

my $test   = 1;
my $rcfile = './t/v2_testrc';
my $conf   = Parse::PlainConfig::Legacy->new(FILE => $rcfile);

# First series with smart parser off
#
# 1 scalar 1
$conf->read($rcfile);
$conf->parameter("SCALAR 1") eq "value1" ? print "ok $test\n" : 
	print "not ok $test\n";
$test++;

# 2 scalar 2
$conf->parameter("SCALAR 2") eq "these, are, all one => value" ? 
  print "ok $test\n" : print "not ok $test\n";
$test++;

# 3 scalar 3
$conf->parameter("SCALAR 3") eq "this is a continued line." ?
  print "ok $test\n" : print "not ok $test\n";
$test++;

# 4 scalar 4
$conf->parameter("SCALAR 4") eq 
  "ASDFKAS234123098ASDFA9082341ASDFIO23489078907SFASDF8A972" ?
  print "ok $test\n" : print "not ok $test\n";
$test++;

# Second series with smart parser on
#
# 5 scalar 1
$conf->property(SMART_PARSER => 1);
$conf->property(AUTOPURGE => 1);
$conf->read("${rcfile}_smart");
$conf->parameter("SCALAR 1") eq "value1" ? print "ok $test\n" : 
	print "not ok $test\n";
$test++;

# 6 scalar 2
$conf->parameter("SCALAR 2") eq "these, are, all one => value" ? 
  print "ok $test\n" : print "not ok $test\n";
$test++;

# 7 scalar 3
$conf->parameter("SCALAR 3") eq "this is a continued line." ?
  print "ok $test\n" : print "not ok $test\n";
$test++;

# 8 scalar 4
$conf->parameter("SCALAR 4") eq 
  "ASDFKAS234123098ASDFA9082341ASDFIO23489078907SFASDF8A972" ?
  print "ok $test\n" : print "not ok $test\n";
$test++;

# 9 scalar 2 with scalar coercion set and smart parsing
$conf->coerce("string", "SCALAR 2");
$conf->read;
$conf->parameter("SCALAR 2") eq '"these, are, all one => value"' ? 
  print "ok $test\n" : print "not ok $test\n";
$test++;

# Set tests
#
# 10 new scalar 1
$conf->parameter("NEW SCALAR 1", "this is new");
$conf->parameter("NEW SCALAR 1") eq "this is new" ?
  print "ok $test\n" : print "not ok $test\n";
$test++;

# 11 new scalar 2 with coercion set
$conf->coerce("string", "NEW SCALAR 2");
$conf->parameter("NEW SCALAR 2", "this is also new");
$conf->parameter("NEW SCALAR 2") eq "this is also new" ?
  print "ok $test\n" : print "not ok $test\n";
$test++;

# 12 new scalar 2 with list value
$conf->parameter("NEW SCALAR 2", [qw(this is new again)]);
$conf->parameter("NEW SCALAR 2") eq "this , is , new , again" ?
  print "ok $test\n" : print "not ok $test\n";
$test++;

# 13 new scalar 2 with hash value
$conf->parameter("NEW SCALAR 2", {qw(this is new indeed)});
$conf->parameter("NEW SCALAR 2") eq "new => indeed , this => is" ?
  print "ok $test\n" : print "not ok $test\n";
$test++;

# end 06_scalar.t
