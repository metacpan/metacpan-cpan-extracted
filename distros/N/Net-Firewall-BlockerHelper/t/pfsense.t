#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

# ban renders the alias membership and applies
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'pfsense',
		name    => 'ssh',
		prefix  => 'kur',
		testing => 1,
		options => { host => 'h', key => 'TOK' },
	);
	$fw->init_backend;

	is( $fw->{test_data}[0]{method}, 'GET', 'init probes the alias with a GET' );
	is( $fw->{test_data}[0]{url},
		'https://h/api/v2/firewall/alias?name=kur_ssh',
		'init fetches the alias by name' );

	$fw->ban( ban => '1.2.3.4' );
	is( scalar( @{ $fw->{test_data} } ), 2, 'ban is two requests' );
	is( $fw->{test_data}[0]{method}, 'PATCH', 'ban first PATCHes the alias' );
	is( $fw->{test_data}[0]{url},    'https://h/api/v2/firewall/alias', 'PATCH goes to the alias endpoint' );
	is( $fw->{test_data}[0]{content},
		'{"address":["1.2.3.4"],"id":"kur_ssh","type":"host"}',
		'rendered body lists the banned IP' );
	is( $fw->{test_data}[1]{method}, 'POST', 'ban then POSTs an apply' );
	is( $fw->{test_data}[1]{url},    'https://h/api/v2/firewall/apply', 'apply goes to the apply endpoint' );

	$fw->ban( ban => '5.6.7.8' );
	is( $fw->{test_data}[0]{content},
		'{"address":["1.2.3.4","5.6.7.8"],"id":"kur_ssh","type":"host"}',
		'second ban renders both IPs sorted' );

	$fw->unban( ban => '1.2.3.4' );
	is( $fw->{test_data}[0]{method}, 'PATCH', 'unban PATCHes the alias' );
	is( $fw->{test_data}[0]{content},
		'{"address":["5.6.7.8"],"id":"kur_ssh","type":"host"}',
		'unban drops the removed IP from the rendered body' );
	is( $fw->{test_data}[1]{url}, 'https://h/api/v2/firewall/apply', 'unban also applies' );

	# CIDR support
	ok( $fw->{backend_obj}{cidr_supported}, 'cidr is supported' );
	$fw->unban( ban => '5.6.7.8' );    # start from an empty alias so the CIDR body is predictable
	$fw->ban_cidr( ban => '1.2.3.0/24' );
	is( $fw->{test_data}[0]{method}, 'PATCH', 'ban_cidr PATCHes the alias' );
	is( $fw->{test_data}[0]{content},
		'{"address":["1.2.3.0/24"],"id":"kur_ssh","type":"host"}',
		'ban_cidr renders the CIDR into the alias body' );
	is( $fw->{test_data}[1]{url}, 'https://h/api/v2/firewall/apply', 'ban_cidr also applies' );
	my %listed = map { $_ => 1 } $fw->{backend_obj}->list_cidr;
	ok( $listed{'1.2.3.0/24'}, 'list_cidr contains the banned CIDR' );
	$fw->unban_cidr( ban => '1.2.3.0/24' );
	%listed = map { $_ => 1 } $fw->{backend_obj}->list_cidr;
	ok( !$listed{'1.2.3.0/24'}, 'list_cidr no longer contains the CIDR after unban_cidr' );
}

# custom alias name
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'pfsense', name => 'ssh', testing => 1,
		options => { host => 'h', key => 't', alias => 'blocked' },
	);
	$fw->init_backend;
	is( $fw->{test_data}[0]{url}, 'https://h/api/v2/firewall/alias?name=blocked', 'custom alias name used' );
}

# host and key are both required
for my $missing (qw(host key)) {
	my %opts = ( host => 'h', key => 't' );
	delete $opts{$missing};
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new(
			backend => 'pfsense', name => 'ssh', testing => 1, options => \%opts,
		);
		$fw->init_backend;
	};
	$died = 1 if ($@);
	ok( $died, "missing $missing is fatal" );
}

done_testing();
