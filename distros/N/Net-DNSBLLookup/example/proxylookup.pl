#!/usr/bin/perl -I./lib

use strict;

use Net::DNSBLLookup;

my $dnsbl = Net::DNSBLLookup->new(timeout => 1);

my $res = $dnsbl->lookup($ARGV[0]);

my ($proxy, $spam, $unknown) = $res->breakdown;

my $num_responded = $res->num_proxies_responded;

my $proxy_score = ($proxy + $unknown/2) * 10 / $num_responded;
my $spam_score = ($spam + $unknown/2) * 10 / $num_responded;

print "lookup of $ARGV[0] resulted in proxy score $proxy_score and spam score $spam_score\n";
