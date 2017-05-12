# =============================================================================
package Net::SNMP::Util::OID;
# -----------------------------------------------------------------------------
$Net::SNMP::Util::OID::VERSION = '1.04';
# -----------------------------------------------------------------------------
use warnings;
use strict;

=head1 NAME

Net::SNMP::Util::OID - OID mapper functions for Net::SNMP::Util

=head1 SYNOPSIS

    # load system and interfaces MIB map
    use Net::SNMP::Util::OID qw(sys* if*);

    printf "OID of sysDescr is %s\n", oid("sysDescr");
    # "1.3.6.1.2.1.1.1"

    printf "1.3.6.1.2.1.2.2.1.3 specifys %s\n", oidt("1.3.6.1.2.1.2.2.1.3");
    # ifType

    printf "OID of MIB %s is %s\n", oidm("ifName");
    # "ifName", "1.3.6.1.2.1.31.1.1.1.1"

    oid_load("someMib1" => "1.3.6.1.4.1.99999.1.2.3",
             "someMib2" => "1.3.6.1.4.1.99999.4.5.6");
    printf "OID of MIB %s is %s\n", oidm("someMib1");


=head1 DESCRIPTION

Module C<Net::SNMP::Util::OID> gives some functions which treats mapping data
between MIB name and OID.

=head2 Basic entry group importing

This module is preparing some basic MIB and OID maps mainly definded RFC-1213.
For example, if you want to treat some MIB and OID with among 'system' and
'snmp' entry group's, declare with C<use> pragma and gives arguments with
tailing '*' like;

    use Net::SNMP::Util::OID qw(system* snmp*);

So, note that no declaring with this tagging couldn't treat mapping data.

    use Net::SNMP::Util::OID;
    $oid = oid("ifType");       # Null string will return!

The prepared entrys are; C<system*>, C<interfaces*>, C<at*>, C<ip*>, C<icmp*>,
 C<tcp*>, C<udp*>, C<egp*>, C<snmp*>, C<tcp*> and C<ifXTable*>.
And there are few sugar syntaxs. Only one character '*' means all prepared
mapping, 'sys*' means 'system*' and 'if*' means importing 'interfaces' and
'ifXTable' at same time.


=head1 EXPORT

This module, C<Net::SNMP::Util::OID>, exports C<oid_load()>, C<oid()>, C<oidt()>
and C<oidm()>.

=cut

use Carp qw();
use List::Util;

use base qw( Exporter );
our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS, $VERSION);
@EXPORT = qw( oid_load oid oidt oidp );

my %_OIDs = ();
my %_MIBs = ();
my @_Cache = ();
my $_CacheNum = 10;     # Number of caching pairs

use constant DEBUG => 0;


# =============================================================================
my %_OID_base = qw(
        iso             1
        org             1.3
        dod             1.3.6
        internet        1.3.6.1
        directory       1.3.6.1.1
        mgmt            1.3.6.1.2
        experimental    1.3.6.1.3
        private         1.3.6.1.4
        security        1.3.6.1.5
        snmpV2          1.3.6.1.6
);

