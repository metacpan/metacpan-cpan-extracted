#!/usr/local/bin/perl
$|=1;
use Net::Whois::IP qw(whoisip_query);

LOOP:while(<>) {
	chomp;
        my $ip = $_;
	print "$ip\n";
        my $response = whoisip_query($ip,1);
	foreach (sort keys(%{$response}) ) {
		print "|$_| \n";
		foreach my $resp (@{$response->{$_}}) {
			print "$resp|";
		}
		print "\n";
	}
	print "------------------------\n\n";
}
