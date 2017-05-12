#!/usr/bin/perl -wT

use Test::More tests => 51;

BEGIN { use_ok( 'Net::DHCP::Packet' ); }
BEGIN { use_ok( 'Net::DHCP::Constants' ); }

use strict;

my $ip0 = '0.0.0.0';
my $pac0 = '\0\0\0\0';
my $foo = 'foobar';

my $pac;
my @arr;

$pac = Net::DHCP::Packet->new();

# dhcp message type
$pac->addOptionValue(DHO_DHCP_MESSAGE_TYPE(), DHCPINFORM());
is($pac->getOptionValue(DHO_DHCP_MESSAGE_TYPE()), DHCPINFORM(), 'testing message type');
is($pac->getOptionRaw(DHO_DHCP_MESSAGE_TYPE()), chr(DHCPINFORM()));


$pac = Net::DHCP::Packet->new();
is($pac->getOptionValue(DHO_SUBNET_MASK()), undef, 'testing inet format');
# test for 'inet' data type
$pac->addOptionValue(DHO_SUBNET_MASK(), "255.255.255.0");
is($pac->getOptionValue(DHO_SUBNET_MASK()), "255.255.255.0");
is($pac->getOptionRaw(DHO_SUBNET_MASK()), "\xFF\xFF\xFF\0");
$pac->addOptionRaw(DHO_SUBNET_MASK(), "\xFF\xFF\xFF\0");
is($pac->getOptionValue(DHO_SUBNET_MASK()), "255.255.255.0");
is($pac->getOptionRaw(DHO_SUBNET_MASK()), "\xFF\xFF\xFF\0");
# exceptions
eval {
  $pac->addOptionValue(DHO_SUBNET_MASK());
};
like( $@, qr/addOptionValue: exactly one value expected/);
eval {
  $pac->addOptionValue(DHO_SUBNET_MASK(), undef);
};
like( $@, qr/addOptionValue: exactly one value expected/);
eval {
  $pac->addOptionValue(DHO_SUBNET_MASK(), "255.255.255.0 255.255.255.0");
};
like( $@, qr/addOptionValue: exactly one value expected/);

$pac = Net::DHCP::Packet->new();
is($pac->getOptionValue(DHO_NAME_SERVERS()), undef, "testing inets format");
# test for 'inets' data type
$pac->addOptionValue(DHO_NAME_SERVERS(), "1.2.3.15 4.5.6.14");

is($pac->getOptionRaw(DHO_NAME_SERVERS()), "\1\2\3\x0F\4\5\6\x0E");
is($pac->getOptionValue(DHO_NAME_SERVERS()), "1.2.3.15 4.5.6.14");
# empty
$pac->addOptionValue(DHO_NAME_SERVERS());
is($pac->getOptionValue(DHO_NAME_SERVERS()), undef);

$pac = Net::DHCP::Packet->new();
is($pac->getOptionValue(DHO_STATIC_ROUTES()), undef, "testing inets2 format");
# test for 'inet2' data type
$pac->addOptionValue(DHO_STATIC_ROUTES(), "1.2.3.15 4.5.6.14");

is($pac->getOptionRaw(DHO_STATIC_ROUTES()), "\1\2\3\x0F\4\5\6\x0E");
is($pac->getOptionValue(DHO_STATIC_ROUTES()), "1.2.3.15 4.5.6.14");
# empty
$pac->addOptionValue(DHO_STATIC_ROUTES());
is($pac->getOptionValue(DHO_STATIC_ROUTES()), undef);
# exceptions
eval {
  $pac->addOptionValue(DHO_STATIC_ROUTES());
};
ok( ! $@ );
eval {
  $pac->addOptionValue(DHO_STATIC_ROUTES(), undef);
};
ok( ! $@ );
eval {
  $pac->addOptionValue(DHO_STATIC_ROUTES(), "255.255.255.0");
};
like( $@, qr/addOptionValue: only pairs of values expected/);

$pac = Net::DHCP::Packet->new();
# test for 'int' format
$pac->addOptionValue(DHO_DHCP_RENEWAL_TIME(), 0x12345678);
is($pac->getOptionValue(DHO_DHCP_RENEWAL_TIME()), 0x12345678, "testing int format");
is($pac->getOptionRaw(DHO_DHCP_RENEWAL_TIME()), "\x12\x34\x56\x78");
eval { $pac->addOptionValue(DHO_DHCP_RENEWAL_TIME(), undef); } ;
like( $@, qr/addOptionValue: exactly one value expected/);

$pac = Net::DHCP::Packet->new();
# test for 'short' format
$pac->addOptionValue(DHO_INTERFACE_MTU(), 0x12345678);
is($pac->getOptionValue(DHO_INTERFACE_MTU()), 0x5678,     'testing short format 0x5678');
is($pac->getOptionRaw(  DHO_INTERFACE_MTU()), "\x56\x78", 'testing short format \x56\x78');
eval { $pac->addOptionValue(DHO_INTERFACE_MTU(), undef); };
like( $@, qr/addOptionValue: exactly one value expected/, 'testing short format undef');

