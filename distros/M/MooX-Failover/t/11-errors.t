use Test::Most;

use MooX::Failover;
use lib 't/lib';

throws_ok {
  failover_to;
} qr/no class defined/, 'failover with no class';

throws_ok {
  failover_to 'InvalidModuleName';
} qr/unable to load InvalidModuleName/, 'failover with invalid module name';

throws_ok {
  failover_to __PACKAGE__;
} qr/cannot failover to self/, 'failover to the same class';

throws_ok {
  failover_to 'Failover' => ( constructor => 'foo' );
} qr/Failover cannot foo/, 'invalid constructor name';

done_testing;

