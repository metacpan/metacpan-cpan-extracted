#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

# ban creates the address object then adds it to the group, split by family
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'fortigate',
		name    => 'ssh',
		prefix  => 'kur',
		testing => 1,
		options => { host => 'fw.example', token => 'TOK', vdom => 'root' },
	);
	$fw->init_backend;

	is( $fw->{test_data}[0]{method}, 'GET', 'init probes the group with a GET' );
	is( $fw->{test_data}[0]{url},
		'https://fw.example/api/v2/cmdb/firewall/addrgrp/kur_ssh?vdom=root',
		'init fetches the v4 address group with the vdom' );

	$fw->ban( ban => '1.2.3.4' );
	is( scalar( @{ $fw->{test_data} } ), 2, 'ban is two requests' );
	is( $fw->{test_data}[0]{url}, 'https://fw.example/api/v2/cmdb/firewall/address?vdom=root',
		'first creates a firewall address' );
	is( $fw->{test_data}[0]{content}, '{"name":"kur_ssh_1-2-3-4","subnet":"1.2.3.4/32"}',
		'address object is a /32 with a sanitized name' );
	is( $fw->{test_data}[1]{url}, 'https://fw.example/api/v2/cmdb/firewall/addrgrp/kur_ssh/member?vdom=root',
		'second adds it to the group member table' );
	is( $fw->{test_data}[1]{content}, '{"name":"kur_ssh_1-2-3-4"}', 'member references the address by name' );

	$fw->ban( ban => 'dead::1' );
	is( $fw->{test_data}[0]{url}, 'https://fw.example/api/v2/cmdb/firewall/address6?vdom=root',
		'IPv6 uses the address6 menu' );
	is( $fw->{test_data}[0]{content}, '{"ip6":"dead::1/128","name":"kur_ssh_dead--1"}',
		'IPv6 object uses the ip6 field and /128' );
	is( $fw->{test_data}[1]{url}, 'https://fw.example/api/v2/cmdb/firewall/addrgrp6/kur_ssh/member?vdom=root',
		'IPv6 uses the addrgrp6 group' );

	$fw->unban( ban => '1.2.3.4' );
	is( $fw->{test_data}[0]{method}, 'DELETE', 'unban deletes' );
	is( $fw->{test_data}[0]{url},
		'https://fw.example/api/v2/cmdb/firewall/addrgrp/kur_ssh/member/kur_ssh_1-2-3-4?vdom=root',
		'unban first removes the group membership' );
	is( $fw->{test_data}[1]{url},
		'https://fw.example/api/v2/cmdb/firewall/address/kur_ssh_1-2-3-4?vdom=root',
		'unban then deletes the address object' );

	# CIDR support
	ok( $fw->{backend_obj}{cidr_supported}, 'cidr is supported' );
	$fw->ban_cidr( ban => '1.2.3.0/24' );
	is( scalar( @{ $fw->{test_data} } ), 2, 'ban_cidr is two requests' );
	is( $fw->{test_data}[0]{url}, 'https://fw.example/api/v2/cmdb/firewall/address?vdom=root',
		'ban_cidr first creates a firewall address' );
	is( $fw->{test_data}[0]{content}, '{"name":"kur_ssh_1-2-3-0-24","subnet":"1.2.3.0/24"}',
		'address object is the subnet with a sanitized name' );
	is( $fw->{test_data}[1]{url}, 'https://fw.example/api/v2/cmdb/firewall/addrgrp/kur_ssh/member?vdom=root',
		'ban_cidr then adds it to the group member table' );
	is( $fw->{test_data}[1]{content}, '{"name":"kur_ssh_1-2-3-0-24"}', 'member references the address by name' );
	my %listed = map { $_ => 1 } $fw->{backend_obj}->list_cidr;
	ok( $listed{'1.2.3.0/24'}, 'list_cidr contains the banned CIDR' );
	$fw->unban_cidr( ban => '1.2.3.0/24' );
	%listed = map { $_ => 1 } $fw->{backend_obj}->list_cidr;
	ok( !$listed{'1.2.3.0/24'}, 'list_cidr no longer contains the CIDR after unban_cidr' );
}

# custom group names, no vdom
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'fortigate', name => 'ssh', testing => 1,
		options => { host => 'h', token => 't', group4 => 'blocked' },
	);
	$fw->init_backend;
	$fw->ban( ban => '9.9.9.9' );
	is( $fw->{test_data}[1]{url}, 'https://h/api/v2/cmdb/firewall/addrgrp/blocked/member',
		'custom group4 used and no vdom appended' );
}

# host and token are both required
for my $missing (qw(host token)) {
	my %opts = ( host => 'h', token => 't' );
	delete $opts{$missing};
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new(
			backend => 'fortigate', name => 'ssh', testing => 1, options => \%opts,
		);
		$fw->init_backend;
	};
	$died = 1 if ($@);
	ok( $died, "missing $missing is fatal" );
}

done_testing();
