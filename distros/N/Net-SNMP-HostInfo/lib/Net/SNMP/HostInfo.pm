package Net::SNMP::HostInfo;

=head1 NAME

Net::SNMP::HostInfo - Access the IP statistics of a MIB-II host

=head1 SYNOPSIS

    use Net::SNMP::HostInfo;

    $host = shift || 'localhost';
    $password = shift || 'public';

    $hostinfo = Net::SNMP::HostInfo->new(Hostname => $host,
                                         Community => $password);

    print "Packets Received = ", $hostinfo->ipInReceives, "\n";
    print "Output Requests = ", $hostinfo->ipOutRequests, "\n";

    print "TCP Segments Received = ", $hostinfo->tcpInSegs, "\n";
    print "TCP Segments Sent = ", $hostinfo->tcpOutSegs, "\n";

    print "UDP Datagrams Received = ", $hostinfo->udpInDatagrams, "\n";
    print "UDP Datagrams Sent = ", $hostinfo->udpOutDatagrams, "\n";

=head1 DESCRIPTION

Net::SNMP::HostInfo is a class that simplifies access to the
IP, TCP, and UDP information of a MIB-II compliant network host,
such as a router or a PC.

You can use it to retrieve numerous statistics on IP, ICMP, TCP, and UDP,
as well as the IP routing table (L<ipRouteTable>),
the IP address table (L<ipAddrTable>),
the ARP table (L<ipNetToMediaTable>),
the TCP connection table (L<tcpConnTable>),
and the UDP listener table (L<udpTable>).
Browse the list of available methods to see what values are available.

=cut

# Base OIDs for the MIB-II groups
# 1.3.6.1.2.1.1 = system
# 1.3.6.1.2.1.2 = interfaces (implemented by Net::SNMP::Interfaces)
# 1.3.6.1.2.1.4 = ip
# 1.3.6.1.2.1.5 = icmp
# 1.3.6.1.2.1.6 = tcp
# 1.3.6.1.2.1.7 = udp
# 1.3.6.1.2.1.11 = snmp (not implemented yet)

use 5.006;
use strict;
use warnings;

use Net::SNMP::HostInfo::IpAddrEntry;
use Net::SNMP::HostInfo::IpRouteEntry;
use Net::SNMP::HostInfo::IpNetToMediaEntry;
use Net::SNMP::HostInfo::TcpConnEntry;
use Net::SNMP::HostInfo::UdpEntry;
use Net::SNMP;
use Carp;

our $VERSION = '0.04';
our $AUTOLOAD;

