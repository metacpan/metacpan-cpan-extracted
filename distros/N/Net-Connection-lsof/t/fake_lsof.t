#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

BEGIN {
	use_ok('Net::Connection::lsof') || print "Bail out!\n";
}

if ( $^O eq 'MSWin32' ) {
	plan skip_all => 'test uses a sh script to fake lsof';
}

my $fake_bin_dir = tempdir( CLEANUP => 1 );
local $ENV{PATH} = $fake_bin_dir . ':' . $ENV{PATH};

my $fixture
	= 'COMMAND     PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME' . "\n"
	. 'sshd       3001    0    4u  IPv4                0x1      0t0  TCP 192.0.2.1:22->192.0.2.2:56618 (ESTABLISHED)'
	. "\n";

# writes out a fake lsof to the fake bin dir printing the specified
# output and exiting with the specified exit code
sub write_fake_lsof {
	my ( $exit_code, $output ) = @_;

	my $script = $fake_bin_dir . '/lsof';
	open( my $script_fh, '>', $script ) || die( 'failed to open "' . $script . '"... ' . $! );
	print $script_fh "#!/bin/sh\n";
	if ( $output ne '' ) {
		print $script_fh "cat << 'FAKE_LSOF_EOF'\n" . $output . "FAKE_LSOF_EOF\n";
	}
	print $script_fh 'exit ' . $exit_code . "\n";
	close($script_fh);
	chmod( 0755, $script ) || die( 'failed to chmod "' . $script . '"... ' . $! );

	return;
} ## end sub write_fake_lsof

my $no_resolve_args = {
	ports       => 0,
	ptrs        => 0,
	uid_resolve => 0,
	proc_info   => 0,
};

# exit 0 works everywhere
write_fake_lsof( 0, $fixture );
my @nc_objects;
my $worked = eval {
	@nc_objects = lsof_to_nc_objects($no_resolve_args);
	1;
};
ok( $worked, 'exit 0 does not die' ) or diag( 'died with... ' . $@ );
is( scalar(@nc_objects),          1,           'exit 0 parses the output' );
is( $nc_objects[0]->pid,          '3001',      'pid parsed' );
is( $nc_objects[0]->proto,        'tcp4',      'proto parsed' );
is( $nc_objects[0]->local_host,   '192.0.2.1', 'local host parsed' );
is( $nc_objects[0]->foreign_port, '56618',     'foreign port parsed' );

# defaults apply when called with out args, header only output so
# nothing is there to resolve
write_fake_lsof( 0, 'COMMAND     PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME' . "\n" );
my @default_nc_objects;
$worked = eval {
	@default_nc_objects = lsof_to_nc_objects();
	1;
};
ok( $worked, 'no args does not die' ) or diag( 'died with... ' . $@ );
is( scalar(@default_nc_objects), 0, 'header only returns no objects' );

# a hard failure dies everywhere
write_fake_lsof( 2, '' );
$worked = eval {
	lsof_to_nc_objects($no_resolve_args);
	1;
};
ok( !$worked, 'exit 2 dies' );

# some Linux distros exit 1 on success, so that is accepted on Linux
# and a failure everywhere else
write_fake_lsof( 1, $fixture );
my @exit_1_nc_objects;
$worked = eval {
	@exit_1_nc_objects = lsof_to_nc_objects($no_resolve_args);
	1;
};
if ( $^O eq 'linux' ) {
	ok( $worked, 'exit 1 does not die on Linux' ) or diag( 'died with... ' . $@ );
	is( scalar(@exit_1_nc_objects), 1, 'exit 1 output parsed on Linux' );
} else {
	ok( !$worked, 'exit 1 dies on ' . $^O );
}

done_testing();
