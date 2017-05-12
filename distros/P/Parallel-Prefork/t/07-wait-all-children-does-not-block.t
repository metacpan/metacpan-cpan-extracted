#! /usr/bin/perl

use strict;
use warnings;

use Fcntl qw/:flock/;
use File::Temp qw/tempfile/;
use Test::More tests => 1;
use Time::HiRes qw/sleep/;

use Parallel::Prefork;

my $pid = fork;
die $! unless defined $pid;

if ($pid) {
    my $timeout = 0;
    local $SIG{ALRM} = sub { $timeout = 1; kill 'INT', $pid };
    alarm 5;
    until(waitpid $pid, 0) {}
    alarm 0;
    ok !$timeout, "wait_all_children does not block";
} else {

    my ($fh, $filename) = tempfile;
    syswrite $fh, '0', 1;
    close $fh;

    my $manager_pid = $$;

    my $pm = Parallel::Prefork->new({
        max_workers   => 30,
        fork_delay    => 0,
    });

    until ($pm->signal_received) {
        $pm->start and next;

        open my $fh, '+<', $filename
            or die "failed to open temporary file: $filename: ";
        flock $fh, LOCK_EX;
        sysread $fh, my $worker_count, 10;
        $worker_count++;
        seek $fh, 0, 0;
        syswrite $fh, $worker_count, length($worker_count);
        flock $fh, LOCK_UN;
        close $fh;

        if ($worker_count == $pm->max_workers) {
            kill 'TERM', $manager_pid;
        }

        # wait for SIGTERM
        my $rcv = 0;
        eval {
            local $SIG{TERM} = sub { $rcv = 1; die "SIGTERM" };
            sleep(100);
        };
        die $@ if $@ && !$rcv;

        # sleep 1 +/- 0.01 seconds
        sleep(0.99 + 0.02 * $worker_count / $pm->max_workers);
        $pm->finish;
    }

    $pm->wait_all_children(1);
    $pm->wait_all_children();
    exit 0;
}
