use strict;
use warnings;

use Test::More;
use Test::SharedFork;
use Parallel::Prefork;

my $i = 0;
my $j = 0;

my $pm = Parallel::Prefork->new({
    max_workers => 3,
    trap_signals => {
        TERM => 'TERM',
    },
    before_fork => sub {
        my $pm = shift;
        $i++;
    },
    after_fork => sub {
        my ($pm, $pid) = @_;
        $j++;
    },
});

while ( $pm->signal_received ne 'TERM' ) {
    $pm->start(
        sub {
            if ( $i == 10 ) {
                kill TERM => $pm->manager_pid;
            }
        }
    );
}

$pm->wait_all_children;

cmp_ok($i, '>=', 10, 'before_fork callback was called 10 times at least');
cmp_ok($j, '>=', 10, 'after_fork callback was called 10 times at least');

done_testing;

