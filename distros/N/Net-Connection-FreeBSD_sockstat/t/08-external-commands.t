#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use Net::Connection::FreeBSD_sockstat;

# sockstat and ps are both invoked unqualified, so standing in for them is a
# matter of putting a script of the same name at the front of the PATH
if ( $^O eq 'MSWin32' ) {
	plan skip_all => 'needs a POSIX shell for the stand in commands';
}

my $fake_bin = tempdir( CLEANUP => 1 );

# Writes a stand in for $name that prints $output and exits with $exit_code.
sub fake_command {
	my ( $name, $output, $exit_code ) = @_;

	my $path = File::Spec->catfile( $fake_bin, $name );

	open( my $fh, '>', $path ) or die "could not write $path: $!";
	print {$fh} "#!/bin/sh\n";
	print {$fh} "cat <<'END_OF_FAKE_OUTPUT'\n$output\nEND_OF_FAKE_OUTPUT\n";
	print {$fh} "exit $exit_code\n";
	close($fh);

	chmod( 0755, $path ) or die "could not chmod $path: $!";

	return;
} ## end sub fake_command

my $good_ps_json = <<'END_JSON';
{"process-information": {"process": [
{"pid":"1","wait-channel":"wait","percent-cpu":"0.0","percent-memory":"0.1","elapsed-times":"100","command":"/sbin/init"},
{"pid":"1234","wait-channel":"select","percent-cpu":"1.5","percent-memory":"2.5","elapsed-times":"50","command":"sshd: /usr/sbin/sshd"}
]}}
END_JSON

subtest 'ps exiting non zero' => sub {
	local $ENV{PATH} = $fake_bin . ':' . $ENV{PATH};
	fake_command( 'ps', '', 3 );

	my $proc_info;
	eval { $proc_info = Net::Connection::FreeBSD_sockstat::_ps_proc_info(); };

	like( $@, qr/Calling ps failed with a exit code of 3/, 'the exit code makes it into the message' );
};

subtest 'ps emitting undecodable JSON' => sub {
	local $ENV{PATH} = $fake_bin . ':' . $ENV{PATH};
	fake_command( 'ps', 'ps: illegal option -- libxo', 0 );

	my $proc_info;
	eval { $proc_info = Net::Connection::FreeBSD_sockstat::_ps_proc_info(); };

	like( $@, qr/Failed to decode the JSON from ps/, 'dies rather than passing garbage along' );
};

subtest 'ps emitting the wrong shape' => sub {
	local $ENV{PATH} = $fake_bin . ':' . $ENV{PATH};

	foreach my $bad_shape ( '[]', '{}', '{"process-information": []}', '{"process-information": {"process": {}}}' )
	{
		fake_command( 'ps', $bad_shape, 0 );

		my $proc_info;
		eval { $proc_info = Net::Connection::FreeBSD_sockstat::_ps_proc_info(); };

		like( $@, qr/does not contain the array \.process-information\.process/, "dies on $bad_shape" );
	}
}; ## end 'ps emitting the wrong shape' => sub

subtest 'ps output being turned into proc info' => sub {
	local $ENV{PATH} = $fake_bin . ':' . $ENV{PATH};
	fake_command( 'ps', $good_ps_json, 0 );

	my $before = time;
	my $proc_info;
	eval { $proc_info = Net::Connection::FreeBSD_sockstat::_ps_proc_info(); };
	my $after = time;

	is( $@,              '',     'does not die' );
	is( ref($proc_info), 'HASH', 'a hash ref comes back' );
	is_deeply( [ sort keys %{$proc_info} ], [ '1', '1234' ], 'keyed on pid' );

	is( $proc_info->{1234}{proc},  'sshd: /usr/sbin/sshd', 'the command becomes proc' );
	is( $proc_info->{1234}{wchan}, 'select',               'wait-channel becomes wchan' );

	# ps hands these back as JSON strings, so they should have been cast
	is( $proc_info->{1234}{pctcpu}, 1.5,                         'percent-cpu becomes pctcpu' );
	is( $proc_info->{1234}{pctmem}, 2.5,                         'percent-memory becomes pctmem' );
	is( $proc_info->{1}{pctcpu},    $proc_info->{1}{pctcpu} + 0, 'pctcpu is a number rather than the string 0.0' );
	is( $proc_info->{1}{pctmem},    $proc_info->{1}{pctmem} + 0, 'pctmem is a number' );

	# ps reports how long a proc has been running, not when it started
	cmp_ok( $proc_info->{1234}{pid_start}, '>=', $before - 50, 'elapsed-times is subtracted from now' );
	cmp_ok( $proc_info->{1234}{pid_start}, '<=', $after - 50,  'and not from anything else' );
}; ## end 'ps output being turned into proc info' => sub

