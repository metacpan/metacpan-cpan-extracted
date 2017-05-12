use strict;
use Test::More 0.98;

use t::Util;
use Queue::Gearman::Socket;
use Queue::Gearman::Message qw/:headers :msgtypes/;

plan skip_all => 'cannot find gearmand.' unless has_gearmand();

my $gearmand = setup_gearmand();
my $server   = sprintf 'localhost:%d', $gearmand->port;

my $socket = Queue::Gearman::Socket->new(
    server             => $server,
    timeout            => 1,
    inactivity_timeout => 1,
);

subtest 'with args' => sub {
    my @args = map { int rand 65535 } 1..3;
    my $res  = $socket->send(HEADER_REQ_ECHO_REQ, @args) && $socket->recv();
    is_deeply $res, +{
        context => 'RES',
        msgtype => MSGTYPE_RES_ECHO_RES,
        bytes   => $res->{bytes},
        args    => \@args,
    }, 'match echo' or diag explain $res;
};

subtest 'without args' => sub {
    my $res  = $socket->send(HEADER_REQ_ECHO_REQ) && $socket->recv();
    is_deeply $res, +{
        context => 'RES',
        msgtype => MSGTYPE_RES_ECHO_RES,
        bytes   => 0,
        args    => [],
    }, 'match echo' or diag explain $res;
};

done_testing;
