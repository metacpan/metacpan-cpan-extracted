#!/perl
use strict;

use Proc::Launcher::Manager;

use File::Temp qw/ :POSIX /;
use Test::More tests => 16;
use File::Temp qw(tempdir);

my $tempdir = tempdir('/tmp/proc_launcher_XXXXXX', CLEANUP => 1);

my $manager = Proc::Launcher::Manager->new( app_name  => 'testapp',
                                            pid_dir   => $tempdir,
                                        );

my @test_daemons = qw( test_1 test_2 test_3 );

for my $daemon_name ( @test_daemons ) {
    ok( $manager->register( daemon_name => $daemon_name, start_method => sub { sleep 600 } ),
        "registering test daemon: $daemon_name"
    );
}

is_deeply( [ $manager->daemons_names() ],
           [ @test_daemons             ],
           "checking all_daemons()"
       );


# startup and shutdown
{
    ok( $manager->start(),
        "calling start() on manager to start registered daemons"
    );

    sleep 2;

    is_deeply( [ $manager->is_running ],
               [ @test_daemons             ],
               "checking all three daemons are now running"
           );

    ok( $manager->stop(),
        "Shutting down all daemons"
    );

    sleep 2;

    is_deeply( [ $manager->is_running ],
               [ ],
               "checking all three daemons were successfully shut down"
           );
}


# enable/disable
{
    ok( $manager->disable(),
        "calling disable() on manager to disable registered daemons"
    );

    ok( $manager->start(),
        "calling start() on manager to start registered daemons"
    );

    sleep 2;

    is_deeply( [ $manager->is_running ],
               [ ],
               "checking all three daemons were successfully shut down"
           );

    ok( $manager->enable(),
        "calling enable() on manager to enable registered daemons"
    );

}

# force_stop
{
    ok( $manager->start(),
        "calling start() on manager to start registered daemons"
    );

    sleep 2;

    is_deeply( [ $manager->is_running ],
               [ @test_daemons             ],
               "checking all three daemons are now running"
           );

    ok( $manager->force_stop(),
        "Shutting down all daemons"
    );

    sleep 2;

    is_deeply( [ $manager->is_running ],
               [ ],
               "checking all three daemons were successfully shut down"
           );
}

