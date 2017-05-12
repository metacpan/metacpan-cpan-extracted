#!/usr/bin/perl
#
# Copyright (c) 2004 Matthias Hilbig <bighil@cpan.org>
# All rights reserved.
# 
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.
#

use strict;
use warnings;

use Net::IPP::IPPMethods qw(:all);
use Net::IPP::IPPUtil qw(:all);
use Net::IPP::IPP qw(:all);

###
# Uses function from Net::IPP::IPPMethods to send IPP Request.
#
# This sample asks the printer for its attributes and prints the most
# important attributes.
#
###

my $url = shift(@ARGV);

if ($url) {
    # use IPPMethods::getPrinterAttributes to get the printer attributes
	my $response = getPrinterAttributes($url);

	# look if IPP request was successful
	if (isSuccessful($response)) {
	  
	    # search for the name of the printer, this attribute should
	    # exist because "printer-name" is a required attribute
		my $value = findAttribute($response, "printer-name");
		if (defined($value)) {
			print "--- Printer: $value ---\n";
		}
		
		# search and print all IPP Versions this printer supports.
		# currently there are only IPP versions 1.0 and 1.1. Most
		# printers should support 1.1 and if they support 1.1 they 
		# also have to support 1.0
		$value = findAttribute($response, "ipp-versions-supported");
		if (defined($value)) {
		  print "\nSupported IPP Versions: ";
			foreach my $version (@{$value}) {
				print $version, " ";
			}
			print "\n";
		} else {
			print "\nIPP Version used in Response: ", $response->{&VERSION}, "\n";
		}
		
		# Different printers support different sets of operations.
		# The getPrinterAttributes Operation and the operations-supported
		# attribute are required, so you can use these two to find out 
		# which operations the printer supports.
		$value = findAttribute($response, "operations-supported"); 
		if (defined($value)) {
			print "\nSupported Operations:\n";
			foreach my $operation (@{$value}) {
				print "    ", operationToString($operation), "\n";
			}
			print "\n";
		}
		
		# every printer can be in three different states:
		# IDLE, PROCESSING and STOPPED
		# - the state STOPPED may signal an error condition.
		# - the reason for the state is found in the printer-state-reasons
		# attribute.
		$value = findAttribute($response, "printer-state");
		if (defined($value)) {
			print "Current printer status: ", printerStateToString($value);
			$value = findAttribute($response, "printer-state-reasons");
			if (defined($value)) {
				print " Reason: ", $value;
			} 
			print "\n";
		}
		
		# the queued-job-count simply counts the number of jobs
		# the printer is currently processing
		$value = findAttribute($response, "queued-job-count");
		if (defined($value)) {
		  print "\nNumber of currently queued jobs: $value\n";
		}
	} else {

	    # if the request was not successful, it can be 
	    # an HTTP error or an IPP request error (look for the STATUS
	    # of the IPP response)
		print "Request not successful.\n";
		print "HTTP code: ", $response->{&HTTP_CODE}, "\n";
		print "HTTP message: ", $response->{&HTTP_MESSAGE}, "\n";
		printIPP($response);
	}
	
} else {
	print "Usage: printerAttributes.pl [URL]\n";
}

