#
# Modbus/TCP-IP core tests
# Test the responses packet parsing
#
# 2007/01/31 Cosimo Streppone <cosimo@cpan.org>
#

use strict;
use warnings;
use Test::More;

BEGIN { plan tests => 3 }

use_ok('Protocol::Modbus');
use_ok('Protocol::Modbus::Response');

my $proto = Protocol::Modbus->new();
ok($proto, 'generic protocol object loaded');

