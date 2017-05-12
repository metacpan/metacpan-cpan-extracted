#!/usr/bin/perl
# Try using the ptrace command somehow.
# This test will count the number of syscalls that occur.

use strict;
use warnings;
use Test::NoWarnings;
use Test::More ( tests => 7 );
use Sys::Ptrace qw( ptrace PTRACE_TRACEME PTRACE_SYSCALL PTRACE_DETACH);
use vars qw($sig_chld);

$| = 1;    # Hot flush output buffer

ok( pipe( READER, WRITER ), 'Created pipe' );

pipe( RD_READY, WR_READY );

my $pid = fork;

if ( !defined $pid ) {
    fail("Could not fork for testing");
    exit;
}

if ( !$pid ) {

    # Child process
    close READER;

    # Send its output down the WRITER pipe
    open( STDOUT, ">&=" . fileno(WRITER) );
    open( STDIN,  "</dev/null" );

    # Wait for parent to block on <RD_READY>
    select( undef, undef, undef, 0.1 );

    ptrace(PTRACE_TRACEME);

    # RD_READY and WR_READY must be closed to
    # signal to the parent that the TRACEME
    # is ready to go.

    close RD_READY;
    close WR_READY;

    # The following exec will block with a
    # SIGTRAP and then trigger the parent
    # with a SIGCHLD because of the TRACEME
    # property installed above:

    #exec q{perl -e 'print "Hello world\n";'}
    exec "echo Hello world"
      or die "Cannot exec";
}

# Parent process

# Safe Signal Handler
$sig_chld = 0;
$SIG{CHLD} = sub { $sig_chld = 1; };

close WRITER;
close WR_READY;

# Wait for PTRACE_TRACEME to finish.
<RD_READY>;

# Wait until child trips the SIGTRAP
select( undef, undef, undef, 0.1 );

ok( ptrace( PTRACE_SYSCALL, $pid, 0x1, 0 ), 'Started SYSCALL trace' );

my $tracing  = 1;
my $syscalls = 0;
while ( $tracing && $tracing < 200 ) {

    # Wait for the next SIGCHLD ...
    select( undef, undef, undef, 0.1 );

    if ($sig_chld) {
        $sig_chld = 0;
        $?        = 0;
        my $w = waitpid( $pid, 0 );
        my $signal_number = ( $? >> 8 );
        if ( $w > 0 ) {
            if ( $signal_number == 5 ) {    # SIG_TRAP
                $syscalls++;
            }
            else {
                is( $signal_number, 0, 'Child process exited without error' );
                ok( ptrace( PTRACE_DETACH, $pid ), 'Detached from child without error' );
                $tracing = 0;
            }
        }
        else {
            fail("WHOA! sig_chld without waitpid!??!?!?!?");
            exit;
        }
    }
    else {
        $tracing++;
        fail("Paused, but SIGCHLD never came.");
        exit;
    }

    ptrace( PTRACE_SYSCALL, $pid );

}

if ($tracing) {
    fail("Took too long!");
    exit;
}

pass("Done tracing");

my $response = <READER>;
$response ||= "(nothing)\n";

like( $response, qr/hello/i, 'Got the expected output from the subprocess' );

#print STDERR "DEBUG: Found [$syscalls] syscalls\n";
