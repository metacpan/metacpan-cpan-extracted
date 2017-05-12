package Net::SNMP::HostInfo::IpAddrEntry;

=head1 NAME

Net::SNMP::HostInfo::IpAddrEntry - An entry in the ipAddrTable of a MIB-II host

=head1 SYNOPSIS

    use Net::SNMP::HostInfo;

    $host = shift || 'localhost';
    $hostinfo = Net::SNMP::HostInfo->new(Hostname => $host);

    print "\nAddress Table:\n";
    printf "%-15s %-3s %-15s %-5s %5s\n",
        qw/Addr If NetMask Bcast ReasmMaxSize/;
    for $addr ($hostinfo->ipAddrTable) {
        printf "%-15s %-3s %-15s %-5s %5s\n",
            $addr->ipAdEntAddr,
            $addr->ipAdEntIfIndex,
            $addr->ipAdEntNetMask,
            $addr->ipAdEntBcastAddr,
            $addr->ipAdEntReasmMaxSize;
    }

=head1 DESCRIPTION

"The addressing information for one of this
entity's IP addresses."

=cut

use 5.006;
use strict;
use warnings;

use Carp;

#our $VERSION = '0.01';

our $AUTOLOAD;

my %oids = (
    ipAdEntAddr => '1.3.6.1.2.1.4.20.1.1',
    ipAdEntIfIndex => '1.3.6.1.2.1.4.20.1.2',
    ipAdEntNetMask => '1.3.6.1.2.1.4.20.1.3',
    ipAdEntBcastAddr => '1.3.6.1.2.1.4.20.1.4',
    ipAdEntReasmMaxSize => '1.3.6.1.2.1.4.20.1.5',
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

=item ipAdEntAddr

"The IP address to which this entry's addressing
information pertains."

=item ipAdEntIfIndex

"The index value which uniquely identifies the
interface to which this entry is applicable.  The
interface identified by a particular value of this
index is the same interface as identified by the
same value of ifIndex."

=item ipAdEntNetMask

"The subnet mask associated with the IP address of
this entry.  The value of the mask is an IP
address with all the network bits set to 1 and all
the hosts bits set to 0."

=item ipAdEntBcastAddr

"The value of the least-significant bit in the IP
broadcast address used for sending datagrams on
the (logical) interface associated with the IP
address of this entry.  For example, when the
Internet standard all-ones broadcast address is
used, the value will be 1.  This value applies to
both the subnet and network broadcasts addresses
used by the entity on this (logical) interface."

=item ipAdEntReasmMaxSize

"The size of the largest IP datagram which this
entity can re-assemble from incoming IP fragmented
datagrams received on this interface."

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
        return $response->{$oid};
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
