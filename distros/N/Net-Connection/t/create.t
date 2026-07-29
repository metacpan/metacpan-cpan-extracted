#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
   use_ok('Net::Connection');
}

my $extra_tests=0;
my $test={
		  'foreign_host' => undef,
		  'local_host' => undef,
		  'foreign_port' => undef,
		  'foreign_port_name' => undef,
		  'local_port' => undef,
		  'local_port_name' => undef,
		  'sendq' => undef,
		  'recvq' => undef,
		  'pid' => undef,
		  'uid' => undef,
		  'username' => undef,
		  'state' => undef,
		  'proto' => undef,
		  'local_ptr' => undef,
		  'foreign_ptr' => undef,
		  };
my $object;

# Make sure the it wont create a object with stuff undefined.
my $worked=0;
eval{
	$object=Net::Connection->new( $test );
	$worked=1;
};
ok( $worked eq '0', 'all undef check') or diag("Created a object when all requirements were undef");

# Make sure it does not work if state is undef.
$test->{'foreign_host'}='1.2.3.4';
$test->{'foreign_port'}='22';
$test->{'local_host'}='1.2.3.4';
$test->{'local_port'}='11111';
$test->{'proto'}='tcp4';
$test->{'state'}=undef;
$worked=0;
eval{
	$object=Net::Connection->new( $test );
	$worked=1;
};
ok( $worked eq '0', 'state undef check') or diag("Created a object when state was undef");

# Make sure it does not work if proto is undef.
$test->{'foreign_host'}='1.2.3.4';
$test->{'foreign_port'}='22';
$test->{'local_host'}='1.2.3.4';
$test->{'local_port'}='11111';
$test->{'proto'}=undef;
$test->{'state'}='ESTABLISHED';
$worked=0;
eval{
	$object=Net::Connection->new( $test );
	$worked=1;
};
ok( $worked eq '0', 'proto undef check') or diag("Created a object when proto was undef");

# Make sure it does not work if local_port is undef.
$test->{'foreign_host'}='1.2.3.4';
$test->{'foreign_port'}='22';
$test->{'local_host'}='1.2.3.4';
$test->{'local_port'}=undef;
$test->{'proto'}='tcp4';
$test->{'state'}='ESTABLISHED';
$worked=0;
eval{
	$object=Net::Connection->new( $test );
	$worked=1;
};
ok( $worked eq '0', 'local_port undef check') or diag("Created a object when local_port was undef");

# Make sure it does not work if local_host is undef.
$test->{'foreign_host'}='1.2.3.4';
$test->{'foreign_port'}='22';
$test->{'local_host'}=undef;
$test->{'local_port'}='11111';
$test->{'proto'}='tcp4';
$test->{'state'}='ESTABLISHED';
$worked=0;
eval{
	$object=Net::Connection->new( $test );
	$worked=1;
};
ok( $worked eq '0', 'local_host undef check') or diag("Created a object when local_host was undef");

# Make sure it does not work if foreign_port is undef.
$test->{'foreign_host'}='1.2.3.4';
$test->{'foreign_port'}=undef;
$test->{'local_host'}='1.2.3.4';
$test->{'local_port'}='11111';
$test->{'proto'}='tcp4';
$test->{'state'}='ESTABLISHED';
$worked=0;
eval{
	$object=Net::Connection->new( $test );
	$worked=1;
};
ok( $worked eq '0', 'foreign_port undef check') or diag("Created a object when foreign_port was undef");

# Make sure it does not work if foreign_host is undef.
$test->{'foreign_host'}=undef;
$test->{'foreign_port'}='22';
$test->{'local_host'}='1.2.3.4';
$test->{'local_port'}='11111';
$test->{'proto'}='tcp4';
$test->{'state'}='ESTABLISHED';
$worked=0;
eval{
	$object=Net::Connection->new( $test );
	$worked=1;
};
ok( $worked eq '0', 'foreign_host undef check') or diag("Created a object when foreign_host was undef");

