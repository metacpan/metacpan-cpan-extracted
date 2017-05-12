use strict;
use warnings;
use Test::More tests => 13;

use Net::SNMP::Util::TC;

is( join( '', map { isup($_) } (0..7) ),
    "01000000",
    qq/isup()/
);

is( join( '', map { updown($_) } (0..7) ),
    "downupdowndowndowndowndowndown",
    qq/updown()/
);

my $tc;
eval {
    $tc = Net::SNMP::Util::TC->new();
};
ok( defined($tc), "new()");
is( $tc->ifAdminStatus(1),  'up',           "method ifAdminStatus()" );
is( $tc->ifAdminStatus(2),  'down',         "method ifAdminStatus() again" );
is( $tc->ifOperStatus(1),   'up',           "method ifOperStatus()"  );
is( $tc->ifOperStatus(2),   'down',         "method ifOperStatus() again"  );
is( $tc->ifType(6),         'ethernet-csmacd',"method ifType()" );
is( $tc->ifRcvAddressType(2),'volatile',    "method ifRcvAddressType()" );
is( $tc->TruthValue(1),     'true',         "method TruthValue()" );
is( $tc->StorageType(3),    'nonVolatile',  "method StorageType()" );
is( $tc->TRUE(),            '1',            "method TRUE()" );
is( $tc->FALSE(),           '2',            "method FALSE()" );
