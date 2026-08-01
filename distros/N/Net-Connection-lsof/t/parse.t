#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Connection::lsof') || print "Bail out!\n";
}

# no resolving or process table lookups so the results are deterministic
my $no_resolve_args = {
	ports       => 0,
	ptrs        => 0,
	uid_resolve => 0,
	proc_info   => 0,
};

# builds a line in the same manner as lsof, a 9 wide command column,
# a space, and then the rest of the fields
sub lsof_line {
	my ( $command, @fields ) = @_;
	return sprintf( '%-9s %s', $command, join( ' ', @fields ) );
}

my $fixture = join( "\n",
	'COMMAND     PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME',
	lsof_line( 'sshd',    qw( 1001 0   4u IPv4 0x1 0t0 TCP 192.0.2.1:22->192.0.2.2:56618 (ESTABLISHED) ) ),
	lsof_line( 'cupsd',   qw( 1002 193 7u IPv6 0x2 0t0 TCP [::1]:631 (LISTEN) ) ),
	lsof_line( 'syslogd', qw( 1003 0   5u IPv4 0x3 0t0 UDP *:514 ) ),
	lsof_line( 'sshd',    qw( 1004 22  6u IPv6 0x4 0t0 TCP [2001:db8::1]:22->[2001:db8::2]:33333 (ESTABLISHED) ) ),
) . "\n";

my @nc_objects = Net::Connection::lsof::_parse_lsof_output( $fixture, $no_resolve_args );

is( scalar(@nc_objects), 4, 'four connections parsed' );

foreach my $nc_object (@nc_objects) {
	isa_ok( $nc_object, 'Net::Connection' );
}

# IPv4 TCP with a foreign host and state
is( $nc_objects[0]->pid,          '1001',        'tcp4 pid' );
is( $nc_objects[0]->uid,          '0',           'tcp4 uid' );
is( $nc_objects[0]->proto,        'tcp4',        'tcp4 proto' );
is( $nc_objects[0]->local_host,   '192.0.2.1',   'tcp4 local host' );
is( $nc_objects[0]->local_port,   '22',          'tcp4 local port' );
is( $nc_objects[0]->foreign_host, '192.0.2.2',   'tcp4 foreign host' );
is( $nc_objects[0]->foreign_port, '56618',       'tcp4 foreign port' );
is( $nc_objects[0]->state,        'ESTABLISHED', 'tcp4 state' );

# IPv6 TCP listener, so no foreign host
is( $nc_objects[1]->proto,        'tcp6',   'tcp6 listener proto' );
is( $nc_objects[1]->local_host,   '::1',    'tcp6 listener local host' );
is( $nc_objects[1]->local_port,   '631',    'tcp6 listener local port' );
is( $nc_objects[1]->foreign_host, '*',      'tcp6 listener foreign host' );
is( $nc_objects[1]->foreign_port, '*',      'tcp6 listener foreign port' );
is( $nc_objects[1]->state,        'LISTEN', 'tcp6 listener state' );

# IPv4 UDP, so no state
is( $nc_objects[2]->proto,      'udp4', 'udp4 proto' );
is( $nc_objects[2]->local_host, '*',    'udp4 local host' );
is( $nc_objects[2]->local_port, '514',  'udp4 local port' );
is( $nc_objects[2]->state,      '',     'udp4 state' );

# IPv6 TCP with a foreign host
is( $nc_objects[3]->proto,        'tcp6',        'tcp6 proto' );
is( $nc_objects[3]->local_host,   '2001:db8::1', 'tcp6 local host' );
is( $nc_objects[3]->local_port,   '22',          'tcp6 local port' );
is( $nc_objects[3]->foreign_host, '2001:db8::2', 'tcp6 foreign host' );
is( $nc_objects[3]->foreign_port, '33333',       'tcp6 foreign port' );
is( $nc_objects[3]->state,        'ESTABLISHED', 'tcp6 state' );

# unparsable lines are skipped rather than producing garbage or warnings
my $garbage_fixture = join( "\n",
	'COMMAND     PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME',
	'',
	'short',
	lsof_line( 'trunc', qw( 2001 0 4u ) ),
	lsof_line( 'sshd',  qw( 2002 0 4u IPv4 0x1 0t0 TCP 192.0.2.1:22->192.0.2.2:56618 (ESTABLISHED) ) ),
) . "\n";

my @warnings;
local $SIG{__WARN__} = sub { push( @warnings, $_[0] ); };
my @garbage_nc_objects = Net::Connection::lsof::_parse_lsof_output( $garbage_fixture, $no_resolve_args );
is( scalar(@garbage_nc_objects), 1,      'unparsable lines skipped' );
is( scalar(@warnings),           0,      'no warnings for unparsable lines' ) or diag( join( '', @warnings ) );
is( $garbage_nc_objects[0]->pid, '2002', 'good line still parsed' );

# header only means nothing parsed
my @empty_nc_objects
	= Net::Connection::lsof::_parse_lsof_output(
		'COMMAND     PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME' . "\n",
		$no_resolve_args );
is( scalar(@empty_nc_objects), 0, 'header only parses to nothing' );

done_testing();
