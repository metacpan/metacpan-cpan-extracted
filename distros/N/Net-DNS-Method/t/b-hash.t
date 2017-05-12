# This is -*- perl -*-
# Basic testing of the Net::DNS::Method::Hash module

# luismunoz@cpan.org
# $Id: b-hash.t,v 1.2 2002/10/23 04:43:58 lem Exp $

use Test::More tests => 13;

use Net::DNS::RR;
use NetAddr::IP 3.00;
use Net::DNS::Method;
use Net::DNS::Method::Hash;

my $res = new Net::DNS::Method::Hash {
    BaseDomain => 'hash.com',
    Hash => { 'www' => [ "IN A 10.10.10.10" ] }
};

ok (defined $res, '->new()');

my $q = new Net::DNS::Question("none.hash.com", "A", "IN");
my $a = new Net::DNS::Packet("none.hash.com", "A", "IN");
my $r = $res->ANY($q, $a, { from => new NetAddr::IP '127.0.0.1' } );

ok ($r == NS_FAIL, 'unexistant name');

$q = new Net::DNS::Question("www.hash.com", "A", "IN");
$a = new Net::DNS::Packet("www.hash.com", "A", "IN");
$r = $res->ANY($q, $a, { from => new NetAddr::IP '127.0.0.1' } );

ok ($r == (NS_OK|NS_STOP), 'proper return value for defined name');
ok (($a->answer)[0]->string 
    eq Net::DNS::RR->new('www.hash.com IN A 10.10.10.10')->string,
    'correct answer for www.hash.com');

$q = new Net::DNS::Question("www.nhash.com", "A", "IN");
$a = new Net::DNS::Packet("www.nhash.com", "A", "IN");
$r = $res->ANY($q, $a, { from => new NetAddr::IP '127.0.0.1' } );

ok ($r == NS_FAIL, 'proper return value for unexistant but close name (tail)');

$q = new Net::DNS::Question("www.hashx.com", "A", "IN");
$a = new Net::DNS::Packet("www.hashx.com", "A", "IN");
$r = $res->ANY($q, $a, { from => new NetAddr::IP '127.0.0.1' } );

ok ($r == NS_FAIL, 'proper return value for unexistant but close name (head)');

$q = new Net::DNS::Question("hash.com", "A", "IN");
$a = new Net::DNS::Packet("hash.com", "A", "IN");
$r = $res->ANY($q, $a, { from => new NetAddr::IP '127.0.0.1' } );

ok ($r == NS_FAIL, 'zone fails when undefined');

$res = new Net::DNS::Method::Hash {
    BaseDomain => 'hash.com',
    Hash => { 
	'www.hash.com' => [ "IN A 10.10.10.10" ],
	'ftp.hash.com.' => [ "IN A 10.10.10.10" ],
	'hash.com' => [ "IN CNAME www.hash.com." ],
    }
};

$q = new Net::DNS::Question("www.hash.com", "A", "IN");
$a = new Net::DNS::Packet("www.hash.com", "A", "IN");
$r = $res->ANY($q, $a, { from => new NetAddr::IP '127.0.0.1' } );
ok (($a->answer)[0]->string 
    eq Net::DNS::RR->new('www.hash.com IN A 10.10.10.10')->string,
    'correct answer for www.hash.com');

ok ($r == (NS_OK|NS_STOP), 'proper return value for defined FQDN');

$q = new Net::DNS::Question("ftp.hash.com", "A", "IN");
$a = new Net::DNS::Packet("ftp.hash.com", "A", "IN");
$r = $res->ANY($q, $a, { from => new NetAddr::IP '127.0.0.1' } );
ok (($a->answer)[0]->string 
    eq Net::DNS::RR->new('ftp.hash.com IN A 10.10.10.10')->string,
    'correct answer for ftp.hash.com');

ok ($r == (NS_OK|NS_STOP), 'proper return value for defined FQDN with dot');

$q = new Net::DNS::Question("hash.com", "ANY", "IN");
$a = new Net::DNS::Packet("hash.com", "ANY", "IN");
$r = $res->ANY($q, $a, { from => new NetAddr::IP '127.0.0.1' } );

ok ($r == (NS_OK|NS_STOP), 'zone succeeds when defined');
ok (($a->answer)[0]->string 
    eq Net::DNS::RR->new('hash.com IN CNAME www.hash.com')->string,
    'correct answer for hash.com');




