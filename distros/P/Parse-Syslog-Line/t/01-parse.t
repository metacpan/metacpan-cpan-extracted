#!perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;
use Test::MockTime;


# this avoids HTTP::Date weirdnes with dates "in the future"
my $year = "2016";
Test::MockTime::set_fixed_time("2016-12-01T00:00:00Z");

use Parse::Syslog::Line qw/:with_timezones/;

set_syslog_timezone('UTC');

my %msgs = (
    'Snort Message Parse'    => q|<11>Jan  1 00:00:00 mainfw snort[32640]: [1:1893:4] SNMP missing community string attempt [Classification: Misc Attack] [Priority: 2]: {UDP} 1.2.3.4:23210 -> 5.6.7.8:161|,
    'IP as Hostname'         => q|<11>Jan  1 00:00:00 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|,
    'Without Preamble'       => q|Jan  1 00:00:00 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|,
    'Dotted Hostname'        => q|<11>Jan  1 00:00:00 dev.example.com dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|,
    'Syslog reset'           => q|Jan  1 00:00:00 example syslogd 1.2.3: restart (remote reception).|,
    'FreeBSD'                => q|<78>Jan  1 08:15:00 /usr/sbin/cron[73991]: (root) CMD (/usr/libexec/atrun)|,
    'Cisco ASA'              => q|<163>Jan 1 18:39:00 hostname.domain.tld %ASA-3-313001: Denied ICMP type=5, code=1 from 1.2.3.4 on interface inside|,
    'Cisco ASA Alt'          => q|<161>Jan 1 18:39:00 hostname : %ASA-3-313001: Denied ICMP type=5, code=1 from 1.2.3.4 on interface inside|,
    'Cisco NX-OS'            => qq|$year-01-01T11:09:36+02:00 hostname.company.tld : $year Jan  1 11:09:36.290 CET: %ETHPORT-5-IF_DOWN_CFG_CHANGE: Interface Ethernet121/1/1 is down(Config change)|,
    'Cisco Catalyst'         => q|<188>Jan 1 00:10:02 10.43.0.10 1813056: Jan 1 00:15:02: %C4K_EBM-4-HOSTFLAPPING: Host 00:1B:21:4B:7B:5D in vlan 1 is flapping between port Gi6/37 and port Gi6/38|,
    'Cisco NTP No Sync'      => q|<187>Jan 1 14:58:58 fqdn.tld 6951: .Jan 1 14:58:57: %LINK-3-UPDOWN: Interface BRI0:1, changed state to down|,
    'Cisco NTP Unconfigured' => q|<189>Jan 1 12:22:26 1.2.3.4 5971: *Jan 1 02:54:25: %SYS-5-CONFIG_I: Configured from console by vty0 (10.100.0.68)|,
    'Cisco Date Insanity'    => q|<189>Jan 1 19:12:19 router.company.tld 11815005: Jan 1 2014 19:12:18.454 CET: %CRYPTO-5-IPSEC_SETUP_FAILURE: IPSEC SETUP FAILED for local:1.2.3.4 local_id:1.2.3.4 remote:4.5.6.7 remote_id:4.5.6.7 IKE profile:foo fvrf:None fail_reason:IPSec Proposal failure fail_class_cnt:14|,
    'NetApp Filer Logs'      => q|<134>Jan 1 11:28:13 filer-201.example.com [filer-201: scsitarget.ispfct.targetReset:notice]: FCP Target 0c: Target was Reset by the Initiator at Port Id: 0x11000 (WWPN 5001438021e071ec)|,
    'NetApp Filer Alt1'      => q|<134>Jan 1 11:28:13 filer-201.example.com [filer-201 scsitarget.ispfct.targetReset:notice]: FCP Target 0c: Target was Reset by the Initiator at Port Id: 0x11000 (WWPN 5001438021e071ec)|,
    'NetApp Filer Alt2'      => q|<134>Jan 1 11:28:13 filer-201.example.com [filer-201:scsitarget.ispfct.targetReset:notice]: FCP Target 0c: Target was Reset by the Initiator at Port Id: 0x11000 (WWPN 5001438021e071ec)|,
    'F5 includes level'      => q|<182>Jan 1 10:55:37 f5lb-201.example.com info logger: [ssl_acc] 10.0.0.1 - bob [01/Jan/2015:10:55:37 +0000] "/xui/update/configuration/alert/statusmenu/coloradvisory" 200 1702|,
    'ISO8601 with micro'     => q|2015-09-30T06:26:06.779373-05:00 my-host my-script.pl: {"lunchTime":1443612366.442}|,
    'Year with old date'     => q|2015 Nov 13 13:40:01 ether rsyslogd-2177: imuxsock begins to drop messages from pid 17840 due to rate-limiting|,
    'High Precision Dates'   => q|2016-11-19T20:50:01.749659+01:00 janus CROND[14400]: (root) CMD (/usr/lib64/sa/sa1 1 1)|,
);

