#!/usr/bin/perl -T

use Test::More tests => 34;
use Paranoid;
use Paranoid::Network;
use Paranoid::Module;
use Paranoid::Debug;
use Socket;

#PDEBUG = 20;

use strict;
use warnings;

psecureEnv();

my $sendmail =
    '... [IPv6:1111:2222:3333:4444:5555:6666:7777:8888] did not issue MAIL/EXPN/VRFY/ETRN during connection ...';
my $ifconfig = << '__EOF__';
lo        Link encap:Local Loopback  
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:16436  Metric:1
          RX packets:199412 errors:0 dropped:0 overruns:0 frame:0
          TX packets:199412 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0 
          RX bytes:90311250 (86.1 MiB)  TX bytes:90311250 (86.1 MiB)

__EOF__

my $iproute = << '__EOF__';
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 16436 qdisc noqueue state UNKNOWN 
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 brd 127.255.255.255 scope host lo
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST> mtu 1500 qdisc pfifo_fast state DOWN qlen 1000
    link/ether 00:d0:f9:6a:cd:d0 brd ff:ff:ff:ff:ff:ff
3: wlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 00:12:a8:ff:0e:a1 brd ff:ff:ff:ff:ff:ff
    inet 192.168.2.156/24 brd 192.168.2.255 scope global wlan0
    inet6 fe80::212:a8ff:feff:0ea1/64 scope link 
       valid_lft forever preferred_lft forever
__EOF__

ok( ipInNetworks( '127.0.0.1', '127.0.0.0/8' ),         'ipInNetworks 1' );
ok( ipInNetworks( '127.0.0.1', '127.0.0.0/255.0.0.0' ), 'ipInNetworks 2' );
ok( ipInNetworks( '127.0.0.1', '127.0.0.1' ),           'ipInNetworks 3' );
ok( !eval "ipInNetworks('127.0.s.1', '127.0.0.1')", 'ipInNetworks 4' );
ok( ipInNetworks( '127.0.0.1', '192.168.0.0/24', '127.0.0.0/8' ),
    'ipInNetworks 5' );
ok( !ipInNetworks( '127.0.0.1', qw(foo bar roo) ), 'ipInNetworks 6' );

ok( hostInDomains( 'foo.bar.com', 'bar.com' ),   'hostInDomains 1' );
ok( hostInDomains( 'localhost',   'localhost' ), 'hostInDomains 2' );
ok( !eval "hostInDomains('localh!?`ls`ost', 'localhost')",
    'hostInDomains 3' );
ok( !hostInDomains( 'localhost', 'local?#$host' ), 'hostInDomains 4' );
ok( hostInDomains(
        'foo-77.bar99.net', 'dist-22.mgmt.bar-bar.com', 'bar99.net'
        ),
    'hostInDomains 5'
    );
is( scalar( grep !/:/, extractIPs($ifconfig) ), 2, 'extractIPs 1' );
is( scalar( grep !/:/, extractIPs($iproute) ),  4, 'extractIPs 2' );
is( scalar( grep !/:/, extractIPs( $ifconfig, $iproute ) ),
    6, 'extractIPs 3' );
is( scalar( grep { $_ eq "192.168.2.255" } extractIPs($iproute) ),
    1, 'extractIPs 4' );

is( netIntersect(qw(192.168.0.0/24 192.168.0.128/25)), 1, 'netIntersect 1' );
is( netIntersect(qw(192.168.0.128/25 192.168.0.128/24)),
    -1, 'netIntersect 2' );
is( netIntersect(qw(192.168.0.0/24 foo)), 0, 'netIntersect 3' );

SKIP: {
    skip( 'Missing IPv6 support -- skipping IPv6 tests', 16 )
        unless $] >= 5.012
            or loadModule('Socket6');

    ok( ipInNetworks( '::1', '::1' ), 'ipInNetworks 7' );
    ok( !ipInNetworks( '::1', '127.0.0.1/8' ), 'ipInNetworks 8' );
    ok( ipInNetworks( '::ffff:192.168.0.5', '192.168.0.0/24' ),
        'ipInNetworks 9' );
    ok( !ipInNetworks( '::ffff:192.168.0.5', '::ffff:192.168.0.0/104' ),
        'ipInNetworks 9' );
    ok( ipInNetworks( 'fe80::212:e9dd:fed9:a1f9', 'fe80::/64' ),
        'ipInNetworks 10' );
    ok( !ipInNetworks( 'fe80::212:e9dd:fed9:a1f9', 'fe81::/64' ),
        'ipInNetworks 11' );
    ok( ipInNetworks( 'fe80::212:e9dd:fed9:a1f9', 'fe80::/60' ),
        'ipInNetworks 12' );
    ok( ipInNetworks( 'fe80::ffff:212:e9dd:fed9:a1f9', 'fe80:0:0:ffff::/60' ),
        'ipInNetworks 13'
        );
    ok( ipInNetworks(
            '::1',                    'fe80:0:0:ffff::/60',
            '::ffff:192.168.0.0/104', '192.168.0.0/24',
            '::1'
            ),
        'ipInNetworks ipv6 1'
        );

    is( scalar( grep /^1111:/, extractIPs($sendmail) ), 1, 'extractIPs 5' );
    ok( scalar extractIPs($ifconfig) == 3, 'extractIPs 6' );
    ok( scalar extractIPs($iproute) == 6,  'extractIPs 7' );
    ok( scalar extractIPs( $ifconfig, $iproute ) == 9, 'extractIPs 8' );

    is( netIntersect(qw(fe80::212:e9dd:fed9:a1f9 fe80::/64)),
        -1, 'netIntersect ipv6 1' );
    is( netIntersect(
            qw(fe80::/64
                fe80::212:e9dd:fed9:a1f9)
            ),
        1,
        'netIntersect ipv6 2'
        );
    is( netIntersect(qw(bar foo)), 0, 'netIntersect ipv6 3' );
}

