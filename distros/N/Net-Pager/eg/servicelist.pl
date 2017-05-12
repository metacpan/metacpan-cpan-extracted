#!/usr/bin/perl

use Net::Pager;
use Net::Pager::Request;
use Net::Pager::Response;


# Look at the other examples files, i'm sure you get that you create
# an object, then a request, form the request and the send it.
my $pager = Net::Pager->new();

my $r = new Net::Pager::Request;
$r->set_servicelist;



######################################################################
# Set the optional parameters for the servicelist request
######################################################################

######################################################################
# This option determines what services get passed back.  The choices
# are "production" which is the default, "discontinued" for
# the services that went out of business, and "development" for development
# services.
######################################################################
$r->option_type("production");

######################################################################
# This option determines what fields get passed back for each service
# the choices are "all" which is the default if nothing is set or
# "selectbox" which provides only enough fields to populate a
# select box on a website.  "selectbox" will pass back the service id,
# Title, and SubTitle for each service.
######################################################################
$r->option_fields("all");


# Send the request now
$response = $pager->request($r);


if ($response->is_success) {
    print "\n###################################\n";
	print "Success!\n";
    print "Error Code: " . $response->error_code . "\n";
	print "Error Description: " . $response->error_description . "\n";
} else {
    print "\n###################################\n";
   	print "Error occurred!\n";
    print "Error Code: " . $response->error_code . "\n";
	print "Error Description: " . $response->error_description . "\n";
}


######################################################################
# Grab all the services and plop them into an array of hashes
######################################################################
@services = $response->fetchall_services();

foreach $ser (@services) {
    print $ser->{ID} . "\n";
}


######################################################################
# Grab a row at a time into a hash
######################################################################
print "\n Now using the dbi style \n";

while ($row = $response->fetchrow_service) {

    foreach $var (keys %{ $row }) {
        print $row->{$var} . "\t";
    }

    print "\n";

}

######################################################################
# Rewind the position of the last function call to the beginning
######################################################################
$response->fetchrow_rewind;

