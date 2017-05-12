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

ok( $launcher->is_enabled(),
    "Checking that the test daemon is currently enabled"
);

ok( $launcher->disable(),
    "Disabling launcher for test daemon"
);

ok( ! $launcher->is_enabled(),
    "Checking that test daemon is now disabled"
);

ok( ! $launcher->start(),
    "Trying to start a disabled process should not work"
);

ok( $launcher->disable(),
    "Disabling launcher that is already disabled"
);

ok( ! $launcher->is_enabled(),
    "Checking that disabled launcher is still disabled"
);

sleep 2;

ok( ! $launcher->is_running(),
    "Checking that disabled process was not started"
);

ok( $launcher->enable(),
    "Enabling launcher"
);

ok( $launcher->is_enabled(),
    "Checking that launcher is now enabled"
);

ok( $launcher->enable(),
    "Enabling launcher while already enabled"
);

ok( $launcher->is_enabled(),
    "Checking that launcher is still enabled"
);

# shut down the test launcher in case this test case is broken and the
# launcher is still running.
$launcher->force_stop();

