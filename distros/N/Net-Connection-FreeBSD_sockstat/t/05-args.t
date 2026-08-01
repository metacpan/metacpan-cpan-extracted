#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Net::Connection::FreeBSD_sockstat;

my $sockstat_json = <<'END_JSON';
{"__version": "1", "sockstat": {"socket": [
{"user":"root","command":"sshd","pid":1234,"fd":4,"proto":"tcp4", "local": {"address":"192.0.2.10","port":22}, "foreign": {"address":"198.51.100.7","port":52344},"conn-state":"ESTABLISHED"}
]}}
END_JSON

subtest 'string and proc_info are mutually exclusive' => sub {
	my @objects;
	eval { @objects = &sockstat_to_nc_objects( { string => $sockstat_json, proc_info => 1 } ); };

	like( $@, qr/mutually exclusive/, 'asking for both dies' );
};

subtest 'proc_info defaults to off when a string is given' => sub {
	my @objects;
	eval { @objects = &sockstat_to_nc_objects( { string => $sockstat_json, ports => 0, ptrs => 0 } ); };

	is( $@,                '',    'leaving proc_info unset does not trip the mutual exclusion check' );
	is( scalar(@objects),  1,     'and the string still gets parsed' );
	is( $objects[0]->proc, undef, 'with no proc info attached' );
};

subtest 'proc_info explicitly off alongside a string' => sub {
	my @objects;
	eval {
		@objects = &sockstat_to_nc_objects(
			{
				string    => $sockstat_json,
				proc_info => 0,
				ports     => 0,
				ptrs      => 0,
			}
		);
	};

	is( $@,               '', 'does not die' );
	is( scalar(@objects), 1,  'and parses' );
}; ## end 'proc_info explicitly off alongside a string' => sub

subtest 'ports off' => sub {
	my @objects = &sockstat_to_nc_objects( { string => $sockstat_json, ports => 0, ptrs => 0 } );

	is( $objects[0]->local_port,      22,    'the port is left numeric' );
	is( $objects[0]->local_port_name, undef, 'and no name is looked up' );
};

subtest 'ports on' => sub {
	my $ssh_name = getservbyport( 22, 'tcp' );

	plan skip_all => 'port 22 does not resolve to a name on this system' if !defined($ssh_name);

	my @objects = &sockstat_to_nc_objects( { string => $sockstat_json, ports => 1, ptrs => 0 } );

	is( $objects[0]->local_port,      22,        'the port itself is unchanged' );
	is( $objects[0]->local_port_name, $ssh_name, 'and the name gets resolved' );
}; ## end 'ports on' => sub

subtest 'ports defaults to on' => sub {
	my $ssh_name = getservbyport( 22, 'tcp' );

	plan skip_all => 'port 22 does not resolve to a name on this system' if !defined($ssh_name);

	my @objects = &sockstat_to_nc_objects( { string => $sockstat_json, ptrs => 0 } );

	is( $objects[0]->local_port_name, $ssh_name, 'leaving ports unset resolves the name' );
};

subtest 'ptrs off' => sub {
	my @objects = &sockstat_to_nc_objects( { string => $sockstat_json, ports => 0, ptrs => 0 } );

	is( $objects[0]->local_ptr,   undef, 'no local ptr lookup happens' );
	is( $objects[0]->foreign_ptr, undef, 'no foreign ptr lookup happens' );
};

# Net::Connection fills in the PTR of anything that already looks like a
# hostname whether or not ptrs is set, so the only way to tell the default
# apart from ptrs=>0 is to let it resolve an address for real. That needs
# working DNS, so it is left opt in.
subtest 'ptrs defaults to on' => sub {
	plan skip_all => 'set NC_FREEBSD_SOCKSTAT_DNS_TESTS=1 to run the tests that resolve PTRs'
		if !$ENV{NC_FREEBSD_SOCKSTAT_DNS_TESTS};

	# one of the root servers, picked as something with a stable PTR
	my $resolvable_json = <<'END_JSON';
{"__version": "1", "sockstat": {"socket": [
{"user":"root","command":"ntpd","pid":1234,"fd":4,"proto":"udp4", "local": {"address":"*","port":123}, "foreign": {"address":"198.41.0.4","port":53}}
]}}
END_JSON

	my @with_default = &sockstat_to_nc_objects( { string => $resolvable_json, ports => 0 } );
	my @with_off     = &sockstat_to_nc_objects( { string => $resolvable_json, ports => 0, ptrs => 0 } );

	is( $with_off[0]->foreign_ptr, undef, 'ptrs=>0 leaves the foreign ptr alone' );
	ok( defined( $with_default[0]->foreign_ptr ), 'leaving ptrs unset resolves the foreign ptr' );
}; ## end 'ptrs defaults to on' => sub

subtest 'a string of a single socket with no args beyond it' => sub {

	# ptrs defaults to on, which would mean hitting DNS, so this only checks
	# that the string alone is enough to avoid calling sockstat
	my @objects;
	eval { @objects = &sockstat_to_nc_objects( { string => $sockstat_json, ptrs => 0 } ); };

	is( $@,               '', 'a string alone is enough to keep it from shelling out' );
	is( scalar(@objects), 1,  'and it parses' );
}; ## end 'a string of a single socket with no args beyond it' => sub

done_testing();
