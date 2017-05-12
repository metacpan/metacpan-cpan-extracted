# Test correct operation of Net::Traces::TSH get_IP_address()
#
use strict;
use Test;

BEGIN { plan tests => 7 };
use Net::Traces::TSH 0.13 qw( get_IP_address );
ok(1);

ok(get_IP_address 167772172, '10.0.0.12');
ok(get_IP_address 167772174, '10.0.0.14');
ok(get_IP_address 180781201, '10.198.128.145');
ok(get_IP_address 947876734, '56.127.115.126');
ok(get_IP_address 2614034432, '155.207.0.0');
ok(get_IP_address 3481237459, '207.127.119.211');
