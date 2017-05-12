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
# insert job information into hash, key is the job-id
#
sub registerJobInformation($$) {
	my $group   = shift;
	my $hashref = shift;

	my $id = searchGroup( $group, "job-id" );
	if ( defined($id) ) {
		my $name        = searchGroup( $group, "job-name" );
		my $user        = searchGroup( $group, "job-originating-user-name" );
		my $state       = searchGroup( $group, "job-state" );
		my $impressions = searchGroup( $group, "job-impressions-completed" );
		my $uptime      = searchGroup( $group, "job-printer-up-time");
		if (not defined($impressions)) {
			$impressions = 0;
		}
		$hashref->{$id} = [ $id, $name, $user, $state, $impressions,$uptime ];
	}
}

###
# get completed and uncompleted jobs with IPP request.
#
# Parameter: $url - URL of printer
#  
# Return hash with all jobs of printer, indexed by job-id 
#
sub getAllJobs($) {
	my $url = shift;
	
	my %jobs;

	for ( my $i = 0 ; $i <= 1 ; $i++ ) {
		my $response = getJobs( $url, $i );

		if ( isSuccessful($response) ) {
			my $jobGroup = findGroup( $response, &JOB_ATTRIBUTES );
			while (defined($jobGroup) ) {
				registerJobInformation( $jobGroup, \%jobs );
				$jobGroup = findNextGroup( $response, &JOB_ATTRIBUTES );
			}
		} else {
			return undef;
		}
	}

	return \%jobs;
}

###
# compare currentJobs hash to previous hash returned by getAllJobs and
# print log line if any of the jobs changed.
#
# Parameter: $lastJobs - Hash from getAllJobs, previous job information
#         $currentJobs - Hash from getAllJobs, current job information
#
#
sub compareJobInformation($$) {
	my $lastJobs    = shift;
	my $currentJobs = shift;

	foreach my $jobId ( keys %{$currentJobs} ) {
		if ( exists( $lastJobs->{$jobId} ) ) {
			if ( $currentJobs->{$jobId}[4] != $lastJobs->{$jobId}[4] ) {
				printImpressionsChanged( $currentJobs->{$jobId} );
			}
			if ( $currentJobs->{$jobId}[3] != $lastJobs->{$jobId}[3] ) {
				printStateChanged( $currentJobs->{$jobId} );
			}
		}
		else {
			printNewJob( $currentJobs->{$jobId} );
		}
	}
}

sub printStateChanged($) {
	my $job = shift;
	print scalar localtime, "(", $job->[5],"): Job State changed: ID ", $job->[0], " New State: ", jobStateToString($job->[3]), "\n";
}

sub printImpressionsChanged($) {
	my $job = shift;
	print scalar localtime, "(", $job->[5],"): Completed Impressions changed: ID ", $job->[0], " Impressions completed: ", $job->[4], "\n";
}

sub printNewJob($) {
	my $job = shift;
	print scalar localtime, "(", $job->[5],"): New Job: ID ", $job->[0], ", \'", $job->[1], "\' from \'", $job->[2], "\' State: ", jobStateToString($job->[3]),"\n";
}

sub printConnectionError($) {
	my $url = shift;
	print scalar localtime, ": Cannot connect to $url.\n";
}

###
# MAIN
#

my $url      = shift(@ARGV);
my $interval = shift(@ARGV);

if ( not $url or not $interval ) {
	print "Usage: monitorJobs.pl [URL] [Interval]\n";
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
	print "Starting job monitoring for Printer: $name , Polling interval: $interval seconds.\n";
}

setRequestedAttributes(
	[
		"job-id",               "job-name",
		"job-originating-user-name", "job-impressions-completed",
		"job-state", "job-printer-up-time"
	]
);

my $lastJobs = "";
while (1) {
	my $currentJobs = getAllJobs($url);
	
	if (defined($currentJobs)) {
		if ($lastJobs) {
			compareJobInformation($lastJobs, $currentJobs);
		} 
		$lastJobs = $currentJobs;
	} else {
		printConnectionError($url);
	}

	sleep($interval);
}
