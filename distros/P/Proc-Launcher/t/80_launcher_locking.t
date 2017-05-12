#!/perl
use strict;

use Test::More;

# Don't run tests during end-user installs
plan( skip_all => 'Author tests not required for installation' )
    unless ( $ENV{RELEASE_TESTING} );

use Proc::Launcher;

use File::Temp qw(tempdir);
my $tempdir = tempdir('/tmp/proc_launcher_XXXXXX', CLEANUP => 1);

my $start_method = sub { my $pid;
                         # get the child's pid, not the current pid!!!
                         eval '$pid = $$';
                         system( 'touch', "$tempdir/started.$pid" );
                         sleep 3;
                     };

my $launcher = Proc::Launcher->new( start_method => $start_method,
                                    daemon_name  => 'test',
                                    pid_dir      => $tempdir,
                                    debug        => 1,
                                );


ok( ! $launcher->is_running(),
    "Checking that test process is not already running"
);

my @pids;

for my $test ( 1 .. 5 ) {

    if ( my $pid = fork() ) {
        push @pids, $pid;
        next;
    }

    if ( $launcher->start() ) {
        exit;
    }

    exit 1;
}

sleep 5;

my $ok_exit_statuses;

for my $pid ( @pids ) {
    print "WAITING ON PID: $pid\n";
    waitpid( $pid, 0 );

    unless ( $? ) {
        $ok_exit_statuses++;
    }
}

is( $ok_exit_statuses,
    1,
    "Checking that only one launcher exited successfully"
);

# waiting for launched daemons to die
sleep 4;

my $files_created = 0;

my $dir_h;
opendir( $dir_h, $tempdir ) or die "Can't opendir $tempdir: $!";
while ( defined( my $entry = readdir( $dir_h ) ) ) {
    next unless $entry;

    if ( $entry =~ m|started| ) {
        print "FOUND: $entry\n";
        $files_created++
    };
}
closedir( $dir_h );

is( $files_created,
    1,
    "Checking that only one child process ran to create a tempfile"
);

# shut down the daemon if we left it running
$launcher->force_stop();

done_testing();
