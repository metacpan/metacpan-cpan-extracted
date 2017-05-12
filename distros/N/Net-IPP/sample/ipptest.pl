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

###
# Low level access to API: 
#   Create IPP Requests yourself and send them to the Printer.
#
# This sample asks for the printer attributes and for current and completed jobs
##

use Net::IPP::IPPRequest qw(:all);
use Net::IPP::IPPUtil qw(:all);
use Net::IPP::IPP qw(:all);

my $url = shift(@ARGV);
my $id = shift(@ARGV);

if (!$url or !$id) {
  print "Usage: ipptest.pl [PRINTER_URL] [ID]\n";
} else {
  testException();
  getPrinterAttributes($url);
  getCurrentJobs($url);
  getCompletedJobs($url);
  getJobAttributes($url, $id);
  #printTestPage();
}

###
# get Printer Attributes
#
sub getPrinterAttributes {
my $url = shift;

my $request = {
# this is the URL for the HTTP request
    &URL => $url,

# every IPP_REQUEST must have a request id. The response is 
# then returned with the same id. It seems the id does not 
# need to differ between different requests.
    &REQUEST_ID => 4,

# choose one of the many IPP operations
    &OPERATION => &IPP_GET_PRINTER_ATTRIBUTES,

# encode all required and optional attributes in a group
    &GROUPS => [
		# An IPP request can consist of many different groups.
		# The type of the group is encoded with the &TYPE key.
    		{
		        # So this is the OPERATION group. Most operations
		        # only need this group. All attributes that describe
		        # parameters for the IPP operations are found in 
		        # this group. The answer will be in a PRINTER_ATTRIBUTES
		        # group if you asked for the printer attributes or in the
		        # JOB_ATTRIBUTES group if you asked for job attributes.
    			&TYPE => &OPERATION_ATTRIBUTES,
		        
		        # the next two attributes are required in every IPP request
                # as they specify which charset and language all 
		        # attribute values are encoded with.
                # They also have to be the first two attributes in this 
		        # particular order (first the charset then the language).
		        #       
		        # The Perl IPP API guarantees that both attributes are 
		        # encoded in the right order and that both attributes 
                # are encoded with default values ("utf-8" and "en") if
                # you did not specify them. 
    			"attributes-charset" => "utf-8",
    			"attributes-natural-language" => "en",
		        
		        # most operations require an URI to the printer or job 
                # object the operation is directed at.
    			"printer-uri" => $url,
		        
		        # you can control which attributes should be returned
                # with the requested-attributes attribute. Only the attributes 
                # specified in the value are returned. Use this attribute
                # to conserve network bandwidth. 
    			# "requested-attributes" => ["printer-state", "printer-name"],
    		}
    	]
    };
    
    # now print a nice looking version of the request to the console
    print "GET PRINTER ATTRIBUTES REQUEST:\n\n";
    printIPP($request);
    
    # send the request ...
    my $response = ippRequest($request);
    
    # ... and look at the response
    print "\nGET PRINTER ATTRIBUTES RESPONSE:\n\n";
    printIPP($response);
}

#
# Get all completed jobs
#
sub getCompletedJobs {
my $url = shift;

my $request = {
    &URL => $url,
    &REQUEST_ID => 4,
    &OPERATION => &IPP_GET_JOBS,
    &GROUPS => [
    		{
    			&TYPE => &OPERATION_ATTRIBUTES,
    			"attributes-charset" => "utf-8",
    			"attributes-natural-language" => "en",
    			"printer-uri" => $url,
                        
                # in this request we use the attribute
                # "which-jobs" to specify which jobs should be returned
    			"which-jobs" => "completed"
    		}
    	]
    };
    
    print "GET JOBS REQUEST(completed):\n\n";
    printIPP($request);
    
    my $response = ippRequest($request);
    
    print "\nGET JOBS RESPONSE(completed):\n\n";
    printIPP($response);

    return $response;
}

#
# Get all current jobs
#
sub getCurrentJobs {
my $url = shift;

my $request = {
    &URL => $url,
    &REQUEST_ID => 4,
    &OPERATION => &IPP_GET_JOBS,
    
    &GROUPS => [
    		{
    			&TYPE => &OPERATION_ATTRIBUTES,
    			"attributes-charset" => "utf-8",
    			"attributes-natural-language" => "en",
    			"printer-uri" => $url,
                        # we only need the ids of the jobs
    			"requested-attributes" => "job-id"
    		}
    	]
    };
    
    print "GET JOBS REQUEST(current):\n\n";
    printIPP($request);
    
    my $response = ippRequest($request);
    
    print "\nGET JOBS RESPONSE(current):\n\n";
    printIPP($response);

    return $response;
}


