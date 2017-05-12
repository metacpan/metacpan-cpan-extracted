
use Test::Most tests => 7;
use Test::NoWarnings;

bail_on_fail;

ok( eval 'use Net::CloudStack::API;                       1', 'basic use' );
ok( eval 'use Net::CloudStack::API ();                    1', 'explicitly import nothing' );
ok( eval "use Net::CloudStack::API 'listVirtualMachines'; 1", 'one method generated' );
ok( eval "use Net::CloudStack::API ':all';                1", 'all methods generate' );

eval "use Net::CloudStack::API 'badmethod'";
like( $@, qr/"badmethod" is not exported/, 'badmethod failed correctly' );

eval "use Net::CloudStack::API ':badgroup'";
like( $@, qr/group "badgroup" is not exported/, 'badgroup failed correctly' );
