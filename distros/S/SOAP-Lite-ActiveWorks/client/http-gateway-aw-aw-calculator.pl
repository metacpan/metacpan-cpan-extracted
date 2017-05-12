#!/usr/bin/perl -w

use strict;

use SOAP::Lite +autodispatch => 
    uri      => 'activeworks://SOAP:devkitClient@my.active.host:7449',
    proxy    => 'http://my.http.host/soap/',
    on_fault => sub { my($soap, $res) = @_; 
       die ref $res ? $res->faultdetail : $soap->transport->status, "\n";
    }
;


my %request = (
    _event_type => "AdapterDevKit::calcRequest",
);



my @Numbers = ( 1 );

$request{numbers} = \@Numbers;

print "Sum(1)    = ", ${ AwGateway->SOAP::relay ( \%request ) }{result}, "\n";
push ( @Numbers, 2 );
print "Sum(1..2) = ", ${ AwGateway->SOAP::relay ( \%request ) }{result}, "\n";
push ( @Numbers, 3 );
print "Sum(1..3) = ", ${ AwGateway->SOAP::relay ( \%request ) }{result}, "\n";
push ( @Numbers, 4 );
print "Sum(1..4) = ", ${ AwGateway->SOAP::relay ( \%request ) }{result}, "\n";


__END__


=head1 DESCRIPTION

This script is part of the SOAP::Transport::ACTIVEWORKS testing suite.

This script uses the SOAP-Lite dispatching mechanism to publish a SOAP request
to an http server given in the 'proxy' parameter.  The server in turn passes
the request data to the 'AwGateway' module 'relay' method.  The 'AwGateway'
module is a normal SOAP module and must be installed in a 'SafeModules'
directory specified in the http server configuration.

The 'AwGateway' module creates an ActiveWorks client and publishes an
'AdapterDevKit::calcRequest' event directly to the ActiveWorks broker specified
in the dispatcher 'uri' parameter.  The event published by AwGateway B<must>
be specified by the '_event_type' field of the '%request' hash.  See the
AwGateway documentation for details.

The companion 'calc-adapter.pl' script is the intended recipient adapter.

The SOAP::Transport::ACTIVEWORKS module is NOT employed.
