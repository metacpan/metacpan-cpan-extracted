#!/perl
use strict;

use Proc::Launcher;

use Test::More tests => 12;

use File::Temp qw(tempdir);
my $tempdir = tempdir('/tmp/proc_launcher_XXXXXX', CLEANUP => 1);

my $start_method = sub { sleep 60 };

my $launcher = Proc::Launcher->new( start_method => $start_method,
                                    daemon_name  => 'test',
                                    pid_dir      => $tempdir,
                                );

ok( ! $launcher->is_running(),
    "Checking that test process is not already running"
);

ok( $launcher->restart(),
    "Restarting a process that isn't currently running"
);

sleep 2;

ok( $launcher->is_running(),
    "Checking that process was started"
);

my $initial_pid = $launcher->pid();
ok( $initial_pid,
    "Checking that a PID was found for the process"
);


{
    ok( $launcher->restart(),
        "Restarting the running process"
    );
    sleep 2;

    my $new_pid = $launcher->pid;
    ok( $new_pid,
        "Checking that a new PID was found after restart"
    );

    ok( $new_pid != $initial_pid,
        "Checking that initial pid $initial_pid is different than new pid $new_pid"
    );

    ok( $launcher->is_running(),
        "Checking that launcher was restarted"
    );
}



{
    ok( $launcher->restart( { test => 1 }, 2 ),
        "Restarting the running process passing in test data and setting sleep to 2"
    );
    sleep 2;

    my $new_pid = $launcher->pid;
    ok( $new_pid,
        "Checking that a new PID was found after restart"
    );

    ok( $new_pid != $initial_pid,
        "Checking that initial pid $initial_pid is different than new pid $new_pid"
    );

    ok( $launcher->is_running(),
        "Checking that launcher was restarted"
    );
}


# shut down the test launcher in case this test case is broken and the
# launcher is still running.
$launcher->force_stop();

