use strict;
use warnings;

use File::Temp qw(tempdir);

use Test::More tests => 15;

use_ok('Parallel::Scoreboard');

# create temporary directory
my $base_dir = tempdir(CLEANUP => 1);

# instantiate
my $sb = Parallel::Scoreboard->new(
    base_dir => $base_dir,
);
ok($sb, 'instantiation');

# save my status (to check the behavior of fork-after-status-update)
$sb->update('me manager');

# create worker procs (that incr the status for each SIGUSR1)
my @workers;
for (0..1) {
    my $pid = fork;
    unless ($pid) {
        die "fork failed:$!"
            unless defined $pid;
        # child process
        my $counter = 0;
        $sb->update($counter);
        $SIG{USR1} = sub {
            $counter++;
            $sb->update($counter);
        };
        while (1) {
            sleep 1000;
        }
    }
    push @workers, $pid;
}

# check status
sleep 1;
my $stats = $sb->read_all();
is(scalar keys %$stats, 3, 'has corrent num of pids');
is($stats->{$$}, 'me manager', 'check my status');
is($stats->{$workers[0]}, 0, 'check counter');
is($stats->{$workers[1]}, 0, 'check counter 2');

# incr workers[0], and check
kill 'USR1', $workers[0];
sleep 1;
$stats = $sb->read_all();
is(scalar keys %$stats, 3, 'has corrent num of pids');
is($stats->{$$}, 'me manager', 'check my status');
is($stats->{$workers[0]}, 1, 'check counter 3');
is($stats->{$workers[1]}, 0, 'check counter 4');

# kill workers[1], and check
kill 'TERM', $workers[1];
sleep 1;
ok(-e "$base_dir/status_$workers[1]", 'status file should still exist');
$stats = $sb->read_all();
is($stats->{$$}, 'me manager', 'check my status');
is(scalar keys %$stats, 2, 'has corrent num of pids');
is($stats->{$workers[0]}, 1, 'check counter 5');
ok(! -e "$base_dir/status_$workers[1]", 'status file should have been removed');

kill 'TERM', $_
    for @workers;
