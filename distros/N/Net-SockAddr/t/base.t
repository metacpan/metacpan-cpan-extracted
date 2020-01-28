use 5.012;
use warnings;
use lib 't/lib';
use MyTest;
use Socket qw/inet_pton sockaddr_in sockaddr_in6 AF_INET AF_INET6 AF_UNIX/;

catch_run('base');

subtest "create from sockaddr" => sub {
    subtest "unspec" => sub {
        my $sa = Net::SockAddr->new(undef);
        is $sa, undef;
    };
    subtest "inet4" => sub {
        my $ip = "192.168.1.1";
        my $addr = inet_pton(AF_INET, $ip);
        my $_sa = sockaddr_in(1234, $addr);
        my $sa = Net::SockAddr->new($_sa);
        isa_ok $sa, "Net::SockAddr::Inet4";
        ok $sa->is_inet4, "is_inet4";
        is $sa->family, AF_INET, "family";
        is $sa->port, 1234, "port";
        is $sa->ip, $ip, "ip";
        is $sa->addr, $addr, "addr";
        is $sa->get, $_sa, "sockaddr";
    };
    subtest "inet6" => sub {
        my $ip = "fe80::71a3:2b00:ddd3:753f";
        my $addr = inet_pton(AF_INET6, $ip);
        my $_sa = sockaddr_in6(123, $addr, 456, 789);
        my $sa = Net::SockAddr->new($_sa);
        isa_ok $sa, "Net::SockAddr::Inet6";
        ok $sa->is_inet6, "is_inet6";
        is $sa->family, AF_INET6, "family";
        is $sa->port, 123, "port";
        is $sa->ip, $ip, "ip";
        is $sa->get, $_sa, "sockaddr";
        is $sa->scope_id, 456, "scope id";
        is $sa->flowinfo, 789, "flow info";
    };
    subtest "unix" => sub {
        plan skip_all => 'AF_UNIX not supported on Windows' if $^O eq 'MSWin32';
        my $path = "/epta/huyli";
        my $_sa = Net::SockAddr::Unix->new($path)->get;
        my $sa = Net::SockAddr->new($_sa);
        isa_ok $sa, "Net::SockAddr::Unix";
        ok $sa->is_unix, "is_unix";
        is $sa->family, AF_UNIX, "family";
        is $sa->path, $path, "path";
        is $sa->get, $_sa, "sockaddr";
    };
};

subtest "create from self" => sub {
    my $src = Net::SockAddr::Inet4->new("1.2.3.4", 80);
    my $sa = Net::SockAddr->new($src);
    ok $sa->is_inet4;
    is $sa->ip, "1.2.3.4";
    is $sa->port, 80;
    ok $sa == $src;
};

subtest 'equality' => sub {
    ok(Net::SockAddr::Inet4->new("1.2.3.4", 80) == Net::SockAddr::Inet4->new("1.2.3.4", 80));
    ok(Net::SockAddr::Inet4->new("1.2.3.4", 80) != Net::SockAddr::Inet4->new("1.2.3.4", 81));
    ok(Net::SockAddr::Inet4->new("1.2.3.4", 80) != Net::SockAddr::Inet4->new("1.2.3.5", 80));
    ok(Net::SockAddr::Inet4->new("1.2.3.4", 80) != Net::SockAddr::Inet6->new("::1", 80));
    ok(Net::SockAddr::Inet6->new("::1", 80) == Net::SockAddr::Inet6->new("::1", 80));
};

done_testing();