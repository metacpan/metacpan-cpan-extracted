# -*- perl -*-
#
#   Test that fork mode properly reaps child processes
#

require 5.004;
use strict;
use Test::More;
use POSIX qw/WNOHANG/;

# Skip on systems without fork
my $can_fork;
eval {
    if ( $^O ne "MSWin32" ) {
        my $pid = fork();
        if ( defined($pid) ) {
            if ( !$pid ) { exit 0; }    # Child
        }
        waitpid($pid, 0);
        $can_fork = 1;
    }
};
if ( !$can_fork ) {
    plan skip_all => 'This test requires a system with working forks';
}

plan tests => 4;

use Net::Daemon ();

# Create a minimal daemon object in fork mode
my $daemon = bless {
    'mode'  => 'fork',
    'debug' => 0,
}, 'Net::Daemon';

# SigChildHandler should return a coderef that reaps children,
# not just 'IGNORE' which is not portable
my $child_pid_ref;
my $handler = $daemon->SigChildHandler( \$child_pid_ref );

ok( defined $handler, 'SigChildHandler returns a defined value for fork mode' );
is( ref $handler, 'CODE', 'SigChildHandler returns a coderef for fork mode' );

# Test that the reaper actually reaps zombie processes
my $pid = fork();
die "Cannot fork: $!" unless defined $pid;
if ( !$pid ) {
    exit(0);    # Child exits immediately
}

# Give child time to exit and become a zombie
select( undef, undef, undef, 0.2 );

# Call the reaper
$handler->();

# The child should now be reaped - waitpid should return -1 or 0
my $result = waitpid( $pid, WNOHANG );
ok( $result <= 0, 'Child process was reaped by handler' );
is( $child_pid_ref, $pid, 'Handler sets child_pid ref to reaped PID' );
