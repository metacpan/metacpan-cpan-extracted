# This is -*- perl -*-
# Basic testing of the Net::DNS::Method::Status module

# luismunoz@cpan.org
# $Id: b-status.t,v 1.3 2003/06/14 20:05:12 lem Exp $

use Test::More tests => 17;

use Net::DNS::RR;
use NetAddr::IP 3.00;
use Net::DNS::Method;
use Net::DNS::Method::Status;

my $res = new Net::DNS::Method::Status {
    BaseDomain		=> 'status.x.com',
    StoreResults	=> 1,
    Reset		=> 'reset',
};

ok (defined $res, '->new()');

my $q = new Net::DNS::Question("mystatus.x.com", "A", "IN");
my $a = new Net::DNS::Packet("mystatus.x.com", "A", "IN");
my $r = $res->ANY($q, $a, { from => new NetAddr::IP '127.0.0.1' } );

ok ($r == NS_FAIL, '1st priming of the ::Status object');

$q = new Net::DNS::Question("reset.mystatus.x.com", "A", "IN");
$a = new Net::DNS::Packet("reset.mystatus.x.com", "A", "IN");
$r = $res->ANY($q, $a, { from => new NetAddr::IP '127.0.0.1' } );

ok ($r == NS_FAIL, '2nd priming of the ::Status object');

$q = new Net::DNS::Question("statusno.x.com", "A", "IN");
$a = new Net::DNS::Packet("statusno.x.com", "A", "IN");
$r = $res->ANY($q, $a, { from => new NetAddr::IP '127.0.0.1' } );

ok ($r == NS_FAIL, '3rd priming of the ::Status object');

$q = new Net::DNS::Question("status.x.com", "A", "IN");
$a = new Net::DNS::Packet("status.x.com", "A", "IN");
$r = $res->ANY($q, $a, { from => new NetAddr::IP '127.0.0.1' } );

ok ($r == (NS_OK|NS_STOP), 'Query of the ::Status object');

ok (($a->answer)[0]->string 
    eq Net::DNS::RR->new('status.x.com. 0 IN TXT "OK"')->string,
    '::Status returns OK');

for my $item (qw(
		 pid.status.x.com
		 started.status.x.com
		 last.status.x.com
		 A.q.status.x.com
		 total.q.status.x.com
		 qps.q.status.x.com
		 q0.status.x.com
	     ))
{
    ok ((grep { $_->name eq $item } $a->additional) == 1,
	"$item report is present");
}

my ($rr) = grep { $_->name eq 'A.q.status.x.com' } $a->additional;
ok ($rr->string eq Net::DNS::RR->new('A.q.status.x.com 0 IN TXT "3"')->string,
    'correct A count');

($rr) = grep { $_->name eq 'total.q.status.x.com' } $a->additional;
ok ($rr->string 
    eq Net::DNS::RR->new('total.q.status.x.com 0 IN TXT "3"')->string,
    'correct total count');

($rr) = grep { $_->name eq 'q0.status.x.com' } $a->additional;
is ($rr->string 
    , Net::DNS::RR
    ->new('q0.status.x.com 0 IN TXT "127.0.0.1->IN" "A" "status.x.com"')->string,
    'correct query history');

ok ((grep { $_->name eq 'q1.status.x.com' } $a->additional) == 0,
    'no additional history entries');

