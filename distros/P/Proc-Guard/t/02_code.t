use strict;
use warnings;
use Test::More;
use Test::Requires qw/File::Which Test::TCP Test::SharedFork/;
use Proc::Guard;
use IO::Socket::INET;

my $port = Test::TCP::empty_port();
my $pid;
{
    my $proc = proc_guard(sub {
        my $sock = IO::Socket::INET->new(
            LocalHost => '127.0.0.1',
            LocalPort => $port,
            Proto     => 'tcp',
            ReuseAddr => 1,
            Listen    => 10,
        ) or die $!;
        while (my $csock = $sock->accept) {
            my $msg = <$csock>;
            defined($msg) or next;
            is $msg, "ping\r\n";
            print {$csock} "pong\r\n";
            close $csock;
        }
    });
    $pid = $proc->pid;
    ok $proc->pid, 'memcached: ' . $proc->pid;
    Test::TCP::wait_port($port);

    my $sock = IO::Socket::INET->new(
                PeerAddr => '127.0.0.1',
                PeerPort => $port,
                Proto => 'tcp',
    ) or die $!;
    print $sock "ping\r\n";
    my $res = <$sock>;
    is $res, "pong\r\n";
}
is scalar(kill($pid)), 0, 'already killed';

done_testing;
