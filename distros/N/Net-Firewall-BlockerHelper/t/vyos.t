#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

# ban/unban records the op JSON (without the key) split by family
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'vyos',
		name    => 'ssh',
		prefix  => 'kur',
		testing => 1,
		options => { host => 'h', key => 'SECRET' },
	);
	$fw->init_backend;

	is( $fw->{test_data}[0]{method}, 'POST', 'init POSTs' );
	is( $fw->{test_data}[0]{url},    'https://h/retrieve', 'init retrieves the config' );
	is( $fw->{test_data}[0]{content},
		'{"op":"showConfig","path":["firewall","group","address-group","kur_ssh"]}',
		'init retrieve body has no key' );

	$fw->ban( ban => '1.2.3.4' );
	is( scalar( @{ $fw->{test_data} } ), 1, 'ban is one request' );
	is( $fw->{test_data}[0]{method}, 'POST', 'ban POSTs' );
	is( $fw->{test_data}[0]{url},    'https://h/configure', 'ban goes to /configure' );
	is( $fw->{test_data}[0]{content},
		'{"op":"set","path":["firewall","group","address-group","kur_ssh","address","1.2.3.4"]}',
		'ban records the set op JSON with no key' );

	$fw->ban( ban => 'dead::1' );
	is( $fw->{test_data}[0]{content},
		'{"op":"set","path":["firewall","group","ipv6-address-group","kur_ssh","address","dead::1"]}',
		'IPv6 uses the ipv6-address-group node' );

	$fw->unban( ban => '1.2.3.4' );
	is( $fw->{test_data}[0]{content},
		'{"op":"delete","path":["firewall","group","address-group","kur_ssh","address","1.2.3.4"]}',
		'unban records the delete op JSON with no key' );

	ok( $fw->{backend_obj}{cidr_supported}, 'cidr is supported' );
	$fw->ban_cidr( ban => '1.2.3.0/24' );
	is( $fw->{test_data}[0]{content},
		'{"op":"set","path":["firewall","group","address-group","kur_ssh","address","1.2.3.0/24"]}',
		'ban_cidr records the set op JSON for the CIDR' );
	my %listed = map { $_ => 1 } $fw->{backend_obj}->list_cidr;
	ok( $listed{'1.2.3.0/24'}, 'list_cidr contains the banned CIDR' );
	$fw->unban_cidr( ban => '1.2.3.0/24' );
	%listed = map { $_ => 1 } $fw->{backend_obj}->list_cidr;
	ok( !$listed{'1.2.3.0/24'}, 'list_cidr no longer contains the CIDR after unban_cidr' );
}

# custom group name
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'vyos', name => 'ssh', testing => 1,
		options => { host => 'h', key => 't', group => 'blocked' },
	);
	$fw->init_backend;
	$fw->ban( ban => '9.9.9.9' );
	is( $fw->{test_data}[0]{content},
		'{"op":"set","path":["firewall","group","address-group","blocked","address","9.9.9.9"]}',
		'custom group name used' );
}

# check does the retrieve probe and returns true in testing
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'vyos', name => 'ssh', testing => 1,
		options => { host => 'h', key => 't' },
	);
	$fw->init_backend;
	ok( $fw->{backend_obj}->check, 'check returns true in testing' );
	is( $fw->{backend_obj}->{test_data} || $fw->{test_data}[0]{url},
		'https://h/retrieve', 'check retrieves' );
}

# host and key are both required
for my $missing (qw(host key)) {
	my %opts = ( host => 'h', key => 't' );
	delete $opts{$missing};
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new(
			backend => 'vyos', name => 'ssh', testing => 1, options => \%opts,
		);
		$fw->init_backend;
	};
	$died = 1 if ($@);
	ok( $died, "missing $missing is fatal" );
}

done_testing();
