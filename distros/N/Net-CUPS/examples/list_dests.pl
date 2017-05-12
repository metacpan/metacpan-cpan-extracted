#!/usr/bin/perl

use strict;
use warnings;

##
##  This is an example of how to get all of the destinations on
##  the default server.
##

use Net::CUPS;
use Net::CUPS::Destination;

{
	my $cups = Net::CUPS->new();

	my @destinations = $cups->getDestinations();

	foreach( @destinations )
	{
		print $_->getName() ."\n";
	}

	exit( 0 );
}
