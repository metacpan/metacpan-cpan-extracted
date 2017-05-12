#!/usr/bin/perl -w

use strict;

#
#  Assuming that the Time adapter is running on the other end.
#
package Time;
use base qw( SOAP::Transport::HTTP::AutoInvoke::Client );


package main;

#
#  Specify host, port, endpoint, method_uri unless using the defaults.
#  Change unless your host is really named 'myshkin'.
#
my $time = new Time ( _soap_host => 'myshkin' );

print "\n";
print "Remote Time is: ", $time->get_time, "\n";
