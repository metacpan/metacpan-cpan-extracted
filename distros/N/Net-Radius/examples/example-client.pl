#!/usr/bin/perl

use Time::HiRes qw(gettimeofday tv_interval);
use Net::Inet qw(:routines);
use Net::Radius::Dictionary;
use Net::Radius::Packet;
use Net::Gen qw(:af);
use POSIX qw(uname);
use Net::UDP;
use warnings;
use strict;
use Fcntl;

# This is a simple test program to originate RADIUS authentication
# and accounting requests for testing a RADIUS server.

# $Id: example-client.pl 7 2003-01-08 03:42:41Z lem $

# test user details
my $user = "testuser";
my $password = "testpassword";

# details of RADIUS authentication and accounting servers
my $authhost = "radius.server.domain.com";
my $authport = 1645;
my $accthost = "radius.server.domain.com";
my $acctport = 1646;
my $secret = "testkey";  # Shared secret for this client

# Parse the RADIUS dictionary file (must have dictionary in current dir)
my $dict = new Net::Radius::Dictionary "dictionary"
	or die "Couldn't read dictionary: $!";

# Set up the network socket
my $s = new Net::UDP or die $!;

my ($authaddr, $acctaddr, $paddr);
$paddr = gethostbyname($authhost) or die "Can't resolve host $authhost\n";
$authaddr = pack_sockaddr_in(AF_INET, $authport, $paddr);
$paddr = gethostbyname($accthost) or die "Can't resolve host $accthost\n";
$acctaddr = pack_sockaddr_in(AF_INET, $acctport, $paddr);

# discover my own IP address
my $myip = join '.',unpack "C4",gethostbyname((uname)[1]);

my $ident = 1;
my $whence;

# subroutine to make string of 16 random bytes
sub bigrand() {
        pack "n8",
                rand(65536), rand(65536), rand(65536), rand(65536),
                rand(65536), rand(65536), rand(65536), rand(65536);
}

my ($rec, $req, $resp);

# Create a request packet
$req = new Net::Radius::Packet $dict;
$req->set_code('Access-Request');

$req->set_attr('User-Name' => $user);
$req->set_attr('Service-Type' => 'Framed');
$req->set_attr('Framed-Protocol' => 'PPP');
$req->set_attr('NAS-Port' => 1234);
$req->set_attr('NAS-Identifier' => 'PerlTester');
$req->set_attr('NAS-IP-Address' => $myip);
$req->set_attr('Called-Station-Id' => '0000');
$req->set_attr('Calling-Station-Id' => '01234567890');

$req->set_identifier($ident);
$req->set_authenticator(bigrand);   # random authenticator required
$req->set_password($password, $secret);	# encode and store password

# Send to the server. Encoding with auth_resp is NOT required.
$s->sendto($req->pack, $authaddr);

# $req->dump;

# wait for response
$rec = $s->recv(undef, undef, $whence);

$resp = new Net::Radius::Packet $dict, $rec;

# $resp->dump;

if ($whence ne $authaddr || $resp->identifier != $ident) {
    die "unexpected reply to Radius authentication!\n";
}

if ($resp->code ne 'Access-Accept') {
    die "Radius response not Access-Accept\n";
}

# note the start time of the session
my $sessiontime = time;

# now construct and send the Accounting-Start packet,
# using the Authentication packet as a starting-point.

$ident = ($ident + 1) & 255;

my $class = $resp->attr('Class');  # to return to Radius

# remove password from packet
$req->unset_attr('User-Password');

# add accounting items
$req->set_code('Accounting-Request');
$req->set_attr('Acct-Status-Type', 'Start');
$req->set_attr('Acct-Delay-Time', 0);
$req->set_attr('Acct-Authentic', 'RADIUS');
$req->set_attr('Class', $class) if $class; # include Class if server gave one

# some example values
$req->set_attr('Acct-Session-Id', '12345678');
$req->set_attr('Framed-IP-Address', '10.0.1.2');

$req->set_identifier($ident);

# for accounting packets, start with a null authenticator
$req->set_authenticator("");

# ... and then hash it with the secret like a response
$s->sendto(auth_resp($req->pack,$secret), $acctaddr);

# $req->dump;

# wait for response
$rec = $s->recv(undef, undef, $whence);

$resp = new Net::Radius::Packet $dict, $rec;

# $resp->dump;

if ($whence ne $acctaddr || $resp->identifier != $ident) {
    die "unexpected reply to Radius accounting start!\n";
}

if ($resp->code ne 'Accounting-Response') {
    die "Radius response not Accounting-Response\n";
}

# sleep for a while to simulate an online session
sleep 20;

# calculate the duration of the session
$sessiontime = time - $sessiontime;

# now construct and send the Accounting-Stop packet,
# using the Accounting-Start packet as a starting point.

$ident = ($ident + 1) & 255;

# add the end-of-session values
$req->set_attr('Acct-Status-Type', 'Stop');
$req->set_attr('Acct-Delay-Time', 0);
$req->set_attr('Acct-Session-Time', $sessiontime);
# make up some values for this example
$req->set_attr('Acct-Input-Octets', $sessiontime * 3000);
$req->set_attr('Acct-Output-Octets', $sessiontime * 300);
$req->set_attr('Acct-Input-Packets', $sessiontime * 30);
$req->set_attr('Acct-Output-Packets', $sessiontime * 10);
$req->set_attr('Acct-Terminate-Cause', 'User-Request');

$req->set_identifier($ident);

# for accounting packets, start with a null authenticator
$req->set_authenticator("");

# ... and then hash it with the secret like a response
$s->sendto(auth_resp($req->pack,$secret), $acctaddr);

# $req->dump;

# wait for response
$rec = $s->recv(undef, undef, $whence);

$resp = new Net::Radius::Packet $dict, $rec;

# $resp->dump;

if ($whence ne $acctaddr || $resp->identifier != $ident) {
    die "unexpected reply to Radius accounting stop!\n";
}

if ($resp->code ne 'Accounting-Response') {
    die "Radius response not Accounting-Response\n";
}

exit;
