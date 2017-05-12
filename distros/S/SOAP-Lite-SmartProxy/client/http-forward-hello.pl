#!/usr/bin/perl -w

use strict;

use SOAP::Lite +autodispatch =>
    uri      => 'urn:',
    proxy    => 'httpx://my.smart.server/soap',
    on_fault => sub { my($soap, $res) = @_; 
       die ref $res ? $res->faultdetail : $soap->transport->status, "\n";
    }
;


print Hello->SOAP::echo ( 'Paul' ), "\n";


__END__


=head1 DESCRIPTION

This script is part of the SOAP::Transport::HTTPX testing suite.

This script creates a SOAP client and publishes a 'Hello' request
to the specified proxy server using the 'httpx' scheme.  The request
will then be forwarded to a 2nd proxy host by the first.

The provided 'Hello' module must be installed in a deployed modules
directory of the server being forwarded to.
