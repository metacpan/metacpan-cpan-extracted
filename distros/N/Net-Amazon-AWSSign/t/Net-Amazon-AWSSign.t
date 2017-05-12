# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-Amazon-AWSSign.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { use_ok('Net::Amazon::AWSSign') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $testKey="00000000000000000000";
my $testSecret="1234567890";
my $aws=new Net::Amazon::AWSSign("$testKey", "$testSecret");

#Rest
my $testUri="http://ecs.amazonaws.com/onca/xml?Service=AWSECommerceService&Version=2009-03-31&Operation=ItemSearch&SearchIndex=Books&Keywords=harry+potter&Timestamp=2009-10-15T13:34:06Z";
my $signedUri=$aws->addRESTSecret($testUri);
ok ($signedUri=~m/0iuZwpjlGArV7MyuU0kvzHFkf2wBjhMo6poKZvr0eV4/, 'Signed a REST query' );

#Soap and timestamp
# Can't really test this since the Timestamp is a pretty critical part of the function!
# On the other hand, if the REST works then this really ought to work as well
my ($testTimestamp, $testSoap)=$aws->SOAPSig('ItemSearch');
open (OUTFILE, ">/tmp/awstest.out");
print OUTFILE "testTimestamp is $testTimestamp\n";
print OUTFILE "length is ", length($testTimestamp), "\n";
print OUTFILE "testSoap is $testSoap\n";
print OUTFILE "length is ", length($testSoap), "\n";
close OUTFILE;
ok (length($testSoap)==44);
ok (length($testTimestamp)==24);
ok ($testTimestamp=~m/^2.*Z$/);
