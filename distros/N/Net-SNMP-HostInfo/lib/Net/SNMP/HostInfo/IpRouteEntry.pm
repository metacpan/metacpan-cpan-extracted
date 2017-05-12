package Net::SNMP::HostInfo::IpRouteEntry;

=head1 NAME

Net::SNMP::HostInfo::IpRouteEntry - An entry in the ipRouteTable of a MIB-II host

=head1 SYNOPSIS

    use Net::SNMP::HostInfo;

    $host = shift || 'localhost';
    $hostinfo = Net::SNMP::HostInfo->new(Hostname => $host);

    print "\nRoute Table:\n";
    printf "%-15s %-15s %-15s %-11s %-10s %-3s %-3s\n",
        qw/Dest Mask NextHop Type Proto If Cost/;
    for $route ($hostinfo->ipRouteTable) {
        printf "%-15s %-15s %-15s %-11s %-10s %-3s %-3s\n",
            $route->ipRouteDest,
            $route->ipRouteMask,
            $route->ipRouteNextHop,
            $route->ipRouteType,
            $route->ipRouteProto,
            $route->ipRouteIfIndex,
            $route->ipRouteMetric1;
    }

=head1 DESCRIPTION

"A route to a particular destination."

=cut

use 5.006;
use strict;
use warnings;

use Carp;

#our $VERSION = '0.01';

our $AUTOLOAD;

my %oids = (
    ipRouteDest    => '1.3.6.1.2.1.4.21.1.1',
    ipRouteIfIndex => '1.3.6.1.2.1.4.21.1.2',
    ipRouteMetric1 => '1.3.6.1.2.1.4.21.1.3',
    ipRouteMetric2 => '1.3.6.1.2.1.4.21.1.4',
    ipRouteMetric3 => '1.3.6.1.2.1.4.21.1.5',
    ipRouteMetric4 => '1.3.6.1.2.1.4.21.1.6',
    ipRouteNextHop => '1.3.6.1.2.1.4.21.1.7',
    ipRouteType    => '1.3.6.1.2.1.4.21.1.8',
    ipRouteProto   => '1.3.6.1.2.1.4.21.1.9',
    ipRouteAge     => '1.3.6.1.2.1.4.21.1.10',
    ipRouteMask    => '1.3.6.1.2.1.4.21.1.11',
    ipRouteMetric5 => '1.3.6.1.2.1.4.21.1.12',
    ipRouteInfo    => '1.3.6.1.2.1.4.21.1.13',
    );

my %decodedObjects = (
    ipRouteType => { qw/1 other 2 invalid 3 direct 4 indirect/ },
    ipRouteProto => { qw/1 other
                         2 local
                         3 netmgmt
                         4 icmp
                         5 egp
                         6 ggp
                         7 hello
                         8 rip
                         9 is-is
                         10 es-is
                         11 ciscoIgrp
                         12 bbnSpfIgp
                         13 ospf
                         14 bgp/ },
    );

# Preloaded methods go here.

=head1 METHODS

=over

=cut

sub new
{
    my $class = shift;

    my %args = @_;

    my $self = {};

    $self->{_session} = $args{Session};
    $self->{_decode} = $args{Decode};
    $self->{_index} = $args{Index};
    
    bless $self, $class;
    return $self;
}

=item ipRouteDest

"The destination IP address of this route.  An
entry with a value of 0.0.0.0 is considered a
default route.  Multiple routes to a single
destination can appear in the table, but access to
such multiple entries is dependent on the table-
access mechanisms defined by the network
management protocol in use."

=item ipRouteIfIndex

"The index value which uniquely identifies the
local interface through which the next hop of this
route should be reached.  The interface identified
by a particular value of this index is the same
interface as identified by the same value of
ifIndex."

=item ipRouteMetric1

"The primary routing metric for this route.  The
semantics of this metric are determined by the
routing-protocol specified in the route's
ipRouteProto value.  If this metric is not used,
its value should be set to -1."

=item ipRouteMetric2

