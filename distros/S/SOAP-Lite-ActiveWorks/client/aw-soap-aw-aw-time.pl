#!/usr/bin/perl -w

use strict;

use SOAP::Lite +autodispatch =>
    uri      => 'activeworks://test_broker:devkitClient@my.other.active.host:8849',
    proxy    => 'ActiveWorks://SOAP:SOAP@my.active.host:7449',
    on_fault => sub { my($soap, $res) = @_;
       die ref $res ? $res->faultdetail : $soap->transport->status, "\n";
    }
;


my %result = %{ AdapterDevKit::timeRequest->SOAP::publish };

print "Remote Time is $result{time}\n";


__END__


=head1 DESCRIPTION

This script is part of the SOAP::Transport::ACTIVEWORKS testing suite.

This script uses the SOAP-Lite dispatching mechanism to publish an
ActiveWorks event to an ActiveWorks broker given in the 'proxy' parameter.
The companion 'soap-lite-adapter.pl' script is the intended recipient adapter.

Event pseudo classes are used.  The SOAP dispatcher will directly publish
the pseudo class, 'AdapterDeveKit::timeRequest' as a native ActiveWorks
event.  The ActiveWorks broker specified published to is specified in the
'proxy' dispatch parameter.

The receiving adapter will then republish the event
(AdapterDeveKit::timeRequest) to the ActiveWorks broker specified in
the dispatcher 'uri' parameter.  The required 'time_adapter.pl' script
(included with the B<Aw> module) then becomes the target adapter.
