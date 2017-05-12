#!/usr/local/bin/perl -w

use Net::Whois::IP qw(whoisip_query);

print "1..5\n";

my $i=1;
my @ips = ("144.134.121.81","209.73.229.163","200.52.173.3","211.184.167.213","80.105.135.82");

foreach my $ip (@ips) {
        my $response = whoisip_query($ip);
	if(ref($response) eq "HASH") {
		printf "ok %d\n",$i++;
	}else{
		print "not";
	}
}


