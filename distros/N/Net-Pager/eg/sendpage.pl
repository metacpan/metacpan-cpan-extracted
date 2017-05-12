#!/usr/bin/perl

use Net::Pager;
use Net::Pager::Request;
use Net::Pager::Response;



######################################################################
# Create a new pager object
######################################################################

my $pager = Net::Pager->new();

######################################################################
# Create a new Net::Pager::Request object from which we will form
# our request to send to simplewire.
######################################################################
my $r = new Net::Pager::Request;

# For purposes of this exmample, we will only be requesting a sendpage
# The other files cover the other requests you can perform.
$r->set_sendpage;


######################################################################
# Set the subscriber information.  SimpleWire is free for moderate use,
# but we still ask you to retrieve a subscriber code form our website.
# Check out www.simplewire.com to get one.
######################################################################
$r->subscriber_id("TES-TTE-STT-EST");


######################################################################
# Set the IP Address of the person you are peforming this request on
# the behalf of.  For example, if this client is being used on a
# website and a websurfer is asking for a page, then please insert
# their IP with this call.
######################################################################
$r->user_ip("56.78.90.45");


######################################################################
# Set the options for this request, which are specific to sendpage
######################################################################

# This overrides simplewire's default delimiter of the " |" to seperate
# a callback, from, and text in the final message sent to users.
$r->option_delimiter("\$");

#!!!!!
# This allows you to send asynchronous or sychronous pages thru
# simplewire.  synch will wait for the server to connect to the final
# service and send the page off.  This gives instant feedback on the
# success or failure of a page.  However, its been know to cause some
# timeout issues.  Guranteed faster delivery is with the asynch property.
# asynch will send the message, do as much error checking as possible
# before sending out the final message.  A TICKET_ID can later be used
# to see what the final status of that message was.
$r->option_method("synch");


######################################################################
# Set the parameters necessary to send a page
######################################################################

# Instead of having to set both the service id and a pin, you can
# also send it to an alias.
$r->alias('email@domain.com');

# However, this will screw up our test script, b/c that is not
# a true alias
$r->alias(undef);

# The service id is proprietary to simplewire and you will have to
# check out our service list via our website (www.simplewire.com) or
# by checking out our servicelist.pl script.
$r->service_id(2);

# These should be pretty intuitive.  However, some of these parameters
# are optional based on the service.  Also the PIN can sometimes get
# a little weird -- like for PageNet.  Check out www.simplewire.com
# for our tech details about each service we support.
$r->pin("1234567890");
$r->from("Joe Lauer");
$r->callback("9876543210");
$r->text("Hello World From Net::Pager 2.00");

# Send the request off and get a Net::Pager::Response object back.
$response = $pager->request($r);


######################################################################
# Check out what happened.
######################################################################
if ($response->is_success) {
    print "\n###################################\n";
	print "Success!\n";
    print "Error Code: " . $response->error_code . "\n";
	print "Error Description: " . $response->error_description . "\n";
    print "Your ticket number is: " . $response->ticket_id . "\n";
} else {
    print "\n###################################\n";
   	print "Error occurred!\n";
    print "Error Code: " . $response->error_code . "\n";
	print "Error Description: " . $response->error_description . "\n";
}




