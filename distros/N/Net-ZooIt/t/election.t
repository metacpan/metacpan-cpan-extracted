#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use POSIX;
use Net::ZooIt;
use Net::ZooKeeper qw(:all);
use ZooItServer;

use Test::More;

$| = 1;

Net::ZooIt::set_log_level(ZOOIT_DEBUG);

my $T_MAX = 30;
my $T_MAX_ERR = 41;

my $server = ZooItServer->start;
eval { $server->connect } or no_server();

# Create 3 child processes running for leadership for random periods of time
my $parent = $$;
my $t0 = time;
my @pids;

for (1 .. 3) {
    my $pid = fork;
    last unless $pid;
    print STDERR "Child $pid forked\n";
    push @pids, $pid;
}

# Parent waiting for workers to complete
if ($$ == $parent) {
    sleep 10;
    $server->stop;
    sleep $t0 + 15 - time;
    $server->start;
    sleep $t0 + $T_MAX_ERR - time;
    for (@pids) {
        if (waitpid($_, WNOHANG) == $_) {
            ok(1, "Child $_ terminated in time");
        } else {
            ok(0, "Child $_ deadlocked");
            kill 'KILL', $_;
            waitpid $_, 0;
        }
    }
    done_testing;
} else {
    # Child processes doing the leader election
    my $zk = $server->connect;
    $zk->create('/zooitelect' => $$, acl => ZOO_OPEN_ACL_UNSAFE);

    while (1) {
        my $lock = Net::ZooIt->new_lock(zk => $zk, path => '/zooitelect');
        if ($lock) {
            print STDERR "$$ elected\n";
            sleep 1 + int rand 5;
            print STDERR "$$ resigns\n";
        } else {
            sleep 1 + int rand 5;
            print STDERR "$$ retrying\n";
        }
        if (time > $t0 + $T_MAX) {
            print STDERR "$$ exiting\n";
            last;
        }
    }
}

sub no_server {
    ok(1, 'Skipping test, no ZK server available');
    done_testing;
    _exit 0;
}
