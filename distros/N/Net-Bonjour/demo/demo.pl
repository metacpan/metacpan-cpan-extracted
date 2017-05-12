#!/usr/bin/perl

use Net::Bonjour;

my $res = new Net::Bonjour( @ARGV );
print $res->domain(), "\n";
$res->discover;

foreach $entry ( $res->entries ) {
	printf "%s %s:%s\n",  $entry->name, $entry->hostname, $entry->port;
}
