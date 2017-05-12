#!/perl
use strict;

use Proc::Launcher;

use Test::More tests => 5;

use File::Temp qw(tempdir);
my $tempdir = tempdir('/tmp/proc_launcher_XXXXXX', CLEANUP => 1);

use lib "t/lib";

my $launcher = Proc::Launcher->new( class        => 'TestApp',
                                    start_method => 'runme',
                                    daemon_name  => 'test',
                                    pid_dir      => $tempdir,
                                );

ok( ! $launcher->is_running(),
    "Checking that test process is not already running"
);

ok( $launcher->start(),
    "Starting the test process"
);

sleep 2;

ok( $launcher->is_running(),
    "Checking that process was started successfully"
);

ok( $launcher->stop(),
    "Calling 'stop' method"
);

sleep 2;

ok( ! $launcher->is_running(),
    "Checking that 'stop' successfully shut down the process"
);

