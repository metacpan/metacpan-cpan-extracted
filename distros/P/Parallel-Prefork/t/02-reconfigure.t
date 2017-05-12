#! /usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use_ok('Parallel::Prefork');

my $pm;
eval {
    $pm = Parallel::Prefork->new({
        max_workers  => 1,
        trap_signals => {
            TERM => 'TERM',
            HUP  => 'TERM',
        },
    });
};
ok($pm);

my $c = 0;

while ($pm->signal_received ne 'TERM') {
    $c++;
    $pm->start(
        sub {
            sleep 1;
            if ($c == 1) {
                kill 'HUP', $pm->manager_pid;
            } else {
                kill 'TERM', $pm->manager_pid;
            }
        },
    );
}
$pm->wait_all_children;

is($c, 2);
