#!/usr/bin/perl

# Test of the ability to capture and display SNMP traffic.


# usage

# capturetest host <maxrep> <list of variables>
#

# Example:

# capturetest myrouter:::::2 25 ifDescr ifInOctets

use strict;

use FindBin;

use lib "/opt/mrtg-2.9.22dev/lib/mrtg2";

use SNMP_util;
use BER;


&main;


sub main
{
    my $router_connect = shift @ARGV;

    my $maxrepeaters = shift @ARGV;
    
    my @req_vars = @ARGV;

    
    my @buffer;


    my @result = snmpwalk($router_connect,
			  {
			      capture_buffer =>\@buffer,
			      return_array_refs => 1,
			      default_max_repetitions => $maxrepeaters
			  },
			 @req_vars
			 );

    print "Result is ", (join "\n\n",(map ((join ' ', @{$_}),@result))), "\n";
    print "Capture buffer contains ", (scalar @buffer), " entries.\n";
    for my $entry (@buffer)
    {
	print "\n";

	print pretty_print($entry), "\n";

    }

    print "\n";
}