my %oids = (
    sysDescr    => '1.3.6.1.2.1.1.1', 
    sysObjectID => '1.3.6.1.2.1.1.2', 
    sysUpTime   => '1.3.6.1.2.1.1.3', 
    sysContact  => '1.3.6.1.2.1.1.4', 
    sysName     => '1.3.6.1.2.1.1.5', 
    sysLocation => '1.3.6.1.2.1.1.6', 
    sysServices => '1.3.6.1.2.1.1.7', 

    ipForwarding      => '1.3.6.1.2.1.4.1',
    ipDefaultTTL      => '1.3.6.1.2.1.4.2',
    ipInReceives      => '1.3.6.1.2.1.4.3',
    ipInHdrErrors     => '1.3.6.1.2.1.4.4',
    ipInAddrErrors    => '1.3.6.1.2.1.4.5',
    ipForwDatagrams   => '1.3.6.1.2.1.4.6',
    ipInUnknownProtos => '1.3.6.1.2.1.4.7',
    ipInDiscards      => '1.3.6.1.2.1.4.8',
    ipInDelivers      => '1.3.6.1.2.1.4.9',
    ipOutRequests     => '1.3.6.1.2.1.4.10',
    ipOutDiscards     => '1.3.6.1.2.1.4.11',
    ipOutNoRoutes     => '1.3.6.1.2.1.4.12',
    ipReasmTimeout    => '1.3.6.1.2.1.4.13',
    ipReasmReqds      => '1.3.6.1.2.1.4.14',
    ipReasmOKs        => '1.3.6.1.2.1.4.15',
    ipReasmFails      => '1.3.6.1.2.1.4.16',
    ipFragOKs         => '1.3.6.1.2.1.4.17',
    ipFragFails       => '1.3.6.1.2.1.4.18',
    ipFragCreates     => '1.3.6.1.2.1.4.19',
#    ipAddrTable       => '1.3.6.1.2.1.4.20',
#    ipRouteTable      => '1.3.6.1.2.1.4.21',
#    ipNetToMediaTable => '1.3.6.1.2.1.4.22',
    ipRoutingDiscards => '1.3.6.1.2.1.4.23',

    icmpInMsgs           => '1.3.6.1.2.1.5.1',
    icmpInErrors         => '1.3.6.1.2.1.5.2',
    icmpInDestUnreachs   => '1.3.6.1.2.1.5.3',
    icmpInTimeExcds      => '1.3.6.1.2.1.5.4',
    icmpInParmProbs      => '1.3.6.1.2.1.5.5',
    icmpInSrcQuenchs     => '1.3.6.1.2.1.5.6',
    icmpInRedirects      => '1.3.6.1.2.1.5.7',
    icmpInEchos          => '1.3.6.1.2.1.5.8',
    icmpInEchoReps       => '1.3.6.1.2.1.5.9',
    icmpInTimestamps     => '1.3.6.1.2.1.5.10',
    icmpInTimestampReps  => '1.3.6.1.2.1.5.11',
    icmpInAddrMasks      => '1.3.6.1.2.1.5.12',
    icmpInAddrMaskReps   => '1.3.6.1.2.1.5.13',
    icmpOutMsgs          => '1.3.6.1.2.1.5.14',
    icmpOutErrors        => '1.3.6.1.2.1.5.15',
    icmpOutDestUnreachs  => '1.3.6.1.2.1.5.16',
    icmpOutTimeExcds     => '1.3.6.1.2.1.5.17',
    icmpOutParmProbs     => '1.3.6.1.2.1.5.18',
    icmpOutSrcQuenchs    => '1.3.6.1.2.1.5.19',
    icmpOutRedirects     => '1.3.6.1.2.1.5.20',
    icmpOutEchos         => '1.3.6.1.2.1.5.21',
    icmpOutEchoReps      => '1.3.6.1.2.1.5.22',
    icmpOutTimestamps    => '1.3.6.1.2.1.5.23',
    icmpOutTimestampReps => '1.3.6.1.2.1.5.24',
    icmpOutAddrMasks     => '1.3.6.1.2.1.5.25',
    icmpOutAddrMaskReps  => '1.3.6.1.2.1.5.26',

    tcpRtoAlgorithm  => '1.3.6.1.2.1.6.1',
    tcpRtoMin        => '1.3.6.1.2.1.6.2',
    tcpRtoMax        => '1.3.6.1.2.1.6.3',
    tcpMaxConn       => '1.3.6.1.2.1.6.4',
    tcpActiveOpens   => '1.3.6.1.2.1.6.5',
    tcpPassiveOpens  => '1.3.6.1.2.1.6.6',
    tcpAttemptFails  => '1.3.6.1.2.1.6.7',
    tcpEstabResets   => '1.3.6.1.2.1.6.8',
    tcpCurrEstab     => '1.3.6.1.2.1.6.9',
    tcpInSegs        => '1.3.6.1.2.1.6.10',
    tcpOutSegs       => '1.3.6.1.2.1.6.11',
    tcpRetransSegs   => '1.3.6.1.2.1.6.12',
#    tcpConnTable     => '1.3.6.1.2.1.6.13',
    tcpInErrs        => '1.3.6.1.2.1.6.14',
    tcpOutRsts       => '1.3.6.1.2.1.6.15',
    
    udpInDatagrams   => '1.3.6.1.2.1.7.1',
    udpNoPorts       => '1.3.6.1.2.1.7.2',
    udpInErrors      => '1.3.6.1.2.1.7.3',
    udpOutDatagrams  => '1.3.6.1.2.1.7.4',
#    udpTable         => '1.3.6.1.2.1.7.5',
    
    );

my %decodedObjects = (
    ipForwarding => { qw/1 forwarding 2 not-forwarding/ },
    tcpRtoAlgorithm => { qw/1 other 2 constant 3 rsre 4 vanj/ },
    );

