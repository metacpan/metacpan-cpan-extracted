#!/usr/bin/perl -w

use strict;

use SOAP::Lite +autodispatch =>
    uri      => 'urn:',
    proxy    => 'ActiveWorks://SOAP:SOAP@my.active.host:7449',
    on_fault => sub { my($soap, $res) = @_;
       die ref $res ? $res->faultdetail : $soap->transport->status, "\n";
    }
;


my @Numbers = ( 1 );

print "Sum(1)    = ", Calculator->SOAP::add ( \@Numbers ), "\n";
push ( @Numbers, 2 );
print "Sum(1..2) = ", Calculator->SOAP::add ( \@Numbers ), "\n";
push ( @Numbers, 3 );
print "Sum(1..3) = ", Calculator->SOAP::add ( \@Numbers ), "\n";
push ( @Numbers, 4 );
print "Sum(1..4) = ", Calculator->SOAP::add ( \@Numbers ), "\n";


__END__


=head1 DESCRIPTION

This script is part of the SOAP::Transport::ACTIVEWORKS testing suite.

This script uses the SOAP-Lite dispatching mechanism to publish an
ActiveWorks 'SOAP::Request' event to an ActiveWorks broker given in the
'proxy' parameter.  The companion 'soap-lite-adapter.pl' script is the
intended recipient adapter.

The receiving adapter then works like an ordinary SOAP server and 
invokes the requested class, 'Calculator', in the usual way.  The results
are returned in a SOAP envelop contained in a SOAP::Reply ActiveWorks
event.  The provided 'Calculator' module must be installed in a
'SafeModules' directory specified in the soap-lite adapter.
