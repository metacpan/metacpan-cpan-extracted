#!/usr/bin/perl -wT

use Test::More tests => 24;

BEGIN { use_ok( 'Net::DHCP::Packet' ); }
BEGIN { use_ok( 'Net::DHCP::Constants' ); }

use strict;

my $ip0 = "0.0.0.0";
my $pac0 = "\0\0\0\0";

my $ref_pac = pack("H*",
"0101060012345678000000000000000000000000000000000000000000000000".
"0000000000000000000000000000000000000000000000000000000000000000".
"0000000000000000000000000000000000000000000000000000000000000000".
"0000000000000000000000000000000000000000000000000000000000000000".
"0000000000000000000000000000000000000000000000000000000000000000".
"0000000000000000000000000000000000000000000000000000000000000000".
"0000000000000000000000000000000000000000000000000000000000000000".
"00000000000000000000000063825363ff000000000000000000000000000000".
"0000000000000000000000000000000000000000000000000000000000000000".
"000000000000000000000000"
);

my $pac = Net::DHCP::Packet->new();

is( $pac->comment(),      undef, "new empty packet");
is( $pac->op(),           BOOTREQUEST());
is( $pac->htype(),        1);
is( $pac->hlen(),         6);
is( $pac->hops(),         0);
is( $pac->xid(),          0x12345678);
is( $pac->secs(),         0);
is( $pac->ciaddr(),       $ip0);
is( $pac->ciaddrRaw(),    $pac0);
is( $pac->yiaddr(),       $ip0);
is( $pac->yiaddrRaw(),    $pac0);
is( $pac->siaddr(),       $ip0);
is( $pac->siaddrRaw(),    $pac0);
is( $pac->giaddr(),       $ip0);
is( $pac->giaddrRaw(),    $pac0);
is( $pac->chaddr(),       "");
is( $pac->sname(),        "");
is( $pac->file(),         "");
is( $pac->padding(),      "");
is( $pac->isDhcp(),       1);
ok( !defined($pac->getOptionRaw(DHO_DHCP_MESSAGE_TYPE())), "undefined message type");

#diag(unpack("H*", $pac->serialize()));
#diag("Packet lenght: ".length($pac->serialize()));

is( $pac->serialize(),    $ref_pac, "compare to reference packet");