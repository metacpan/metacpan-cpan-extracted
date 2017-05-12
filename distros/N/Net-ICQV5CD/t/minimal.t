use Test;

BEGIN { plan tests => 6 };

ok(eval { require Net::ICQV5CD; });

use Net::ICQV5CD;
ok(1);

@teststrings = qw(
000102030405060708090A0B0C0D0E0F101112131415161718
000102030405060708090A0B0C0D0E0F10111213141516171819
000102030405060708090A0B0C0D0E0F1011121314151617181920
000102030405060708090A0B0C0D0E0F101112131415161718192021
);

foreach $packetstr (@teststrings) {

$packet = pack("H*",$packetstr);
$packetcrypted = ICQV5_CRYPT_PACKET($packet);
$packetdecrypted = ICQV5_DECRYPT_PACKET($packetcrypted);

$packet = substr($packet,0,0x14) . pack("V",0) . substr($packet,0x18);
$packetdecrypted = substr($packetdecrypted,0,0x14) . pack("V",0) . substr($packetdecrypted,0x18);

if($packet eq $packetdecrypted)
    {
    ok(1)
    }
else
    {
    ok(0)
    }    
    
}