my @dtfields = qw/time datetime_obj epoch datetime_str/;

my %resps = (
  'Snort Message Parse' => {
          'priority' => 'err',
          'time' => '00:00:00',
          'date' => qq{$year-01-01},
          'content' => '[1:1893:4] SNMP missing community string attempt [Classification: Misc Attack] [Priority: 2]: {UDP} 1.2.3.4:23210 -> 5.6.7.8:161',
          'facility' => 'user',
          'domain' => undef,
          'program_sub' => undef,
          'host_raw' => 'mainfw',
          'program_raw' => 'snort[32640]',
          'datetime_raw' => 'Jan  1 00:00:00',
          'date_raw' => 'Jan  1 00:00:00',
          'message_raw' => '<11>Jan  1 00:00:00 mainfw snort[32640]: [1:1893:4] SNMP missing community string attempt [Classification: Misc Attack] [Priority: 2]: {UDP} 1.2.3.4:23210 -> 5.6.7.8:161',
          'priority_int' => 3,
          'preamble' => '11',
          'datetime_str' => qq{$year-01-01T00:00:00Z},
          'program_pid' => '32640',
          'facility_int' => 8,
          'program_name' => 'snort',
          'message' => 'snort[32640]: [1:1893:4] SNMP missing community string attempt [Classification: Misc Attack] [Priority: 2]: {UDP} 1.2.3.4:23210 -> 5.6.7.8:161',
          'host' => 'mainfw'
        },
 'IP as Hostname' => {
          'priority' => 'err',
          'time' => '00:00:00',
          'date' => qq{$year-01-01},
          'content' => 'DHCPINFORM from 172.16.2.137 via vlan3',
          'facility' => 'user',
          'domain' => undef,
          'program_sub' => undef,
          'host_raw' => '11.22.33.44',
          'program_raw' => 'dhcpd',
          'datetime_raw' => 'Jan  1 00:00:00',
          'date_raw' => 'Jan  1 00:00:00',
          'message_raw' => '<11>Jan  1 00:00:00 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3',
          'priority_int' => 3,
          'preamble' => '11',
          'datetime_str' => qq{$year-01-01T00:00:00Z},
          'program_pid' => undef,
          'facility_int' => 8,
          'program_name' => 'dhcpd',
          'message' => 'dhcpd: DHCPINFORM from 172.16.2.137 via vlan3',
          'host' => '11.22.33.44'
        },
 'Without Preamble' => {
          'priority' => undef,
          'time' => '00:00:00',
          'date' => qq{$year-01-01},
          'content' => 'DHCPINFORM from 172.16.2.137 via vlan3',
          'facility' => undef,
          'domain' => undef,
          'program_sub' => undef,
          'host_raw' => '11.22.33.44',
          'program_raw' => 'dhcpd',
          'datetime_raw' => 'Jan  1 00:00:00',
          'date_raw' => 'Jan  1 00:00:00',
          'message_raw' => 'Jan  1 00:00:00 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3',
          'priority_int' => undef,
          'preamble' => undef,
          'datetime_str' => qq{$year-01-01T00:00:00Z},
          'program_pid' => undef,
          'facility_int' => undef,
          'program_name' => 'dhcpd',
          'message' => 'dhcpd: DHCPINFORM from 172.16.2.137 via vlan3',
          'host' => '11.22.33.44'
        },
 'Dotted Hostname' => {
          'priority' => 'err',
          'time' => '00:00:00',
          'date' => qq{$year-01-01},
          'content' => 'DHCPINFORM from 172.16.2.137 via vlan3',
          'facility' => 'user',
          'domain' => 'example.com',
          'program_sub' => undef,
          'host_raw' => 'dev.example.com',
          'program_raw' => 'dhcpd',
          'datetime_raw' => 'Jan  1 00:00:00',
          'date_raw' => 'Jan  1 00:00:00',
          'message_raw' => '<11>Jan  1 00:00:00 dev.example.com dhcpd: DHCPINFORM from 172.16.2.137 via vlan3',
          'priority_int' => 3,
          'preamble' => '11',
          'datetime_str' => qq{$year-01-01T00:00:00Z},
          'program_pid' => undef,
          'facility_int' => 8,
          'program_name' => 'dhcpd',
          'message' => 'dhcpd: DHCPINFORM from 172.16.2.137 via vlan3',
          'host' => 'dev'
        },
 'Syslog reset' => {
          'priority' => undef,
          'time' => '00:00:00',
          'date' => qq{$year-01-01},
          'content' => 'restart (remote reception).',
          'facility' => undef,
          'domain' => undef,
          'program_sub' => undef,
          'host_raw' => 'example',
          'program_raw' => 'syslogd 1.2.3',
          'datetime_raw' => 'Jan  1 00:00:00',
          'date_raw' => 'Jan  1 00:00:00',
          'message_raw' => 'Jan  1 00:00:00 example syslogd 1.2.3: restart (remote reception).',
          'priority_int' => undef,
          'preamble' => undef,
          'datetime_str' => qq{$year-01-01T00:00:00Z},
          'program_pid' => undef,
          'facility_int' => undef,
          'program_name' => 'syslogd',
          'message' => 'syslogd 1.2.3: restart (remote reception).',
          'host' => 'example'
        },
 'FreeBSD' => {
          'priority' => 'info',
          'time' => '08:15:00',
          'date' => qq{$year-01-01},
          'content' => '(root) CMD (/usr/libexec/atrun)',
          'facility' => 'cron',
          'domain' => undef,
          'program_sub' => undef,
          'host_raw' => undef,
          'program_raw' => '/usr/sbin/cron[73991]',
          'datetime_raw' => 'Jan  1 08:15:00',
          'date_raw' => 'Jan  1 08:15:00',
          'message_raw' => '<78>Jan  1 08:15:00 /usr/sbin/cron[73991]: (root) CMD (/usr/libexec/atrun)',
          'priority_int' => 6,
          'preamble' => 78,
          'datetime_str' => qq{$year-01-01T08:15:00Z},
          'program_pid' => '73991',
          'facility_int' => 72,
          'program_name' => '/usr/sbin/cron',
          'message' => '/usr/sbin/cron[73991]: (root) CMD (/usr/libexec/atrun)',
          'host' => undef,
 },
 'Cisco ASA' => {
           'priority' => 'err',
           'time' => '18:39:00',
           'date' => qq{$year-01-01},
           'content' => 'Denied ICMP type=5, code=1 from 1.2.3.4 on interface inside',
           'facility' => 'local4',
           'domain' => 'domain.tld',
           'program_sub' => undef,
           'host_raw' => 'hostname.domain.tld',
           'program_raw' => '%ASA-3-313001',
           'datetime_raw' => 'Jan 1 18:39:00',
           'message_raw' => '<163>Jan 1 18:39:00 hostname.domain.tld %ASA-3-313001: Denied ICMP type=5, code=1 from 1.2.3.4 on interface inside',
           'priority_int' => 3,
           'preamble' => '163',
           'datetime_str' => qq{$year-01-01T18:39:00Z},
           'program_pid' => undef,
           'program_name' => '%ASA-3-313001',
           'facility_int' => 160,
           'message' => '%ASA-3-313001: Denied ICMP type=5, code=1 from 1.2.3.4 on interface inside',
           'host' => 'hostname',
           'date_raw' => 'Jan 1 18:39:00'
        },
 'Cisco ASA Alt' => {
           'priority' => 'alert',
           'time' => '18:39:00',
           'date' => qq{$year-01-01},
           'content' => 'Denied ICMP type=5, code=1 from 1.2.3.4 on interface inside',
           'facility' => 'local4',
           'domain' => undef,
           'program_sub' => undef,
           'host_raw' => 'hostname',
           'program_raw' => '%ASA-3-313001',
           'datetime_raw' => 'Jan 1 18:39:00',
           'message_raw' => '<161>Jan 1 18:39:00 hostname : %ASA-3-313001: Denied ICMP type=5, code=1 from 1.2.3.4 on interface inside',
           'priority_int' => 1,
           'preamble' => '161',
           'datetime_str' => qq{$year-01-01T18:39:00Z},
           'program_pid' => undef,
           'program_name' => '%ASA-3-313001',
           'facility_int' => 160,
           'message' => '%ASA-3-313001: Denied ICMP type=5, code=1 from 1.2.3.4 on interface inside',
           'host' => 'hostname',
           'date_raw' => 'Jan 1 18:39:00'
        },
  'Cisco NX-OS' => {
           'ntp' => 'ok',
            message_raw => qq|$year-01-01T11:09:36+02:00 hostname.company.tld : $year Jan  1 11:09:36.290 CET: %ETHPORT-5-IF_DOWN_CFG_CHANGE: Interface Ethernet121/1/1 is down(Config change)|,
           'priority' => undef,
           'time' => '09:09:36',
           'date' => qq{$year-01-01},
           'content' => 'Interface Ethernet121/1/1 is down(Config change)',
           'facility' => undef,
           'domain' => 'company.tld',
           'program_sub' => undef,
           'host_raw' => 'hostname.company.tld',
           'program_raw' => '%ETHPORT-5-IF_DOWN_CFG_CHANGE',
           'date_raw' => qq{$year-01-01T11:09:36+02:00},
           'datetime_raw' => qq{$year-01-01T11:09:36+02:00},
           'datetime_str' => qq{$year-01-01T09:09:36Z},
           'priority_int' => undef,
           'preamble' => undef,
           'program_pid' => undef,
           'program_name' => '%ETHPORT-5-IF_DOWN_CFG_CHANGE',
           'facility_int' => undef,
           'message' => '%ETHPORT-5-IF_DOWN_CFG_CHANGE: Interface Ethernet121/1/1 is down(Config change)',
           'host' => 'hostname',
           'ntp' => 'ok',
    },
    'Cisco Catalyst' => {
           'ntp' => 'ok',
            message_raw => q|<188>Jan 1 00:10:02 10.43.0.10 1813056: Jan 1 00:15:02: %C4K_EBM-4-HOSTFLAPPING: Host 00:1B:21:4B:7B:5D in vlan 1 is flapping between port Gi6/37 and port Gi6/38|,
           'priority' => 'warn',
           'priority_int' => 4,
           'time' => '00:10:02',
           'date' => qq{$year-01-01},
           'content' =>'Host 00:1B:21:4B:7B:5D in vlan 1 is flapping between port Gi6/37 and port Gi6/38',
           'facility' => 'local7',
           'facility_int' => 184,
           'domain' => undef,
           'program_sub' => undef,
           'host_raw' => '10.43.0.10',
           'program_raw' => '%C4K_EBM-4-HOSTFLAPPING',
           'date_raw' => 'Jan 1 00:10:02',
           'datetime_raw' => 'Jan 1 00:10:02',
           'datetime_str' => qq{$year-01-01T00:10:02Z},
           'preamble' => 188,
           'program_pid' => undef,
           'program_name' => '%C4K_EBM-4-HOSTFLAPPING',
           'message' => '%C4K_EBM-4-HOSTFLAPPING: Host 00:1B:21:4B:7B:5D in vlan 1 is flapping between port Gi6/37 and port Gi6/38',
           'host' => '10.43.0.10',
           'ntp' => 'ok',
    },
    'Cisco NTP Unconfigured' => {
           'priority' => 'notice',
           'date' => qq{$year-01-01},
           'time' => '12:22:26',
           'content' => 'Configured from console by vty0 (10.100.0.68)',
           'facility' => 'local7',
           'domain' => undef,
           'program_sub' => undef,
           'host_raw' => '1.2.3.4',
           'program_raw' => '%SYS-5-CONFIG_I',
           'datetime_raw' => 'Jan 1 12:22:26',
           'ntp' => 'not configured',
           'message_raw' => '<189>Jan 1 12:22:26 1.2.3.4 5971: *Jan 1 02:54:25: %SYS-5-CONFIG_I: Configured from console by vty0 (10.100.0.68)',
           'priority_int' => 5,
           'preamble' => '189',
           'datetime_str' => qq{$year-01-01T12:22:26Z},
           'program_pid' => undef,
           'facility_int' => 184,
           'program_name' => '%SYS-5-CONFIG_I',
           'message' => '%SYS-5-CONFIG_I: Configured from console by vty0 (10.100.0.68)',
           'host' => '1.2.3.4',
           'date_raw' => 'Jan 1 12:22:26'
    },
    'Cisco NTP No Sync' => {
           'priority' => 'err',
           'date' => qq{$year-01-01},
           'time' => '14:58:58',
           'content' => 'Interface BRI0:1, changed state to down',
           'facility' => 'local7',
           'domain' => 'tld',
           'program_sub' => undef,
           'host_raw' => 'fqdn.tld',
           'program_raw' => '%LINK-3-UPDOWN',
           'datetime_raw' => 'Jan 1 14:58:58',
           'ntp' => 'out of sync',
           'datetime_str' => qq{$year-01-01T14:58:58Z},
           'message_raw' => '<187>Jan 1 14:58:58 fqdn.tld 6951: .Jan 1 14:58:57: %LINK-3-UPDOWN: Interface BRI0:1, changed state to down',
           'priority_int' => 3,
           'preamble' => '187',
           'program_pid' => undef,
           'facility_int' => 184,
           'program_name' => '%LINK-3-UPDOWN',
           'message' => '%LINK-3-UPDOWN: Interface BRI0:1, changed state to down',
           'host' => 'fqdn',
           'date_raw' => 'Jan 1 14:58:58'
    },
    'Cisco Date Insanity' => {
           'priority' => 'notice',
           'date' => qq{$year-01-01},
           'time' => '19:12:19',
           'content' => 'IPSEC SETUP FAILED for local:1.2.3.4 local_id:1.2.3.4 remote:4.5.6.7 remote_id:4.5.6.7 IKE profile:foo fvrf:None fail_reason:IPSec Proposal failure fail_class_cnt:14',
           'facility' => 'local7',
           'domain' => 'company.tld',
           'program_sub' => undef,
           'program_sub' => undef,
           'host_raw' => 'router.company.tld',
           'program_raw' => '%CRYPTO-5-IPSEC_SETUP_FAILURE',
           'datetime_raw' => 'Jan 1 19:12:19',
           'ntp' => 'ok',
           'message_raw' => '<189>Jan 1 19:12:19 router.company.tld 11815005: Jan 1 2014 19:12:18.454 CET: %CRYPTO-5-IPSEC_SETUP_FAILURE: IPSEC SETUP FAILED for local:1.2.3.4 local_id:1.2.3.4 remote:4.5.6.7 remote_id:4.5.6.7 IKE profile:foo fvrf:None fail_reason:IPSec Proposal failure fail_class_cnt:14',
           'priority_int' => 5,
           'preamble' => 189,
           'datetime_str' => qq{$year-01-01T19:12:19Z},
           'program_pid' => undef,
           'program_name' => '%CRYPTO-5-IPSEC_SETUP_FAILURE',
           'facility_int' => 184,
           'message' => '%CRYPTO-5-IPSEC_SETUP_FAILURE: IPSEC SETUP FAILED for local:1.2.3.4 local_id:1.2.3.4 remote:4.5.6.7 remote_id:4.5.6.7 IKE profile:foo fvrf:None fail_reason:IPSec Proposal failure fail_class_cnt:14',
           'host' => 'router',
           'date_raw' => 'Jan 1 19:12:19'
    },
    'NetApp Filer Logs' => {
           'priority' => 'info',
           'facility_int' => 128,
           'message' => '[filer-201: scsitarget.ispfct.targetReset:notice]: FCP Target 0c: Target was Reset by the Initiator at Port Id: 0x11000 (WWPN 5001438021e071ec)',
           'program_name' => 'scsitarget.ispfct.targetReset',
           'facility' => 'local0',
           'host_raw' => 'filer-201.example.com',
           'program_raw' => '[filer-201: scsitarget.ispfct.targetReset:notice]',
           'priority_int' => 6,
           'program_pid' => undef,
           'domain' => 'example.com',
           'datetime_raw' => 'Jan 1 11:28:13',
           'content' => 'FCP Target 0c: Target was Reset by the Initiator at Port Id: 0x11000 (WWPN 5001438021e071ec)',
           'date' => qq{$year-01-01},
           'time' => '11:28:13',
           'datetime_str' => qq{$year-01-01T11:28:13Z},
           'program_sub' => undef,
           'host' => 'filer-201',
           'date_raw' => 'Jan 1 11:28:13',
           'preamble' => 134,
           'message_raw' => '<134>Jan 1 11:28:13 filer-201.example.com [filer-201: scsitarget.ispfct.targetReset:notice]: FCP Target 0c: Target was Reset by the Initiator at Port Id: 0x11000 (WWPN 5001438021e071ec)'
    },
    "NetApp Filer Alt1" => {
           'datetime_str' => "$year-01-01T11:28:13Z",
           'host' => 'filer-201',
           'date' => "$year-01-01",
           'time' => '11:28:13',
           'facility' => 'local0',
           'priority_int' => 6,
           'program_sub' => undef,
           'program_name' => 'scsitarget.ispfct.targetReset',
           'facility_int' => 128,
           'datetime_raw' => 'Jan 1 11:28:13',
           'domain' => 'example.com',
           'priority' => 'info',
           'preamble' => 134,
           'message' => '[filer-201 scsitarget.ispfct.targetReset:notice]: FCP Target 0c: Target was Reset by the Initiator at Port Id: 0x11000 (WWPN 5001438021e071ec)',
           'content' => 'FCP Target 0c: Target was Reset by the Initiator at Port Id: 0x11000 (WWPN 5001438021e071ec)',
           'message_raw' => '<134>Jan 1 11:28:13 filer-201.example.com [filer-201 scsitarget.ispfct.targetReset:notice]: FCP Target 0c: Target was Reset by the Initiator at Port Id: 0x11000 (WWPN 5001438021e071ec)',
           'host_raw' => 'filer-201.example.com',
           'program_raw' => '[filer-201 scsitarget.ispfct.targetReset:notice]',
           'program_pid' => undef,
           'date_raw' => 'Jan 1 11:28:13',
    },
    "NetApp Filer Alt2" => {
           'program_pid' => undef,
           'priority_int' => 6,
           'preamble' => 134,
           'message_raw' => '<134>Jan 1 11:28:13 filer-201.example.com [filer-201:scsitarget.ispfct.targetReset:notice]: FCP Target 0c: Target was Reset by the Initiator at Port Id: 0x11000 (WWPN 5001438021e071ec)',
           'domain' => 'example.com',
           'time' => '11:28:13',
           'date_raw' => 'Jan 1 11:28:13',
           'datetime_str' => "$year-01-01T11:28:13Z",
           'facility_int' => 128,
           'program_raw' => '[filer-201:scsitarget.ispfct.targetReset:notice]',
           'content' => 'FCP Target 0c: Target was Reset by the Initiator at Port Id: 0x11000 (WWPN 5001438021e071ec)',
           'priority' => 'info',
           'host_raw' => 'filer-201.example.com',
           'date' => "$year-01-01",
           'facility' => 'local0',
           'message' => '[filer-201:scsitarget.ispfct.targetReset:notice]: FCP Target 0c: Target was Reset by the Initiator at Port Id: 0x11000 (WWPN 5001438021e071ec)',
           'datetime_raw' => 'Jan 1 11:28:13',
           'host' => 'filer-201',
           'program_sub' => undef,
           'program_name' => 'scsitarget.ispfct.targetReset',
    },
    'F5 includes level' => {
           'preamble' => 182,
           'program_raw' => 'info logger',
           'datetime_raw' => 'Jan 1 10:55:37',
           'datetime_str' => "$year-01-01T10:55:37Z",
           'domain' => 'example.com',
           'host_raw' => 'f5lb-201.example.com',
           'priority_int' => 6,
           'message_raw' => '<182>Jan 1 10:55:37 f5lb-201.example.com info logger: [ssl_acc] 10.0.0.1 - bob [01/Jan/2015:10:55:37 +0000] "/xui/update/configuration/alert/statusmenu/coloradvisory" 200 1702',
           'content' => '[ssl_acc] 10.0.0.1 - bob [01/Jan/2015:10:55:37 +0000] "/xui/update/configuration/alert/statusmenu/coloradvisory" 200 1702',
           'host' => 'f5lb-201',
           'program_pid' => undef,
           'facility_int' => 176,
           'program_sub' => undef,
           'facility' => 'local6',
           'message' => 'info logger: [ssl_acc] 10.0.0.1 - bob [01/Jan/2015:10:55:37 +0000] "/xui/update/configuration/alert/statusmenu/coloradvisory" 200 1702',
           'date_raw' => 'Jan 1 10:55:37',
           'program_name' => 'logger',
           'priority' => 'info',
           'time' => '10:55:37',
           'date' => "$year-01-01"
    },
    'ISO8601 with micro' => {
           'program_name' => 'my-script.pl',
           'program_raw' => 'my-script.pl',
           'datetime_raw' => '2015-09-30T06:26:06.779373-05:00',
           'date_raw' => '2015-09-30T06:26:06.779373-05:00',
           'message_raw' => '2015-09-30T06:26:06.779373-05:00 my-host my-script.pl: {"lunchTime":1443612366.442}',
           'facility' => undef,
           'content' => '{"lunchTime":1443612366.442}',
           'date' => '2015-09-30',
           'program_pid' => undef,
           'facility_int' => undef,
           'priority' => undef,
           'domain' => undef,
           'message' => 'my-script.pl: {"lunchTime":1443612366.442}',
           'host_raw' => 'my-host',
           'time' => '11:26:06.779373',
           'priority_int' => undef,
           'host' => 'my-host',
           'program_sub' => undef,
           'preamble' => undef,
           'datetime_str' => '2015-09-30T11:26:06.779373Z'
    },
    'Year with old date' => {
           'priority' => undef,
           'date' => '2015-11-13',
           'time' => '13:40:01',
           'content' => 'imuxsock begins to drop messages from pid 17840 due to rate-limiting',
           'facility' => undef,
           'domain' => undef,
           'program_sub' => undef,
           'host_raw' => 'ether',
           'program_raw' => 'rsyslogd-2177',
           'datetime_raw' => 'Nov 13 13:40:01 2015',
           'message_raw' => '2015 Nov 13 13:40:01 ether rsyslogd-2177: imuxsock begins to drop messages from pid 17840 due to rate-limiting',
           'priority_int' => undef,
           'preamble' => undef,
           'datetime_str' => '2015-11-13T13:40:01Z',
           'program_pid' => undef,
           'program_name' => 'rsyslogd-2177',
           'facility_int' => undef,
           'message' => 'rsyslogd-2177: imuxsock begins to drop messages from pid 17840 due to rate-limiting',
           'host' => 'ether',
           'date_raw' => 'Nov 13 13:40:01 2015'
    },
    'High Precision Dates' => {
           'program_pid' => '14400',
           'datetime_str' => '2016-11-19T19:50:01.749659Z',
           'content' => '(root) CMD (/usr/lib64/sa/sa1 1 1)',
           'priority_int' => undef,
           'message_raw' => '2016-11-19T20:50:01.749659+01:00 janus CROND[14400]: (root) CMD (/usr/lib64/sa/sa1 1 1)',
           'priority' => undef,
           'program_raw' => 'CROND[14400]',
           'program_name' => 'CROND',
           'program_sub' => undef,
           'preamble' => undef,
           'time' => '19:50:01.749659',
           'facility_int' => undef,
           'host_raw' => 'janus',
           'host' => 'janus',
           'datetime_raw' => '2016-11-19T20:50:01.749659+01:00',
           'facility' => undef,
           'message' => 'CROND[14400]: (root) CMD (/usr/lib64/sa/sa1 1 1)',
           'domain' => undef,
           'date' => '2016-11-19',
           'date_raw' => '2016-11-19T20:50:01.749659+01:00'
    },
);

