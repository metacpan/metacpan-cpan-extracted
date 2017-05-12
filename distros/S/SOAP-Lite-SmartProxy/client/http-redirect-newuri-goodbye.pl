#!/usr/bin/perl -w

use strict;

use SOAP::Lite +autodispatch =>
    uri      => 'urn:',
    proxy    => 'httpx://my.smart.server/soap',
    on_fault => sub { my($soap, $res) = @_; 
       die ref $res ? $res->faultdetail : $soap->transport->status, "\n";
    }
;


print GoodBye->SOAP::echo ( 'Paul' ), "\n";


__END__


=head1 DESCRIPTION

This script is part of the SOAP::Transport::HTTPX testing suite.

This script creates a SOAP client and publishes a 'GoodBye' request
to the specified proxy server using the 'httpx' scheme.  The request
will then be redirected to a 2nd proxy host by the first.  The request
uri will also be remapped to use the 'NewGoodBye' class.

The provided 'Calculator' module must be installed in a deployed modules
directory of the server being redirected to.
