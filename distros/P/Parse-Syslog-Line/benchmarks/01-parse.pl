#!perl

use strict;
use warnings;
use Benchmark qw/timethese cmpthese/;
use Const::Fast;
use Parse::Syslog::Line;

# Disable warnings
$ENV{PARSE_SYSLOG_LINE_QUIET} = 1;

const my @msgs => (
    q|<11>Jan  1 00:00:00 mainfw snort[32640]: [1:1893:4] SNMP missing community string attempt [Classification: Misc Attack] [Priority: 2]: {UDP} 1.2.3.4:23210 -> 5.6.7.8:161|,
    q|<11>Jan  1 00:00:00 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|,
    q|Jan  1 00:00:00 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|,
    q|<11>Jan  1 00:00:00 dev.example.com dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|,
    q|Jan  1 00:00:00 example syslogd 1.2.3: restart (remote reception).|,
    q|<163>Jun 7 18:39:00 hostname.domain.tld %ASA-3-313001: Denied ICMP type=5, code=1 from 1.2.3.4 on interface inside|,
    q|<161>Jun 7 18:39:00 hostname : %ASA-3-313001: Denied ICMP type=5, code=1 from 1.2.3.4 on interface inside|,
    q|2013-08-09T11:09:36+02:00 hostname.company.tld : 2013 Aug  9 11:09:36.290 CET: %ETHPORT-5-IF_DOWN_CFG_CHANGE: Interface Ethernet121/1/1 is down(Config change)|,
    q|<134>Jan 1 11:28:13 filer-201.example.com [filer-201: scsitarget.ispfct.targetReset:notice]: FCP Target 0c: Target was Reset by the Initiator at Port Id: 0x11000 (WWPN 5001438021e071ec)|,
    q|2016-11-19T20:50:01.749659+01:00 janus CROND[14400]: (root) CMD (/usr/lib64/sa/sa1 1 1)|,
    q|2015 Nov 13 13:40:01 ether rsyslogd-2177: imuxsock begins to drop messages from pid 17840 due to rate-limit|,
    q|2015 Nov 13 13:40:01 ether application: JSON log is: {"src_ip":"1.2.3.4","src_port":35235}|,
    q|2015 Nov 13 13:40:01 ether application: this is words with some splunk k/v at the end: k1=v1, k2=v2, k3=v3|,
    q|May 24 09:14:21 deprecation GoogleSoftwareUpdateAgent[22548]: 2018-05-24 09:14:21.050 GoogleSoftwareUpdateAgent[22548/0x70000b057000] [lvl=2] -[KSAgentApp(PrivateMethods) setUpLoggerOutputForVerboseMode:] Agent default/global settings: <KSAgentSettings:0x1003390a0 bundleID=com.google.Keystone.Agent lastCheck=2018-05-24 00:07:32 +0000 lastServerCheck=2018-05-24 00:07:31 +0000 lastCheckStart=2018-05-24 16:14:19 +0000 checkInterval=18000.000000 uiDisplayInterval=604800.000000 sleepInterval=1800.000000 jitterInterval=900 maxRunInterval=0.000000 isConsoleUser=1 ticketStorePath=/Users/brad/Library/Google/GoogleSoftwareUpdate/TicketStore/Keystone.ticketstore runMode=3 daemonUpdateEngineBrokerServiceName=com.google.Keystone.Daemon.UpdateEngine daemonAdministrationServiceName=com.google.Keystone.Daemon.Administration alwaysPromptForUpdates=0 lastUIDisplayed=(null) alwaysShowStatusItem=0 updateCheckTag=(null) printResults=NO userInitiated=NO>|,
    q|2015 Nov 13 13:40:01 ether application: [lvl=2] [foo x=1] some context [bar x=3 t=4]|,
    q|2015 Nov 13 13:40:01 ether application: [prop@12345 x="2"] some context|,
);

my $last = '';
my @copy = ();
my $stub = sub {
    my ($test) = @_;
    @copy = @msgs unless @copy and $last ne $test;
    $last=$test;
    parse_syslog_line(shift @copy);
};
my $results = timethese(50_000, {
    'DateTimeCreate' => sub {
        local $Parse::Syslog::Line::DateTimeCreate  = 1;
        $stub->('DateTimeCreate');
    },
    'Defaults' => sub {
        $stub->('Defaults');
    },
    'NormalizeToUTC' => sub {
        local $Parse::Syslog::Line::NormalizeToUTC  = 1;
        $stub->('NormalizeToUTC');
    },
    'PruneEmpty' => sub {
        local $Parse::Syslog::Line::PruneEmpty      = 1;
        $stub->('PruneEmpty');
    },
    'NoDatesPruned' => sub {
        local $Parse::Syslog::Line::DateParsing     = 0;
        local $Parse::Syslog::Line::PruneRaw        = 1;
        local $Parse::Syslog::Line::PruneEmpty      = 1;
        $stub->('No Dates, Pruned');
    },
    'NoDates' => sub {
        local $Parse::Syslog::Line::DateParsing     = 0;
        $stub->('No Dates');
    },
    'JSON' => sub {
        local $Parse::Syslog::Line::AutoDetectJSON = 1;
        $stub->('JSON');
    },
    'KV' => sub {
        local $Parse::Syslog::Line::AutoDetectKeyValues = 1;
        $stub->('KV');
    },
    'NoRFCSDATA' => sub {
        local $Parse::Syslog::Line::RFC5424StructuredData = 0;
        $stub->('SDATA');
    },
    'StrictRFC' => sub {
        local $Parse::Syslog::Line::RFC5424StructuredDataStrict = 1;
        $stub->('SDATA');
    },
    'AutoSDATA' => sub {
        local $Parse::Syslog::Line::AutoDetectJSON = 1;
        local $Parse::Syslog::Line::AutoDetectKeyValues = 1;
        $stub->('SDATA');
    },
});

print "\n";
cmpthese($results);
print "\nGood logfiles which have UTC offsets (like Cisco) run waaaay faster:\n";

const my @utc_syslogs => (
    q|2015-01-01T11:09:36+02:00 hostname.company.tld : $year Jan  1 11:09:36.290 CET: %ETHPORT-5-IF_DOWN_CFG_CHANGE: Interface Ethernet121/1/1 is down(Config change)|,
    q|2015-09-30T06:26:06.779373-05:00 my-host my-script.pl: {"lunchTime":1443612366.442}|,
    q|2015-09-30T06:26:06.779373Z my-host my-script.pl: {"lunchTime":1443612366.442}|,
);

@copy = @utc_syslogs;
my $utc_stub = sub {
    my ($test) = @_;
    @copy = @utc_syslogs unless @copy and $test ne $last;
    $last = $test;
    parse_syslog_line( shift @copy );
};
my $results_pure = timethese(50_000, {
    'NormalizeToUTC' => sub {
        local $Parse::Syslog::Line::NormalizeToUTC  = 1;
        $utc_stub->('NormalizeToUTC');
    },
    'DateTimeCreate' => sub {
        local $Parse::Syslog::Line::DateTimeCreate  = 1;
        $utc_stub->('Defaults');
    },
    'No Date Parsing' => sub {
        local $Parse::Syslog::Line::DateParsing     = 0;
        $utc_stub->('No Date Parsing');
    },
});

print "\n";
cmpthese($results_pure);
print "\n";

print "Done.\n";
