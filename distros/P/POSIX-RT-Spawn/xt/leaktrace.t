use strict;
use warnings;
use Test::More;

use POSIX::RT::Spawn;

BEGIN {
    eval "use Test::LeakTrace; 1" or do {
        plan skip_all => 'Test::LeakTrace is not installed.';
    };
}

no_leaks_ok {
    my @cmd = qw(echo hello world);
    my $pid = spawn(@cmd);
    waitpid $pid, 0;
};

done_testing;