# Makes sure we can set the queue stuff
$test->{'foreign_host'}='1.2.3.4';
$test->{'foreign_port'}='22';
$test->{'local_host'}='1.2.3.4';
$test->{'local_port'}='11111';
$test->{'proto'}='tcp4';
$test->{'state'}='ESTABLISHED';
$test->{'sendq'}='1';
$test->{'recvq'}='0';
$worked=0;
eval{
	$object=Net::Connection->new( $test );
	$worked=1;
};
ok( $worked eq '1', 'queue defined check') or diag("Failed to create a object with numeric queue values");

# Makes sure we send queue errors if non-numeric
$test->{'foreign_host'}='1.2.3.4';
$test->{'foreign_port'}='22';
$test->{'local_host'}='1.2.3.4';
$test->{'local_port'}='11111';
$test->{'proto'}='tcp4';
$test->{'state'}='ESTABLISHED';
$test->{'sendq'}='A';
$test->{'recvq'}='0';
$worked=0;
eval{
	$object=Net::Connection->new( $test );
	$worked=1;
};
ok( $worked eq '0', 'send queue non-numeric check') or diag("Created a object when sendq was non-numeric");

# Makes sure we recieve queue errors if non-numeric
$test->{'foreign_host'}='1.2.3.4';
$test->{'foreign_port'}='22';
$test->{'local_host'}='1.2.3.4';
$test->{'local_port'}='11111';
$test->{'proto'}='tcp4';
$test->{'state'}='ESTABLISHED';
$test->{'sendq'}='0';
$test->{'recvq'}='A';
$worked=0;
eval{
	$object=Net::Connection->new( $test );
	$worked=1;
};
ok( $worked eq '0', 'recieve queue non-numeric check') or diag("Created a object when recvq was non-numeric");

# Makes sure we setting the pid works
$test->{'foreign_host'}='1.2.3.4';
$test->{'foreign_port'}='22';
$test->{'local_host'}='1.2.3.4';
$test->{'local_port'}='11111';
$test->{'proto'}='tcp4';
$test->{'state'}='ESTABLISHED';
$test->{'sendq'}='0';
$test->{'recvq'}='0';
$test->{'pid'}='33';
$worked=0;
eval{
	$object=Net::Connection->new( $test );
	$worked=1;
};
ok( $worked eq '1', 'pid numeric check') or diag("Failed to create object");

# Makes sure we pid errors if non-numeric
$test->{'foreign_host'}='1.2.3.4';
$test->{'foreign_port'}='22';
$test->{'local_host'}='1.2.3.4';
$test->{'local_port'}='11111';
$test->{'proto'}='tcp4';
$test->{'state'}='ESTABLISHED';
$test->{'sendq'}='0';
$test->{'recvq'}='0';
$test->{'pid'}='A';
$worked=0;
eval{
	$object=Net::Connection->new( $test );
	$worked=1;
};
ok( $worked eq '0', 'pid non-numeric check') or diag("Created a object when pid was non-numeric");

# Makes sure we setting the uid works
$test->{'foreign_host'}='1.2.3.4';
$test->{'foreign_port'}='22';
$test->{'local_host'}='1.2.3.4';
$test->{'local_port'}='11111';
$test->{'proto'}='tcp4';
$test->{'state'}='ESTABLISHED';
$test->{'sendq'}='0';
$test->{'recvq'}='0';
$test->{'pid'}='33';
$test->{'uid'}='0';
$worked=0;
eval{
	$object=Net::Connection->new( $test );
	$worked=1;
};
ok( $worked eq '1', 'uid numeric check') or diag("Failed to create object");

# Makes sure we uid errors if non-numeric
$test->{'foreign_host'}='1.2.3.4';
$test->{'foreign_port'}='22';
$test->{'local_host'}='1.2.3.4';
$test->{'local_port'}='11111';
$test->{'proto'}='tcp4';
$test->{'state'}='ESTABLISHED';
$test->{'sendq'}='0';
$test->{'recvq'}='0';
$test->{'pid'}='0';
$test->{'uid'}='A';
$worked=0;
eval{
	$object=Net::Connection->new( $test );
	$worked=1;
};
ok( $worked eq '0', 'uid non-numeric check') or diag("Created a object when uid was non-numeric");

