#
# Modbus/TCP-IP core tests
# Test the exceptions system
#
# Cosimo 2007/02/05
#

use strict;
use warnings;
use Test::More;

BEGIN { plan tests => 6 }

use_ok('Protocol::Modbus');
use_ok('Protocol::Modbus::Exception');

my $proto = Protocol::Modbus->new();
ok($proto, 'generic protocol object loaded');

# Request without value should generate an exception
my $req = $proto->writeCoilRequest( address => 0x0000 );

ok($req, 'request method returned something');
ok($req->isa('Protocol::Modbus::Exception'), 'erroneous request without "value" returned an exception');

diag('Exception object: ', $req);
is($req->code(), &Protocol::Modbus::Exception::ILLEGAL_DATA_VALUE, 'Exception code should be ILLEGAL_DATA_VALUE');

#
# End of test
