use strict;
use warnings;

use File::Temp qw();
use Test::More tests => 8;

use_ok('Parallel::Prefork::SpareWorkers');

my $tempdir = File::Temp::tempdir(CLEANUP => 1);

my $pm = Parallel::Prefork::SpareWorkers->new({
    min_spare_workers    => 3,
    max_spare_workers    => 5,
    max_workers          => 10,
    err_respawn_interval => 0,
    trap_signals         => {
        TERM => 'TERM',
    },
});
is $pm->num_active_workers, 0, 'no active workers';

my @tests = (
    sub {
        is $pm->num_workers, 3, 'min_spare_workers';
        is $pm->num_active_workers, 0, 'no active workers';
        open my $fh, '>', "$tempdir/active"
                or die "failed to touch file $tempdir/active:$!";
        close $fh;
    },
    sub {
        is $pm->num_workers, 10, 'max_workers';
        is $pm->num_active_workers, 10, 'all workers active';
        unlink "$tempdir/active"
            or die "failed to unlink file $tempdir/active:$!";
    },
    sub {
        is $pm->num_workers, 5, 'max_spare_workers';
        is $pm->num_active_workers, 0, 'no active workers';
    },
);

my $SLEEP_SECS = 3; # 1 second until all clients update their state, plus 10 invocations to min/max the process, plus 1 second bonus

$SIG{ALRM} = sub {
    my $test = shift @tests;
    $test->();
    if (@tests) {
	alarm $SLEEP_SECS;
    } else {
        $pm->signal_received('TERM');
    }
};
alarm $SLEEP_SECS;

while ($pm->signal_received ne 'TERM') {
    $pm->start and next;
    while (1) {
        $pm->set_status(
            -e "$tempdir/active"
                ? 'A' : Parallel::Prefork::SpareWorkers::STATUS_IDLE(),
        );
        sleep 1;
    }
}

$pm->wait_all_children;
