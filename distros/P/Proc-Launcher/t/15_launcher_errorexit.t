#!/perl
use strict;

use Proc::Launcher;

use Test::More tests => 2;

use File::Temp qw(tempdir);
my $tempdir = tempdir('/tmp/proc_launcher_XXXXXX', CLEANUP => 1);

my $start_method = sub { exit 1 };

my $launcher = Proc::Launcher->new( start_method => $start_method,
                                    daemon_name  => 'test',
                                    pid_dir      => $tempdir,
                                    );

ok( ! $launcher->is_running(),
    "Checking that test process is not already running"
);

# Starting the test process
$launcher->start(),

sleep 2;

ok( ! $launcher->is_running(),
    "Checking that process already exited"
);

