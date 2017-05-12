use Test::More 0.82;
use Test::Deep;
use Net::DNSBL::Client;

plan skip_all => 'DNS unavailable; skipping tests' unless Net::DNS::Resolver->new->query('cpan.org');
plan tests => 2;

my $c = Net::DNSBL::Client->new();

# http://www.dnswl.org/tech
$c->query_ip('127.0.0.2', [
	{
		domain => 'list.dnswl.org',
		type   => 'mask',
		data   => '0.0.255.255',
		userdata => 'Matches any dnswl.org category',
	},
]);

my @expected = (
	{
		domain => 'list.dnswl.org',
		userdata => 'Matches any dnswl.org category',
		hit => 1,
		data => '0.0.255.255',
		actual_hits => [ '127.0.10.0' ],
		replycode  => 'NOERROR',
		type => 'mask'
	},
);
$got = $c->get_answers();
cmp_deeply( $got, bag(@expected), "Got expected answers from dnswl testpoint") || diag explain \@expected, $got;

$c->query_ip('127.0.0.2', [
	{
		domain => 'list.dnswl.org',
		type   => 'txt',
		userdata => 'Matches any dnswl.org category',
	},
]);

@expected = (
	{
		domain => 'list.dnswl.org',
		userdata => 'Matches any dnswl.org category',
		hit => 1,
		data => undef,
		actual_hits => [ 'dnswl.test http://dnswl.org/s?s=127' ],
		replycode  => 'NOERROR',
		type => 'txt'
	},
);
my $got = $c->get_answers();
cmp_deeply( $got, bag(@expected), "Got expected answers from dnswl testpoint") || diag explain \@expected, $got;
