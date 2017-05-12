use strict;
use Test::More 0.98;
use Test::SharedFork;

use t::Util;
use Queue::Gearman::Socket;
use Scalar::Util qw/refaddr/;

plan skip_all => 'cannot find gearmand.' unless has_gearmand();

my $gearmand = setup_gearmand();
my $server   = sprintf 'localhost:%d', $gearmand->port;

my $socket = Queue::Gearman::Socket->new(
    server             => $server,
    timeout            => 1,
    inactivity_timeout => 1,
);
my $before = refaddr $socket->sock;

my $pid = fork;
if ($pid == 0) {
    # child
    my $after = refaddr $socket->sock;
    isnt $after, $before, 'expect reconnecting on child process';
    exit 0;
}
else {
    # parent
    my $after = refaddr $socket->sock;
    is $after, $before, 'expect non-reconnecting on owner process';
    wait;
}

done_testing;
