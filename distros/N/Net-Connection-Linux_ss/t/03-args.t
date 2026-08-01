#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Net::Connection::Linux_ss;

my $ipv4_raw = <<'END_SS';
Netid  State   Recv-Q  Send-Q    Local Address:Port    Peer Address:Port  Process
tcp    LISTEN  0       4096            0.0.0.0:22           0.0.0.0:*     users:(("sshd",pid=4108,fd=3))
tcp    ESTAB   0       0         192.168.14.15:22      192.168.15.2:63126 users:(("sshd",pid=2301,fd=8))
END_SS

my $ipv6_raw = <<'END_SS';
Netid  State   Recv-Q  Send-Q    Local Address:Port    Peer Address:Port  Process
tcp    LISTEN  0       4096               [::]:22              [::]:*     users:(("sshd",pid=4108,fd=4))
END_SS

subtest 'the string args and proc_info are mutually exclusive' => sub {
	foreach my $string_arg (qw( ipv4_string ipv6_string )) {
		my @objects;
		eval { @objects = &ss_to_nc_objects( { $string_arg => $ipv4_raw, proc_info => 1 } ); };

		like( $@, qr/mutually exclusive with proc_info/, $string_arg . ' with proc_info dies' );
	}

	# proc_info defaults to off when a string is given, so this is fine
	my @objects;
	eval { @objects = &ss_to_nc_objects( { ipv4_string => $ipv4_raw, ports => 0, ptrs => 0 } ); };
	is( $@, '', 'leaving proc_info to default does not die' );
	ok( scalar(@objects) > 0, 'and objects come back' );

	# and explicitly turning it off is fine as well
	eval { @objects = &ss_to_nc_objects( { ipv4_string => $ipv4_raw, ports => 0, ptrs => 0, proc_info => 0 } ); };
	is( $@, '', 'explicitly turning proc_info off does not die' );
}; ## end 'the string args and proc_info are mutually exclusive' => sub

subtest 'calling ss elsewhere than Linux' => sub {
	if ( $^O =~ /linux/ ) {
		plan skip_all => 'this is Linux, so ss is what is meant to be called';
	}

	foreach my $args ( undef, {}, { ports => 0, ptrs => 0 } ) {
		my @objects;
		eval { @objects = &ss_to_nc_objects($args); };

		like( $@, qr/this is not Linux/, 'dies instead of trying to call ss' );
	}
}; ## end 'calling ss elsewhere than Linux' => sub

subtest 'asking for neither address family' => sub {
	my @objects;
	eval { @objects = &ss_to_nc_objects( { ipv4 => 0, ipv6 => 0 } ); };

	like( $@, qr/leaving nothing for ss to be called for/, 'dies rather than returning an empty array' );

	# the ipv4 and ipv6 args only gate the calls to ss, so the strings are
	# still parsed regardless of them
	eval {
		@objects = &ss_to_nc_objects(
			{ ipv4_string => $ipv4_raw, ipv6_string => $ipv6_raw, ipv4 => 0, ipv6 => 0, ports => 0, ptrs => 0 } );
	};
	is( $@,               '', 'but a string is parsed either way' );
	is( scalar(@objects), 3,  'with every socket in it' );
}; ## end 'asking for neither address family' => sub

subtest 'port resolution' => sub {
	my @unresolved;
	eval { @unresolved = &ss_to_nc_objects( { ipv4_string => $ipv4_raw, ports => 0, ptrs => 0 } ); };
	is( $@,                              '',    'with ports off, parsing does not die' );
	is( $unresolved[0]->local_port_name, undef, 'and the port name is left alone' );

	my @resolved;
	eval { @resolved = &ss_to_nc_objects( { ipv4_string => $ipv4_raw, ports => 1, ptrs => 0 } ); };
	is( $@,                       '', 'with ports on, parsing does not die' );
	is( $resolved[0]->local_port, 22, 'the port itself is unchanged' );

	# skipped rather than failed as a machine may have no services file
	my $ssh_service = getservbyport( 22, 'tcp' );
	if ( !defined($ssh_service) ) {
		plan skip_all => 'port 22 does not resolve on this machine';
	}
	is( $resolved[0]->local_port_name, $ssh_service, 'and the name is filled in from the services records' );
}; ## end 'port resolution' => sub

subtest 'output with nothing parsable in it' => sub {
	my @nothing = (
		[ '',                                                                         'an empty string' ],
		[ "\n\n\n",                                                                   'nothing but newlines' ],
		[ "Netid State Recv-Q Send-Q Local Address:Port Peer Address:Port Process\n", 'a header and nothing else' ],
		[ "tcp LISTEN 0 4096\n", 'a line missing the address columns' ],
	);

	foreach my $case (@nothing) {
		my ( $raw, $description ) = @{$case};

		my @objects;
		eval { @objects = &ss_to_nc_objects( { ipv4_string => $raw, ports => 0, ptrs => 0 } ); };

		is( $@, '', "$description does not die" );
		is_deeply( \@objects, [], "and yields no objects" );
	}
}; ## end 'output with nothing parsable in it' => sub

done_testing();
