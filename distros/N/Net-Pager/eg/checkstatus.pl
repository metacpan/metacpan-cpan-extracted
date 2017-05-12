#!/usr/bin/perl

use Net::Pager;
use Net::Pager::Request;
use Net::Pager::Response;


######################################################################
# Note that you will have had to do a sendpage and get a TICKET_ID
# back for you to check with.
######################################################################

# New pager object
my $pager = Net::Pager->new();


# New request object
my $r = new Net::Pager::Request;

# Set the type of request to perform
$r->set_checkstatus;

# Set the ticket id to check.
$r->ticket_id("D9VZ1-3MTWX-28UM0-8H1L7");

# Request it.
$response = $pager->request($r);

# Check it and NOTE
if ($response->is_success) {
    print "\n###################################\n";
	print "Success!\n";
    print "The status code: " . $response->status_description . "\n";
    print "The status description: " . $response->status_description . "\n";
} else {
    print "\n###################################\n";
   	print "Error occurred!\n";
    print "Error Code: " . $response->error_code . "\n";
	print "Error Description: " . $response->error_description . "\n";
}




