use strict;
use Test::More;
use Test::TCP;
use Errno;
use POSIX::getpeername;
use Storable;

test_tcp(
    client => sub {
        my ($port, $server_pid) = @_;
        my $sock = IO::Socket::INET->new(
            PeerAddr => "localhost:$port",
            Proto    => 'tcp'
        ) or die $!;
        my $ret = $sock->sysread(my $buf, 4096);
        ok($ret);
        my $args = Storable::thaw($buf);
        is($args->[0],0);
        my ($r_port, $r_addr) = Socket::sockaddr_in($args->[1]);
        is($r_port,$sock->sockport);        
    },
    server => sub {
        my $port = shift;
        my $listen = IO::Socket::INET->new(
            ReuseAddr => 1,
            Listen    => 5,
            LocalHost => 'localhost',
            LocalPort => $port,
            Proto     => 'tcp'
        );
        while ( my $sock = $listen->accept ) {
            my $ret = POSIX::getpeername::_getpeername($sock->fileno, my $addr);
            $sock->syswrite(Storable::nfreeze([$ret,$addr]));
        }
    },
);

done_testing;

