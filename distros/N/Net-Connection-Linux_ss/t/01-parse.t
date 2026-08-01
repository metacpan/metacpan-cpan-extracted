#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Net::Connection::Linux_ss;

# the captured output of a real 'ss -p4an' and 'ss -p6an'
my $ipv4_raw = &slurp_example('ss_-p4an');
my $ipv6_raw = &slurp_example('ss_-p6an');

# ports and ptrs are both turned off so nothing here reaches /etc/services or DNS
my @objects;
eval { @objects = &ss_to_nc_objects( { ipv4_string => $ipv4_raw, ipv6_string => $ipv6_raw, ports => 0, ptrs => 0 } ); };
is( $@, '', 'parsing the examples does not die' );

isa_ok( $_, 'Net::Connection' ) foreach @objects;

subtest 'the two examples parse to the expected sockets' => sub {

	# 86 IPv4 lines and 8 IPv6 lines, with the sockets held open by more than
	# one process yielding a object per process
	is( scalar(@objects), 109, 'the socket and process count' );

	my %proto_counts;
	$proto_counts{ $_->proto }++ foreach @objects;
	is_deeply(
		\%proto_counts,
		{ tcp4 => 89, udp4 => 9, tcp6 => 5, udp6 => 5, icmp6 => 1 },
		'the netid and address family are combined into the proto'
	);

	my %state_counts;
	$state_counts{ $_->state }++ foreach @objects;
	is_deeply(
		\%state_counts,
		{ ESTAB => 73, LISTEN => 21, UNCONN => 15 },
		'the state column is carried over verbatim'
	);

	# the IPv4 output is parsed before the IPv6 one, with the socket order
	# within each preserved
	is( $objects[0]->proto,      'udp4', 'the first object is from the IPv4 output' );
	is( $objects[-1]->proto,     'tcp6', 'and the last from the IPv6 one' );
	is( $objects[0]->local_port, 42541,  'the first object is the first socket ss listed' );
}; ## end 'the two examples parse to the expected sockets' => sub

subtest 'a listening IPv4 socket' => sub {
	my ($listener) = grep { $_->proto eq 'tcp4' && $_->local_port eq 27017 && $_->state eq 'LISTEN' } @objects;

	is( $listener->local_host,   '127.0.0.1', 'local address' );
	is( $listener->foreign_host, '0.0.0.0',   'the wildcard peer address is left as ss printed it' );
	is( $listener->foreign_port, '*',         'and the wildcard peer port as a star' );
	is( $listener->recvq,        0,           'Recv-Q' );
	is( $listener->sendq,        4096,        'Send-Q' );
	is( $listener->pid,          1008,        'pid' );
	is( $listener->proc,         'mongod',    'proc falls back to the name ss printed' );
	is( $listener->uid,          undef,       'no UID, as /proc is not poked at for a parsed string' );
	is( $listener->username,     undef,       'and so no username either' );
}; ## end 'a listening IPv4 socket' => sub

subtest 'an established IPv4 socket' => sub {
	my ($established) = grep { $_->proto eq 'tcp4' && $_->local_port eq 53826 } @objects;

	is( $established->local_host,   '192.168.14.15', 'local address' );
	is( $established->local_port,   53826,           'local port' );
	is( $established->foreign_host, '192.168.14.21', 'peer address' );
	is( $established->foreign_port, 5432,            'peer port' );
	is( $established->state,        'ESTAB',         'state' );
	is( $established->proc,         'lilu',          'proc' );
}; ## end 'an established IPv4 socket' => sub

subtest 'the send queue of a busy socket' => sub {
	my ($busy) = grep { $_->proto eq 'tcp4' && $_->local_port eq 22 && $_->foreign_port eq 63126 } @objects;

	is( $busy->recvq, 0,  'Recv-Q' );
	is( $busy->sendq, 36, 'Send-Q is not assumed to be zero' );
};

subtest 'an IPv4 address with a scope ID' => sub {
	my ($scoped) = grep { $_->proto eq 'udp4' && $_->local_port eq 67 } @objects;

	is( $scoped->local_host, '0.0.0.0%virbr0', 'the scope ID is kept as part of the address' );
	is( $scoped->local_port, 67,               'and does not confuse the port split' );
};

subtest 'IPv6 addresses' => sub {
	my ($wildcard) = grep { $_->proto eq 'tcp6' && $_->local_port eq 8118 } @objects;
	is( $wildcard->local_host,   '::1', 'the brackets ss wraps IPv6 addresses in are stripped' );
	is( $wildcard->foreign_host, '::',  'including on the wildcard peer address' );
	is( $wildcard->foreign_port, '*',   'the wildcard peer port is a star' );

	my ($link_local) = grep { $_->proto eq 'udp6' && $_->local_port eq 546 } @objects;
	is(
		$link_local->local_host,
		'fe80::ae1f:6bff:fe63:75bc%eno3',
		'a scope ID outside of the brackets ends up on the address'
	);
	is( $link_local->local_port, 546, 'and the port is still split off correctly' );
}; ## end 'IPv6 addresses' => sub

subtest 'a netid that already names the address family' => sub {
	my ($icmp) = grep { $_->proto =~ /icmp/ } @objects;

	is( $icmp->proto,        'icmp6',  'icmp6 does not become icmp66' );
	is( $icmp->local_host,   '*%eno3', 'a bare star with a scope ID for the local address' );
	is( $icmp->local_port,   58,       'local port' );
	is( $icmp->foreign_host, '*',      'and a bare star for the peer address' );
	is( $icmp->foreign_port, '*',      'and the peer port' );
};

subtest 'parsing just the one address family' => sub {
	my @ipv4_only;
	eval { @ipv4_only = &ss_to_nc_objects( { ipv4_string => $ipv4_raw, ports => 0, ptrs => 0 } ); };
	is( $@,                                              '', 'ipv4_string on its own does not die' );
	is( scalar(@ipv4_only),                              98, 'and yields only the IPv4 sockets' );
	is( scalar( grep { $_->proto =~ /6$/ } @ipv4_only ), 0,  'none of which are IPv6' );

	my @ipv6_only;
	eval { @ipv6_only = &ss_to_nc_objects( { ipv6_string => $ipv6_raw, ports => 0, ptrs => 0 } ); };
	is( $@,                                              '', 'ipv6_string on its own does not die' );
	is( scalar(@ipv6_only),                              11, 'and yields only the IPv6 sockets' );
	is( scalar( grep { $_->proto =~ /4$/ } @ipv6_only ), 0,  'none of which are IPv4' );
}; ## end 'parsing just the one address family' => sub

done_testing();

sub slurp_example {
	my $example_name = $_[0];

	# prove and make test both run from the dist root, but running the test
	# from within t/ is common enough to be worth handling
	my $example_file = 't/examples/' . $example_name;
	if ( !-f $example_file ) {
		$example_file = 'examples/' . $example_name;
	}

	open( my $example_fh, '<', $example_file ) or BAIL_OUT( 'failed to open ' . $example_file . ': ' . $! );
	local $/ = undef;
	my $example_raw = readline($example_fh);
	close($example_fh);

	return $example_raw;
} ## end sub slurp_example
