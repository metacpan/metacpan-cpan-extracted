#!/usr/bin/perl -w

use strict;

use SOAP::Lite +autodispatch =>
    uri      => 'urn:',
    proxy    => 'http://my.http.host/aw-soap/',
    on_fault => sub { my($soap, $res) = @_;
       die ref $res ? $res->faultdetail : $soap->transport->status, "\n";
    }
;


print "Remote Time is ", Time->SOAP::publish, "\n";


__END__


=head1 DESCRIPTION

This script is part of the SOAP::Transport::ACTIVEWORKS testing suite.

This script uses the SOAP-Lite dispatching mechanism to publish a SOAP request
to an http server given in the 'proxy' parameter.  The server in turn publishes
an ActiveWorks 'SOAP::Request' event to a default ActiveWorks broker.  The
companion 'soap-lite-adapter.pl' script is the intended recipient adapter.

The receiving adapter will then handle the request in a define subroutine.
The required 'time_adapter.pl' script (included with the B<Aw> module) then
becomes the target adapter.
