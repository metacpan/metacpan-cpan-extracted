###
# Copyright (c) 2004 Matthias Hilbig <bighil@cpan.org>
# All rights reserved.
# 
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.
#

package Net::IPP::IPPMethods;

use strict;
use warnings;

use Net::IPP::IPP qw(:all);
use Net::IPP::IPPRequest qw(:all);

require Exporter;
our @ISA = ("Exporter");
our @EXPORT_OK = qw(setRequestedAttributes getPrinterAttributes getJobs getJobAttributes);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $request_id = 0;
our $requestedAttributes = ["all"];

###
# Set requested attributes to use in IPP Requests.
#
# Parameter: $attribs - scalar or reference to array with requested attributes
#                       use setRequestedAttributes("all") to get every attribute
#
sub setRequestedAttributes($) {
  my $attribs = shift;

  if (ref($attribs) eq 'SCALAR') {
  		$requestedAttributes = [$attribs];
  } elsif(ref($attribs) eq 'ARRAY') {
	$requestedAttributes = $attribs;
  } else {
  	confess ("Expected scalar or reference to array");
  }
}

###
# Get Printer Attributes
#
# Parameter: $url - URL of printer object
#
# return: response to IPP request
#
sub getPrinterAttributes($) {
  my $url = shift;

  my $request = {
     &URL => $url,
     &REQUEST_ID => $request_id++,
     &OPERATION => &IPP_GET_PRINTER_ATTRIBUTES,
     &GROUPS => [
         {
	      &TYPE => &OPERATION_ATTRIBUTES,
	      "attributes-charset" => "utf-8",
	      "attributes-natural-language" => "en",
	      "printer-uri" => $url,
	      "requested-attributes" => $requestedAttributes,
	 }
     ]
  };

  return ippRequest($request);
}

###
# Get Jobs
#
# Parameter: $url - URL of printer object
#      $completed - 1 return completed jobs, 0 return only uncompleted jobs
#
# return: response to IPP request
#
sub getJobs($$) {
my $url = shift;
my $completed = shift;

if ($completed) {
  $completed = "completed";
} else {
  $completed = "not-completed";
}

my $request = {
    &URL => $url,
    &REQUEST_ID => $request_id++,
    &OPERATION => &IPP_GET_JOBS,
    &GROUPS => [
    		{
    			&TYPE => &OPERATION_ATTRIBUTES,
    			"attributes-charset" => "utf-8",
    			"attributes-natural-language" => "en",
    			"printer-uri" => $url,
    			"which-jobs" => $completed,
    			"requested-attributes" => $requestedAttributes,
    		}
    	]
    };

    return ippRequest($request);
}

###
# Get Job Attributes
#
# Parameter: $url - URL of printer object
#          $jobId - ID of job
#
# return: response to IPP request
#
sub getJobAttributes($$) {
my $url = shift;
my $jobId = shift;

my $request = {
    &URL => $url,
    &REQUEST_ID => $request_id++,
    &OPERATION => &IPP_GET_JOB_ATTRIBUTES,
    &GROUPS => [
    		{
    			&TYPE => &OPERATION_ATTRIBUTES,
    			"attributes-charset" => "utf-8",
    			"attributes-natural-language" => "en",
    			"printer-uri" => $url,
    			"job-id" => $jobId,
    			"requested-attributes" => $requestedAttributes,
    		}
    	]
    };

    return ippRequest($request);
}

###
# Print Job
#
# Parameter: $url - URL of printer object
#           $name - Name of print job
#           $user - User who submitted the print job
#         $format - Document format of print job (f.e. application/postscript)
#           $data - Data of print job
#
# return: response to IPP request
#
sub printJob($$$$$) {
my $url = shift;
my $name = shift;
my $user = shift;
my $format = shift;
my $data = shift;

my $request = {
    &URL => $url,
    &REQUEST_ID => $request_id++,
    &OPERATION => &IPP_PRINT_JOB,
    &DATA => $data,
    &GROUPS => [
    		{
    			&TYPE => &OPERATION_ATTRIBUTES,
    			"attributes-charset" => "utf-8",
    			"attributes-natural-language" => "en",
    			"printer-uri" => $url,
    			"requesting-user-name" => $user,
    			"document-format" => $format,
    			"document-name" => $name,
    			"requested-attributes" => $requestedAttributes,
    		}
    	]
    };
    
    return ippRequest($request);
}

1;
__END__

=head1 NAME

Net::IPP::IPPMethods - Wrapper Functions for Net::IPP::ippRequest()

=head1 FUNCTIONS

B<getPrinterAttributes($)>

Fetches attributes of a printer object.

B<getJobAttributes($$)>

Fetches attributes of a job object.

B<getJobs($)>

Fetches all jobs from printer object.

B<printJob($$$$)>

Prints job on printer object.

B<setRequestedAttributes($)>

Set requested attributes for all following IPPMethod function calls.

=cut

