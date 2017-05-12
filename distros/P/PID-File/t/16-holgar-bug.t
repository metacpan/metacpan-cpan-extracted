use strict;
use warnings;

use Test::More;
use Test::Exception;

use PID::File;

my $pid_file;

sub make_pid_file {

    lives_ok { $pid_file = PID::File->new } "instantiated ok";
    lives_ok { $pid_file->file('pidfile') } "set pidfile name ok";

    lives_ok { $pid_file->create } "created ok";
    lives_ok { $pid_file->guard } "set guard ok";
}

make_pid_file();

done_testing();