subtest 'a ps entry with no pid' => sub {
	local $ENV{PATH} = $fake_bin . ':' . $ENV{PATH};
	fake_command(
		'ps',
		'{"process-information": {"process": ['
			. '{"wait-channel":"-","percent-cpu":"0.0","percent-memory":"0.0","elapsed-times":"1","command":"[nopid]"},'
			. '{"pid":"1","wait-channel":"wait","percent-cpu":"0.0","percent-memory":"0.1","elapsed-times":"100","command":"/sbin/init"}'
			. ']}}',
		0
	);

	my $proc_info;
	eval { $proc_info = Net::Connection::FreeBSD_sockstat::_ps_proc_info(); };

	is( $@, '', 'does not die' );
	is_deeply( [ keys %{$proc_info} ], ['1'], 'the entry with no pid is skipped and the rest kept' );
}; ## end 'a ps entry with no pid' => sub

#
# The remaining checks go through sockstat_to_nc_objects without a string,
# which refuses to run anywhere but FreeBSD.
#
SKIP: {
	skip 'sockstat is only called on FreeBSD', 3 if $^O !~ /freebsd/;

	my $sockstat_json = <<'END_JSON';
{"__version": "1", "sockstat": {"socket": [
{"user":"root","command":"sshd","pid":1234,"fd":4,"proto":"tcp4", "local": {"address":"*","port":22}, "foreign": {"address":"*","port":0},"conn-state":"LISTEN"},
{"proto":"tcp6", "local": {"address":"::1","port":4045}, "foreign": {"address":"*","port":0},"conn-state":"LISTEN"},
{"user":"root","command":"gone","pid":4321,"fd":9,"proto":"udp4", "local": {"address":"*","port":123}, "foreign": {"address":"*","port":0}}
]}}
END_JSON

	subtest 'sockstat exiting non zero' => sub {
		local $ENV{PATH} = $fake_bin . ':' . $ENV{PATH};
		fake_command( 'sockstat', 'sockstat: unknown option -- libxo', 1 );

		my @objects;
		eval { @objects = &sockstat_to_nc_objects( { ports => 0, ptrs => 0, proc_info => 0 } ); };

		like( $@, qr/failed with a exit code of 1/, 'the exit code makes it into the message' );
	};

	subtest 'sockstat emitting undecodable JSON' => sub {
		local $ENV{PATH} = $fake_bin . ':' . $ENV{PATH};
		fake_command( 'sockstat', 'USER COMMAND PID FD PROTO', 0 );

		my @objects;
		eval { @objects = &sockstat_to_nc_objects( { ports => 0, ptrs => 0, proc_info => 0 } ); };

		like( $@, qr/Failed to decode the JSON from sockstat/, 'dies rather than passing garbage along' );
	};

	subtest 'proc info being matched up against sockets' => sub {
		local $ENV{PATH} = $fake_bin . ':' . $ENV{PATH};
		fake_command( 'sockstat', $sockstat_json, 0 );
		fake_command( 'ps',       $good_ps_json,  0 );

		# an orphan has no pid to look the proc info up by, so skipping it is
		# what keeps this from warning about an undefined hash key
		my @warnings;
		local $SIG{__WARN__} = sub { push( @warnings, $_[0] ); };

		my @objects;
		eval { @objects = &sockstat_to_nc_objects( { ports => 0, ptrs => 0, zombie_skip => 0 } ); };

		is( $@, '', 'does not die' );
		is_deeply( \@warnings, [], 'and mixing orphans with proc info warns about nothing' );
		is( scalar(@objects), 3, 'every socket comes back' );

		# pid 1234 is in the ps output, so it gets the full treatment
		is( $objects[0]->pid,    1234,                   'the owned socket kept its pid' );
		is( $objects[0]->proc,   'sshd: /usr/sbin/sshd', 'and picked up proc' );
		is( $objects[0]->wchan,  'select',               'and wchan' );
		is( $objects[0]->pctcpu, 1.5,                    'and pctcpu' );
		is( $objects[0]->pctmem, 2.5,                    'and pctmem' );

		# an orphan has no proc to look up in the first place
		is( $objects[1]->username, '?',   'the orphan is still an orphan' );
		is( $objects[1]->proc,     undef, 'and gets no proc' );
		is( $objects[1]->wchan,    undef, 'and no wchan' );

		# pid 4321 is not in the ps output, standing in for a proc that exited
		# between the sockstat and ps calls
		is( $objects[2]->pid,   4321,  'a socket whose proc is missing from ps kept its pid' );
		is( $objects[2]->proc,  undef, 'but got no proc' );
		is( $objects[2]->wchan, undef, 'and no wchan' );
	}; ## end 'proc info being matched up against sockets' => sub
} ## end SKIP:

done_testing();
