#!/usr/bin/perl

# ABSTRACT: SHA-256 hashing tests for Net::Google::SafeBrowsing4::URI class

use strict;
use warnings;

use Test::More 0.92 qw(no_plan);

use Net::Google::SafeBrowsing4::URI;


my %uris = (
	# Same URI with different scheme should result the same SHA-256
	'http://google.com/?query=&param=data' => '59229a9f8fafeab4cf7de06a6b34f78a5c9ac4a2116e73f915b0f4994ba5a389',
	'https://google.com/?query=&param=data' => '59229a9f8fafeab4cf7de06a6b34f78a5c9ac4a2116e73f915b0f4994ba5a389',
);

foreach my $uri (sort(keys(%uris))) {
	my $gsb_uri = Net::Google::SafeBrowsing4::URI->new($uri);
	my $hash = unpack("H*", $gsb_uri->hash());
	is($hash, $uris{$uri}, "Hash URI '". $uri ."'  to '". $uris{$uri} ."' (got: '". $hash ."')");
}