# Makes sure uid_resolve errors if both uid and username are undef
$test->{'uid'}=undef;
$test->{'username'}=undef;
$test->{'uid_resolve'}='1';
$worked=0;
eval{
	$object=Net::Connection->new( $test );
	$worked=1;
};
ok( $worked eq '0', 'uid_resolve undef uid/username check') or diag("Created a object when uid_resolve was true and both uid and username were undef");

# UID resolving tests if on unix
if (
	( $^O =~ /bsd$/ ) ||
	( $^O =~ /linux/ )
	){
	$extra_tests=$extra_tests+2;

	# Makes sure we can resolve UID 0 to root
	$test->{'uid'}='0';
	$test->{'uid_resolve'}='1';
	$worked=0;
	eval{
		$object=Net::Connection->new( $test );
		if ( defined( $object->username ) ){
		$worked=$object->username;
		}
	};
	ok( $worked eq 'root', 'uid 0->root resolve check') or diag("Unable to resolve UID 0 to root");

	# Makes sure can resovle root to UID 0
	$test->{'uid'}=undef;
	$test->{'username'}='root';
	$test->{'uid_resolve'}='1';
	$worked=1;
	eval{
		$object=Net::Connection->new( $test );
		if ( defined( $object->uid ) ){
			$worked=$object->uid;
		}
	};
	ok( $worked eq '0', 'root->uid 0 resolve check') or diag("Unable to resolve root to UID 0");
}

# Make sure what is set via new is what the accessors return
my $accessor_args={
		  'foreign_host' => '10.0.0.1',
		  'local_host' => '10.0.0.2',
		  'foreign_port' => '22',
		  'local_port' => '11132',
		  'proto' => 'tcp4',
		  'state' => 'ESTABLISHED',
		  'sendq' => '1',
		  'recvq' => '2',
		  'pid' => '33',
		  'uid' => '1000',
		  'username' => 'someuser',
		  'proc' => '/usr/bin/perl',
		  'wchan' => 'kqread',
		  'pctcpu' => '1.5',
		  'pctmem' => '2.5',
		  'pid_start' => '12345',
		  'local_ptr' => 'a.example.com',
		  'foreign_ptr' => 'b.example.com',
		  };
$object=Net::Connection->new( $accessor_args );
my @round_trip_accessors=(
						  'foreign_host', 'local_host', 'foreign_port', 'local_port',
						  'proto', 'state', 'sendq', 'recvq', 'pid', 'uid', 'username',
						  'proc', 'wchan', 'pctcpu', 'pctmem', 'pid_start',
						  'local_ptr', 'foreign_ptr',
						  );
foreach my $accessor_name (@round_trip_accessors){
	is( $object->$accessor_name, $accessor_args->{$accessor_name}, $accessor_name.' round trip check' );
}

# Numeric ports with the ports option unset should leave the port names undef
is( $object->local_port_name, undef, 'numeric local port, no ports option, name undef check' );
is( $object->foreign_port_name, undef, 'numeric foreign port, no ports option, name undef check' );

# Named ports with the ports option unset should be copied to the name and otherwise left as is
my $named_ports_args={
		  'foreign_host' => '10.0.0.1',
		  'local_host' => '10.0.0.2',
		  'foreign_port' => 'smtp',
		  'local_port' => 'ssh',
		  'proto' => 'tcp4',
		  'state' => 'ESTABLISHED',
		  };
$object=Net::Connection->new( $named_ports_args );
is( $object->local_port, 'ssh', 'named local port, no ports option, port check' );
is( $object->local_port_name, 'ssh', 'named local port, no ports option, name check' );
is( $object->foreign_port, 'smtp', 'named foreign port, no ports option, port check' );
is( $object->foreign_port_name, 'smtp', 'named foreign port, no ports option, name check' );

# The ports option with numeric ports should resolve names using the connection protocol
my $ports_tcp_args={
		  'foreign_host' => '10.0.0.1',
		  'local_host' => '10.0.0.2',
		  'foreign_port' => '514',
		  'local_port' => '22',
		  'proto' => 'TCPv4',
		  'state' => 'ESTABLISHED',
		  'ports' => '1',
		  };
