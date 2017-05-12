# This is -*- perl -*-
# Basic testing of the Net::DNS::Method::Regexp module

# luismunoz@cpan.org
# $Id: b-regex.t,v 1.2 2002/10/23 04:43:59 lem Exp $

use Test::More tests => 41;

use Net::DNS::RR;
use Net::DNS::Method;
use Net::DNS::Method::Regexp;

my $res = new Net::DNS::Method::Regexp {
    '^w+\.test\.com\.? \s+ IN \s+ A$' => {
	answer => [ new Net::DNS::RR "www.test.com. 10 IN A 10.10.10.10" ],
	authority => [ new Net::DNS::RR "test.com. 1000 IN NS ns.test.com." ],
	additional => [ new Net::DNS::RR "ns.test.com. 10 IN A 10.10.10.11" ],
	question => [],
	ra => 1,
	rd => 1,
	aa => 1,
	tc => 1,
	return => NS_OK | NS_STOP
    }
};

ok (defined $res, '->new()');

my $q = new Net::DNS::Question("w.test.com", "A", "IN");
my $a = new Net::DNS::Packet("w.test.com", "A", "IN");
my $r = $res->A($q, $a);

ok ($r == (NS_OK|NS_STOP), 'Proper return value for A');

ok (($a->answer)[0]->string 
    eq Net::DNS::RR->new('www.test.com 10 IN A 10.10.10.10')->string,
    'Proper answer to A RR w/o dot');

ok (($a->authority)[0]->string 
    eq Net::DNS::RR->new('test.com 1000 IN NS ns.test.com.')->string,
    'Proper authority to A RR w/o dot');

ok (($a->additional)[0]->string 
    eq Net::DNS::RR->new('ns.test.com 10 IN A 10.10.10.11')->string,
    'Proper additional to A RR w/o dot');

ok ($a->header->ra, "ra flag");
ok ($a->header->rd, "rd flag");
ok ($a->header->aa, "aa flag");
ok ($a->header->tc, "tc flag");

$q = new Net::DNS::Question("w.test.com", "A", "IN");
$a = new Net::DNS::Packet("w.test.com", "A", "IN");
$r = $res->ANY($q, $a);

ok ($r == (NS_OK|NS_STOP), 'Proper return value for ANY');
ok (($a->answer)[0]->string 
    eq Net::DNS::RR->new('www.test.com 10 IN A 10.10.10.10')->string,
    'Proper answer to ANY RR w/o dot');

ok (($a->authority)[0]->string 
    eq Net::DNS::RR->new('test.com 1000 IN NS ns.test.com.')->string,
    'Proper authority to ANY RR w/o dot');

ok (($a->additional)[0]->string 
    eq Net::DNS::RR->new('ns.test.com 10 IN A 10.10.10.11')->string,
    'Proper additional to ANY RR w/o dot');

ok ($a->header->ra, "ra flag");
ok ($a->header->rd, "rd flag");
ok ($a->header->aa, "aa flag");
ok ($a->header->tc, "tc flag");

$q = new Net::DNS::Question("w.test.com.", "A", "IN");
$a = new Net::DNS::Packet("w.test.com.", "A", "IN");
$r = $res->A($q, $a);

ok ($r == (NS_OK|NS_STOP), 'Proper return value for A');

ok (($a->answer)[0]->string 
    eq Net::DNS::RR->new('www.test.com. 10 IN A 10.10.10.10')->string,
    'Proper answer to A RR with dot');

ok (($a->authority)[0]->string 
    eq Net::DNS::RR->new('test.com. 1000 IN NS ns.test.com.')->string,
    'Proper authority to A RR with dot');

ok (($a->additional)[0]->string 
    eq Net::DNS::RR->new('ns.test.com. 10 IN A 10.10.10.11')->string,
    'Proper additional to A RR with dot');

ok ($a->header->ra, "ra flag");
ok ($a->header->rd, "rd flag");
ok ($a->header->aa, "aa flag");
ok ($a->header->tc, "tc flag");

$q = new Net::DNS::Question("w.test.com.", "A", "IN");
$a = new Net::DNS::Packet("w.test.com.", "A", "IN");
$r = $res->ANY($q, $a);

ok ($r == (NS_OK|NS_STOP), 'Proper return value for ANY');
ok (($a->answer)[0]->string 
    eq Net::DNS::RR->new('www.test.com. 10 IN A 10.10.10.10')->string,
    'Proper answer to ANY RR with dot');

ok (($a->authority)[0]->string 
    eq Net::DNS::RR->new('test.com. 1000 IN NS ns.test.com..')->string,
    'Proper authority to ANY RR with dot');

ok (($a->additional)[0]->string 
    eq Net::DNS::RR->new('ns.test.com. 10 IN A 10.10.10.11')->string,
    'Proper additional to ANY RR with dot');

ok ($a->header->ra, "ra flag");
ok ($a->header->rd, "rd flag");
ok ($a->header->aa, "aa flag");
ok ($a->header->tc, "tc flag");

$q = new Net::DNS::Question("w.xfail.net.", "A", "IN");
$a = new Net::DNS::Packet("w.xfail.net.", "A", "IN");
$r = $res->ANY($q, $a);

ok ($r == NS_FAIL, 'Proper return value for ANY with wrong name');

ok (!$a->$_, qq{No $_ for ANY with wrong name}) 
for (qw(answer authority additional));

ok (!$a->header->ra, "no ra flag");
ok ($a->header->rd, "rd flag");
ok (!$a->header->aa, "no aa flag");
ok (!$a->header->tc, "no tc flag");