my %_OID_mgmt = (

    # --- from RFC-1213 ---
    'system' => {
        system              => '1.3.6.1.2.1.1',
        sysDescr            => '1.3.6.1.2.1.1.1.0',
        sysObjectID         => '1.3.6.1.2.1.1.2.0',
        sysUpTime           => '1.3.6.1.2.1.1.3.0',
        sysUptime           => '1.3.6.1.2.1.1.3.0',
        sysContact          => '1.3.6.1.2.1.1.4.0',
        sysName             => '1.3.6.1.2.1.1.5.0',
        sysLocation         => '1.3.6.1.2.1.1.6.0',
        sysServices         => '1.3.6.1.2.1.1.7.0',

        sysORLastChange     => '1.3.6.1.2.1.1.8.0',     # from RFC-1907,3418
        sysORTable          => '1.3.6.1.2.1.1.9',       # from RFC-1907,3418
        sysOREntry          => '1.3.6.1.2.1.1.9.1',     # from RFC-1907,3418
        sysORIndex          => '1.3.6.1.2.1.1.9.1.1',   # from RFC-1907,3418
        sysORID             => '1.3.6.1.2.1.1.9.1.2',   # from RFC-1907,3418
        sysORDescr          => '1.3.6.1.2.1.1.9.1.3',   # from RFC-1907,3418
        sysORUpTime         => '1.3.6.1.2.1.1.9.1.4',   # from RFC-1907,3418
    },
    interfaces => {
        interfaces          => '1.3.6.1.2.1.2',
        ifNumber            => '1.3.6.1.2.1.2.1.0',     # from RFC-2863
        ifTable             => '1.3.6.1.2.1.2.2',
        ifEntry             => '1.3.6.1.2.1.2.2.1',
        ifIndex             => '1.3.6.1.2.1.2.2.1.1',
        ifDescr             => '1.3.6.1.2.1.2.2.1.2',
        ifType              => '1.3.6.1.2.1.2.2.1.3',
        ifMtu               => '1.3.6.1.2.1.2.2.1.4',
        ifSpeed             => '1.3.6.1.2.1.2.2.1.5',
        ifPhysAddress       => '1.3.6.1.2.1.2.2.1.6',
        ifAdminStatus       => '1.3.6.1.2.1.2.2.1.7',
        ifOperStatus        => '1.3.6.1.2.1.2.2.1.8',
        ifLastChange        => '1.3.6.1.2.1.2.2.1.9',
        ifInOctets          => '1.3.6.1.2.1.2.2.1.10',
        ifInUcastPkts       => '1.3.6.1.2.1.2.2.1.11',
        ifInNUcastPkts      => '1.3.6.1.2.1.2.2.1.12',  # deprecated at RFC-2863
        ifInDiscards        => '1.3.6.1.2.1.2.2.1.13',
        ifInErrors          => '1.3.6.1.2.1.2.2.1.14',
        ifInUnknownProtos   => '1.3.6.1.2.1.2.2.1.15',
        ifOutOctets         => '1.3.6.1.2.1.2.2.1.16',
        ifOutUcastPkts      => '1.3.6.1.2.1.2.2.1.17',
        ifOutNUcastPkts     => '1.3.6.1.2.1.2.2.1.18',  # deprecated at RFC-2863
        ifOutDiscards       => '1.3.6.1.2.1.2.2.1.19',
        ifOutErrors         => '1.3.6.1.2.1.2.2.1.20',
        ifOutQLen           => '1.3.6.1.2.1.2.2.1.21',  # deprecated at RFC-2863
        ifSpecific          => '1.3.6.1.2.1.2.2.1.22',  # deprecated at RFC-2863
    },
    at => {
        at                  => '1.3.6.1.2.1.3',
        atTable             => '1.3.6.1.2.1.3.1',
        atEntry             => '1.3.6.1.2.1.3.1.1',
        atIfIndex           => '1.3.6.1.2.1.3.1.1.1',
        atPhysAddress       => '1.3.6.1.2.1.3.1.1.2',
        atNetAddress        => '1.3.6.1.2.1.3.1.1.3',
    },
    ip => {
        ip                  => '1.3.6.1.2.1.4',
        ipForwarding        => '1.3.6.1.2.1.4.1',
        ipDefaultTTL        => '1.3.6.1.2.1.4.2',
        ipInReceives        => '1.3.6.1.2.1.4.3',
        ipInHdrErrors       => '1.3.6.1.2.1.4.4',
        ipInAddrErrors      => '1.3.6.1.2.1.4.5',
        ipForwDatagrams     => '1.3.6.1.2.1.4.6',
        ipInUnknownProtos   => '1.3.6.1.2.1.4.7',
        ipInDiscards        => '1.3.6.1.2.1.4.8',
        ipInDelivers        => '1.3.6.1.2.1.4.9',
        ipOutRequests       => '1.3.6.1.2.1.4.10',
        ipOutDiscards       => '1.3.6.1.2.1.4.11',
        ipOutNoRoutes       => '1.3.6.1.2.1.4.12',
        ipReasmTimeout      => '1.3.6.1.2.1.4.13',
        ipReasmReqds        => '1.3.6.1.2.1.4.14',
        ipReasmOKs          => '1.3.6.1.2.1.4.15',
        ipReasmFails        => '1.3.6.1.2.1.4.16',
        ipFragOKs           => '1.3.6.1.2.1.4.17',
        ipFragFails         => '1.3.6.1.2.1.4.18',
        ipFragCreates       => '1.3.6.1.2.1.4.19',
        ipAddrTable         => '1.3.6.1.2.1.4.20',
        ipAddrEntry         => '1.3.6.1.2.1.4.20.1',
        ipAdEntAddr         => '1.3.6.1.2.1.4.20.1.1',
        ipAdEntIfIndex      => '1.3.6.1.2.1.4.20.1.2',
        ipAdEntNetMask      => '1.3.6.1.2.1.4.20.1.3',
        ipAdEntBcastAddr    => '1.3.6.1.2.1.4.20.1.4',
        ipAdEntReasmMaxSize => '1.3.6.1.2.1.4.20.1.5',
        ipRouteTable        => '1.3.6.1.2.1.4.21',
        ipRouteEntry        => '1.3.6.1.2.1.4.21.1',
        ipRouteDest         => '1.3.6.1.2.1.4.21.1.1',
        ipRouteIfIndex      => '1.3.6.1.2.1.4.21.1.2',
        ipRouteMetric1      => '1.3.6.1.2.1.4.21.1.3',
        ipRouteMetric2      => '1.3.6.1.2.1.4.21.1.4',
        ipRouteMetric3      => '1.3.6.1.2.1.4.21.1.5',
        ipRouteMetric4      => '1.3.6.1.2.1.4.21.1.6',
        ipRouteNextHop      => '1.3.6.1.2.1.4.21.1.7',
        ipRouteType         => '1.3.6.1.2.1.4.21.1.8',
        ipRouteProto        => '1.3.6.1.2.1.4.21.1.9',
        ipRouteAge          => '1.3.6.1.2.1.4.21.1.10',
        ipRouteMask         => '1.3.6.1.2.1.4.21.1.11',
        ipRouteMetric5      => '1.3.6.1.2.1.4.21.1.12',
        ipRouteInfo         => '1.3.6.1.2.1.4.21.1.13',
        ipNetToMediaTable   => '1.3.6.1.2.1.4.22',
        ipNetToMediaEntry   => '1.3.6.1.2.1.4.22.1',
        ipNetToMediaIfIndex => '1.3.6.1.2.1.4.22.1.1',
        ipNetToMediaPhysAddress => '1.3.6.1.2.1.4.22.1.2',
        ipNetToMediaNetAddress  => '1.3.6.1.2.1.4.22.1.3',
        ipNetToMediaType    => '1.3.6.1.2.1.4.22.1.4',
        ipRoutingDiscards   => '1.3.6.1.2.1.4.23',
    },
    icmp => {
        icmp                => '1.3.6.1.2.1.5',
        icmpInMsgs          => '1.3.6.1.2.1.5.1',
        icmpInErrors        => '1.3.6.1.2.1.5.2',
        icmpInDestUnreachs  => '1.3.6.1.2.1.5.3',
        icmpInTimeExcds     => '1.3.6.1.2.1.5.4',
        icmpInParmProbs     => '1.3.6.1.2.1.5.5',
        icmpInSrcQuenchs    => '1.3.6.1.2.1.5.6',
        icmpInRedirects     => '1.3.6.1.2.1.5.7',
        icmpInEchos         => '1.3.6.1.2.1.5.8',
        icmpInEchoReps      => '1.3.6.1.2.1.5.9',
        icmpInTimestamps    => '1.3.6.1.2.1.5.10',
        icmpInTimestampReps => '1.3.6.1.2.1.5.11',
        icmpInAddrMasks     => '1.3.6.1.2.1.5.12',
        icmpInAddrMaskReps  => '1.3.6.1.2.1.5.13',
        icmpOutMsgs         => '1.3.6.1.2.1.5.14',
        icmpOutErrors       => '1.3.6.1.2.1.5.15',
        icmpOutDestUnreachs => '1.3.6.1.2.1.5.16',
        icmpOutTimeExcds    => '1.3.6.1.2.1.5.17',
        icmpOutParmProbs    => '1.3.6.1.2.1.5.18',
        icmpOutSrcQuenchs   => '1.3.6.1.2.1.5.19',
        icmpOutRedirects    => '1.3.6.1.2.1.5.20',
        icmpOutEchos        => '1.3.6.1.2.1.5.21',
        icmpOutEchoReps     => '1.3.6.1.2.1.5.22',
        icmpOutTimestamps   => '1.3.6.1.2.1.5.23',
        icmpOutTimestampReps => '1.3.6.1.2.1.5.24',
        icmpOutAddrMasks    => '1.3.6.1.2.1.5.25',
        icmpOutAddrMaskReps => '1.3.6.1.2.1.5.26',
    },
    tcp => {
        tcp                 => '1.3.6.1.2.1.6',
        tcpRtoAlgorithm     => '1.3.6.1.2.1.6.1',
        tcpRtoMin           => '1.3.6.1.2.1.6.2',
        tcpRtoMax           => '1.3.6.1.2.1.6.3',
        tcpMaxConn          => '1.3.6.1.2.1.6.4',
        tcpActiveOpens      => '1.3.6.1.2.1.6.5',
        tcpPassiveOpens     => '1.3.6.1.2.1.6.6',
        tcpAttemptFails     => '1.3.6.1.2.1.6.7',
        tcpEstabResets      => '1.3.6.1.2.1.6.8',
        tcpCurrEstab        => '1.3.6.1.2.1.6.9',
        tcpInSegs           => '1.3.6.1.2.1.6.10',
        tcpOutSegs          => '1.3.6.1.2.1.6.11',
        tcpRetransSegs      => '1.3.6.1.2.1.6.12',
        tcpConnTable        => '1.3.6.1.2.1.6.13',
        tcpConnEntry        => '1.3.6.1.2.1.6.13.1',
        tcpConnState        => '1.3.6.1.2.1.6.13.1.1',
        tcpConnLocalAddress => '1.3.6.1.2.1.6.13.1.2',
        tcpConnLocalPort    => '1.3.6.1.2.1.6.13.1.3',
        tcpConnRemAddress   => '1.3.6.1.2.1.6.13.1.4',
        tcpConnRemPort      => '1.3.6.1.2.1.6.13.1.5',
        tcpInErrs           => '1.3.6.1.2.1.6.14',
        tcpOutRsts          => '1.3.6.1.2.1.6.15',
    },
    udp => {
        udp                 => '1.3.6.1.2.1.7',
        udpInDatagrams      => '1.3.6.1.2.1.7.1',
        udpNoPorts          => '1.3.6.1.2.1.7.2',
        udpInErrors         => '1.3.6.1.2.1.7.3',
        udpOutDatagrams     => '1.3.6.1.2.1.7.4',
        udpTable            => '1.3.6.1.2.1.7.5',
        udpEntry            => '1.3.6.1.2.1.7.5.1',
        udpLocalAddress     => '1.3.6.1.2.1.7.5.1.1',
        udpLocalPort        => '1.3.6.1.2.1.7.5.1.2',
    },
    egp => {
        egp                     => '1.3.6.1.2.1.8',
        egpInMsgs               => '1.3.6.1.2.1.8.1',
        egpInErrors             => '1.3.6.1.2.1.8.2',
        egpOutMsgs              => '1.3.6.1.2.1.8.3',
        egpOutErrors            => '1.3.6.1.2.1.8.4',
        egpNeighTable           => '1.3.6.1.2.1.8.5',
        egpNeighEntry           => '1.3.6.1.2.1.8.5.1',
        egpNeighState           => '1.3.6.1.2.1.8.5.1.1',
        egpNeighAddr            => '1.3.6.1.2.1.8.5.1.2',
        egpNeighAs              => '1.3.6.1.2.1.8.5.1.3',
        egpNeighInMsgs          => '1.3.6.1.2.1.8.5.1.4',
        egpNeighInErrs          => '1.3.6.1.2.1.8.5.1.5',
        egpNeighOutMsgs         => '1.3.6.1.2.1.8.5.1.6',
        egpNeighOutErrs         => '1.3.6.1.2.1.8.5.1.7',
        egpNeighInErrMsgs       => '1.3.6.1.2.1.8.5.1.8',
        egpNeighOutErrMsgs      => '1.3.6.1.2.1.8.5.1.9',
        egpNeighStateUps        => '1.3.6.1.2.1.8.5.1.10',
        egpNeighStateDowns      => '1.3.6.1.2.1.8.5.1.11',
        egpNeighIntervalHello   => '1.3.6.1.2.1.8.5.1.12',
        egpNeighIntervalPoll    => '1.3.6.1.2.1.8.5.1.13',
        egpNeighMode            => '1.3.6.1.2.1.8.5.1.14',
        egpNeighEventTrigger    => '1.3.6.1.2.1.8.5.1.15',
        egpAs                   => '1.3.6.1.2.1.8.6',
    },
    transmission => {
        transmission            => '1.3.6.1.2.1.10',
    },
    snmp => {
        snmp                    => '1.3.6.1.2.1.11',
        snmpInPkts              => '1.3.6.1.2.1.11.1',
        snmpOutPkts             => '1.3.6.1.2.1.11.2',
        snmpInBadVersions       => '1.3.6.1.2.1.11.3',
        snmpInBadCommunityNames => '1.3.6.1.2.1.11.4',
        snmpInBadCommunityUses  => '1.3.6.1.2.1.11.5',
        snmpInASNParseErrs      => '1.3.6.1.2.1.11.6',
        snmpInTooBigs           => '1.3.6.1.2.1.11.8',
        snmpInNoSuchNames       => '1.3.6.1.2.1.11.9',
        snmpInBadValues         => '1.3.6.1.2.1.11.10',
        snmpInReadOnlys         => '1.3.6.1.2.1.11.11',
        snmpInGenErrs           => '1.3.6.1.2.1.11.12',
        snmpInTotalReqVars      => '1.3.6.1.2.1.11.13',
        snmpInTotalSetVars      => '1.3.6.1.2.1.11.14',
        snmpInGetRequests       => '1.3.6.1.2.1.11.15',
        snmpInGetNexts          => '1.3.6.1.2.1.11.16',
        snmpInSetRequests       => '1.3.6.1.2.1.11.17',
        snmpInGetResponses      => '1.3.6.1.2.1.11.18',
        snmpInTraps             => '1.3.6.1.2.1.11.19',
        snmpOutTooBigs          => '1.3.6.1.2.1.11.20',
        snmpOutNoSuchNames      => '1.3.6.1.2.1.11.21',
        snmpOutBadValues        => '1.3.6.1.2.1.11.22',
        snmpOutGenErrs          => '1.3.6.1.2.1.11.24',
        snmpOutGetRequests      => '1.3.6.1.2.1.11.25',
        snmpOutGetNexts         => '1.3.6.1.2.1.11.26',
        snmpOutSetRequests      => '1.3.6.1.2.1.11.27',
        snmpOutGetResponses     => '1.3.6.1.2.1.11.28',
        snmpOutTraps            => '1.3.6.1.2.1.11.29',
        snmpEnableAuthenTraps   => '1.3.6.1.2.1.11.30',
        snmpSilentDrops         => '1.3.6.1.2.1.11.31', # from RFC-1907,3418
        snmpProxyDrops          => '1.3.6.1.2.1.11.32', # from RFC-1907,3418
    },

    # --- from RFC-2863 ---
    'ifMIB' => {
        ifMIB                   => '1.3.6.1.2.1.31',
        ifMIBObjects            => '1.3.6.1.2.1.31.1',
        ifConformance           => '1.3.6.1.2.1.31.2',
    },

    'ifXTable' => {
        ifXTable                => '1.3.6.1.2.1.31.1.1',
        ifXEntry                => '1.3.6.1.2.1.31.1.1.1',
        ifName                  => '1.3.6.1.2.1.31.1.1.1.1',
        ifInMulticastPkts       => '1.3.6.1.2.1.31.1.1.1.2',
        ifInBroadcastPkts       => '1.3.6.1.2.1.31.1.1.1.3',
        ifOutMulticastPkts      => '1.3.6.1.2.1.31.1.1.1.4',
        ifOutBroadcastPkts      => '1.3.6.1.2.1.31.1.1.1.5',
        ifHCInOctets            => '1.3.6.1.2.1.31.1.1.1.6',
        ifHCInUcastPkts         => '1.3.6.1.2.1.31.1.1.1.7',
        ifHCInMulticastPkts     => '1.3.6.1.2.1.31.1.1.1.8',
        ifHCInBroadcastPkts     => '1.3.6.1.2.1.31.1.1.1.9',
        ifHCOutOctets           => '1.3.6.1.2.1.31.1.1.1.10',
        ifHCOutUcastPkts        => '1.3.6.1.2.1.31.1.1.1.11',
        ifHCOutMulticastPkts    => '1.3.6.1.2.1.31.1.1.1.12',
        ifHCOutBroadcastPkts    => '1.3.6.1.2.1.31.1.1.1.13',
        ifLinkUpDownTrapEnable  => '1.3.6.1.2.1.31.1.1.1.14',
        ifHighSpeed             => '1.3.6.1.2.1.31.1.1.1.15',
        ifPromiscuousMode       => '1.3.6.1.2.1.31.1.1.1.16',
        ifConnectorPresent      => '1.3.6.1.2.1.31.1.1.1.17',
        ifAlias                 => '1.3.6.1.2.1.31.1.1.1.18',
        ifCounterDiscontinuityTime => '1.3.6.1.2.1.31.1.1.1.19',
    },
);
# =============================================================================
our @MAPS = ( \%_OID_mgmt );

