use strict;
use warnings;

use Net::ZooKeeper qw/:acls :node_flags/;
use Net::ZooKeeper::Semaphore;
use Test::Exception;
use Test::More;


my $zkh = Net::ZooKeeper->new(
    $ENV{ZOOKEEPER_HOST} || 'localhost:2181',
    session_timeout => 1000,
);

my $path = $zkh->create('/test_sems123', '0',
    acl   => ZOO_OPEN_ACL_UNSAFE,
    flags => ZOO_EPHEMERAL,
);
unless ($path) {
    plan skip_all => 'zookeeper is not available';
}

my $TOTAL = 5;

ok(!get_sem($TOTAL + 1), 'not enough resources');
my @sems = ();
for (1 .. $TOTAL) {
    my $sem = get_sem(1);
    push @sems, $sem if $sem;
}
is(scalar(@sems), $TOTAL, "created $TOTAL separate semaphores");

ok(!get_sem(1), 'no more resourses');
@sems = ();
my $sem = get_sem(1);
ok($sem, 'resourses are available again');
throws_ok {get_sem(1, 10)} qr/Totals mismatch/, 'totals mismatch dies';

done_testing;


sub get_sem {
    return Net::ZooKeeper::Semaphore->new(
        zkh => $zkh,
        path => '/test_sems/test1',
        count => $_[0],
        total => $_[1] || $TOTAL,
    );
}
