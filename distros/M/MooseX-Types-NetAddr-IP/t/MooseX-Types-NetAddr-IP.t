
use strict;
use warnings;

use Test::More tests => 22;
use Test::Exception;
use Moose::Util::TypeConstraints;

use_ok 'MooseX::Types::NetAddr::IP';

isa_ok find_type_constraint('NetAddr::IP') 
    => 'Moose::Meta::TypeConstraint';

{
    package NetAddrIPTest;
    use Moose;
    use MooseX::Types::NetAddr::IP qw( NetAddrIP );
    has 'address' => ( is => 'ro', isa => NetAddrIP, coerce => 1 );
}{
    my $ip = NetAddrIPTest->new({address => '127.0.0.1/32'})->address;
    isa_ok $ip, "NetAddr::IP", "coerced from string";

    $ip = NetAddrIPTest->new({address => ['10.0.0.255', '255.0.0.0']})->address;
    isa_ok $ip, "NetAddr::IP", "coerced from string";

    dies_ok { 
        NetAddrIPTest->new({address => '343.0.0.1/320'}) 
    } "invalid IP address";
}

{
    package NetAddrIPv4Test;
    use Moose;
    use MooseX::Types::NetAddr::IP qw( NetAddrIPv4 );

    has 'address' => ( 
        is      => 'ro', 
        isa     => NetAddrIPv4, 
        coerce  => 1, 
        handles => [qw/ network broadcast /],
    );
}{
    my $ip = NetAddrIPv4Test->new({address => '127.0.0.1/24'})->address;
    isa_ok $ip, "NetAddr::IP", "coerced from string";
    is $ip->network->addr, '127.0.0.0';
    is $ip->network, '127.0.0.0/24';
    is $ip->broadcast->addr, '127.0.0.255';
    is $ip->broadcast, '127.0.0.255/24';

    $ip = NetAddrIPv4Test->new({address => ['10.0.0.255', '255.0.0.0']})->address;
    isa_ok $ip, "NetAddr::IP", "coerced from string";

    foreach my $invalidIPv4Addr (qw(
        1080:0:0:0:8:800:200C:417A 
        43.0.0.1/320
        10.0.0.256
    )) {
        throws_ok { 
            NetAddrIPv4Test->new({address => $invalidIPv4Addr}); 
        } qr/'$invalidIPv4Addr' is not an IPv4 address/, "invalid IPv4 address";
    }
}

{
    package NetAddrIPv6Test;
    use Moose;
    use MooseX::Types::NetAddr::IP qw( NetAddrIPv6 );
    has 'address' => ( is => 'ro', isa => NetAddrIPv6, coerce => 1 );
}{
    foreach my $ipv6Addr (qw/ 
        ::
        ::1
        0:0:0:0:0:0:0:0
        1080:0:0:0:8:800:200C:417A 
        1080::8:800:200C:417A 
        ::FFFF:192.168.1.1 /) {
        my $ip = NetAddrIPv6Test->new({address => $ipv6Addr})->address;
        isa_ok $ip, "NetAddr::IP", "coerced from string";
    }

    my $ip = NetAddrIPv6Test->new({
                 address => [
                     '1080:0:0:0:8:800:200C:417A', 
                     'FFFF:FFFF:FFFF:FFFF:0000:0000:0000:0000'
                 ],
             })->address;
    isa_ok $ip, "NetAddr::IP", "coerced from string";

    throws_ok { 
        NetAddrIPv6Test->new({address => '192.168.1.1'}) } 
            qr/'192.168.1.1' is not an IPv6 address/,
                'invalid IP address';
}

