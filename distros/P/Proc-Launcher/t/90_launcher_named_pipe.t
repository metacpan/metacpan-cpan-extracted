#!/perl
use strict;

use Proc::Launcher;

use IO::File;
use Test::More tests => 6;

use File::Temp qw(tempdir);
my $tempdir = tempdir('/tmp/proc_launcher_XXXXXX', CLEANUP => 1);

my $launcher = Proc::Launcher->new( start_method => sub { $| = 1; print "FOO\n"; print <STDIN>; print "BAR\n" },
                                    daemon_name  => 'test-exec',
                                    pid_dir      => $tempdir,
                                    pipe         => 1,
                                    debug        => 1,
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

my $random_number = rand( 1000000 );
ok( $random_number,
    "Checking that we generated a random number"
);

# give the child process a second to fire up and open the named pipe
sleep 2;

# write random number to file
$launcher->write_pipe( $random_number );

# wait a bit to make sure the child reads and writes to it's log
sleep 2;

# search for the random number in the file
my $found;
my @log_contents;
{
    my $path = $launcher->log_file;

    open(my $read, "<", $path)
        or die "Couldn't open $path for reading: $!\n";

  LINE:
    while ( my $line = <$read> ) {
        if ( $line =~ m|^$random_number| ) {
            $found++;
            last LINE;
        }

        push @log_contents, $line;
    }

    close $read or die "Error closing file: $!\n";
}

ok( $found,
    "Checking that random number was found in log file"
) or diag ( "Did not find random number $random_number in log file: ", @log_contents );

ok( ! $launcher->is_running(),
    "Checking that process exec'd process was shut down"
);

# force it to shut down just in case we left it running
$launcher->force_stop(),