my %tables = (
    ipAddrTable =>
        [qw/1.3.6.1.2.1.4.20.1.1 Net::SNMP::HostInfo::IpAddrEntry C4/],
    ipRouteTable =>
        [qw/1.3.6.1.2.1.4.21.1.1 Net::SNMP::HostInfo::IpRouteEntry C4/],
    ipNetToMediaTable =>
        [qw/1.3.6.1.2.1.4.22.1.1 Net::SNMP::HostInfo::IpNetToMediaEntry NC4/],
    tcpConnTable =>
        [qw/1.3.6.1.2.1.6.13.1.1 Net::SNMP::HostInfo::TcpConnEntry C4nC4n/],
    udpTable =>
        [qw/1.3.6.1.2.1.7.5.1.1 Net::SNMP::HostInfo::UdpEntry C4n/],
    );

# Preloaded methods go here.

=head1 METHODS

=over

=item new

Creates a new Net::SNMP::HostInfo object. You can specify the
following optional parameters:

=over

=item Hostname => $hostname

The hostname of the target device; defaults to 'localhost'.

=item Community => $community

The community string of the target device; defaults to 'public'.

=item Session => $session

An alternative to specifying the Hostname and Community
parameters: you can use an existing Net::SNMP session for
all Net::SNMP::HostInfo queries.

=item Decode => $decode

If true, certain values, such as ipForwarding, will be
returned as strings instead of numbers. For example,
ipForwarding will be returned as 'forwarding(1)' or
'not-forwarding(2)'. The following values are affected:

    ipForwarding
    tcpRtoAlgorithm
    ipNetToMediaType (ipNetToMediaTable)
    ipRouteType (ipRouteTable)
    ipRouteProto (ipRouteTable)
    tcpConnState (tcpConnTable)

Additionally, ethernet addresses returned by
ipNetToMediaPhysAddress will be prettified.

=back

Here are some examples:

    $hostinfo = Net::SNMP::HostInfo->new(Hostname => 'quartz',
                                         Community => 'crystal',
                                         Decode => 1);

    $interfaces = Net::SNMP::Interfaces->new(Hostname => 'quartz',
                                             Community => 'crystal');
    $hostinfo = Net::SNMP::HostInfo->new(Session => $interfaces->session,
                                         Decode => 1);

    ($session, $error) = Net::SNMP->session(-hostname => 'quartz',
                                            -community => 'crystal');
    $hostinfo = Net::SNMP::HostInfo->new(Session => $session,
                                         Decode => 1);

=cut

sub new
{
    my $class = shift;

    my %args = @_;

    my $self = {};

    $self->{_decode} = $args{Decode} || 0;

    my ($session, $error);
    if ($args{Session} && ref($args{Session}) eq "Net::SNMP") {
        # Use existing Net::SNMP session
        $session = $args{Session};
    } else {
        # Create new Net::SNMP session
        $self->{_hostname} = $args{Hostname} || 'localhost';
        $self->{_community} = $args{Community} || 'public';
        $self->{_port} = $args{Port} || 161;

        ($session, $error) = Net::SNMP->session(
            -hostname => $self->{_hostname},
            -community => $self->{_community},
            -port => $self->{_port}
            );
    }

    # check that we have a session with an SNMP host
    if (defined $session) {
        my $oid = '1.3.6.1.2.1.1.5.0'; # sysName
        my $response = $session->get_request($oid);

        if (defined $response) {
            # we're okay
        } else {
            croak "Could not establish session to host";
        }
    } else {
        croak "Could not establish session to host";
    }

    $self->{_session} = $session;
    
    bless $self, $class;
    return $self;
}

=item session

Returns the Net::SNMP session object being used.
The session can be then used for other SNMP queries.

=cut

sub session { return $_[0]->{_session}; }

=item ipForwarding

"The indication of whether this entity is acting
as an IP gateway in respect to the forwarding of
datagrams received by, but not addressed to, this
entity.  IP gateways forward datagrams.  IP hosts
do not (except those source-routed via the host).

