#!/usr/bin/perl

use Net::Bonjour;

foreach my $res ( Net::Bonjour->all_services($ARGV[0] || 'local') ) {
        printf "-- %s (%s) ---\n", $res->service, $res->protocol;
	$res->discover;
	foreach my $entry ( $res->entries ) {
		printf "\t%s (%s:%s)\n", $entry->name, $entry->address, $entry->port;	
	}
}
