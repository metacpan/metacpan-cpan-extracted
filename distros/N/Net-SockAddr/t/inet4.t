use 5.012;
use warnings;
use lib 't/lib';
use MyTest;
use Socket 'inet_aton';

catch_run('inet4');

my $ip = "192.168.1.1";
my $addr = inet_aton($ip);

subtest 'from ip' => sub {
    my $sa = Net::SockAddr::Inet4->new($ip, 80);
    is $sa->port, 80, "port";
    is $sa->ip, $ip, "ip";
    is $sa, "$ip:80", "stringify";
    is $sa->addr, $addr, "addr";
};

subtest 'from addr' => sub {
    my $sa = Net::SockAddr::Inet4::from_addr($addr, 90);
    is $sa->port, 90, "port";
    is $sa->ip, $ip, "ip";
    is $sa->addr, $addr, "addr";
};

dies_ok { Net::SockAddr::Inet4->new("192.168.1", 80) } "invalid addr";

done_testing();