Note that for some managed nodes, this object may
take on only a subset of the values possible.
Accordingly, it is appropriate for an agent to
return a `badValue' response if a management
station attempts to change this object to an
inappropriate value."

Possible values are:

    forwarding(1),    
    not-forwarding(2) 

=item ipDefaultTTL

"The default value inserted into the Time-To-Live
field of the IP header of datagrams originated at
this entity, whenever a TTL value is not supplied
by the transport layer protocol."

=item ipInReceives

"The total number of input datagrams received from
interfaces, including those received in error."

=item ipInHdrErrors

"The number of input datagrams discarded due to
errors in their IP headers, including bad
checksums, version number mismatch, other format
errors, time-to-live exceeded, errors discovered
in processing their IP options, etc."

=item ipInAddrErrors

"The number of input datagrams discarded because
the IP address in their IP header's destination
field was not a valid address to be received at
this entity.  This count includes invalid
addresses (e.g., 0.0.0.0) and addresses of
unsupported Classes (e.g., Class E).  For entities
which are not IP Gateways and therefore do not
forward datagrams, this counter includes datagrams
discarded because the destination address was not
a local address."

=item ipForwDatagrams

"The number of input datagrams for which this
entity was not their final IP destination, as a
result of which an attempt was made to find a
route to forward them to that final destination.
In entities which do not act as IP Gateways, this
counter will include only those packets which were
Source-Routed via this entity, and the Source-
Route option processing was successful."

=item ipInUnknownProtos 

"The number of locally-addressed datagrams
received successfully but discarded because of an
unknown or unsupported protocol."

=item ipInDiscards

"The number of input IP datagrams for which no
problems were encountered to prevent their
continued processing, but which were discarded
(e.g., for lack of buffer space).  Note that this
counter does not include any datagrams discarded
while awaiting re-assembly."

=item ipInDelivers

"The total number of input datagrams successfully
delivered to IP user-protocols (including ICMP)."

=item ipOutRequests

"The total number of IP datagrams which local IP
user-protocols (including ICMP) supplied to IP in
requests for transmission.  Note that this counter
does not include any datagrams counted in
ipForwDatagrams."

=item ipOutDiscards

"The number of output IP datagrams for which no
problem was encountered to prevent their
transmission to their destination, but which were
discarded (e.g., for lack of buffer space).  Note
that this counter would include datagrams counted
in ipForwDatagrams if any such packets met this
(discretionary) discard criterion."

=item ipOutNoRoutes

"The number of IP datagrams discarded because no
route could be found to transmit them to their
destination.  Note that this counter includes any
packets counted in ipForwDatagrams which meet this
`no-route' criterion.  Note that this includes any
datagarms which a host cannot route because all of
its default gateways are down."

=item ipReasmTimeout

"The maximum number of seconds which received
fragments are held while they are awaiting
reassembly at this entity."

=item ipReasmReqds

"The number of IP fragments received which needed
to be reassembled at this entity."

=item ipReasmOKs

"The number of IP datagrams successfully re-
assembled."

=item ipReasmFails

"The number of failures detected by the IP re-
assembly algorithm (for whatever reason: timed
out, errors, etc).  Note that this is not
necessarily a count of discarded IP fragments
since some algorithms (notably the algorithm in
RFC 815) can lose track of the number of fragments
by combining them as they are received."

=item ipFragOKs

"The number of IP datagrams that have been
successfully fragmented at this entity."

=item ipFragFails

"The number of IP datagrams that have been
discarded because they needed to be fragmented at
this entity but could not be, e.g., because their
Don't Fragment flag was set."

=item ipFragCreates

"The number of IP datagram fragments that have
been generated as a result of fragmentation at
this entity."

=item ipAddrTable

"The table of addressing information relevant to
this entity's IP addresses."

Returns a list of Net::SNMP::HostInfo::IpAddrEntry objects.

=item ipRouteTable

"This entity's IP Routing table."

Returns a list of Net::SNMP::HostInfo::IpRouteEntry objects.

=item ipNetToMediaTable

"The IP Address Translation table used for mapping
from IP addresses to physical addresses."

Returns a list of Net::SNMP::HostInfo::IpNetToMediaEntry objects.

=item ipRoutingDiscards

"The number of routing entries which were chosen
to be discarded even though they are valid.  One
possible reason for discarding such an entry could
be to free-up buffer space for other routing
entries."

=item icmpInMsgs

"The total number of ICMP messages which the
entity received.  Note that this counter includes
all those counted by icmpInErrors."

=item icmpInErrors

"The number of ICMP messages which the entity
received but determined as having ICMP-specific
errors (bad ICMP checksums, bad length, etc.)."

=item icmpInDestUnreachs

"The number of ICMP Destination Unreachable
messages received."

=item icmpInTimeExcds

"The number of ICMP Time Exceeded messages
received."

=item icmpInParmProbs

"The number of ICMP Parameter Problem messages
received."

=item icmpInSrcQuenchs

"The number of ICMP Source Quench messages
received."

=item icmpInRedirects

"The number of ICMP Redirect messages received."

=item icmpInEchos

"The number of ICMP Echo (request) messages
received."

