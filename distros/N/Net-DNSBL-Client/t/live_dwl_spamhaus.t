use Test::More 0.82;
use Test::Deep;
use Net::DNSBL::Client;

plan skip_all => 'DNS unavailable; skipping tests' unless Net::DNS::Resolver->new->query('cpan.org');
plan tests => 1;

ok(1, 'dwltest.com._vouch.dwl.spamhaus.org returns nothing useful; enable these tests if/when SpamHaus fixes it.');
exit(0);

my $c = Net::DNSBL::Client->new();

# http://www.spamhauswhitelist.com/en/usage.html
$c->query_domain('dwltest.com', [
	{
		domain => '_vouch.dwl.spamhaus.org',
		type   => 'txt',
		userdata => 'Matches DWL TXT',
	},
	{
		domain => '_vouch.dwl.spamhaus.org',
		type   => 'normal',
		userdata => 'Matches DWL A',
	},
]);

my @expected = (
	{
		data => undef,
		domain => '_vouch.dwl.spamhaus.org',
		actual_hits => ['all test'],
		hit => 1,
		replycode => 'NOERROR',
		type => 'txt',
		userdata => 'Matches DWL TXT',
	},
	{
		data => undef,
		domain => '_vouch.dwl.spamhaus.org',
		actual_hits => ['127.0.0.0'],
		hit => 1,
		replycode => 'NOERROR',
		type => 'normal',
		userdata => 'Matches DWL A',
	},
);
my $got = $c->get_answers();

cmp_deeply( $got, bag(@expected), "Got expected answers from dnswl testpoint") || diag explain \@expected, $got;