$pac = Net::DHCP::Packet->new();
# test for 'byte' format
$pac->addOptionValue(DHO_DEFAULT_TCP_TTL(), 0x12345678);
is($pac->getOptionValue(DHO_DEFAULT_TCP_TTL()), 0x78,     'testing byte format 0x78');
is($pac->getOptionRaw(  DHO_DEFAULT_TCP_TTL()), "\x78",   'testing byte format \x78');
eval { $pac->addOptionValue(DHO_DEFAULT_TCP_TTL(), undef); };
like( $@, qr/addOptionValue: exactly one value expected/, 'testing byte format undef');

$pac = Net::DHCP::Packet->new();
is($pac->getOptionValue(DHO_DHCP_PARAMETER_REQUEST_LIST()), undef, 'testing bytes format is init\'d as empty');
# test for 'bytes' format
$pac->addOptionValue(DHO_DHCP_PARAMETER_REQUEST_LIST(),  "1 3 5 1278 ".0xFFFFFFFF,);
is($pac->getOptionValue(DHO_DHCP_PARAMETER_REQUEST_LIST()), '1 3 5 254 255', 'testing bytes format with some integers, a wrap and a hex');
is($pac->getOptionRaw(DHO_DHCP_PARAMETER_REQUEST_LIST()), "\x01\x03\x05\xFE\xFF", 'testing bytes format as above, using hex format');
$pac->addOptionValue(DHO_DHCP_PARAMETER_REQUEST_LIST(), undef);
is($pac->getOptionValue(DHO_DHCP_PARAMETER_REQUEST_LIST()), q(), 'testing bytes format, clearing with undef');

$pac = Net::DHCP::Packet->new();
# test for 'string' format
$pac->addOptionValue(DHO_TFTP_SERVER(), $foo);
is($pac->getOptionValue(DHO_TFTP_SERVER()), $foo, "testing string format");
is($pac->getOptionRaw(DHO_TFTP_SERVER()), $foo);
eval { $pac->addOptionValue(DHO_TFTP_SERVER(), undef); };
is($pac->getOptionRaw(DHO_TFTP_SERVER()), undef);

$pac = Net::DHCP::Packet->new();
# test for 'relays' format
#my @relay = ( 1 => 'foo', 2 => 'bar', 3 => 'baz');
#$pac->addOptionValue(DHO_DHCP_AGENT_OPTIONS(), @relay);
#my @relay2 = $pac->getOptionValue(DHO_DHCP_AGENT_OPTIONS());
#is_deeply(\@relay2, \@relay, "testing relays format");

# added removeOption as of version 0.64
$pac = Net::DHCP::Packet->new();
$pac->addOptionValue(DHO_DEFAULT_TCP_TTL(), 0x78);
$pac->addOptionValue(DHO_DHCP_PARAMETER_REQUEST_LIST(),  "1 3 5 254 255");
$pac->addOptionValue(DHO_TFTP_SERVER(), $foo);
is($pac->getOptionValue(DHO_TFTP_SERVER()), $foo, "testing option removal");
is($pac->getOptionValue(DHO_DHCP_PARAMETER_REQUEST_LIST()), '1 3 5 254 255');
is($pac->getOptionValue(DHO_DEFAULT_TCP_TTL()), 0x78);
# now remove one middle one
$pac->removeOption(DHO_DHCP_PARAMETER_REQUEST_LIST());
is($pac->getOptionValue(DHO_TFTP_SERVER()), $foo);
is($pac->getOptionRaw(DHO_DHCP_PARAMETER_REQUEST_LIST()), undef);
is($pac->getOptionValue(DHO_DEFAULT_TCP_TTL()), 0x78);
# remove again and undefs
$pac->removeOption(DHO_DHCP_PARAMETER_REQUEST_LIST());
$pac->removeOption(DHO_STATIC_ROUTES());
# remove first value
$pac->removeOption(DHO_TFTP_SERVER());
is($pac->getOptionRaw(DHO_TFTP_SERVER()), undef);
is($pac->getOptionRaw(DHO_DHCP_PARAMETER_REQUEST_LIST()), undef);
is($pac->getOptionValue(DHO_DEFAULT_TCP_TTL()), 0x78);
# remove last
$pac->removeOption(DHO_DEFAULT_TCP_TTL());
is($pac->getOptionRaw(DHO_TFTP_SERVER()), undef);
is($pac->getOptionRaw(DHO_DHCP_PARAMETER_REQUEST_LIST()), undef);
is($pac->getOptionRaw(DHO_DEFAULT_TCP_TTL()), undef);

