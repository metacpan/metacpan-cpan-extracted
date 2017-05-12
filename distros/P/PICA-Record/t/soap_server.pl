#!/usr/bin/perl

# This scrip contains a SOAP server accessible via CGI
# settings are read from t/soapserver.conf

use SOAP::Transport::HTTP;
use PICA::Store;
use PICA::SOAPServer;

my $store  = PICA::Store->new( config => "t/soapserver.conf" );
my $server = PICA::SOAPServer->new( $store );

SOAP::Transport::HTTP::CGI   
    -> serializer( SOAP::Serializer->new->envprefix('soap') )
    -> dispatch_with( { 'http://www.gbv.de/schema/webcat-1.0' => $server } )
    -> handle;

1;
