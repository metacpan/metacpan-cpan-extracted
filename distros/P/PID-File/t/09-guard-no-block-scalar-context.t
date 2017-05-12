use strict;
use warnings;

use Test::More;
use Test::Exception;

use PID::File;

my $pid_file = PID::File->new;

ok( $pid_file->create, "created pid file ok");

my $guard = $pid_file->guard;

ok( -e $pid_file->file, "pid file ('" . $pid_file->file . "') does exist");

done_testing();
