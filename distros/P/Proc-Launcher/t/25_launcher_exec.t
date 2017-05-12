#!/perl
use strict;

use Proc::Launcher;

use Test::More tests => 8;

use File::Temp qw(tempdir);
my $tempdir = tempdir('/tmp/proc_launcher_XXXXXX', CLEANUP => 1);

# ignore kill signal (this is what makes us stubborn)
$SIG{HUP}  = 'IGNORE';

my $launcher = Proc::Launcher->new( start_method => sub { exec 'sleep 60' },
                                    daemon_name  => 'test-exec',
                                    pid_dir      => $tempdir,
                                );

ok( ! $launcher->is_running(),
    "Checking that test process is not already running"
);

ok( ! $launcher->pid(),
    "Checking that pid file is empty"
);

ok( $launcher->start(),
    "Starting the test process"
);

sleep 2;

ok( $launcher->is_running(),
    "Checking that process was started successfully"
);

ok( $launcher->pid(),
    "Checking that pid file is not empty"
);

ok( ! $launcher->start(),
    "Calling start() while process is already running"
);

ok( $launcher->force_stop(),
    "Calling 'force_stop' method"
);

sleep 2;

ok( ! $launcher->is_running(),
    "Checking that process exec'd process was shut down"
);
