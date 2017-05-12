package Net::SNMP::HostInfo::TcpConnEntry;

=head1 NAME

Net::SNMP::HostInfo::TcpConnEntry - An entry in the tcpConnTable of a MIB-II host

=head1 SYNOPSIS

    use Net::SNMP::HostInfo;

    $host = shift || 'localhost';
    $hostinfo = Net::SNMP::HostInfo->new(Hostname => $host);

    print "\nTcp Connection Table:\n";
    printf "%-15s %-5s %-15s %-5s %s\n",
        qw/LocalAddress Port RemAddress Port State/;
    for $entry ($hostinfo->tcpConnTable) {
        printf "%-15s %-5s %-15s %-5s %s\n",
            $entry->tcpConnLocalAddress,
            $entry->tcpConnLocalPort,
            $entry->tcpConnRemAddress,
            $entry->tcpConnRemPort,
            $entry->tcpConnState;
    }

=head1 DESCRIPTION

"Information about a particular current TCP
connection.  An object of this type is transient,
in that it ceases to exist when (or soon after)
the connection makes the transition to the CLOSED
state."

=cut

use 5.006;
use strict;
use warnings;

use Carp;

#our $VERSION = '0.01';

our $AUTOLOAD;

my %oids = (
    tcpConnState => '1.3.6.1.2.1.6.13.1.1', 
    tcpConnLocalAddress => '1.3.6.1.2.1.6.13.1.2', 
    tcpConnLocalPort => '1.3.6.1.2.1.6.13.1.3', 
    tcpConnRemAddress => '1.3.6.1.2.1.6.13.1.4', 
    tcpConnRemPort => '1.3.6.1.2.1.6.13.1.5', 
    );

my %decodedObjects = (
    tcpConnState => { qw/1 closed
                         2 listen
                         3 synSent
                         4 synReceived
                         5 established
                         6 finWait1
                         7 finWait2
                         8 closeWait
                         9 lastAck
                         10 closing
                         11 timeWait
                         12 deleteTCB/ },
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

=item tcpConnState

"The state of this TCP connection.

The only value which may be set by a management
station is deleteTCB(12).  Accordingly, it is
appropriate for an agent to return a `badValue'
response if a management station attempts to set
this object to any other value.

If a management station sets this object to the
value deleteTCB(12), then this has the effect of
deleting the TCB (as defined in RFC 793) of the
corresponding connection on the managed node,
resulting in immediate termination of the
connection.

As an implementation-specific option, a RST
segment may be sent from the managed node to the
other TCP endpoint (note however that RST segments
are not sent reliably)."

Possible values are:

    closed(1),
    listen(2),
    synSent(3),
    synReceived(4),
    established(5),
    finWait1(6),
    finWait2(7),
    closeWait(8),
    lastAck(9),
    closing(10),
    timeWait(11),
    deleteTCB(12)

=item tcpConnLocalAddress

"The local IP address for this TCP connection.  In
the case of a connection in the listen state which
is willing to accept connections for any IP
interface associated with the node, the value
0.0.0.0 is used."

=item tcpConnLocalPort

"The local port number for this TCP connection."

=item tcpConnRemAddress

"The remote IP address for this TCP connection."

=item tcpConnRemPort

"The remote port number for this TCP connection."

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
