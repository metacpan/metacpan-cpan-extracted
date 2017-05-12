# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..last_test_to_print\n"; }
END {print "not ok 1\n" unless $loaded;}
use Net::DLookup;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use constant CLASS => "Net::DLookup";

print "Enter complete domain name to check:  ";
my $domain = <>;
chomp $domain;

# Initialize Net::DLookup object
my $dlu = Net::DLookup -> new;

# Replace domain definitions from a file
# $dlu -> LoadTLD($file, 1);
# Add domain definitions from a file
# $dlu -> LoadTLD($file, 0);

# Check domain name validity and assign it to the object
@errors = $dlu -> IsValid($domain);

if (@errors){
	print $_,"\n";
}
else {
	my ($registered,$registra,$registraurl,$whoisserver,$whoisoutput,$response,$tld) = $dlu->DoWhois(1);
	print $response;
	print "\nRegistrar:\t\t$registra\n\n$whoisoutput\n\n";
	
}
exit;