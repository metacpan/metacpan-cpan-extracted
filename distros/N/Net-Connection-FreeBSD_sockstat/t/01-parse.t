#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Net::Connection::FreeBSD_sockstat;

# A trimmed but structurally faithful sample of 'sockstat -46s --libxo json',
# covering every proto sockstat -46 can emit as well as the with/without
# 'conn-state' split.
my $sockstat_json = <<'END_JSON';
{"__version": "1", "sockstat": {"socket": [
{"user":"root","command":"sshd","pid":1234,"fd":4,"proto":"tcp4", "local": {"address":"*","port":22}, "foreign": {"address":"*","port":0},"conn-state":"LISTEN"},
{"user":"root","command":"sshd","pid":1235,"fd":5,"proto":"tcp4", "local": {"address":"192.0.2.10","port":22}, "foreign": {"address":"198.51.100.7","port":52344},"conn-state":"ESTABLISHED"},
{"user":"root","command":"sshd","pid":1234,"fd":6,"proto":"tcp6", "local": {"address":"::1","port":22}, "foreign": {"address":"*","port":0},"conn-state":"LISTEN"},
{"user":"root","command":"ntpd","pid":1300,"fd":21,"proto":"udp4", "local": {"address":"*","port":123}, "foreign": {"address":"*","port":0}},
{"user":"root","command":"ntpd","pid":1300,"fd":22,"proto":"udp6", "local": {"address":"::1","port":123}, "foreign": {"address":"*","port":0}},
{"user":"root","command":"icecast","pid":3109,"fd":5,"proto":"tcp46", "local": {"address":"*","port":8000}, "foreign": {"address":"*","port":0},"conn-state":"LISTEN"}
]}}
END_JSON

# ports and ptrs are both turned off so nothing here reaches /etc/services or DNS
my @objects;
eval { @objects = &sockstat_to_nc_objects( { string => $sockstat_json, ports => 0, ptrs => 0, } ); };
is( $@, '', 'parsing the sample does not die' );

is( scalar(@objects), 6, 'one object per socket in the array' );

isa_ok( $_, 'Net::Connection' ) foreach @objects;

# the objects are expected to come back in the order sockstat listed them
is_deeply(
	[ map { $_->proto } @objects ],
	[qw( tcp4 tcp4 tcp6 udp4 udp6 tcp46 )],
	'proto is carried over verbatim and the socket order is preserved'
);

subtest 'a listening tcp4 socket' => sub {
	my $listener = $objects[0];

	is( $listener->local_host,   '*',                        'wildcard local address' );
	is( $listener->local_port,   22,                         'local port' );
	is( $listener->foreign_host, '*',                        'wildcard foreign address' );
	is( $listener->foreign_port, '*',                        'port 0 becomes a star, matching the text output' );
	is( $listener->state,        'LISTEN',                   'conn-state becomes the state' );
	is( $listener->username,     'root',                     'username' );
	is( $listener->pid,          1234,                       'pid' );
	is( $listener->uid,          scalar( getpwnam('root') ), 'uid resolved from the username' );
}; ## end 'a listening tcp4 socket' => sub

subtest 'an established tcp4 socket' => sub {
	my $established = $objects[1];

	is( $established->local_host,   '192.0.2.10',   'local address' );
	is( $established->local_port,   22,             'local port' );
	is( $established->foreign_host, '198.51.100.7', 'foreign address' );
	is( $established->foreign_port, 52344,          'foreign port' );
	is( $established->state,        'ESTABLISHED',  'state' );
};

subtest 'an ipv6 socket' => sub {
	my $v6 = $objects[2];

	is( $v6->proto,      'tcp6', 'proto' );
	is( $v6->local_host, '::1',  'the colons in a v6 address survive intact' );
	is( $v6->local_port, 22,     'v6 address and port are not run together' );
};

subtest 'sockets with no connection state' => sub {
	foreach my $index ( 3, 4 ) {
		my $udp = $objects[$index];

		is( $udp->state, '', $udp->proto . ' has no conn-state, so the state is left empty' );
	}
};

# no proc info was asked for, so none of it should have been filled in
subtest 'proc info is absent unless asked for' => sub {
	foreach my $object (@objects) {
		is( $object->proc,   undef, 'proc' );
		is( $object->wchan,  undef, 'wchan' );
		is( $object->pctcpu, undef, 'pctcpu' );
		is( $object->pctmem, undef, 'pctmem' );
	}
};

# an empty run is valid, such as when sockstat is filtered down to nothing
subtest 'an empty socket array' => sub {
	my @empty;
	eval {
		@empty = &sockstat_to_nc_objects(
			{
				string => '{"__version": "1", "sockstat": {"socket": []}}',
				ports  => 0,
				ptrs   => 0,
			}
		);
	};

	is( $@,             '', 'an empty array of sockets does not die' );
	is( scalar(@empty), 0,  'and returns no objects' );
}; ## end 'an empty socket array' => sub

done_testing();
