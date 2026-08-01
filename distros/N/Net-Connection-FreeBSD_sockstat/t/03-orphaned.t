#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Net::Connection::FreeBSD_sockstat;

# Sockets with no owning process lack the user, command, pid, and fd keys.
# The third entry below is the half populated case of a pid with no user,
# which is treated as orphaned as well since there is nothing to resolve.
my $sockstat_json = <<'END_JSON';
{"__version": "1", "sockstat": {"socket": [
{"user":"root","command":"sshd","pid":1234,"fd":4,"proto":"tcp4", "local": {"address":"*","port":22}, "foreign": {"address":"*","port":0},"conn-state":"LISTEN"},
{"proto":"tcp6", "local": {"address":"::1","port":4045}, "foreign": {"address":"*","port":0},"conn-state":"LISTEN"},
{"command":"sshd","pid":9999,"fd":7,"proto":"tcp4", "local": {"address":"192.0.2.10","port":51705}, "foreign": {"address":"198.51.100.7","port":22},"conn-state":"TIME_WAIT"},
{"proto":"udp4", "local": {"address":"*","port":37066}, "foreign": {"address":"*","port":0}}
]}}
END_JSON

my %base_args = (
	string => $sockstat_json,
	ports  => 0,
	ptrs   => 0,
);

subtest 'zombie_skip defaults to on' => sub {
	my @objects;
	eval { @objects = &sockstat_to_nc_objects( {%base_args} ); };

	is( $@,               '',   'does not die' );
	is( scalar(@objects), 1,    'only the socket with an owning process comes back' );
	is( $objects[0]->pid, 1234, 'and it is the one that had a pid' );
};

subtest 'zombie_skip explicitly on' => sub {
	my @objects;
	eval { @objects = &sockstat_to_nc_objects( { %base_args, zombie_skip => 1 } ); };

	is( $@,               '', 'does not die' );
	is( scalar(@objects), 1,  'matches the default behavior' );
};

subtest 'zombie_skip off' => sub {
	my @objects;
	eval { @objects = &sockstat_to_nc_objects( { %base_args, zombie_skip => 0 } ); };

	is( $@,               '', 'does not die, unlike the 0.0.x releases' );
	is( scalar(@objects), 4,  'every socket comes back' );

	# Net::Connection requires the pid and uid to be numeric when they are
	# defined, so they are left undef rather than filled in with a question mark
	foreach my $index ( 1, 2, 3 ) {
		my $orphan = $objects[$index];

		is( $orphan->username, '?',   "socket $index has a username of a question mark" );
		is( $orphan->pid,      undef, "socket $index has an undefined pid" );
		is( $orphan->uid,      undef, "socket $index has an undefined uid" );
	}

	# everything that does not come from the owning process is still parsed
	is( $objects[1]->proto,        'tcp6',      'the orphan proto is still set' );
	is( $objects[1]->local_host,   '::1',       'the orphan local address is still set' );
	is( $objects[1]->local_port,   4045,        'the orphan local port is still set' );
	is( $objects[1]->foreign_port, '*',         'the orphan foreign port is still starred' );
	is( $objects[1]->state,        'LISTEN',    'the orphan state is still set' );
	is( $objects[2]->state,        'TIME_WAIT', 'a pid with no user is treated as orphaned' );
	is( $objects[3]->state,        '',          'an orphaned udp socket has an empty state' );
}; ## end 'zombie_skip off' => sub

subtest 'proc info is never attached to an orphan' => sub {
	my @objects;

	# proc_info is only meaningful when not passing a string, but the orphan
	# handling is what is being checked here
	eval { @objects = &sockstat_to_nc_objects( { %base_args, zombie_skip => 0 } ); };

	is( $@, '', 'does not die' );

	foreach my $index ( 1, 2, 3 ) {
		is( $objects[$index]->proc,  undef, "socket $index has no proc" );
		is( $objects[$index]->wchan, undef, "socket $index has no wchan" );
	}
}; ## end 'proc info is never attached to an orphan' => sub

done_testing();
