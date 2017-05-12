# 08_hash.t
#
# Tests for proper extraction of hash values

use Parse::PlainConfig::Legacy;

$|++;
print "1..6\n";

my $test   = 1;
my $rcfile = './t/v2_testrc';
my $conf   = Parse::PlainConfig::Legacy->new(FILE => $rcfile);
$conf->read($rcfile);
my %hash = ( $conf->parameter("HASH 1") );

# 1 hash 1
$hash{two} eq "2" ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 2 hash 1
$hash{three} eq "Three for Me! 3 => 2" ?  print "ok $test\n" : 
  print "not ok $test\n";
$test++;

# Set tests
#
# 3 new hash 1
$conf->parameter('NEW HASH 1', { 'foo' => 'bar' });
%hash = $conf->parameter('NEW HASH 1');
$hash{foo} eq "bar" ?  print "ok $test\n" : print "not ok $test\n";
$test++;

# 4 new hash 2 with coercion set
$conf->coerce('hash', 'NEW HASH 2');
$conf->parameter('NEW HASH 2', { 'foo' => 'bar' });
%hash = $conf->parameter('NEW HASH 2');
$hash{foo} eq "bar" ?  print "ok $test\n" : print "not ok $test\n";
$test++;

# 5 new hash 2 with string value
$conf->parameter('NEW HASH 2', "bar => foo");
%hash = $conf->parameter('NEW HASH 2');
$hash{bar} eq "foo" ?  print "ok $test\n" : print "not ok $test\n";
$test++;

# 6 new hash 2 with list value
$conf->parameter('NEW HASH 2', [qw(foo bar roo)]);
%hash = $conf->parameter('NEW HASH 2');
$hash{foo} eq "bar" ?  print "ok $test\n" : print "not ok $test\n";
$test++;

# end 08_hash.t
