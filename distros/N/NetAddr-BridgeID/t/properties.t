use sanity;

use Test::More tests => 10;

use_ok('NetAddr::BridgeID');

my $obj;
my @all = qw(
   is_eui48
   is_eui64
   is_multicast
   is_unicast
   is_local
   is_universal
   as_basic
   as_bpr
   as_cisco
   as_ieee
   as_ipv6_suffix
   as_microsoft
   as_singledash
   as_sun
   as_tokenring
   to_eui48
   to_eui64
   mac

   original
   bridge_id
   priority
   mac_obj
);

# Bridge ID provided
$obj = new_ok( 'NetAddr::BridgeID' => [ bridge_id => '65535#0000.1111.ffff' ], 'new with bridge_id' );
can_ok($obj, @all);
is($obj->as_cisco, '0000.1111.ffff', 'eq 0000.1111.ffff');

# NetAddr::BridgeID object
$obj = new_ok( 'NetAddr::BridgeID' => [ $obj ], 'new with NetAddr::BridgeID object' );
is($obj->as_cisco, '0000.1111.ffff', 'eq 0000.1111.ffff');

# NetAddr::MAC object
$obj = new_ok( 'NetAddr::BridgeID' => [ $obj->mac_obj ], 'new with NetAddr::MAC object' );
is($obj->as_cisco, '0000.1111.ffff', 'eq 0000.1111.ffff');

# explicit
$obj = new_ok( 'NetAddr::BridgeID' => [ priority => 5, mac => '00:11:22:33:44:55' ], 'new with priority/mac' );
is($obj->as_cisco, '0011.2233.4455', 'eq 0011.2233.4455');
