#!/usr/bin/perl -w

use strict;

use SOAP::Lite +autodispatch =>
    uri      => 'urn:',
    proxy    => 'httpx://my.smart.server/soap',
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

This script is part of the SOAP::Transport::HTTPX testing suite.

This script creates a SOAP client and publishes a 'Calculator' request
to the specified proxy server using the 'httpx' scheme.  The request
will then be redirected to a 2nd proxy host.

The provided 'Calculator' module must be installed in a deployed modules
directory of the server being redirected to.
