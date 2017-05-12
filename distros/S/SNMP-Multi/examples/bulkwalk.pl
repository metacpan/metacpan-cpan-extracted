#!/usr/local/bin/perl -w
#
# $Id: bulkwalk.pl,v 1.1.1.1 2003/12/18 01:16:52 toni Exp $
#
# This is an example of using the 'bulkwalk' functionality of the SNMP::Multi
# module.  This script queries the hosts 'router1.my.com' and 'router2.my.com'
# for the sysUpTime.0 and sysContact.0 non-repeater variables, as well as the
# 'ifInOctets' and 'ifOutOctets' subtree on each host.
#
# Remember that GETBULK works like GETNEXT -- if you want the first instance
# of a tag (i.e. 'sysUpTime.0'), you must ask for the preceeding tag (the
# branch 'sysUpTime', in this case).
#
# Note that the response contains one SNMP::VarList for each requested Varbind.
#
use strict;
use Carp;

use SNMP::Multi;

my $comm  = 'super!secret';			  # SNMP community string
my @hosts = qw/ router1.my.com router2.my.com /;  # List of hosts to query

# Build a VarReq for the hosts we wish to query.  This request asks for
# the sysUpTime.0 and sysContact.0 vars, as well as a list of the in and
# out octet counts for every interface.  The request is the same for both
# hosts.
#
my $req = SNMP::Multi::VarReq->new (
    nonrepeaters   => 2,
    maxrepetitions => 100,
    hosts          => [ @hosts ],
    vars           => [ [ 'sysUpTime' ],  [ 'sysContact'  ],	# Non-repeaters
	                [ 'ifInOctets' ], [ 'ifOutOctets' ] ]	# Repeated vars
) or croak "VarReq: $SNMP::Multi::VarReq::error\n";

# Create an SNMP::Multi object to do the work.  This will be a "bulkwalk"
# object, so we have to use SNMP v2c.
#
my $sm = SNMP::Multi->new (
    Method	=> 'bulkwalk',
    Community	=> $comm,
    Version	=> '2c',
    Timeout	=> 5
) or croak "$SNMP::Multi::error\n";

# Hand the host/variable request structure into the SNMP::Multi object.  It
# could also have done in the SNMP::Multi::new() invocation above.
#
$sm->request($req) or die $sm->error;

# Now go out and make the requests to the hosts.  The execute() method will
# return after either 15 seconds has elapsed, or a response has been received
# for all of the requests in the VarReq.
#
my $response = $sm->execute(15) or croak "$SNMP::Multi::error\n";

# Now unpack the Response object.  Note that lists of the returned values for
# any part of the Response tree can be retrieved through the values() methods
# of the various objects in the Response.
#
print "Got responses for ", (join ' ', $response->hostnames), ":\n";

# This is rather noisy, but a good example...
# print map { "\t$_\n" } $response->values();

for my $host ($response->hosts()) {
    print "Results for $host: \n";	# $host will stringify to the hostname.

    for my $result ($host->results()) {
	# If there was an error on this set of requests, print it and go to
	# the next request Result.
	#
	if ($result->error()) {
	    print "Error: ", $result->error(), "\n";
	    next;
	}

	# Dump the values of all requests for the host.  Again, this is
	# just an example of what could be done.
	#
	# print "Values for $host: ", map { "\t$_\n" } $result->values();

	# Print the variables returned by the agent on the host.  This is
	# much easier to read than the values() output above.  $varist is
	# an SNMP::VarList as returned by SNMP.pm.
	#
	for my $varlist ($result->varlists()) {
	    print "VarList:\n", map { "\t" . $_->fmt() . "\n" } @$varlist;
	}
	print "\n";
    }
}

exit 0;
