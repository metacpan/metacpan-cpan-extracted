#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Net::Connection::Linux_ss;

# A trimmed but structurally faithful sample of 'ss -p4an', covering the
# single process, multiple process, and empty process column cases.
my $ipv4_raw = <<'END_SS';
Netid  State      Recv-Q  Send-Q    Local Address:Port    Peer Address:Port  Process
tcp    LISTEN     0       4096            0.0.0.0:22           0.0.0.0:*     users:(("sshd",pid=4108,fd=3),("systemd",pid=1,fd=221))
tcp    ESTAB      0       0         192.168.14.15:22      192.168.15.2:63126 users:(("sshd",pid=2301,fd=8))
tcp    TIME-WAIT  0       0             127.0.0.1:45832     127.0.0.1:5432
udp    UNCONN     0       0               0.0.0.0:161          0.0.0.0:*     users:(("gnome shell",pid=1332,fd=6))
END_SS

subtest 'a socket held open by more than one process' => sub {
	my @objects;
	eval { @objects = &ss_to_nc_objects( { ipv4_string => $ipv4_raw, ports => 0, ptrs => 0 } ); };
	is( $@, '', 'parsing does not die' );

	my @listeners = grep { $_->state eq 'LISTEN' } @objects;
	is( scalar(@listeners), 2, 'both processes in the column get an object' );

	is_deeply( [ map { $_->pid } @listeners ],  [ 4108,   1 ], 'each with its own pid, in the order ss listed them' );
	is_deeply( [ map { $_->proc } @listeners ], [ 'sshd', 'systemd' ], 'and its own proc' );

	# the socket itself is the same for both
	foreach my $listener (@listeners) {
		is( $listener->local_host,   '0.0.0.0', 'the local address is shared' );
		is( $listener->local_port,   22,        'as is the local port' );
		is( $listener->foreign_port, '*',       'and the peer port' );
		is( $listener->sendq,        4096,      'and the send queue' );
	}
}; ## end 'a socket held open by more than one process' => sub

subtest 'a process name with whitespace in it' => sub {
	my @objects;
	eval { @objects = &ss_to_nc_objects( { ipv4_string => $ipv4_raw, ports => 0, ptrs => 0 } ); };
	is( $@, '', 'parsing does not die' );

	my ($named) = grep { $_->proto eq 'udp4' } @objects;
	is( $named->proc, 'gnome shell', 'the space does not truncate the name' );
	is( $named->pid,  1332,          'and the pid is still picked up' );
};

subtest 'zombie_skip' => sub {
	my @skipped;
	eval { @skipped = &ss_to_nc_objects( { ipv4_string => $ipv4_raw, ports => 0, ptrs => 0 } ); };
	is( $@,               '', 'the default does not die' );
	is( scalar(@skipped), 4,  'the socket with an empty process column is dropped by default' );
	is( scalar( grep { $_->state eq 'TIME-WAIT' } @skipped ), 0, 'so the TIME-WAIT socket is not there' );

	my @kept;
	eval { @kept = &ss_to_nc_objects( { ipv4_string => $ipv4_raw, ports => 0, ptrs => 0, zombie_skip => 0 } ); };
	is( $@,            '', 'turning it off does not die' );
	is( scalar(@kept), 5,  'and the socket comes back' );

	my ($orphan) = grep { $_->state eq 'TIME-WAIT' } @kept;
	is( $orphan->local_host,   '127.0.0.1', 'with its local address' );
	is( $orphan->local_port,   45832,       'and local port' );
	is( $orphan->foreign_host, '127.0.0.1', 'and peer address' );
	is( $orphan->foreign_port, 5432,        'and peer port' );
	is( $orphan->pid,          undef,       'but no pid' );
	is( $orphan->uid,          undef,       'and no uid' );
	is( $orphan->proc,         undef,       'and no proc' );
}; ## end 'zombie_skip' => sub

subtest 'the process column parser' => sub {
	my @processes
		= Net::Connection::Linux_ss::_parse_process_column('users:(("rpcbind",pid=915,fd=4),("systemd",pid=1,fd=244))');
	is_deeply(
		\@processes,
		[ { name => 'rpcbind', pid => 915, fd => 4 }, { name => 'systemd', pid => 1, fd => 244 } ],
		'both processes come back'
	);

	# ss appends further keys to the process entries when given the likes of -Z
	@processes = Net::Connection::Linux_ss::_parse_process_column(
		'users:(("sshd",pid=4108,fd=3,proc_ctx=system_u:system_r:sshd_t:s0-s0:c0.c1023))');
	is_deeply( \@processes, [ { name => 'sshd', pid => 4108, fd => 3 } ], 'extra keys do not break the parse' );

	is_deeply( [ Net::Connection::Linux_ss::_parse_process_column(undef) ], [], 'no column at all yields nothing' );
	is_deeply( [ Net::Connection::Linux_ss::_parse_process_column('') ],    [], 'nor does an empty one' );
	is_deeply( [ Net::Connection::Linux_ss::_parse_process_column('   ') ], [], 'nor does a blank one' );
}; ## end 'the process column parser' => sub

subtest 'the address and port splitter' => sub {
	my @splits = (
		[ '0.0.0.0:*',                            '0.0.0.0',                        '*' ],
		[ '192.168.122.1:53',                     '192.168.122.1',                  53 ],
		[ '0.0.0.0%virbr0:67',                    '0.0.0.0%virbr0',                 67 ],
		[ '[::]:*',                               '::',                             '*' ],
		[ '[::1]:8118',                           '::1',                            8118 ],
		[ '[fe80::ae1f:6bff:fe63:75bc]%eno3:546', 'fe80::ae1f:6bff:fe63:75bc%eno3', 546 ],
		[ '*%eno3:58',                            '*%eno3',                         58 ],
		[ '*:*',                                  '*',                              '*' ],
	);

	foreach my $split (@splits) {
		my ( $address_port, $expected_host, $expected_port ) = @{$split};

		is_deeply(
			[ Net::Connection::Linux_ss::_split_host_port($address_port) ],
			[ $expected_host, $expected_port ],
			$address_port . ' splits as expected'
		);
	}
}; ## end 'the address and port splitter' => sub

done_testing();
