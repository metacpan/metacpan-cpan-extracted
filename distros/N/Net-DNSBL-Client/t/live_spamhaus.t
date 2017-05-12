use Test::More 0.82;
use Test::Deep;
use Net::DNSBL::Client;

plan skip_all => 'DNS unavailable; skipping tests' unless Net::DNS::Resolver->new->query('cpan.org');
plan tests => 5;

my $c = Net::DNSBL::Client->new();


my $rbls = [ {
		domain => 'zen.spamhaus.org',
		type   => 'match',
		data   => '127.0.0.2'
	},
	{
		domain => 'zen.spamhaus.org',
		type   => 'match',
		data   => '127.0.0.4'
	},
	{
		domain => 'zen.spamhaus.org',
		type   => 'match',
		data   => '127.0.0.10'
	},
	{
		domain => 'zen.spamhaus.org',
		type   => 'match',
		data   => '127.0.0.20'
	}
    ];

$c->query_ip('127.0.0.2', $rbls);

my @expected = ({
		domain     => 'zen.spamhaus.org',
		userdata   => undef,
		hit        => 1,
		data       => '127.0.0.2',
		actual_hits => [ '127.0.0.2' ],
		replycode  => 'NOERROR',
		type       => 'match'
	},
	{
		domain     => 'zen.spamhaus.org',
		userdata   => undef,
		hit        => 1,
		data       => '127.0.0.4',
		actual_hits => [ '127.0.0.4' ],
		replycode  => 'NOERROR',
		type       => 'match'
	},
	{
		domain     => 'zen.spamhaus.org',
		userdata   => undef,
		hit        => 1,
		data       => '127.0.0.10',
		actual_hits => [ '127.0.0.10' ],
		replycode  => 'NOERROR',
		type       => 'match'
	});

my $got = $c->get_answers();
cmp_deeply( $got, bag(@expected), "Got expected answers from spamhaus testpoint") || diag explain \@expected, $got;

# Now try it with the return_all flag on
push(@expected, {
	data => '127.0.0.20',
	domain => 'zen.spamhaus.org',
	hit => 0,
	replycode => 'NOERROR',
	type => 'match',
	userdata => undef});

$c->query_ip('127.0.0.2', $rbls, {return_all => 1});
$got = $c->get_answers();
cmp_deeply( $got, bag(@expected), "Got expected answers from spamhaus testpoint") || diag explain \@expected, $got;

$c->query_ip('127.0.0.3', [{domain => 'zen.spamhaus.org',
			    type   => 'match',
			    data   => '127.0.0.2'},
			   {domain => 'zen.spamhaus.org',
			    type   => 'match',
			    data   => '127.0.0.2'}]);
$got = $c->get_answers();
cmp_deeply( $got, [], "Got expected NXDOMAIN answers from spamhaus with return_all => 0") || diag explain [], $got;

@expected = ({data => '127.0.0.2',
	      domain => 'zen.spamhaus.org',
	      hit => 0,
	      replycode => 'NXDOMAIN',
	      type => 'match',
	      userdata => undef},
	     {
	      data => '127.0.0.2',
	      domain => 'zen.spamhaus.org',
	      hit => 0,
	      replycode => 'NXDOMAIN',
	      type => 'match',
	      userdata => undef
	     }
    );

$c->query_ip('127.0.0.3', [{domain => 'zen.spamhaus.org',
			    type   => 'match',
			    data   => '127.0.0.2'},
			   {domain => 'zen.spamhaus.org',
			    type   => 'match',
			    data   => '127.0.0.2'}], {return_all => 1});
$got = $c->get_answers();
cmp_deeply( $got, \@expected, "Got expected NXDOMAIN answers from spamhaus with return_all => 1") || diag explain \@expected, $got;


@expected = (
	{
		domain     => 'zen.spamhaus.org',
		userdata   => undef,
		hit        => 1,
		data       => undef,
		actual_hits => bag(
			'127.0.0.2',
			'127.0.0.4',
			'127.0.0.10',
		),
		replycode  => 'NOERROR',
		type       => 'normal'
	},
);
$c->query_ip('127.0.0.2', [ { domain => 'zen.spamhaus.org'} ]);
$got = $c->get_answers();
cmp_deeply( $got, \@expected, "Got multiple actual_hits in normal mode") || diag explain \@expected, $got;
