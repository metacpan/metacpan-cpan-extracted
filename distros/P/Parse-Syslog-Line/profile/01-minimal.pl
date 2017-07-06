#!perl

use strict;
use warnings;
use Parse::Syslog::Line;
use Time::HiRes qw(gettimeofday tv_interval);

my @msgs = (
    q|<11>Jan  1 00:00:00 mainfw snort[32640]: [1:1893:4] SNMP missing community string attempt [Classification: Misc Attack] [Priority: 2]: {UDP} 1.2.3.4:23210 -> 5.6.7.8:161|,
    q|<11>Jan  1 00:00:00 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|,
    q|Jan  1 00:00:00 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|,
    q|<11>Jan  1 00:00:00 dev.example.com dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|,
    q|Jan  1 00:00:00 example syslogd 1.2.3: restart (remote reception).|,
    q|<163>Jun 7 18:39:00 hostname.domain.tld %ASA-3-313001: Denied ICMP type=5, code=1 from 1.2.3.4 on interface inside|,
    q|<161>Jun 7 18:39:00 hostname : %ASA-3-313001: Denied ICMP type=5, code=1 from 1.2.3.4 on interface inside|,
    q|2013-08-09T11:09:36+02:00 hostname.company.tld : 2013 Aug  9 11:09:36.290 CET: %ETHPORT-5-IF_DOWN_CFG_CHANGE: Interface Ethernet121/1/1 is down(Config change)|,
);

my $count = 20_000;
my $start = [gettimeofday];
my $total = $count * @msgs;
for( 1..$count ) {
    parse_syslog_line($_) for @msgs
}
my $elapsed = tv_interval( $start, [gettimeofday] );

printf "Took $elapsed seconds to parse $total messages. (%0.2f mps)\n", $total / $elapsed;
