# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Net::Whois::IP;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
#!/usr/local/bin/perl -w

use Net::Whois::IP qw(whoisip_query);

print "1..4\n";

my $i=1;
my @ips = ("209.73.229.163","200.52.173.3","211.184.167.213","80.105.135.82","196.218.159.212");
my $ok = 1;
foreach my $ip (@ips) {
        my $response = whoisip_query($ip);
        if(ref($response) ne "HASH") {
		$ok=0;
                print "not ";
        }
        printf "ok %d\n",$i++;
}
if($ok == 1) {
	print "    Things seem OK!\n";
}else{
	print "    Things seem broken.  Do you have internet access?\n";
}
