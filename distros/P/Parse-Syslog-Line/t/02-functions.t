#!perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok( 'Parse::Syslog::Line' );
}

# Test Non default behaviour
$Parse::Syslog::Line::DateTimeCreate = 0;
$Parse::Syslog::Line::EpochCreate    = 1;
$Parse::Syslog::Line::PruneRaw       = 1;
$Parse::Syslog::Line::PruneEmpty     = 1;
$Parse::Syslog::Line::PruneFields    = qw(program);

my %msgs = (
    'Snort Message Parse' => q|<11>Jan  1 00:00:00 mainfw snort[32640]: [1:1893:4] SNMP missing community string attempt [Classification: Misc Attack] [Priority: 2]: {UDP} 1.2.3.4:23210 -> 5.6.7.8:161|,
    'IP as Hostname'      => q|<11>Jan  1 00:00:00 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|,
    'Without Preamble'    => q|Jan  1 00:00:00 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|,
    'Dotted Hostname'     => q|<11>Jan  1 00:00:00 dev.example.com dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|,
    'Syslog reset'        => q|Jan  1 00:00:00 example syslogd 1.2.3: restart (remote reception).|,
    'Cisco ASA'           => q|<163>Jun 7 18:39:00 hostname.domain.tld %ASA-3-313001: Denied ICMP type=5, code=1 from 1.2.3.4 on interface inside|,
    'Cisco ASA Alt'       => q|<161>Jun 7 18:39:00 hostname : %ASA-3-313001: Denied ICMP type=5, code=1 from 1.2.3.4 on interface inside|,
    'Cisco NX-OS'         => q|2013-08-09T11:09:36+02:00 hostname.company.tld : 2013 Aug  9 11:09:36.290 CET: %ETHPORT-5-IF_DOWN_CFG_CHANGE: Interface Ethernet121/1/1 is down(Config change)|,
    'Cisco Catalyst'      => q|<188>Aug 13 00:10:02 10.43.0.10 1813056: Aug 13 00:15:02: %C4K_EBM-4-HOSTFLAPPING: Host 00:1B:21:4B:7B:5D in vlan 1 is flapping between port Gi6/37 and port Gi6/38|,
);


foreach my $name (sort keys %msgs) {
    my $msg = parse_syslog_line($msgs{$name});

    # Verify PruneRaw works
    my @raw_keys = grep { $_ =~ /_raw$/ } keys %{ $msg };
    ok( @raw_keys == 0, "KeepRaw disabled for $name") || diag( Dumper $msg );

    # Verify PruneEmpty works
    my @undef_keys = grep { !defined $msg->{$_} } keys %{ $msg };
    ok( @undef_keys == 0, "DropUndefKeys enabled for $name") || diag( Dumper $msg );

    # Verify EpochCreate works
    ok( exists $msg->{epoch} && $msg->{epoch} > 0, "EpochCreate for $name") || diag( Dumper $msg );

    # Verify PruneFields works
    ok( !exists $msg->{program}, "PruneFields for $name" ) || diag( Dumper $msg );
}

done_testing();
