use Test::More tests => 10;
use Test::Exception;
use Net::DNSBL::Client;

my $c = Net::DNSBL::Client->new();

throws_ok
	{ $c->query_ip(); }
	qr/^First argument \(ip address\) is required/,
	'->query_ip dies when called with no args';

throws_ok
	{ $c->query_ip('127.0.0.2') }
	qr/^Second argument \(dnsbl list\) is required/,
	'->query_ip() dies when called with no dnsbl list';

throws_ok
	{ $c->query_ip('roaringpenguin.com', [ { domain => 'bogus.for.testing' } ] ) }
	qr/^Unrecognized IP address 'roaringpenguin.com'/,
	'->query_ip() dies when called with hostname instead of IP address';

throws_ok
{ $c->get_answers() ; }
    qr/^Cannot call get_answers unless a query is in flight/,
    'get_answers() dies when no query is in flight';

# Hack
{
	local $c->{in_flight} = 1;
	throws_ok
		{ $c->query_ip('127.0.0.2', [ { domain => 'bogus.for.testing' } ] ) }
		qr/^Cannot issue new query while one is in flight/,
		'->query_ip() dies when called with existing query in flight';
}

throws_ok
{ $c->set_timeout('wookie'); }
qr/^Timeout must be a positive integer/,
    'set_timeout dies when given nonsensical timeout';

throws_ok
{ $c->set_timeout(0); }
qr/^Timeout must be a positive integer/,
    'set_timeout dies when given zero timeout';

throws_ok
{ my $d = Net::DNSBL::Client->new({timeout => 'wookie'}); }
qr/^Timeout must be a positive integer/,
    'Constructor dies when given nonsensical timeout';

throws_ok
{ my $d = Net::DNSBL::Client->new({timeout => 0}); }
qr/^Timeout must be a positive integer/,
    'Constructor dies when given zero timeout';

throws_ok
{ my $d = Net::DNSBL::Client->new({burble => 1, quux => 2, barf => 3}); }
qr/^Unknown arguments to new: barf, burble, quux/,
    'Constructor dies when given unknown parameters';
