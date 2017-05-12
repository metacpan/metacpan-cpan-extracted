#!perl -T
# $RedRiver: 30-decode-sysname.t,v 1.2 2008/02/18 16:37:35 andrew Exp $

use Test::More tests => 19;
use File::Spec;

BEGIN {
    use_ok( 'Net::Telnet::Trango' );
}

diag("30: Parse login banners");

my @banners = (
    { 
        banner => 'Welcome to Trango Broadband Wireless, TrangoLINK-45 DFS PtP-P5055M 2p0r1D07070201',
        host_type => 'TrangoLINK-45 DFS',
        version   => 'DFS PtP-P5055M 2p0r1D07070201',
    },
    {
        banner => 'Welcome to Trango Broadband Wireless M5830S AP 2p0r7H8002D07010207',
        host_type => 'M5830S AP',
        version   => 'AP 2p0r7H8002D07010207',
    },
    {
        banner => 'Welcome to Trango Broadband Wireless M5800S-FSU 2p0r2H0004D05121201',
        host_type => 'M5800S-FSU',
        version   => 'FSU 2p0r2H0004D05121201',
    },
    {
        banner => 'Welcome to Trango Broadband Wireless M5830S AP 2p0r7H8002D07010207',
        host_type => 'M5830S AP',
        version   => 'AP 2p0r7H8002D07010207',
    },
    {
        banner => 'Welcome to Trango Broadband Wireless M5830S SU 2p0r7H0002D07010207',
        host_type => 'M5830S SU',
        version   => 'SU 2p0r7H0002D07010207',
    },
    {
        banner => 'Welcome to Trango Broadband Wireless M5300S-FSU 2p0r2H0003D05121201',
        host_type => 'M5300S-FSU',
        version   => 'FSU 2p0r2H0003D05121201',
    },
);

foreach my $banner (@banners) {
    my $decoded;
    my $t = Net::Telnet::Trango->new();
    ok($decoded = $t->parse_login_banner($banner->{banner}), 
        "Decoding linktest");

    is($t->host_type(), $banner->{host_type}, "Host Type matches");
    is($t->firmware_version(), $banner->{version}, "Firmware Version matches");
}

