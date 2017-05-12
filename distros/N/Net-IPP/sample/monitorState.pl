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
# Return current status of printer
#
# Parameter: $url - Printer URL
#
# Return: reference to array [printer-state, printer-state-reasons, printer-is-accepting-jobs]
#
sub getCurrentState($) {
	my $url = shift;
	
	my $response = getPrinterAttributes($url);

	my $printerState = "unknown";
	my $reasons = "unknown";
	my $isAccepting = "0";
	my $uptime = -1;
	my $jobs = 0;
	
	if (isSuccessful($response)) {
		my $value;
		$value = findAttribute($response, "printer-state");
		if (defined($value)) {
			$printerState = printerStateToString($value);
		}
		
		$value = findAttribute($response, "printer-state-reasons");
		if (defined($value)) {
			if (ref($value) eq 'ARRAY') {
				foreach my $reason (@{$value}) {
					$reasons .= " " . $reason;
				}
			} else {
				$reasons = $value;
			}
		}
		
		$value = findAttribute($response, "printer-is-accepting-jobs");
		if (defined($value)) {
			$isAccepting = $value;
		}
		
		$value = findAttribute($response, "printer-up-time");
		if (defined($value)) {
			$uptime = $value;		
		}
		
		$value = findAttribute($response, "queued-job-count");
		if (defined($value)) {
			$jobs = $value;
		}
		
	} else {
		return undef;
	}
	return [$printerState, $reasons, $isAccepting, $uptime, $jobs];
}

###
# Output log line
#
# Parameter: $status - reference to array as returned by getCurrentStatus()
#
sub printStateChanged($) {
	my $status = shift;
	
	print scalar localtime, " (", $status->[3], "): New State: ", $status->[0], ", Reason: ", $status->[1], "\n";
}

sub printAcceptingChanged($) {
	my $status = shift;
	
	print scalar localtime, " (", $status->[3], "): Now ", ($status->[2])?"":"not ", "accepting jobs.\n";

}

sub printJobCountChanged($) {
	my $status = shift;
	
	print scalar localtime, " (", $status->[3], "): New queued job count: ", $status->[4], "\n";

}

sub printConnectionError($) {
	my $url = shift;
	print scalar localtime, ": Cannot connect to $url.\n";
}


###
# MAIN
#

my $url = shift(@ARGV);
my $interval = shift(@ARGV);

if (not $url or not $interval) {
	print STDERR "Usage: monitorState.pl [URL] [Interval]\n";
	exit(1);
}

my $response = getPrinterAttributes($url);

if (!isSuccessful($response)) {
	print STDERR "Could not get Name of Printer.\n";
	if ($response->{&HTTP_CODE} != 200) {
		print STDERR "HTTP code: ", $response->{&HTTP_CODE}, "\n";
		print STDERR "HTTP message: ", $response->{&HTTP_MESSAGE}, "\n";
	} else {
		print STDERR "IPP error: ", statusToDetailedString($response->{&STATUS}), "\n"; 
	}
	exit(1);
}
	
my $name = findAttribute($response, "printer-name");
		
if (defined($name)) {
	print "Starting monitoring for Printer: $name , Polling interval: $interval seconds.\n";
}

setRequestedAttributes(["printer-state", "printer-state-reasons", "printer-is-accepting-jobs", "printer-up-time", "queued-job-count"]);	

my $lastStatus = "";
while (1) {
	my $currentStatus = getCurrentState($url);
	
	if (defined($currentStatus)) {
		if ($lastStatus) {
			if (($currentStatus->[0] ne $lastStatus->[0])
			or ($currentStatus->[1] ne $lastStatus->[1])) {
				printStateChanged($currentStatus);
			} 
			if ($currentStatus->[2] ne $lastStatus->[2]) {
				printAcceptingChanged($currentStatus);
			}
			if ($currentStatus->[4] ne $lastStatus->[4]) {
				printJobCountChanged($currentStatus);
			}
		}
	} else {
		printConnectionError($url);
	} 
	$lastStatus = $currentStatus;
	sleep($interval);
}
		

