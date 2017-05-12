#!/usr/bin/perl -w

use Net::ICQV5CD;



$p = "050000000000ce0cbb0190056fe23f00a8e11b04cbcea8a85e37ba5c1f644a56157342570978a14d0f7489460e37f303";
$p = pack("H*",$p);
$p = ICQV5_DECRYPT_PACKET($p);

$p = unpack("H*",$p);
print "$p\n";

