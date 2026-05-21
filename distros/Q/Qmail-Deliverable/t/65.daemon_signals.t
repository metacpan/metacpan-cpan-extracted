use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX ":sys_wait_h";

use lib 'lib';
use lib 't/lib';

use Qmail::Deliverable;
use QDTest qw(setup_abs_fixtures start_daemon stop_daemon);

my $fixtures = setup_abs_fixtures();

subtest 'pidfile is created with correct PID and removed on SIGTERM' => sub {
    my $tmp     = tempdir( CLEANUP => 1 );
    my $pidfile = "$tmp/qd.pid";
    my ( $pid, $port ) = start_daemon(
        qmail_dir => $fixtures,
        pidfile   => $pidfile,
    );

    ok -e $pidfile, 'pidfile exists after start';

    open my $fh, '<', $pidfile or die "open $pidfile: $!";
    my $written_pid = do { local $/; <$fh> };
    close $fh;
    chomp $written_pid;
    is $written_pid, $pid, 'pidfile contains the daemon PID';

    stop_daemon($pid);

    ok !-e $pidfile, 'pidfile removed on shutdown';
};

subtest 'SIGINT also triggers clean shutdown + pidfile cleanup' => sub {
    my $tmp     = tempdir( CLEANUP => 1 );
    my $pidfile = "$tmp/qd.pid";
    my ( $pid, $port ) = start_daemon(
        qmail_dir => $fixtures,
        pidfile   => $pidfile,
    );

    ok -e $pidfile, 'pidfile exists';

    # Send SIGINT and wait for the child to exit.
    {
        local $?;
        kill 'INT', $pid;
        my $deadline = time + 5;
        while ( time < $deadline ) {
            my $r = waitpid $pid, WNOHANG;
            last if $r == $pid;
            select undef, undef, undef, 0.05;
        }
    }

    ok !kill( 0, $pid ), 'daemon process has exited';
    ok !-e $pidfile,     'pidfile removed after SIGINT';
};

subtest 'no pidfile written when --pidfile is not given' => sub {
    my $tmp = tempdir( CLEANUP => 1 );
    my ( $pid, $port ) = start_daemon( qmail_dir => $fixtures );

    opendir my $dh, $tmp or die $!;
    my @entries = grep !/^\.\.?$/, readdir $dh;
    closedir $dh;
    is scalar @entries, 0, 'no stray files appear in the tempdir without --pidfile';

    stop_daemon($pid);
};

subtest 'startup failure leaves no pidfile behind' => sub {
    my $tmp     = tempdir( CLEANUP => 1 );
    my $pidfile = "$tmp/qd.pid";

    # Run a first daemon that occupies a known port.
    my ( $pid1, $port ) = start_daemon( qmail_dir => $fixtures );

    # Try to start a second daemon on the same port -- bind will fail
    # before pidfile is opened, so no pidfile should be left.
    my $child = fork;
    die "fork: $!" if not defined $child;
    if ( $child == 0 ) {
        @ARGV = ( '--foreground', '--listen', "127.0.0.1:$port", '--pidfile', $pidfile );
        $Qmail::Deliverable::qmail_dir = $fixtures;
        Qmail::Deliverable::reread_config();
        my $bin = QDTest::repo_root() . '/bin/qmail-deliverabled';
        do $bin;
        exit 1;
    }
    waitpid $child, 0;
    ok !-e $pidfile, 'failed startup (port in use) does not leave an orphan pidfile';

    stop_daemon($pid1);
};

done_testing();