=item icmpInEchoReps

"The number of ICMP Echo Reply messages received."

=item icmpInTimestamps

"The number of ICMP Timestamp (request) messages
received."

=item icmpInTimestampReps

"The number of ICMP Timestamp Reply messages
received."

=item icmpInAddrMasks

"The number of ICMP Address Mask Request messages
received."

=item icmpInAddrMaskReps

"The number of ICMP Address Mask Reply messages
received."

=item icmpOutMsgs

"The total number of ICMP messages which this
entity attempted to send.  Note that this counter
includes all those counted by icmpOutErrors."

=item icmpOutErrors

"The number of ICMP messages which this entity did
not send due to problems discovered within ICMP
such as a lack of buffers.  This value should not
include errors discovered outside the ICMP layer
such as the inability of IP to route the resultant
datagram.  In some implementations there may be no
types of error which contribute to this counter's
value."

=item icmpOutDestUnreachs

"The number of ICMP Destination Unreachable
messages sent."

=item icmpOutTimeExcds

"The number of ICMP Time Exceeded messages sent."

=item icmpOutParmProbs

"The number of ICMP Parameter Problem messages
sent."

=item icmpOutSrcQuenchs

"The number of ICMP Source Quench messages sent."

=item icmpOutRedirects

"The number of ICMP Redirect messages sent.  For a
host, this object will always be zero, since hosts
do not send redirects."

=item icmpOutEchos

"The number of ICMP Echo (request) messages sent."

=item icmpOutEchoReps

"The number of ICMP Echo Reply messages sent."

=item icmpOutTimestamps

"The number of ICMP Timestamp (request) messages
sent."

=item icmpOutTimestampReps

"The number of ICMP Timestamp Reply messages
sent."

=item icmpOutAddrMasks

"The number of ICMP Address Mask Request messages
sent."

=item icmpOutAddrMaskReps

"The number of ICMP Address Mask Reply messages
sent."

=item tcpRtoAlgorithm

"The algorithm used to determine the timeout value
used for retransmitting unacknowledged octets."

Possible values are:

    other(1),    
    constant(2), 
    rsre(3),     
    vanj(4)     

=item tcpRtoMin

"The minimum value permitted by a TCP
implementation for the retransmission timeout,
measured in milliseconds.  More refined semantics
for objects of this type depend upon the algorithm
used to determine the retransmission timeout.  In
particular, when the timeout algorithm is rsre(3),
an object of this type has the semantics of the
LBOUND quantity described in RFC 793."

=item tcpRtoMax

"The maximum value permitted by a TCP
implementation for the retransmission timeout,
measured in milliseconds.  More refined semantics
for objects of this type depend upon the algorithm
used to determine the retransmission timeout.  In
particular, when the timeout algorithm is rsre(3),
an object of this type has the semantics of the
UBOUND quantity described in RFC 793."

=item tcpMaxConn

"The limit on the total number of TCP connections
the entity can support.  In entities where the
maximum number of connections is dynamic, this
object should contain the value -1."

=item tcpActiveOpens

"The number of times TCP connections have made a
direct transition to the SYN-SENT state from the
CLOSED state."

=item tcpPassiveOpens

"The number of times TCP connections have made a
direct transition to the SYN-RCVD state from the
LISTEN state."

=item tcpAttemptFails

"The number of times TCP connections have made a
direct transition to the CLOSED state from either
the SYN-SENT state or the SYN-RCVD state, plus the
number of times TCP connections have made a direct
transition to the LISTEN state from the SYN-RCVD
state."

=item tcpEstabResets

"The number of times TCP connections have made a
direct transition to the CLOSED state from either
the ESTABLISHED state or the CLOSE-WAIT state."

=item tcpCurrEstab

"The number of TCP connections for which the
current state is either ESTABLISHED or CLOSE-
WAIT."

=item tcpInSegs

"The total number of segments received, including
those received in error.  This count includes
segments received on currently established
connections."

=item tcpOutSegs

"The total number of segments sent, including
those on current connections but excluding those
containing only retransmitted octets."

=item tcpRetransSegs

"The total number of segments retransmitted - that
is, the number of TCP segments transmitted
containing one or more previously transmitted
octets."

=item tcpConnTable

"A table containing TCP connection-specific
information."

Returns a list of Net::SNMP::HostInfo::TcpConnEntry objects.

=item tcpInErrs