my @test_configs = (
    { 'Defaults'        => { 'EpochCreate' => 0, 'IgnoreTimeZones' => 0, 'NormalizeToUTC' => 0, }, },
);

subtest "Basic Functionality Test" => sub {
    my @_delete = qw(datetime_obj epoch offset);

    foreach my $name (sort keys %msgs) {
        my $msg = parse_syslog_line($msgs{$name});
        delete $msg->{$_} for grep { exists $msg->{$_} } @_delete;
        if ( !exists $resps{$name} ) {
            diag( Dumper $msg );
        }
        is_deeply( $msg, $resps{$name}, $name );
    }

    # Disable Program extraction
    do {
        local $Parse::Syslog::Line::ExtractProgram = 0;
        foreach my $name (sort keys %msgs) {
            my $msg = parse_syslog_line($msgs{$name});
            my %expected = %{ $resps{$name} };
            delete $msg->{$_} for @_delete;
            $expected{content} = $expected{program_raw} . ': ' . $expected{content};
            $expected{$_} = undef for qw(program_raw program_name program_sub program_pid);
            is_deeply( $msg, \%expected, "$name (no extract program)" );
        }
    };
};

subtest 'Custom parser' => sub {

    sub parse_func {
        my ($date) = @_;
        $date //= " ";
        my $modified = "[$date]";

        return $modified;
    }

    local $Parse::Syslog::Line::FmtDate = \&parse_func;

    foreach my $name (sort keys %msgs) {
        foreach my $part (@dtfields) {
            $resps{$name}{$part} = undef;
        }
        $resps{$name}{date} = "[" . $resps{$name}{datetime_raw} . "]";
        my $msg = parse_syslog_line($msgs{$name});
        is_deeply( $msg, $resps{$name}, "FmtDate " . $name );
    }
    done_testing();
};

done_testing();

sub _set_test_config{
    my ( $config ) = @_;

    # set config values
    while (my ($name, $value) = each %{$config}) {
        ${"Parse::Syslog::Line::$name"} = $value;
    };

    return;
};
