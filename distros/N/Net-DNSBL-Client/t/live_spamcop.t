use Test::More 0.82;
use Test::Deep;
use Net::DNSBL::Client;

plan skip_all => 'DNS unavailable; skipping tests' unless Net::DNS::Resolver->new->query('cpan.org');
plan tests => 1;

my $c = Net::DNSBL::Client->new();


$c->query_ip('127.0.0.2',
	[ {
		domain => 'bl.spamcop.net',
		type   => 'match',
		data   => '127.0.0.2'
	},
]);

my @expected = ({
		domain     => 'bl.spamcop.net',
		userdata   => undef,
		hit        => 1,
		data       => '127.0.0.2',
		actual_hits => [ '127.0.0.2' ],
		replycode  => 'NOERROR',
		type       => 'match'
	});

my $got = $c->get_answers();
cmp_deeply( $got, bag(@expected), "Got expected answers from spamcop testpoint") || diag explain \@expected, $got;
