# This is -*- perl -*-
# Basic testing of the Net::DNS::Method::Constant module

# luismunoz@cpan.org
# $Id: b-const.t,v 1.2 2002/10/23 04:43:58 lem Exp $

use Test::More tests => 19;

use Net::DNS::RR;
use Net::DNS::Method;
use Net::DNS::Method::Constant;

my $rr_data = "IN A 127.0.0.1";

my $rr_a = new Net::DNS::RR $rr_data;

my $res = new Net::DNS::Method::Constant('acme.com', 'IN', 'A',
					 $rr_data);

ok (defined $res, 'new Net::DNS::Method::Constant');

my $q = new Net::DNS::Question("acme.com", "A", "IN");
my $a = new Net::DNS::Packet("acme.com", "A", "IN");
my $r = $res->A($q, $a);

ok ($r == (NS_OK|NS_STOP), 'Proper return value for A');
ok (($a->answer)[0]->string 
    eq Net::DNS::RR->new('acme.com ' 
			 . $rr_data)->string,
    'Proper answer to A RR w/o dot');

$r = $res->ANY($q, $a);

ok ($r == (NS_OK|NS_STOP), 'Proper return value for ANY');
ok (($a->answer)[0]->string 
    eq Net::DNS::RR->new('acme.com ' 
			 . $rr_data)->string,
    'Proper answer to ANY RR w/o dot');

$q = new Net::DNS::Question("acme.com.", "A", "IN");
$a = new Net::DNS::Packet("acme.com.", "A", "IN");
$r = $res->A($q, $a);

ok ($r == (NS_OK|NS_STOP), 'Proper return value for A');
ok (($a->answer)[0]->string 
    eq Net::DNS::RR->new('acme.com ' 
			 . $rr_data)->string,
    'Proper answer to A RR with dot');

$q = new Net::DNS::Question("nacme.com.", "A", "IN");
$a = new Net::DNS::Packet("nacme.com.", "A", "IN");
$r = $res->A($q, $a);

ok ($r == NS_FAIL, 'Proper return value for a wrong question with head');

$q = new Net::DNS::Question("acme.comx", "A", "IN");
$a = new Net::DNS::Packet("acme.comx", "A", "IN");
$r = $res->A($q, $a);

ok ($r == NS_FAIL, 'Proper return value for a wrong question with tail');

$q = new Net::DNS::Question("www.acme.com.", "A", "IN");
$a = new Net::DNS::Packet("www.acme.com.", "A", "IN");
$r = $res->A($q, $a);

ok ($r == (NS_OK|NS_STOP), 'Proper return value for A');
ok (($a->answer)[0]->string 
    eq Net::DNS::RR->new('www.acme.com ' 
			 . $rr_data)->string,
    'Proper answer to A FQDN RR with dot');

$q = new Net::DNS::Question("s1.www.acme.com.", "A", "IN");
$a = new Net::DNS::Packet("s1.www.acme.com.", "A", "IN");
$r = $res->A($q, $a);

ok ($r == (NS_OK|NS_STOP), 'Proper return value for A');
ok (($a->answer)[0]->string 
    eq Net::DNS::RR->new('s1.www.acme.com ' 
			 . $rr_data)->string,
    'Proper answer to A (double) FQDN RR with dot');

$q = new Net::DNS::Question("www.acme.com", "A", "IN");
$a = new Net::DNS::Packet("www.acme.com", "A", "IN");
$r = $res->A($q, $a);

ok ($r == (NS_OK|NS_STOP), 'Proper return value for A');
ok (($a->answer)[0]->string 
    eq Net::DNS::RR->new('www.acme.com ' 
			 . $rr_data)->string,
    'Proper answer to A FQDN RR w/o dot');

$q = new Net::DNS::Question("s1.www.acme.com", "A", "IN");
$a = new Net::DNS::Packet("s1.www.acme.com", "A", "IN");
$r = $res->A($q, $a);

ok ($r == (NS_OK|NS_STOP), 'Proper return value for A');
ok (($a->answer)[0]->string 
    eq Net::DNS::RR->new('s1.www.acme.com ' 
			 . $rr_data)->string,
    'Proper answer to A (double) FQDN RR w/o dot');

$res = new Net::DNS::Method::Constant('www.acme.com', 'IN', 'A',
					 $rr_data);

$q = new Net::DNS::Question("s1.www.acme.com", "A", "IN");
$a = new Net::DNS::Packet("s1.www.acme.com", "A", "IN");
$r = $res->A($q, $a);

ok ($r == (NS_OK|NS_STOP), 'Proper return value for A');
ok (($a->answer)[0]->string 
    eq Net::DNS::RR->new('s1.www.acme.com ' 
			 . $rr_data)->string,
    'Proper answer to A (double) FQDN RR w/o dot, longer zone');

