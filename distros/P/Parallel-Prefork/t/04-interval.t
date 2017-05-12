use strict;
use warnings;

use File::Temp ();
use Parallel::Prefork;
use Time::HiRes qw(sleep);
use Test::Requires qw(Parallel::Scoreboard);

use Test::More tests => 6;

my $sb = Parallel::Scoreboard->new(
    base_dir => File::Temp::tempdir(CLEANUP => 1),
);

if (my $pid = fork) {
    
    # parent
    sleep 0.5;
    is scalar(keys %{$sb->read_all}), 1, 'workers at 0.5 sec';
    sleep 1;
    is scalar(keys %{$sb->read_all}), 2, 'workers at 1.5 sec';
    sleep 1;
    is scalar(keys %{$sb->read_all}), 3, 'workers at 2.5 sec';
    sleep 1;
    is scalar(keys %{$sb->read_all}), 3, 'workers at 3.5 sec';
    kill 'TERM', $pid;
    sleep 0.5;
    is scalar(keys %{$sb->read_all}), 2, 'workers at 4 sec';
    sleep 2;
    is scalar(keys %{$sb->read_all}), 1, 'workers at 6 sec';
    while (wait == -1) {}
    
} else {
    
    # child
    my $pm = Parallel::Prefork->new({
        max_workers    => 3,
        spawn_interval => 1,
        trap_signals => {
            TERM => [ 'TERM', 2 ],
            HUP  => 'TERM',
        },
    });
    while ($pm->signal_received ne 'TERM') {
        $pm->start and next;
        # worker process
        my $term_req;
        $SIG{TERM} = sub { $term_req = 1 };
        $sb->update('A');
        sleep 1000 until $term_req;
        $pm->finish;
    }
    $pm->wait_all_children;
    exit 0;
    
}