sub import
{
    my $class = shift;
    my @args  = ();
    oid_load( \%_OID_base );

    foreach ( map { lc } @_ ){
        if ( /^(.*)\*$/ ){
            # OID map loading
            my $which = $1;
            my @which = ();
            my $found = 0;

            if ( $which eq '' ){
                foreach my $map ( @MAPS ){
                    foreach my $w ( keys %{$map} ){
                        oid_load( $map->{$w} );
                    }
                }
                $found = 1;
            }
            else {
                if ( $which eq 'if' ){
                    push @which, qw( interfaces ifXTable ); # suger
                }
                elsif ( $which eq 'sys' ){
                    push @which, 'system';                  # suger
                }
                else {
                    push @which, $which;
                }
                my $found = _mapdata_loader(@which);
                unless ( $found ){
                    Carp::carp(qq(Not found mapping data of "$which*".));
                }
            }
        }
        else {
            push @args, @_;
        }
    }

    __PACKAGE__->export_to_level(1, @args);
}


# =============================================================================
sub _mapdata_loader
{
    my $found = 0;

    foreach my $map ( @MAPS ){
        foreach my $which ( @_ ){
            if ( exists $map->{$which} ){
                oid_load( $map->{$which} );
                $found = 1;
            }
        }
    }
    return $found;
}


