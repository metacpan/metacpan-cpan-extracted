use strict;
use Sys::Syscall ':epoll';
use Test::More;
use POSIX;
use IO::Socket::INET;
use Socket qw(PF_INET IPPROTO_TCP SOCK_STREAM);

my ($sysname, $nodename, $release, $version, $machine) = POSIX::uname();

if ($^O ne 'linux' || $release =~ /^2\.[01234]\b/) {
    non_linux_26();
}

plan tests => 20;
ok(Sys::Syscall::epoll_defined(), "have epoll");

my $epfd = epoll_create();
ok($epfd >= 0, "did epoll_create");

ok(EPOLLHUP && EPOLLIN && EPOLLOUT && EPOLLERR,     "epoll masks");
ok(EPOLL_CTL_ADD && EPOLL_CTL_DEL && EPOLL_CTL_MOD, "epoll_ctl constants");

my $udp_sock = IO::Socket::INET->new(PeerPort  => 9999,
				     PeerAddr  => inet_ntoa(INADDR_BROADCAST),
				     Proto     => 'udp',
				     LocalAddr => '127.0.0.1',
				     Broadcast => 1 )
    or die "Can't bind : $@\n";

my $tempfd = fileno($udp_sock);

is(epoll_ctl($epfd, EPOLL_CTL_ADD, $tempfd, EPOLLOUT), 0, "epoll_ctl udp socket EPOLLOUT");

my $events = [];
is(epoll_wait($epfd, 1, 500, $events), 1, "epoll_wait");
my $ev = $events->[0];
ok(ref $ev eq "ARRAY", "got an array in our event");
$ev ||= [];
is($ev->[0], $tempfd, "event is stdout");
is($ev->[1], EPOLLOUT, "udp socket is writable");

is(epoll_ctl($epfd, EPOLL_CTL_MOD, $tempfd, EPOLLIN), 0, "watch reads on udp socket");
my ($t1, $t2);
$t1 = time();
is(epoll_wait($epfd, 1, 1000, $events), 0, "get no events");
$t2 = time();
ok($t2 > $t1 && $t2 < ($t1 + 3), "took a second");

my $ip   = '127.0.0.1';
my $listen = IO::Socket::INET->new(Listen    => 5,
                                   LocalAddr => $ip,
                                   ReuseAddr => 1,
                                   Proto     => 'tcp');
my $listen_port = $listen->sockport;
my $listen2 = IO::Socket::INET->new(Listen    => 5,
                                    LocalAddr => $ip,
                                    ReuseAddr => 1,
                                    Proto     => 'tcp');
my $listen2_port = $listen2->sockport;
diag "listening on $listen_port and $listen2_port";
ok($listen, "made temp listening socket");
ok(fileno($listen), "has fileno");

my ($sock, $sock2);
socket $sock, PF_INET, SOCK_STREAM, IPPROTO_TCP;
socket $sock2, PF_INET, SOCK_STREAM, IPPROTO_TCP;
IO::Handle::blocking($sock, 0);
IO::Handle::blocking($sock2, 0);
connect $sock, Socket::sockaddr_in($listen_port, Socket::inet_aton($ip));
connect $sock2, Socket::sockaddr_in($listen2_port, Socket::inet_aton($ip));
select undef, undef, undef, 0.25;

my $lifd1 = fileno($listen);
my $lifd2 = fileno($listen2);

$epfd = epoll_create();
is(epoll_ctl($epfd, EPOLL_CTL_ADD, fileno($listen), EPOLLIN), 0, "epoll_ctl listen socket writable") or diag "reason: $!";
is(epoll_ctl($epfd, EPOLL_CTL_ADD, fileno($listen2), EPOLLIN), 0, "epoll_ctl listen2 socket writable") or diag "reason: $!";
is(epoll_wait($epfd, 2, 500, $events), 2, "epoll_wait") or diag("Got $events->[0][0] (listen=$lifd1, listen2=$lifd2)");
ok(($events->[0][0] == fileno($listen) && $events->[1][0] == fileno($listen2)) ||
   ($events->[1][0] == fileno($listen) && $events->[0][0] == fileno($listen2)), "got both");

is(epoll_ctl($epfd, EPOLL_CTL_DEL, fileno($listen), 0), 0, "epoll_ctl del stdout");
ok(epoll_ctl($epfd, EPOLL_CTL_MOD, 9999, 0), "epoll_ctl on bad fd");

sub non_linux_26 {
    plan skip_all => "test good only for Linux 2.6+";
    exit 0;
}

