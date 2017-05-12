use strict;
use warnings;
use Test::More;
use Test::Requires qw/File::Which Test::TCP/;
use Proc::Guard;
use IO::Socket::INET;

my $ktserver_bin = File::Which::which('ktserver');
plan skip_all => "This test requires ktserver binary" unless $ktserver_bin;

my $port = Test::TCP::empty_port();
my $pid;
{
    my $proc = proc_guard(
        $ktserver_bin,
        '-log'  => File::Spec->devnull,
        '-port' => $port
    );
    $pid = $proc->pid;
    ok $proc->pid, 'ktserver: ' . $proc->pid;
    Test::TCP::wait_port($port);

    my $sock = IO::Socket::INET->new(
                PeerAddr => '127.0.0.1',
                PeerPort => $port,
                Proto => 'tcp',
    ) or die $!;
    print $sock "GET / HTTP/1.0\015\012\015\012";
    my $version = <$sock>;
    like $version, qr{^HTTP/1.1 404 Not Found};
    note $version;
}
is scalar(kill($pid)), 0, 'already killed';

done_testing;