$object=Net::Connection->new( $ports_tcp_args );
is( $object->local_port, '22', 'ports option numeric port unchanged check' );
is( $object->local_port_name, scalar getservbyport( 22, 'tcp' ), 'numeric local port resolved as tcp check' );
is( $object->foreign_port_name, scalar getservbyport( 514, 'tcp' ), 'numeric foreign port resolved as tcp check' );

my $ports_udp_args={
		  'foreign_host' => '10.0.0.1',
		  'local_host' => '10.0.0.2',
		  'foreign_port' => '514',
		  'local_port' => '514',
		  'proto' => 'udp4',
		  'state' => 'ESTABLISHED',
		  'ports' => '1',
		  };
$object=Net::Connection->new( $ports_udp_args );
is( $object->local_port_name, scalar getservbyport( 514, 'udp' ), 'numeric local port resolved as udp check' );

# The ports option with named ports should resolve numbers using the connection protocol
my $expected_ssh_port=getservbyname( 'ssh', 'tcp' );
if ( !defined( $expected_ssh_port ) ){
	$expected_ssh_port='ssh';
}
my $named_tcp_args={
		  'foreign_host' => '10.0.0.1',
		  'local_host' => '10.0.0.2',
		  'foreign_port' => '514',
		  'local_port' => 'ssh',
		  'proto' => 'tcp4',
		  'state' => 'ESTABLISHED',
		  'ports' => '1',
		  };
$object=Net::Connection->new( $named_tcp_args );
is( $object->local_port, $expected_ssh_port, 'named local port resolved as tcp check' );
is( $object->local_port_name, 'ssh', 'named local port name kept check' );

my $expected_syslog_port=getservbyname( 'syslog', 'udp' );
if ( !defined( $expected_syslog_port ) ){
	$expected_syslog_port='syslog';
}
my $named_udp_args={
		  'foreign_host' => '10.0.0.1',
		  'local_host' => '10.0.0.2',
		  'foreign_port' => '514',
		  'local_port' => 'syslog',
		  'proto' => 'udp6',
		  'state' => 'ESTABLISHED',
		  'ports' => '1',
		  };
$object=Net::Connection->new( $named_udp_args );
is( $object->local_port, $expected_syslog_port, 'named local port resolved as udp check' );
is( $object->local_port_name, 'syslog', 'named udp local port name kept check' );

# Hostname hosts should be copied to the PTRs when ptrs is unset
my $hostname_args={
		  'foreign_host' => 'b.example.com',
		  'local_host' => 'a.example.com',
		  'foreign_port' => '22',
		  'local_port' => '11132',
		  'proto' => 'tcp4',
		  'state' => 'ESTABLISHED',
		  };
$object=Net::Connection->new( $hostname_args );
is( $object->local_ptr, 'a.example.com', 'hostname local host, no ptrs option, ptr check' );
is( $object->foreign_ptr, 'b.example.com', 'hostname foreign host, no ptrs option, ptr check' );

# Hostname hosts should be copied to the PTRs when ptrs is set, with out a DNS lookup
$hostname_args->{'ptrs'}='1';
$object=Net::Connection->new( $hostname_args );
is( $object->local_ptr, 'a.example.com', 'hostname local host, ptrs option, ptr check' );
is( $object->foreign_ptr, 'b.example.com', 'hostname foreign host, ptrs option, ptr check' );

# IPv6 hosts contain letters, but should not be treated as hostnames
my $ipv6_args={
		  'foreign_host' => 'fe80::1',
		  'local_host' => '::1',
		  'foreign_port' => '22',
		  'local_port' => '11132',
		  'proto' => 'tcp6',
		  'state' => 'ESTABLISHED',
		  };
$object=Net::Connection->new( $ipv6_args );
is( $object->local_ptr, undef, 'IPv6 local host not treated as a hostname check' );
is( $object->foreign_ptr, undef, 'IPv6 foreign host not treated as a hostname check' );

my $tests_ran=54+$extra_tests;
done_testing($tests_ran);
