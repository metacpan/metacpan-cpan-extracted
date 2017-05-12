

use warnings;
use strict;
use SOAP::Lite;
use MIME::Entity;


my $server = SOAP::Lite->new(
			   proxy => 'http://sirevih.trunk.localdomain/webservices.php',
			   service => 'http://sirevih.trunk.localdomain/soapservices.wsdl',
			   );


my $retval = $server->getFactorial('x','y',124)->result;

print $retval;


