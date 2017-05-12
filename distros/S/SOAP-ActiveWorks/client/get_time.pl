#!/usr/bin/perl -w

use strict;

#
#  Assuming that the Time adapter is running on the other end.
#
package Time;
use base qw( SOAP::Transport::ActiveWorks::AutoInvoke::Client );


package main;

#
#  Specify host, port,broker, clientgroup, method_uri unless using the defaults.
#  Change unless your host is really named 'myshkin'.
#
my $time = new Time ( _soap_host => 'myshkin', _soap_port => 8849 );

print "\n";
print "Remote Time is: ", $time->get_time, "\n";
