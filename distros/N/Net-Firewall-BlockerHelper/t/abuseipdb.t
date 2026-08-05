#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

# ban reports, unban/flush/teardown are internal only
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'abuseipdb',
		name    => 'ssh',
		prefix  => 'kur',
		testing => 1,
		options => { key => 'someAPIkey', categories => [ '18', '22' ] },
	);
	$fw->init_backend;

	is( $fw->{test_data}[0]{method}, 'GET', 'init probes with a GET' );
	is( $fw->{test_data}[0]{url},
		'https://api.abuseipdb.com/api/v2/check?ipAddress=127.0.0.2&maxAgeInDays=1',
		'init probes the check endpoint' );

	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data}[0]{method}, 'POST', 'ban is a POST' );
	is( $fw->{test_data}[0]{url}, 'https://api.abuseipdb.com/api/v2/report', 'ban targets the report endpoint' );
	is( $fw->{test_data}[0]{content},
		'ip=1.2.3.4&categories=18%2C22&comment=banned%20by%20kur_ssh',
		'report body carries ip, categories, and the default comment' );

	$fw->ban( ban => 'DEAD::1' );
	like( $fw->{test_data}[0]{content}, qr/^ip=dead%3A%3A1&/, 'IPv6 is reported lowercased' );

	$fw->unban( ban => '1.2.3.4' );
	is( $fw->{test_data}, 'unban is internal only', 'unban makes no API call' );

	my $cidr_blocked = 0;
	eval { $fw->ban_cidr( ban => '1.2.3.0/24' ); };
	if ( defined( $fw->{error} ) && $fw->{error} == 29 ) { $cidr_blocked = 1; }
	if ( !$cidr_blocked ) {
		die( 'ban_cidr did not set frontend error 29 cidrNotSupported... got ' . ( defined( $fw->{error} ) ? $fw->{error} : 'undef' ) );
	}

	my @banned = sort( $fw->list );
	is_deeply( \@banned, ['dead::1'], 'unban removed the IP from the ban book' );

	$fw->flush;
	is( $fw->{test_data}, 'flush is internal only', 'flush makes no API call' );
	@banned = $fw->list;
	is_deeply( \@banned, [], 'flush cleared the ban book' );
}

# comment templating and string categories
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'abuseipdb',
		name    => 'ssh',
		testing => 1,
		options => { key => 'k', categories => '18', comment => 'seen brute forcing from %%%BAN%%%' },
	);
	$fw->init_backend;
	$fw->ban( ban => '9.9.9.9' );
	is( $fw->{test_data}[0]{content},
		'ip=9.9.9.9&categories=18&comment=seen%20brute%20forcing%20from%209.9.9.9',
		'%%%BAN%%% in the comment is replaced with the IP' );
}

# a blank comment is left out
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'abuseipdb',
		name    => 'ssh',
		testing => 1,
		options => { key => 'k', comment => '' },
	);
	$fw->init_backend;
	$fw->ban( ban => '9.9.9.9' );
	is( $fw->{test_data}[0]{content}, 'ip=9.9.9.9&categories=18', 'blank comment is omitted from the body' );
}

# key is required
{
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new( backend => 'abuseipdb', name => 'ssh', testing => 1 );
		$fw->init_backend;
	};
	$died = 1 if ($@);
	ok( $died, 'missing key is fatal' );
}

# categories must be positive ints
for my $bad ( [ '18', 'derp' ], 'derp', '18,,22' ) {
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new(
			backend => 'abuseipdb', name => 'ssh', testing => 1,
			options => { key => 'k', categories => $bad },
		);
		$fw->init_backend;
	};
	$died = 1 if ($@);
	ok( $died, 'invalid categories are fatal' );
}

# ports are rejected (reporting is whole IP)
{
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new(
			backend => 'abuseipdb', name => 'ssh', testing => 1,
			ports   => ['22'], options => { key => 'k' },
		);
		$fw->init_backend;
	};
	$died = 1 if ($@);
	ok( $died, 'specifying ports is fatal' );
}

done_testing();
