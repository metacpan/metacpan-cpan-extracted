# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..14\n"; }
END {print "not ok 1\n" unless $loaded;}
use Ph;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

#
# Note - these tests are designed to be run from a host with
# internet access.  If you don't have internet access edit
# the lines below to provide the names of some servers you do
# have access to.
#
$server1 = "ns.sdsu.edu";
$port1 = "ns(105)";
$server2 = "ns.uiuc.edu";
$port2 = "ns(105)";

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):


$ph1 = Ph->new();
$ph2 = Ph->new();

# test #2: try connecting to a known invalid port
print "not " if ($ph1->Connect("127.0.0.1", "nosuchport"));
print "ok 2\n";

# test #3
print "not " if ($ph2->Connect("nosuchhost", "25"));
print "ok 3\n";

# test #4 -- try a real connection (this may fail inside firewalls)
print "not " unless ($ph1->Connect($server1, $port1));
print "ok 4\n";

# test #5 -- now try setting up a second independent connection
print "not " unless ($ph2->Connect($server2, $port2));
print "ok 5\n";

# tests 6 & 7 -- check for maildomains -- we check each one independently
# we don't check that they are different, because we can't verify that
# the $server1 and $server2 are in different domains.
%siteinfo1 = $ph1->SiteInfo();
print "not " unless ($server1 =~ /$siteinfo1{maildomain}$/i);
print "ok 6\n";
%siteinfo2 = $ph2->SiteInfo();
print "not " unless ($server2 =~ /$siteinfo2{maildomain}$/i);
print "ok 7\n";

# disconnect session 2, we've proven our point
$ph2->Disconnect();

# tests 8 & 9 -- now check the field configurations
%fields = $ph1->Fields();
# all sites should have "name" set to be lookup-able
print "not " unless (defined ($fields{name}->{Lookup}));
print "ok 8\n";

# and this should be a nonzero max length
print "not " unless ($fields{name}->{max} > 0);
print "ok 9\n";

# test 10 involves doing an actual queries
# all schools have an admissions department
@results = $ph1->Query(  [ "name=admissions" ] );
print "not " unless (defined ($results[0]->{name}));
print "ok 10\n";
%query = ( "name" => "admissions");
@results = $ph1->Query(  \%query );
print "not " unless (defined ($results[0]->{name}));
print "ok 11\n";

# i'd like to test add, delete, and change functionality, but
# that implies having sufficient privileges to the ph server.
# sorry -- these go untested...

# test login (should fail!)
print "not " if $ph1->Login("bogususer", "boguspassword");
print "ok 12\n";

# tests 12 & 13, make sure we can't use the closed session #2
print "not " if $ph2->IsConnected();
print "ok 13\n";

%fields = $ph2->Fields();
print "not " if (int($ph2->GetLastCode() / 100) == 2);
print "ok 14\n";

# all looks good, bail out
