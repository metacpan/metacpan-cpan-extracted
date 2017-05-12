#!/perl
use strict;

use Proc::Launcher;

use Test::More tests => 2;

use File::Temp qw(tempdir);
my $tempdir = tempdir('/tmp/proc_launcher_XXXXXX', CLEANUP => 1);

my $start_method = sub { sleep 60 };

my $launcher = Proc::Launcher->new( start_method => $start_method,
                                    daemon_name  => 'test',
                                    pid_file     => $tempdir,
                                );

ok( ! $launcher->is_running(),
    "Checking that test process is not already running"
);

ok( ! $launcher->remove_pidfile(),
    "Checking that remove_pidfile does nothing since process is not running"
);

