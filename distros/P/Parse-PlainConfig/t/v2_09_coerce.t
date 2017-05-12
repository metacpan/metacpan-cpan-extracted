# 09_coerce.t
#
# Tests coerce method

use Parse::PlainConfig::Legacy;

$|++;
print "1..5\n";

my $test   = 1;
my $rcfile = './t/v2_testrc_smart';
my $conf   = Parse::PlainConfig::Legacy->new(
  FILE          => $rcfile,
  SMART_PARSER  => 1,
  COERCE        => {
      'SCALAR 2'  => 'string',
      'LIST 3'    => 'list',
      },
  );
$conf->read;
my %hash;

# 1 scalar 2
$conf->parameter("SCALAR 2") eq '"these, are, all one => value"' ? 
  print "ok $test\n" : print "not ok $test\n";
$test++;

# 2 list 3
($conf->parameter("LIST 3"))[2] eq "two => parts" ? print "ok $test\n" : 
  print "not ok $test\n";
$test++;

# 3 coerce list 1 into string
$conf->coerce('string', 'LIST 1');
$conf->parameter("LIST 1") eq "value1 , value2 , value3" ? 
  print "ok $test\n" : print "not ok $test\n";
$test++;

# 4 .. 5 coerce scalar 2 into a hash
$conf->parameter('SCALAR 2', 
  ($conf->parameter('SCALAR 2') =~ /^"(.*)"$/)[0]);
$conf->coerce('hash', 'SCALAR 2');
%hash = ( $conf->parameter('SCALAR 2') );
$hash{"these"} eq 'are' ? print "ok $test\n" : print "not ok $test\n";
$test++;
$hash{"all one"} eq 'value' ? print "ok $test\n" : print "not ok $test\n";
$test++;

# end 09_coerce.t
