use Test::More 0.82;
use Test::Deep;
use Net::DNSBL::Client;

plan skip_all => 'DNS unavailable; skipping tests' unless Net::DNS::Resolver->new->query('cpan.org');
plan tests => 2;

my $c = Net::DNSBL::Client->new();

# http://virbl.bit.nl/
# Has ipv6 entries (well... an ipv6 test entry)
$c->query_ip('::127.0.0.2', [
	{
		domain => 'virbl.dnsbl.bit.nl',
		type   => 'match',
		data   => '127.0.0.2'
	},
]);

my @expected = ({
		domain     => 'virbl.dnsbl.bit.nl',
		userdata   => undef,
		hit        => 1,
		data       => '127.0.0.2',
		actual_hits => [ '127.0.0.2' ],
		type       => 'match',
		replycode  => 'NOERROR'
	},
);

my $got = $c->get_answers();
cmp_deeply( $got, bag(@expected), "Got expected answers from virbl ipv6 testpoint (embedded ipv4)") || diag explain \@expected, $got;

$c->query_ip('::ffff:7f00:0002', [
	{
		domain => 'virbl.dnsbl.bit.nl',
		type   => 'match',
		data   => '127.0.0.2'
	},
]);
$got = $c->get_answers();
cmp_deeply( $got, bag(@expected), "Got expected answers from virbl ipv6 testpoint (ipv6-formatted ipv4)") || diag explain \@expected, $got;
