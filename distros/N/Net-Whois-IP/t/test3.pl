#!/usr/local/bin/perl
$|=1;
use Net::Whois::IP qw(whoisip_query);

LOOP:while(<>) {
	chomp;
        my $ip = $_;
	print "$ip\n";
	my $search_options = ["NetName","OrgName"];
        my $response = whoisip_query($ip,"",$search_options);
	foreach (sort keys(%{$response}) ) {
		print "|$_|-|$response->{$_} \n";
	}
	print "------------------------\n\n";
}
