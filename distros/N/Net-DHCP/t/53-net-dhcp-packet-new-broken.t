#!/usr/bin/perl -wT

use Test::More tests => 11;

BEGIN { use_ok( 'Net::DHCP::Packet' ); }
BEGIN { use_ok( 'Net::DHCP::Constants' ); }

use strict;

my $ip0 = "0.0.0.0";
my $pac0 = "\0\0\0\0";

my $pac;

eval {
  $pac = Net::DHCP::Packet->new("");
};
#diag($@);
like( $@, qr/marshall: packet too small/, "packet too small");

eval {
  $pac = Net::DHCP::Packet->new("\0" x 2000);
};
#diag($@);
like( $@, qr/marshall: packet too big/, "packet too big");

eval {
  $pac = Net::DHCP::Packet->new( Net::DHCP::Packet->new()->serialize());
};
#diag($@);
ok( ! $@, "verifying default packet");

my $pac_without_option_end = pack("H*",
"0101060012345678000000000000000000000000000000000000000000000000".
"0000000000000000000000000000000000000000000000000000000000000000".
"0000000000000000000000000000000000000000000000000000000000000000".
"0000000000000000000000000000000000000000000000000000000000000000".
"0000000000000000000000000000000000000000000000000000000000000000".
"0000000000000000000000000000000000000000000000000000000000000000".
"0000000000000000000000000000000000000000000000000000000000000000".
"0000000000000000000000006382536300000000000000000000000000000000".
"0000000000000000000000000000000000000000000000000000000000000000".
"000000000000000000000000"
);
eval {
  $pac = Net::DHCP::Packet->new($pac_without_option_end);
};
#diag($@);
like( $@, qr/marshall: unexpected end of options/, "marshall: unexpected end of options");

# now test serialize
$pac = Net::DHCP::Packet->new();
$pac->padding("\0" x 2000);
eval {
  $pac->serialize();
};
#diag($@);
like($@, qr/serialize: packet too big/, "serialize: packet too big");

# testing DHO_DHCP_MAX_MESSAGE_SIZE conformance
my %options = ( DHO_DHCP_MAX_MESSAGE_SIZE() => 200);
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
"00000000000000000000000000000000"
);
$pac = Net::DHCP::Packet->new($ref_pac);
eval {
  $pac->serialize(\%options);
};
#diag($@);
ok( ! $@, "DHO_DHCP_MAX_MESSAGE_SIZE too small");
$options{DHO_DHCP_MAX_MESSAGE_SIZE()} = 2000;
eval {
  $pac->serialize(\%options);
};
#diag($@);
ok( ! $@, "DHO_DHCP_MAX_MESSAGE_SIZE too big");
$options{DHO_DHCP_MAX_MESSAGE_SIZE()} = 305;
eval {
  $pac->serialize(\%options);
};
#diag($@);
ok( ! $@, "DHO_DHCP_MAX_MESSAGE_SIZE is ok");
$options{DHO_DHCP_MAX_MESSAGE_SIZE()} = 302;
eval {
  $pac->serialize(\%options);
};
#diag($@);
like($@, qr/serialize: message is bigger than allowed/, "serialize: packet too big");
