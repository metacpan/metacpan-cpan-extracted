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
# Uses functions from Net::IPP::IPPMethods to send IPP Requests.
#
# This sample asks the printer for completed and not-completed jobs and prints
# some informations for each found job.
#
###

my $url = shift(@ARGV);

if ($url) {

  # use IPPMethod::getJobs function to get all jobs that are not completed
  my $response = getJobs($url,0);
  print ("***NOT-COMPLETED Jobs for URI $url***\n");
  printJobs($response);

  # get all completed jobs
  $response = getJobs($url,1);
  print ("***COMPLETED Jobs for URI $url***\n");
  printJobs($response);
} else {
  print "Usage: showJobs.pl [URL]\n";
}

sub printJobs {
  my $response = shift;

  # look if IPP Request was successful
  if (isSuccessful($response)) {

    my @jobIds;

    # search for job-id attribute in IPP Request
    my $value = findAttribute($response, "job-id");
    while (defined($value)) {

      # push all found Ids of jobs unto the array jobIds 
      push @jobIds, $value;
      $value = findNextAttribute($response, "job-id");
    }

    # for each found job print the most important attributes
    foreach my $id (@jobIds) {
      printJobAttributes($url, $id);
    }

  } else {
    print "Request not successful.\n";
    print "HTTP code: ", $response->{&HTTP_CODE}, "\n";
    print "HTTP message: ", $response->{&HTTP_MESSAGE}, "\n";
    printIPP($response);
  }
}

sub printJobAttributes {
  my $url = shift;
  my $id = shift;

  # start another IPP request to get more attributes for this job
  my $response = getJobAttributes($url, $id);

  # again look if the request was successful
  if (isSuccessful($response)) {

    # if it was successful, look for required attributes:
    # job-name: Name of job
    # job-originating-user-name: User who submitted this job
    # job-state: state of job
    # job-state-reasons: reasons for the current state of this job
    #

    my $name = findAttribute($response, "job-name");
    my $user = findAttribute($response, "job-originating-user-name");
    
    if (defined($name) and defined($user)) {
      print "\nJOB $id: \"$name\" from $user\n";
    }

    my $state = findAttribute($response, "job-state"); 
    if (defined($state)) {
      print "state: ", jobStateToString($state), "\n";
    }

    my $reason = findAttribute($response, "job-state-reasons");
    if (defined($reason)) {
      print "reason: $reason\n";
    }
  } else {
	print "Request not successful.\n";
	print "HTTP code: ", $response->{&HTTP_CODE}, "\n";
	print "HTTP message: ", $response->{&HTTP_MESSAGE}, "\n";
	printIPP($response);
  }
}
