# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use Net::GrpNetworks;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$ntest = 1;

my $test = new Net::GrpNetworks();
$ntest++;
if ( $test->add("GROUP-1", "200.200.200.0", "255.255.255.0") )
   { print "ok $ntest\n"; }
  else
   { print "not ok $ntest\n"; }

$ntest++;
if ( $test->add("GROUP-1", "200.200.208.128", "255.255.255.128") )
   { print "ok $ntest\n"; }
  else
   { print "not ok $ntest\n"; }

$ntest++;
if ( $test->add("GROUP-2", "200.200.204.0", "255.255.254.0") )
   { print "ok $ntest\n"; }
  else
   { print "not ok $ntest\n"; }

$ntest++;
if ( ($grp = $test->find("200.200.200.3")) eq 'GROUP-1' )
   { print "ok $ntest\n"; }
  else
   { print "not ok $ntest\n"; }

 
exit;

 