"The total number of segments received in error
(e.g., bad TCP checksums)."

=item tcpOutRsts

"The number of TCP segments sent containing the
RST flag."

=item udpInDatagrams

"The total number of UDP datagrams delivered to
UDP users."

=item udpNoPorts

"The total number of received UDP datagrams for
which there was no application at the destination
port."

=item udpInErrors

"The number of received UDP datagrams that could
not be delivered for reasons other than the lack
of an application at the destination port."

=item udpOutDatagrams

"The total number of UDP datagrams sent from this
entity."

=item udpTable

"A table containing UDP listener information."

Returns a list of Net::SNMP::HostInfo::UdpEntry objects.

=back

=cut

sub AUTOLOAD
{
    my $self = shift;


    return if $AUTOLOAD =~ /DESTROY$/;

    my ($name) = $AUTOLOAD =~ /::([^:]+)$/;
    #print "Called $name\n";

    if (exists $tables{$name}) {
        my ($baseoid, $class, $indexTemplate) = @{$tables{$name}};
        return $self->getTable($baseoid, $class, $indexTemplate);
    }

    if (!exists $oids{$name}) {
        croak "Can't locate object method '$name'";
    }

    my $oid = $oids{$name} . ".0";

    #print "Trying $oid\n";

    my $response = $self->{_session}->get_request($oid);

    if ($response) {
        my $value = $response->{$oid};

        if ($self->{_decode} &&
            exists $decodedObjects{$name} &&
            exists $decodedObjects{$name}{$value}) {
            return $decodedObjects{$name}{$value}."($value)";
        } else {
            return $value;
        }
    } else {
        return undef;
    }
}

# The ipAddrTable is indexed by ipAdEntAddr
# |------baseoid------|--index---|
# 1.3.6.1.2.1.4.20.1.1.192.168.0.1 = '192.168.0.1'

# The ipRouteTable is indexed by ipRouteDest
# |------baseoid------|---index----|
# 1.3.6.1.2.1.4.21.1.1.192.168.0.255 = '192.168.0.255'

# The index to the ipNetToMediaTable is formed of two values:
#   ipNetToMediaIfIndex
#   ipNetToMediaNetAddress
# |------baseoid------|---index----|
# 1.3.6.1.2.1.4.22.1.1.2.192.168.0.1 = '2'

# The index to the tcpConnTable is formed of four values:
#   tcpConnLocalAddress
#   tcpConnLocalPort
#   tcpConnRemAddress
#   tcpConnRemPort
# |------baseoid------|------------index-------------|
# 1.3.6.1.2.1.6.13.1.1.192.168.0.1.12345.0.0.0.0.57528 = '2'

# The index to the udpTable is formed of two values:
#   udpLocalAddress
#   udpLocalPort
# |-----baseoid------|--------------|
# 1.3.6.1.2.1.7.5.1.1.192.168.0.1.123 = '192.168.0.1'

sub getTable
{
    my $self = shift;
    my $baseoid = shift;
    my $class = shift; # class for each entry in the table
    my $indexTemplate = shift; # how to pack the object's index for sorting
    
    my $response = $self->{_session}->get_table(-baseoid => $baseoid);
    #use Data::Dumper; print Dumper($response);

    my @table = ();
    my @indices = sort { pack($indexTemplate, split(/\./, $a)) cmp
                         pack($indexTemplate, split(/\./, $b)) }
                  map { /^$baseoid\.(.*)/ } keys %$response;
    #for (@indices) { print "$_\n"; }

    for my $index (@indices) {
        my %args = (
            Index => $index,
            Decode => $self->{_decode},
            Session => $self->{_session},
            );
        push @table, $class->new(%args);
    }

    return wantarray ? @table : \@table;
}

1;

__END__

=head1 ACKNOWLEDGEMENTS

David M. Town - Author of Net::SNMP

Jonathan Stowe - Author of Net::SNMP::Interfaces

=head1 AUTHOR

James Macfarlane, E<lt>jmacfarla@cpan.orgE<gt>

=head1 SEE ALSO

RFC 1213 MIB-II,
Net::SNMP,
Net::SNMP::HostInfo::IpAddrEntry,
Net::SNMP::HostInfo::IpRouteEntry,
Net::SNMP::HostInfo::IpNetToMediaEntry,
Net::SNMP::HostInfo::TcpConnEntry,
Net::SNMP::HostInfo::UdpEntry

=cut
