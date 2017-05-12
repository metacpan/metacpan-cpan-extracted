#!/perl
use strict;

use Proc::Launcher::Manager;

use File::Temp qw/ :POSIX /;
use Test::More tests => 2;
use File::Temp qw(tempdir);

my $tempdir = tempdir('/tmp/proc_launcher_XXXXXX', CLEANUP => 1);

my $manager = Proc::Launcher::Manager->new( app_name  => 'testapp',
                                            pid_dir   => $tempdir,
                                        );

ok( ! $manager->is_running,
    "Checking that is_running gives an error when no daemons have been defined"
);

ok( ! $manager->read_log,
    "Checking that read_log gives an error when no daemons have been defined"
);