sub getJobAttributes {
my $url = shift;
my $jobId = shift;

my $request = {
    &URL => $url,
    &REQUEST_ID => 4,
    &OPERATION => &IPP_GET_JOB_ATTRIBUTES,

    # the HP Laserjet 4100 does not return rfc conform
    # encoded TEXT_WITH_LANGUAGE and NAME_WITH_LANGUAGE 
    # attributes, you have to use &HP_BUGFIX => 1 to enable
    # the bugfix for this request. Of course the request will then 
    # only work with the HP printer or printers who have the same defect.
    #&HP_BUGFIX => 1,
    &GROUPS => [
    		{
    			&TYPE => &OPERATION_ATTRIBUTES,
    			"attributes-charset" => "utf-8",
    			"attributes-natural-language" => "en",
		        # job objects are addressed with a printer-uri
		        # attribute and a job-id or directly with
                # a job-uri attribute
    			"printer-uri" => $url,
    			"job-id" => $jobId
    		}
    	]
    };
    
    print "GET JOB ATTRIBUTES REQUEST:\n\n";
    printIPP($request);
    
    my $response = ippRequest($request);
    
    print "\nGET JOB ATTRIBUTES RESPONSE:\n\n";
    printIPP($response);
}

###
# Test exception handling
#
# This function shows how to handle exceptions.
#

# The signal handler for API warnings.
# We will use this function later on, it simply 
# prints all warnings it catches.
sub warnHandler {
	print "Catched Warning: $_[0]";
}

sub testException {

print "EXCEPTION HANDLING:\n";

# first build an invalid IPP request. In this example the request ID and Operation ID are
# missing
my $request = {
    &URL => $url
    };
  
    # with eval you can catch exceptions.
    my $response = eval {ippRequest($request);};
    
    # if an exception occurs $@ will be set to a non-null value 
    if ($@) {
    	# As the IPP request was invalid this line should be printed to the terminal.
    	print "This should be a warning about a missing request ID: $@";
    } else {
    	# This line should never get printed.
    	print "This shouldn't happen!!\n";
    }

# Next we want to produce a warning. 
# For that reason we are going to use an attribute whose type is not a registered
# IPP type.
$request = {
    &URL => $url,
    &REQUEST_ID => 5,
    &OPERATION => &IPP_GET_PRINTER_ATTRIBUTES,
    &GROUPS => [
    		{
    			&TYPE => &OPERATION_ATTRIBUTES,
    			"attributes-charset" => "utf-8",
    			"attributes-natural-language" => "en",
    			"printer-uri" => $url,
    			"some-attribute" => {&TYPE=>0xff, # invalid IPP type
    								&VALUE => "test"},
    		}
    	]
    };
    
    # register warning handler
    $SIG{__WARN__} = \&warnHandler;
    
    $response = ippRequest($request);
	
	$SIG{__WARN__} = 'DEFAULT'; # reset signal handler
	
	#printIPP($response);
	
	if ($@) {
		print "This warning shouldn't be there: $@";
	} else {
		print "Ok, no error occured. But a warning should have been catched in the line above.\n\n";
	}
}

###
# Now the obligatory "Hello World!" example with IPP.
#
# This function is not enabled by default, to conserve paper...
#
sub printTestPage {
my $url = shift;

my $request = {
    &URL => $url,
    &REQUEST_ID => 4,
    &OPERATION => &IPP_PRINT_JOB,
    # you can give additional data for the IPP request with
    # the &DATA key. This is for example needed to print 
    # Documents.
    &DATA => "Hello World!",
    &GROUPS => [
    		{
    			&TYPE => &OPERATION_ATTRIBUTES,
    			"attributes-charset" => "utf-8",
    			"attributes-natural-language" => "en",
    			"printer-uri" => $url,

                # The requesting-user-name is required
		        # for the IPP_PRINT_JOB operation. 
    			"requesting-user-name" => "root",

		        # Printers support different types of 
                # document formats. As we want to print 
                # text we have to use the MIME type "text/plain" 
                # here. 
    			"document-format" => "text/plain",

		        # Every job needs a name
    			"document-name" => "test-page"
    		}
    	]
    };
    
    print "PRINT REQUEST:\n\n";
    printIPP($request);
    
    my $response = ippRequest($request);
    
    print "\nPRINT RESPONSE:\n\n";
    printIPP($response);
}
