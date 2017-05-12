#!/usr/local/bin/perl -w
#
# $Id: set.pl,v 1.1.1.1 2003/12/18 01:16:52 toni Exp $
#
# An example of using SNMP::Multi for 'set' operations on a set of hosts.
#
use strict;
use Carp;

use SNMP::Multi;

my $wcomm  = 'secret!write';	# SNMP write community string

# Build up a VarReq containing a SET request for each of several hosts.
# This request will contain the values for 'sysLocation.0' and 'sysContact.0'
# variables, which are different for each host.
#
# Setting autovalidate will cause the request to be validated each time the
# add() method is called.  This can be a bit excessive, so put it off to the
# end when the VarReq is fully populated.
#
# $SNMP::Multi::VarReq::autovalidate = 1;

my $req = SNMP::Multi::VarReq->new( ) 
    or croak "VarReq: $SNMP::Multi::VarReq::error\n";

$req->add(hosts =>   [ 'portland.our.com' ], 
	  vars  => [ [ 'sysLocation', '0', 'Portland, OR',     'OCTETSTR' ],
		     [ 'sysContact',  '0', 'portland@our.com', 'OCTETSTR' ] ])
      or croak $req->error() . "\n";

$req->add(hosts =>   [ 'seattle.our.com' ], 
	  vars  => [ [ 'sysLocation', '0', 'Seattle, WA',      'OCTETSTR' ],
		     [ 'sysContact',  '0', 'seattle@our.com',  'OCTETSTR' ] ])
      or croak $req->error() . "\n";

$req->add(hosts =>   [ 'dallas.our.com' ], 
	  vars  => [ [ 'sysLocation', '0', 'Dallas, TX',       'OCTETSTR' ],
		     [ 'sysContact',  '0', 'dallas@our.com',   'OCTETSTR' ] ])
      or croak $req->error() . "\n";

$req->add(hosts =>   [ 'boston.our.com' ], 
	  vars  => [ [ 'sysLocation', '0', 'Boston, MA',       'OCTETSTR' ],
		     [ 'sysContact',  '0', 'boston@our.com',   'OCTETSTR' ] ])
      or croak $req->error() . "\n";

# Validate the hostnames and SNMP variables in the request before handing the
# request to SNMP::Multi.
#
$req->validate or croak $req->error() . "\n";

# Create an SNMP::Multi object to do the work.  Note that the method is 'set',
# but the requests will be using SNMP V2c (for improved error handling).
#
my $sm = SNMP::Multi->new (
    Method	=> 'set',
    Community	=> $wcomm,
    Version	=> '2c',
    Timeout	=> 5
) or croak "$SNMP::Multi::error\n";

# Hand the host/variable request structure into the SNMP::Multi object.  It
# could also have done in the SNMP::Multi::new() invocation above, but it
# would be more difficult to do the error checking.
#
$sm->request($req) or croak $sm->error() . "\n";

# Now go out and make the requests to the hosts.  The execute() method will
# return after either 15 seconds has elapsed, or a response has been received
# for all of the requests in the VarReq.
#
my $response = $sm->execute(15) or croak $sm->error() . "\n";

# Now unpack the Response object.  We should see that the requests were
# successful, and the new values returned to us (with a VarList for each
# variable request).
#
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

	# Print the variables returned by the agent on the host.  This is
	# much easier to read than the values() output above.  $varist is
	# an SNMP::VarList as returned by SNMP.pm.
	#
	for my $varlist ($result->varlists()) {
	    print map { "\t" . $_->fmt() . "\n" } @$varlist;
	}
	print "\n";
    }
}

exit 0;
