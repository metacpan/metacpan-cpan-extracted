#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use Net::ZooIt;
use Net::ZooKeeper qw(:all);
use ZooItServer;
use Test::More;
use POSIX;

$| = 1;
Net::ZooIt::set_log_level(ZOOIT_DEBUG);

my $server = ZooItServer->start;
eval { $server->connect } or no_server();

my $pid = fork;
my $zk = $server->connect;
my $file = "$server->{dir}/incr.txt";
$zk->create('/zooitlock' => $$, acl => ZOO_OPEN_ACL_UNSAFE);

incr() for 0 .. 9;
$pid ? wait : exit;
$zk->delete('/zooitlock');

open FILE, $file or die $!;
my $n;
(undef, $n) = split /\s/ while <FILE>;
close FILE;
ok($n == 20, 'n incrmented to 20, races avoided');

done_testing;

sub incr {
    my $lock;
    until ($lock = Net::ZooIt->new_lock(zk => $zk, path => '/zooitlock', timeout => 1)) {
        sleep 1;
    }
    my $num;
    if (open FILE, $file) {
        (undef, $num) = split /\s/ while <FILE>;
        close FILE;
    }
    $num //= 0;
    $num++;
    sleep 1 + rand 3;
    open FILE, ">>", $file or die $!;
    print STDERR "$$ $num\n";
    print FILE "$$ $num\n";
    close FILE;
}

sub no_server {
    ok(1, 'Skipping test, no ZK server available');
    done_testing;
    _exit 0;
}
