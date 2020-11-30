use 5.012;
use warnings;
use lib 't/lib';
use MyTest;
use Net::SockAddr;
use Socket();

sub is_bin {
    my ($got, $expected, $name) = @_;
    return if our $leak_test;
    state $has_binary = eval { require Test::BinaryData; Test::BinaryData->import(); 1 };
    $has_binary ? is_binary($got, $expected, $name) : is($got, $expected, $name);
}

is AF_UNSPEC, Socket::AF_UNSPEC, "AF_UNSPEC";
is AF_INET,   Socket::AF_INET,   "AF_INET";
is AF_INET6,  Socket::AF_INET6,  "AF_INET6";
is AF_UNIX(), Socket::AF_UNIX,   "AF_UNIX" if $^O ne 'MSWin32';

is_bin INADDR_ANY,       Socket::INADDR_ANY,       "INADDR_ANY";
is_bin INADDR_LOOPBACK,  Socket::INADDR_LOOPBACK,  "INADDR_LOOPBACK";
is_bin INADDR_BROADCAST, Socket::INADDR_BROADCAST, "INADDR_BROADCAST";
is_bin INADDR_NONE,      Socket::INADDR_NONE,      "INADDR_NONE";
is_bin IN6ADDR_ANY,      Socket::IN6ADDR_ANY,      "IN6ADDR_ANY";
is_bin IN6ADDR_LOOPBACK, Socket::IN6ADDR_LOOPBACK, "IN6ADDR_LOOPBACK";

ok SOCKADDR_ANY       == Net::SockAddr::Inet4::from_addr(INADDR_ANY,       0), "SOCKADDR_ANY";
ok SOCKADDR_LOOPBACK  == Net::SockAddr::Inet4::from_addr(INADDR_LOOPBACK,  0), "SOCKADDR_LOOPBACK";
ok SOCKADDR6_ANY      == Net::SockAddr::Inet6::from_addr(IN6ADDR_ANY,      0), "SOCKADDR6_ANY";
ok SOCKADDR6_LOOPBACK == Net::SockAddr::Inet6::from_addr(IN6ADDR_LOOPBACK, 0), "SOCKADDR6_LOOPBACK";

done_testing();