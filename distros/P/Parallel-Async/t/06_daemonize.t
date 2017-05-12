use strict;
use warnings;

use Test::More;
use IO::Pipe;

use Parallel::Async;

my $pipe = IO::Pipe->new;
note "parent: $$";
my $pid = async {
    note "child: $$";
    return async {
        $pipe->writer();
        note "daemon: $$";
        print $pipe $$;
        sleep 1;
    }->daemonize;
}->recv;

$pipe->reader();
my $res = <$pipe>;
   $res = <$pipe> until $res;
is $res, $pid, 'daemon pid';
kill 0, $pid;

done_testing;