# =============================================================================

=head1 FUNCTIONS

=head2 oid_load()

    oid_load( $mib_name => $oid, ... );
    oid_load( \%somehash, ... );

Functions oid_load() takes hash pairs or a referances of hash as arguments, and
store intarnally MIB name and OID (Object IDentifier) mapping data from them.

=cut

# -----------------------------------------------------------------------------
sub _oid_load_sub
{
    my ($mib,$oid) = @_;

    unless ( defined($mib) and defined($oid) ){
        Carp::carp("Undefined MIB name or OID is given");
        return;
    }
    unless ( $mib =~ /^[a-zA-Z][\w\-]*(\.[a-zA-Z][\w\-])*$/ ){
        Carp::carp("Unrecognized MIB name, $mib, is given");
        return;
    }
    unless ( $oid =~ /^\.?\d+(\.\d+)*$/ ){
        Carp::carp("Unrecognized OID, $oid, is given");
        return;
    }
    (my $soid = $oid) =~ s/^\.?1\.3\.6\.1\./_/;

    $_OIDs{$mib}  = $oid;
    $_MIBs{$soid} = $mib;
}

sub oid_load
{
    my @args = @_;
    while ( $#args >= 0 )
    {
        my $mib = shift @args;
        if ( ref($mib) eq 'HASH' ){
            while ( my ($m, $o) = each %{$mib} ){
                _oid_load_sub( $m => $o );
            }
            next;
        }
        my $oid = shift @args;
        _oid_load_sub( $mib => $oid );
    }
}


# =============================================================================

=head2 oid

    oid( $mib_name, ... )

Function C<oid()> takes MIB names and returns OIDs of them.
If OID is not found, given MIB name uses as returing value.

This function treats sub OID of a part of given MIB name as well as sample
below;

    print oid("ifName.100");  # shows 1.3.6.1.2.1.31.1.1.1.1.100

=cut

# -----------------------------------------------------------------------------
sub _check_cache
{
    my $str = shift;
    my $grp = List::Util::first { $_->[0] eq $str } @_Cache;
    if ( $grp ){
        @_Cache = ( $grp, (grep { $_->[0] ne $str } @_Cache) );
        return $grp->[1];
    }
    return undef;
}

sub _unshift_cache
{
    my ($mib,$oid) = @_;
    unshift @_Cache, [ $mib, $oid ];
    if ( @_Cache > $_CacheNum ){
        pop @_Cache;
    }
}

sub _oid_sub
{
    my $mib = shift || return '';

    my $oid = _check_cache($mib);
    unless ( defined $oid ){

        $oid = $_OIDs{$mib};
        unless ( defined $oid ){
            # not found
            return $mib;
        }

        _unshift_cache($mib, $oid); # cache refresh
    }

    return $oid;
}

sub oid
{
    my @ret = map {
        my @t = ();
        foreach my $s ( split(/\./) ){
            $s = _oid_sub($s) if ( $s =~ /\D/ );
            push @t, $s;
        }
        join('.',@t);
    } @_;
    return wantarray? @ret: $ret[0];
}


# =============================================================================

=head2 oidt

    oidt( $mib_oid, ... )

Function C<oidt()> translates OID to MIB name. 
This returns null string C<''> if it can't find specified OID.

=cut

# -----------------------------------------------------------------------------
sub oidt
{

    my @ret = ();
    foreach my $oid ( @_ ){
        (my $s = $oid) =~ s/^\.?1\.3\.6\.1\./_/;
        my $mib = $_MIBs{$s} || $_MIBs{$oid};
        unless ( defined $mib ){
                push @ret, '';
                next;
        }
        push @ret, $mib;
    }
    return wantarray? @ret: $ret[0];
}


# =============================================================================

=head2 oidp

    ($mib_name, $oid) = oidp( $mib_name )

Function C<oidp()> takes a MIB name and returns array contains itself and it's
OID search by C<oid()>.

=cut


# -----------------------------------------------------------------------------
sub oidp
{
    my $mib = shift;
    return ($mib, oid($mib));
}


=head1 AUTHOR

t.onodera, C<< <cpan :: garakuta.net> >>

=head1 SEE ALSO

L<Net::SNMP::Util>, L<Net::SNMP::Util::TC>

=head1 LICENSE AND COPYRIGHT

Copyright(C) 2010 Takahiro Ondoera.

This program is free software; you may redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1; # End of Net::SNMP::Util::OID