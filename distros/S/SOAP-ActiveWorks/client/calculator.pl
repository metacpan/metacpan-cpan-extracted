#!/usr/bin/perl -w

use strict;

#
#  Assuming that 'Calculator.pm' has been installed server side.
#
package Calculator;
# use base qw( SOAP::Transport::HTTP::AutoInvoke::Client );
use base qw( SOAP::Transport::ActiveWorks::AutoInvoke::Client );


package main;

#
#  Specify host, port, endpoint, method_uri unless using the defaults.
#  Change unless your host is really named 'myshkin'.
#
my $calc = new Calculator ( _soap_host => 'myshkin', _soap_port => 8849 );

print "\n";
print "Arguements Passed in Natural Style:\n";

print "Sum(1)    = ", $calc->add ( 1 ), "\n";
print "Sum(1..2) = ", $calc->add ( 1, 2, ), "\n";
print "Sum(1..3) = ", $calc->add ( 1, 2, 3 ), "\n";
print "Sum(1..4) = ", $calc->add ( 1, 2, 3, 4 ), "\n";

print "\n";
print "Starting Over Using Array References:\n";

my @Numbers = ( 1 );

print "Sum(1)    = ", $calc->add ( \@Numbers ), "\n";
push ( @Numbers, 2 );
print "Sum(1..2) = ", $calc->add ( \@Numbers ), "\n";
push ( @Numbers, 3 );
print "Sum(1..3) = ", $calc->add ( \@Numbers ), "\n";
push ( @Numbers, 4 );
print "Sum(1..4) = ", $calc->add ( \@Numbers ), "\n";



