#!/perl
use strict;

use Proc::Launcher::Manager;

use File::Temp qw/ :POSIX /;
use Test::More tests => 8;
use File::Temp qw(tempdir);

my $tempdir = tempdir('/tmp/proc_launcher_XXXXXX', CLEANUP => 1);

my $manager = Proc::Launcher::Manager->new( app_name  => 'testapp',
                                            pid_dir   => $tempdir,
                                        );

ok( $manager->register( daemon_name => 'test1', start_method => sub { sleep 600 } ),
    "registering test daemon"
);

my $output = "";

ok( $manager->tail( sub { $output .= join @_ }, 1 ),
    "calling tail() method"
);

is( $output,
    "",
    "No output produced by simply registering a daemon"
);

ok( $manager->start(),
    "Calling start on daemon test1"
);

sleep 2;

ok( $manager->stop(),
    "Calling stop on daemon test1"
);

sleep 1;

ok( $manager->tail( sub { $output = join "\n", $output, @_ }, 1 ),
    "calling tail() method"
);

like( $output,
      qr/Starting process/,
      "Checking that output contains 'Starting process'"
  ) or diag( "Output did not contain 'Starting process': $output" );

like( $output,
      qr/test1/,
      "Checking that our daemon is named in the output"
  ) or diag( "Output did not contain 'Starting process': $output" );

