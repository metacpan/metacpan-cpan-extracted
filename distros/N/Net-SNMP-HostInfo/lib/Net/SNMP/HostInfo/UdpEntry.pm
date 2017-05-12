package Net::SNMP::HostInfo::UdpEntry;

=head1 NAME

Net::SNMP::HostInfo::UdpEntry - An entry in the udpTable of a MIB-II host

=head1 SYNOPSIS

    use Net::SNMP::HostInfo;

    $host = shift || 'localhost';
    $hostinfo = Net::SNMP::HostInfo->new(Hostname => $host);

    print "\nUdp Listeners Table:\n";
    printf "%-15s %-5s\n",
        qw/LocalAddress Port/;
    for $entry ($hostinfo->udpTable) {
        printf "%-15s %-5s\n",
            $entry->udpLocalAddress,
            $entry->udpLocalPort;
    }

=head1 DESCRIPTION

"Information about a particular current UDP
listener."

=cut

use 5.006;
use strict;
use warnings;

use Carp;

#our $VERSION = '0.01';

our $AUTOLOAD;

my %oids = (
    udpLocalAddress => '1.3.6.1.2.1.7.5.1.1', 
    udpLocalPort => '1.3.6.1.2.1.7.5.1.2', 
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

=item udpLocalAddress

"The local IP address for this UDP listener.  In
the case of a UDP listener which is willing to
accept datagrams for any IP interface associated
with the node, the value 0.0.0.0 is used."

=item udpLocalPort

"The local port number for this UDP listener."

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
