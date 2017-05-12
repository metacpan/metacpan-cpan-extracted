#!/usr/bin/perl -w

use strict;

use SOAP::Lite +autodispatch =>
    uri      => 'urn:',
    proxy    => 'http://my.other.http.host/soap',
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

This script creates a SOAP client and publishes a 'Calculator' request
directly to a SOAP server in the standard way.

The provided 'Calculator' module must be installed in a
'SafeModules' directory specified in the http server configuration.

B<No> ActiveWorks components are employed.
