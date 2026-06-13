use strict;
use warnings;

use lib 't/';

use POSIX qw(WIFSIGNALED WTERMSIG);
use RPiTest;
use Test::More;

rpi_running_test(__FILE__);

my $mod = 'RPi::WiringPi';

{ # Any live object with fatal_exit => 0 keeps the process alive on SIGINT

    my $default = $mod->new(label => 't/154-default', shm_key => 'rpit');
    my $lenient = $mod->new(
        label      => 't/154-lenient',
        shm_key    => 'rpit',
        fatal_exit => 0
    );

    kill 'INT', $$;
    select undef, undef, undef, 0.2;

    ok 1, "process survived SIGINT with a fatal_exit => 0 object live";
    ok $default->{clean}, "default object was cleaned up by the signal handler";
    ok $lenient->{clean}, "lenient object was cleaned up by the signal handler";
}

{ # With every object at the default, SIGINT terminates the process

    my $pid = fork();

    die "fork failed: $!\n" if ! defined $pid;

    if ($pid == 0) {
        # Child: a single default (fatal_exit true) object must die by SIGINT

        my $obj = $mod->new(label => 't/154-child', shm_key => 'rpit');

        kill 'INT', $$;
        select undef, undef, undef, 2;

        # Should never be reached

        exit 0;
    }

    waitpid $pid, 0;

    ok WIFSIGNALED(${^CHILD_ERROR_NATIVE}),
        "process with only default fatal_exit objects dies on SIGINT";
    is WTERMSIG(${^CHILD_ERROR_NATIVE}), 2,
        "...and the termination signal is SIGINT";
}

rpi_check_pin_status();

done_testing();
