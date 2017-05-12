#!/usr/bin/perl -w

use strict;

use SOAP::Lite +autodispatch =>
    uri      => 'activeworks://test_broker:devkitClient@my.other.http.host:8849', 
    proxy    => 'http://my.http.host/aw-soap/',
    on_fault => sub { my($soap, $res) = @_;
       die ref $res ? $res->faultdetail : $soap->transport->status, "\n";
    }
;


#
# publish request:
#
my %result = %{ AdapterDevKit::timeRequest->SOAP::publish };

print "Remote Time is $result{time}\n";


__END__


=head1 DESCRIPTION

This script is part of the SOAP::Transport::ACTIVEWORKS testing suite.

This script uses the SOAP-Lite dispatching mechanism to publish an
SOAP request to an http server given in the 'proxy' parameter.

Event pseudo classes are used.  The SOAP dispatcher will directly publish
the pseudo class, 'AdapterDeveKit::timeRequest' as a native ActiveWorks
event and populate the fields of the event with the fields of the hash
reference passed as the class argument.  The ActiveWorks broker 
published to is specified in the 'uri' dispatch parameter.

The receiving adapter will then handle the request in a define subroutine.
The required 'time_adapter.pl' script (included with the B<Aw> module) then
becomes the target adapter.
