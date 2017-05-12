#!/usr/bin/env perl

use Parallel::ForkManager::Scaled;

my $pm = Parallel::ForkManager::Scaled->new(
    run_on_update => \&Parallel::ForkManager::Scaled::dump_stats
);

# just to be sure we can saturate the CPU
$pm->hard_max_procs($pm->ncpus * 4);

$pm->set_waitpid_blocking_sleep(0);

while (<>) {
    chomp;
    $pm->start and next;

    # In the child now, run the shell process
    system $_;
    $pm->finish;
}

$pm->wait_all_children;
