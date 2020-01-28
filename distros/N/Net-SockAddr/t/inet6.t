use 5.012;
use warnings;
use lib 't/lib';
use MyTest;
use Socket qw/AF_INET6 inet_pton/;

catch_run('inet6');

my $ip = "12:34:56:78:90:ab:cd:ef";
my $addr = inet_pton(AF_INET6, $ip);

subtest "from ip" => sub {
    my $sa = Net::SockAddr::Inet6->new($ip, 80, 10, 20);
    is $sa->port, 80, "port";
    is $sa->ip, $ip, "ip";
    is $sa, "[$ip%10]:80", "stringify";
    is length($sa->addr), 16, "addr";
    is $sa->scope_id, 10, "scope id";
    is $sa->flowinfo, 20, "flow info";
};

subtest "from addr" => sub {
    my $sa = Net::SockAddr::Inet6::from_addr($addr, 81, 30, 40);
    is $sa->port, 81, "port";
    is $sa->ip, $ip, "ip";
    is $sa->addr, $addr, "addr";
    is $sa->scope_id, 30, "scope id";
    is $sa->flowinfo, 40, "flow info";
};

dies_ok { Net::SockAddr::Inet6->new("adsf:asdf", 80) } "invalid ip";

done_testing();