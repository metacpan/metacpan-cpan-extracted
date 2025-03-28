#!/usr/bin/perl -w

use strict;

use SOAP::Lite +autodispatch => 
    uri      => 'activeworks://SOAP:devkitClient@my.active.host:7449', 
    proxy    => 'http://my.http.host/aw-soap/',
    on_fault => sub { my($soap, $res) = @_; 
       die ref $res ? $res->faultdetail : $soap->transport->status, "\n";
    }
;


my %request = ();


my @Numbers = ( 1 );

$request{numbers} = \@Numbers;

print "Sum(1)    = ", ${ AdapterDevKit::calcRequest->SOAP::publish ( \%request ) }{result}, "\n";
push ( @Numbers, 2 );
print "Sum(1..2) = ", ${ AdapterDevKit::calcRequest->SOAP::publish ( \%request ) }{result}, "\n";
push ( @Numbers, 3 );
print "Sum(1..3) = ", ${ AdapterDevKit::calcRequest->SOAP::publish ( \%request ) }{result}, "\n";
push ( @Numbers, 4 );
print "Sum(1..4) = ", ${ AdapterDevKit::calcRequest->SOAP::publish ( \%request ) }{result}, "\n"; 


__END__


=head1 DESCRIPTION

This script is part of the SOAP::Transport::ActiveWorks::Lite  testing suite.

This script uses the SOAP-Lite dispatching mechanism to publish an
SOAP request to an http server given in the 'proxy' parameter.

Event pseudo classes are used.  The SOAP dispatcher will directly publish
the pseudo class, 'AdapterDeveKit::calcRequest' as a native ActiveWorks
event and populate the fields of the event with the fields of the hash
reference passed as the class argument.  The ActiveWorks broker 
published to is specified in the 'uri' dispatch parameter.

The companion 'calc-adapter.pl' script is the intended recipient adapter.
