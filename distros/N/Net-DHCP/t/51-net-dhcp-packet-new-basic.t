#!/usr/bin/perl -wT

use Test::More tests => 33;
use Test::Warn;

BEGIN { use_ok('Net::DHCP::Packet'); }
BEGIN { use_ok('Net::DHCP::Constants'); }

use strict;
my $str200 = '1234567890' x 20;
my $pac;

my $ref_packet = pack( 'H*',
        '0101060011223344000080000a0000010a0000020a0000030a00000400112233'
      . '445566778899aabbccddeeff3132333435363738393031323334353637383930'
      . '3132333435363738393031323334353637383930313233343536373839303132'
      . '3334353637383930313233003132333435363738393031323334353637383930'
      . '3132333435363738393031323334353637383930313233343536373839303132'
      . '3334353637383930313233343536373839303132333435363738393031323334'
      . '3536373839303132333435363738393031323334353637383930313233343536'
      . '3738393031323334353637006382536335010136040c22384433040001518001'
      . '04ffffff0003040a0000fe210816212c370a0000fe2a040a00000548040a0000'
      . '06ff000000000000000000000000000000000000000000000000000000000000'
      . '0000000000000000000000000000000000000000000000000000000000000000'
      . '0000000000000000000000000000000000000000000000000000000000000000'
      . '0000000000000000000000000000000000000000000000000000000000000000'
      . '0000000000000000000000000000000000000000000000000000000000000000'
      . '0000000000000000000000000000000000000000000000000000000000000000'
      . '0000000000000000000000000000000000000000000000000000000000000000'
      . '0000000000000000000000000000000000000000000000000000000000000000'
      . '0000' );

my $packet;
warnings_are {
    $packet = Net::DHCP::Packet->new(
        op                           => BOOTREQUEST(),
        Htype                        => HTYPE_ETHER(),
        Hlen                         => 6,
        Hops                         => 0,
        Xid                          => 0x11223344,
        Flags                        => 0x8000,
        Ciaddr                       => '10.0.0.1',
        Yiaddr                       => '10.0.0.2',
        Siaddr                       => '10.0.0.3',
        Giaddr                       => '10.0.0.4',
        Chaddr                       => '00112233445566778899AABBCCDDEEFF00',
        Sname                        => $str200,
        File                         => $str200,
        DHO_DHCP_MESSAGE_TYPE()      => DHCPDISCOVER(),
        DHO_DHCP_SERVER_IDENTIFIER() => '12.34.56.68',
        DHO_DHCP_LEASE_TIME()        => 86400,
        DHO_SUBNET_MASK()            => '255.255.255.0',
        DHO_ROUTERS()                => '10.0.0.254',
        DHO_STATIC_ROUTES()          => '22.33.44.55 10.0.0.254',
        DHO_NTP_SERVERS()            => '10.0.0.5',
        DHO_WWW_SERVER()             => '10.0.0.6',
        Padding                      => "\x00" x 256
    );
}
[
    q|'sname' must not be > 63 bytes, (currently 200)|,
    q|'file' must not be > 127 bytes, (currently 200)|
];

my $packet2 = Net::DHCP::Packet->new($ref_packet);

#diag($packet2->toString());
#diag(unpack("H*", $packet->serialize()));
is( $packet2->serialize(), $ref_packet, 'comparing with reference packet' );

$pac = Net::DHCP::Packet->new($ref_packet);
is( $pac->comment(), undef, 'comparing each attribute' );
is( $pac->op(),      BOOTREQUEST() );
is( $pac->htype(),   HTYPE_ETHER() );
is( $pac->hlen(),    6 );
is( $pac->hops(),    0 );
is( $pac->xid(),     0x11223344 );
is( $pac->flags(),   0x8000 );
is( $pac->ciaddr(),  '10.0.0.1' );
is( $pac->ciaddrRaw(), "\x0a\x00\x00\x01" );
is( $pac->yiaddr(),    '10.0.0.2' );
is( $pac->yiaddrRaw(), "\x0a\x00\x00\x02" );
is( $pac->siaddr(),    '10.0.0.3' );
is( $pac->siaddrRaw(), "\x0a\x00\x00\x03" );
is( $pac->giaddr(),    '10.0.0.4' );
is( $pac->giaddrRaw(), "\x0a\x00\x00\x04" );
is( $pac->chaddr(),    '00112233445566778899aabbccddeeff' );
is( $pac->chaddrRaw(),
    "\x00\x11\x22\x33\x44\x55\x66\x77\x88\x99\xaa\xbb\xcc\xdd\xee\xff" );
is( $pac->sname(), substr( $str200, 0, 63 ) );
is( $pac->file(),  substr( $str200, 0, 127 ) );
is( $pac->padding(), "\x00" x 256 );
is( $pac->isDhcp(),  1 );

is( $pac->getOptionValue( DHO_DHCP_MESSAGE_TYPE() ),      DHCPDISCOVER() );
is( $pac->getOptionValue( DHO_DHCP_SERVER_IDENTIFIER() ), '12.34.56.68' );
is( $pac->getOptionValue( DHO_DHCP_LEASE_TIME() ),        86400 );
is( $pac->getOptionValue( DHO_SUBNET_MASK() ),            '255.255.255.0' );
is( $pac->getOptionValue( DHO_ROUTERS() ),                '10.0.0.254' );
is( $pac->getOptionValue( DHO_STATIC_ROUTES() ), '22.33.44.55 10.0.0.254' );
is( $pac->getOptionValue( DHO_WWW_SERVER() ),    '10.0.0.6' );
is( $pac->getOptionValue( DHO_IRC_SERVER() ),    undef );
