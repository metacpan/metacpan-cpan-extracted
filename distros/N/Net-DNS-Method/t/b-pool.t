# This is -*- perl -*-
# Basic testing of the Net::DNS::Method::Pool module

# luismunoz@cpan.org
# $Id: b-pool.t,v 1.2 2002/10/23 04:43:59 lem Exp $

use Test::More tests => 7;

use Net::DNS::RR;
use NetAddr::IP 3.00;
use Net::DNS::Method;
use Net::DNS::Method::Pool;

my $res = new Net::DNS::Method::Pool {
    BaseDomain	=> 'd.p.com',
    Prefix	=> 'd-',
    Pool	=> [ '10.', '192.168.0/24' ],
    ttl		=> 7200
};

ok (defined $res, '->new()');

my $q = new Net::DNS::Question("mystatus.x.com", "A", "IN");
my $a = new Net::DNS::Packet("mystatus.x.com", "A", "IN");
my $r = $res->ANY($q, $a, { from => new NetAddr::IP '127.0.0.1' } );

ok ($r == NS_FAIL, 'unexistant object');

$q = new Net::DNS::Question("d-10-0-0-0.d.p.com", "A", "IN");
$a = new Net::DNS::Packet("d-10-0-0-0.d.p.com", "A", "IN");
$r = $res->ANY($q, $a, { from => new NetAddr::IP '127.0.0.1' } );

ok ($r == (NS_OK|NS_STOP), 'return for a correct forward resolution');
ok (($a->answer)[0]->string
    eq Net::DNS::RR->new('d-10-0-0-0.d.p.com 7200 IN A 10.0.0.0')->string,
    'correct forward answer for A');

$q = new Net::DNS::Question("1.2.3.10.in-addr.arpa", "PTR", "IN");
$a = new Net::DNS::Packet("1.2.3.10.in-addr.arpa", "PTR", "IN");
$r = $res->ANY($q, $a, { from => new NetAddr::IP '127.0.0.1' } );

ok ($r == (NS_OK|NS_STOP), 'return for a correct reverse resolution');
ok (($a->answer)[0]->string
    eq Net::DNS::RR->new('1.2.3.10.in-addr.arpa 7200 IN PTR '
			 . 'd-10-3-2-1.d.p.com')->string,
    'correct reverse answer for PTR');

$q = new Net::DNS::Question("d-10-0-0-0.dyp.com", "A", "IN");
$a = new Net::DNS::Packet("d-10-0-0-0.dyp.com", "A", "IN");
$r = $res->ANY($q, $a, { from => new NetAddr::IP '127.0.0.1' } );

ok ($r == NS_FAIL, 'unexistant but similar object');

