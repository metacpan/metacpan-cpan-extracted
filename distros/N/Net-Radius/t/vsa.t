#!/usr/bin/perl

# Test VSA packing and unpacking

# $Id: vsa.t 83 2007-06-08 13:57:58Z lem $


use IO::File;
use Test::More tests => 14;
use Net::Radius::Packet;
use Net::Radius::Dictionary;

# Init the dictionary for our test run...
BEGIN {
    my $fh = new IO::File "dict.$$", ">";
    print $fh <<EOF;
ATTRIBUTE	User-Name		1	string
ATTRIBUTE	NAS-Port		5	integer
ATTRIBUTE	Service-Type		6	integer

VALUE           Service-Type            Framed-User             2

VENDOR		Cisco-VPN3000	3076

ATTRIBUTE CVPN3000-Access-Hours			1	string Cisco-VPN3000
ATTRIBUTE CVPN3000-Simultaneous-Logins		2	integer Cisco-VPN3000

VENDORATTR      88888   Resource-Name       1       string 
EOF

    close $fh;
};

END { unlink 'dict.' . $$; }

my $d = new Net::Radius::Dictionary "dict.$$";
isa_ok($d, 'Net::Radius::Dictionary');

# use Data::Dumper;
# diag 'd: ', Data::Dumper->Dump([$d]);

# Build a request and test it is ok - We're leaving out the
# authenticator calculation

my $p = new Net::Radius::Packet $d;
isa_ok($p, 'Net::Radius::Packet');
$p->set_identifier(42);
$p->set_authenticator("\x66" x 16);
$p->set_code("Access-Accept");
$p->set_attr("User-Name" => 'foo');
$p->set_attr('Service-Type' => 'Framed-User');
$p->set_attr('NAS-Port' => '42');
$p->set_vsattr('Cisco-VPN3000', 'CVPN3000-Access-Hours', "Access-Hours");
$p->set_vsattr('Cisco-VPN3000', 'CVPN3000-Simultaneous-Logins', 63);
$p->set_vsattr(88888, 'Resource-Name', 'storage');

my $q = new Net::Radius::Packet $d, $p->pack;
isa_ok($q, 'Net::Radius::Packet');

is($p->code, 'Access-Accept', "Correct packet code");
is($p->attr('User-Name'), 'foo', "Correct User-Name");
is($p->attr('Service-Type'), 'Framed-User', "Correct Framed-User");
is($p->attr('NAS-Port'), 42, "Correct NAS-Port");
is($p->attr('User-Name'), 'foo', "Correct User-Name");
is(ref($p->vsattr('Cisco-VPN3000', 'CVPN3000-Access-Hours')), 
   'ARRAY', "Correct type for string VSA");
is($p->vsattr('Cisco-VPN3000', 'CVPN3000-Access-Hours')->[0], 
   'Access-Hours', "Correct string VSA");
is(ref($p->vsattr('Cisco-VPN3000', 'CVPN3000-Simultaneous-Logins')), 
   'ARRAY', "Correct type for integer VSA");
is($p->vsattr('Cisco-VPN3000', 'CVPN3000-Simultaneous-Logins')->[0], 
   '63', "Correct integer VSA");
if(ok($p->vsattr(88888, 'Resource-Name'), "Fetch of numeric vid from VSA"))
{
    is($p->vsattr(88888, 'Resource-Name')->[0], 
       'storage', "Correct integer VSA (numeric vid)");
}
else
{
#     use Data::Dumper;
#     diag 'q: ', Data::Dumper->Dump([$q]);
#     diag 'p: ', Data::Dumper->Dump([$p]);
    fail("Cannot test numeric vid VSA value");
}
