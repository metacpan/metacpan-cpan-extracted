#!/usr/local/bin/perl
$|=1;
use Net::Whois::IP qw(whoisip_query);
use IP::Country::Fast;

LOOP:while(<>) {
	chomp;
        my $ip = $_;
	print "$ip\n";
        my $reg = IP::Country::Fast->new();
	my $country = $reg->inet_atocc($ip);
	if(defined($country)){
		print "$country\n";
	}

        my $response = whoisip_query($ip);
	foreach (sort keys(%{$response}) ) {
#	print "$response->{'owner'}\n";	
		print "|$_| ==> $response->{$_} \n";
	}
	print "------------------------\n\n";
}
