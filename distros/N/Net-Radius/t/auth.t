#!/usr/bin/perl

# Test packet auth code

# $Id: auth.t 48 2006-11-14 20:05:11Z lem $


no utf8;
use IO::File;
use Test::More 'no_plan';
use Net::Radius::Packet;
use Net::Radius::Dictionary;

# Init the dictionary for our test run...
BEGIN {
    my $fh = new IO::File "dict.$$", ">";
    print $fh <<EOF;
ATTRIBUTE	User-Name		1	string
ATTRIBUTE	User-Password		2	string
ATTRIBUTE	NAS-IP-Address		4	ipaddr
ATTRIBUTE	NAS-Port		5	integer
ATTRIBUTE	Service-Type		6	integer
ATTRIBUTE	Framed-Protocol		7	integer
ATTRIBUTE	Called-Station-Id	30	string
ATTRIBUTE	Calling-Station-Id	31	string
ATTRIBUTE	Acct-Status-Type	40	integer
ATTRIBUTE	Acct-Session-Id		44	string
ATTRIBUTE	Acct-Authentic		45	integer
ATTRIBUTE	NAS-Port-Type		61	integer

VALUE		Service-Type		Framed-User	2
VALUE		Framed-Protocol		PPP		1
VALUE		Acct-Authentic		RADIUS		1
VALUE		NAS-Port-Type		Virtual		5
VALUE		Acct-Status-Type	Stop		2
EOF

    close $fh;
};

END { unlink 'dict.' . $$; }

my $d = new Net::Radius::Dictionary "dict.$$";
isa_ok($d, 'Net::Radius::Dictionary');

# Build a request and test it is ok
my $p = new Net::Radius::Packet $d;
isa_ok($p, 'Net::Radius::Packet');
$p->set_identifier(42);
$p->set_authenticator("\x66" x 16);
$p->set_code("Access-Request");
$p->set_attr("User-Name" => 'foo');
$p->set_attr('NAS-Port-Type' => 'Virtual');
$p->set_attr('NAS-IP-Address' => '10.10.10.10');
$p->set_attr('Service-Type' => 'Framed-User');
$p->set_attr('NAS-Port' => '42');
$p->set_attr('Calling-Station-Id' => '5551212');
$p->set_attr('Called-Station-Id' => '5551111');
$p->set_attr('Framed-Protocol' => 'PPP');
$p->set_password('bar', 'good-secret', 'User-Password');

my $q = new Net::Radius::Packet $d, $p->pack;
isa_ok($q, 'Net::Radius::Packet');

my $pass = $q->password('good-secret');
is($pass, 'bar', 'Correct password when good secret used');

$pass = $q->password('bad-secret');
isnt($pass, 'bar', 'Bad password when bad secret used');

# Now test the response authentication scheme
my $r = new Net::Radius::Packet $d;
isa_ok($r, 'Net::Radius::Packet');
$r->set_code('Access-Accept');
$r->set_attr("User-Name" => 'foo');
$r->set_identifier($p->identifier);
$r->set_authenticator($p->authenticator);
my $r_data = auth_resp($r->pack, 'good-secret');

ok(auth_req_verify($r_data, 'good-secret', $p->authenticator),
   "Response matches request with proper secret");
ok(!auth_req_verify($r_data, 'bad-secret', $p->authenticator),
   "Response doesn't match request with bad secret");

# Now test the accounting authentication scheme
$p = new Net::Radius::Packet $d;
isa_ok($p, 'Net::Radius::Packet');
$p->set_identifier(42);
$p->set_authenticator("\x0" x 16);
$p->set_code("Accounting-Request");
$p->set_attr("User-Name" => 'foo');
$p->set_attr('NAS-Port-Type' => 'Virtual');
$p->set_attr('NAS-IP-Address' => '10.10.10.10');
$p->set_attr('Service-Type' => 'Framed-User');
$p->set_attr('NAS-Port' => '42');
$p->set_attr('Calling-Station-Id' => '5551212');
$p->set_attr('Called-Station-Id' => '5551111');
$p->set_attr('Framed-Protocol' => 'PPP');

my $p_data = auth_resp($p->pack, 'good-secret');

ok(auth_acct_verify($p_data, 'good-secret'), 
   "Validate acct req with good secret");

ok(!auth_acct_verify($p_data, 'bad-secret'), 
   "Validate acct req with bad secret");
