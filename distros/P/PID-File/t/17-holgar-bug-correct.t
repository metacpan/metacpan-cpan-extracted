use strict;
use warnings;

use Test::More;
use Test::Exception;

use PID::File;

sub make_pid_file {

    my $pid_file;

    lives_ok { $pid_file = PID::File->new } "instantiated ok";
    lives_ok { $pid_file->file('pidfile') } "set pidfile name ok";

    lives_ok { $pid_file->create } "created ok";
    lives_ok { $pid_file->guard } "set guard ok";

    return $pid_file;
}

my $pid_file = make_pid_file();

done_testing();
