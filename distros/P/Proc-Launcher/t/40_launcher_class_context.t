#!/perl
use strict;

package main;

use Proc::Launcher;

use Test::More tests => 4;

use File::Temp qw(tempdir);
my $tempdir = tempdir('/tmp/proc_launcher_XXXXXX', CLEANUP => 1);

use lib "t/lib";

my $context = { sleep => 5 };

my $launcher = Proc::Launcher->new( class        => 'TestApp',
                                    start_method => 'runme',
                                    daemon_name  => 'test',
                                    pid_dir      => $tempdir,
                                    context      => $context,
                                );

ok( ! $launcher->is_running(),
    "Checking that test process is not already running"
);

ok( $launcher->start(),
    "Starting the test process"
);

ok( $launcher->is_running(),
    "Checking that process was started successfully"
);

sleep 8;

ok( ! $launcher->is_running(),
    "Checking that process was started successfully"
);