"An alternate routing metric for this route.  The
semantics of this metric are determined by the
routing-protocol specified in the route's
ipRouteProto value.  If this metric is not used,
its value should be set to -1."

=item ipRouteMetric3

"An alternate routing metric for this route.  The
semantics of this metric are determined by the
routing-protocol specified in the route's
ipRouteProto value.  If this metric is not used,
its value should be set to -1."

=item ipRouteMetric4

"An alternate routing metric for this route.  The
semantics of this metric are determined by the
routing-protocol specified in the route's
ipRouteProto value.  If this metric is not used,
its value should be set to -1."

=item ipRouteNextHop

"The IP address of the next hop of this route.
(In the case of a route bound to an interface
which is realized via a broadcast media, the value
of this field is the agent's IP address on that
interface.)"

=item ipRouteType

"The type of route.  Note that the values
direct(3) and indirect(4) refer to the notion of
direct and indirect routing in the IP
architecture.

Setting this object to the value invalid(2) has
the effect of invalidating the corresponding entry
in the ipRouteTable object.  That is, it
effectively dissasociates the destination
identified with said entry from the route
identified with said entry.  It is an
implementation-specific matter as to whether the
agent removes an invalidated entry from the table.
Accordingly, management stations must be prepared
to receive tabular information from agents that
corresponds to entries not currently in use.
Proper interpretation of such entries requires
examination of the relevant ipRouteType object."

Possible values are:

    other(1),        
    invalid(2),      
    direct(3),       
    indirect(4) 

=item ipRouteProto

"The routing mechanism via which this route was
learned.  Inclusion of values for gateway routing
protocols is not intended to imply that hosts
should support those protocols."

Possible values are:

    other(1),       
    local(2),       
    netmgmt(3),     
    icmp(4),        
    egp(5),
    ggp(6),
    hello(7),
    rip(8),
    is-is(9),
    es-is(10),
    ciscoIgrp(11),
    bbnSpfIgp(12),
    ospf(13),
    bgp(14)

=item ipRouteAge

"The number of seconds since this route was last
updated or otherwise determined to be correct.
Note that no semantics of `too old' can be implied
except through knowledge of the routing protocol
by which the route was learned."

=item ipRouteMask

"Indicate the mask to be logical-ANDed with the
destination address before being compared to the
value in the ipRouteDest field.  For those systems
that do not support arbitrary subnet masks, an
agent constructs the value of the ipRouteMask by
determining whether the value of the correspondent
ipRouteDest field belong to a class-A, B, or C
network, and then using one of:

    mask           network
    255.0.0.0      class-A
    255.255.0.0    class-B
    255.255.255.0  class-C

If the value of the ipRouteDest is 0.0.0.0 (a
default route), then the mask value is also
0.0.0.0.  It should be noted that all IP routing
subsystems implicitly use this mechanism."

=item ipRouteMetric5

"An alternate routing metric for this route.  The
semantics of this metric are determined by the
routing-protocol specified in the route's
ipRouteProto value.  If this metric is not used,
its value should be set to -1."

=item ipRouteInfo

"A reference to MIB definitions specific to the
particular routing protocol which is responsible
for this route, as determined by the value
specified in the route's ipRouteProto value.  If
this information is not present, its value should
be set to the OBJECT IDENTIFIER { 0 0 }, which is
a syntatically valid object identifier, and any
conformant implementation of ASN.1 and BER must be
able to generate and recognize this value."

=back

=cut

sub AUTOLOAD
{
    my $self = shift;

    return if $AUTOLOAD =~ /DESTROY$/;

    my ($name) = $AUTOLOAD =~ /::([^:]+)$/;
    #print "Called $name\n";

    if (!exists $oids{$name}) {
        croak "Can't locate object method '$name'";
    }

    my $oid = $oids{$name} . '.' . $self->{_index};

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

1;

__END__

=head1 AUTHOR

James Macfarlane, E<lt>jmacfarla@cpan.orgE<gt>

=head1 SEE ALSO

Net::SNMP::HostInfo

=cut
