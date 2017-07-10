#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use Net::ZooKeeper qw(:all);
use ZooItServer;
use POSIX;

use Test::More;

$| = 1;

my $server = ZooItServer->start;
my $zk = eval { $server->connect } or no_server();

$zk->create('/connect', 42, acl => ZOO_OPEN_ACL_UNSAFE);
my @z = $zk->get_children('/');
print "@z\n";
ok(scalar (grep { /connect/ } @z), "Znode /connect found");

$server->stop;
@z = $zk->get_children('/');
ok(@z == 0, "No Znode found after server stop");

$server->start;
$server->connect;
@z = $zk->get_children('/');
print "@z\n";
ok(scalar (grep { /connect/ } @z), "Znode /connect found after server restart");

done_testing;

sub no_server {
    ok(1, 'Skipping test, no ZK server available');
    done_testing;
    _exit 0;
}
