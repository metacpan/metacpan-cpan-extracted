#!/usr/bin/env perl

use Parallel::ForkManager::Scaled;

my $pm = Parallel::ForkManager::Scaled->new(
    run_on_update => \&Parallel::ForkManager::Scaled::dump_stats,
    idle_target => 50,
);

$pm->set_waitpid_blocking_sleep(0);

for my $i (0..1000) {
    $pm->start and next;

    my $start = time;
    srand($$);
    my $lifespan = 5+int(rand(10));

    # Keep the CPU busy until it's time to exit
    while (time - $start < $lifespan) { 
        my $a = time; 
        my $b = $a^time/3;
    }

    $pm->finish;
}
