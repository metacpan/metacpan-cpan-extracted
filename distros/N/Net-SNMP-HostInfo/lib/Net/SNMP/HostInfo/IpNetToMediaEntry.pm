package Net::SNMP::HostInfo::IpNetToMediaEntry;

=head1 NAME

Net::SNMP::HostInfo::IpNetToMediaEntry - An entry in the ipNetToMediaTable of a MIB-II host

=head1 SYNOPSIS

    use Net::SNMP::HostInfo;

    $host = shift || 'localhost';
    $hostinfo = Net::SNMP::HostInfo->new(Hostname => $host);

    print "\nNet To Media Table:\n";
    printf "%-3s %-15s %-17s %s\n",
        qw/If NetAddress PhysAddress Type/;
    for $entry ($hostinfo->ipNetToMediaTable) {
        printf "%-3s %-15s %-17s %s\n",
            $entry->ipNetToMediaIfIndex,
            $entry->ipNetToMediaNetAddress,
            $entry->ipNetToMediaPhysAddress,
            $entry->ipNetToMediaType;
    }

=head1 DESCRIPTION

"Each entry contains one IpAddress to `physical'
address equivalence."

=cut

use 5.006;
use strict;
use warnings;

use Carp;

#our $VERSION = '0.01';

our $AUTOLOAD;

my %oids = (
    ipNetToMediaIfIndex => '1.3.6.1.2.1.4.22.1.1', 
    ipNetToMediaPhysAddress => '1.3.6.1.2.1.4.22.1.2', 
    ipNetToMediaNetAddress => '1.3.6.1.2.1.4.22.1.3', 
    ipNetToMediaType => '1.3.6.1.2.1.4.22.1.4', 
    );

my %decodedObjects = (
    ipNetToMediaType => { qw/1 other 2 invalid 3 dynamic 4 static/ },
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

=item ipNetToMediaIfIndex

"The interface on which this entry's equivalence
is effective.  The interface identified by a
particular value of this index is the same
interface as identified by the same value of
ifIndex."

=item ipNetToMediaPhysAddress

"The media-dependent `physical' address."

=item ipNetToMediaNetAddress

"The IpAddress corresponding to the media-
dependent `physical' address."

=item ipNetToMediaType

"The type of mapping.

Setting this object to the value invalid(2) has
the effect of invalidating the corresponding entry
in the ipNetToMediaTable.  That is, it effectively
dissasociates the interface identified with said
entry from the mapping identified with said entry.
It is an implementation-specific matter as to
whether the agent removes an invalidated entry
from the table.  Accordingly, management stations
must be prepared to receive tabular information
from agents that corresponds to entries not
currently in use.  Proper interpretation of such
entries requires examination of the relevant
ipNetToMediaType object."

Possible values are:

    other(1),        
    invalid(2),      
    dynamic(3),
    static(4)

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
            if ($self->{_decode} && $name eq "ipNetToMediaPhysAddress") {
                $value =~ s/^0x(\w\w)(\w\w)(\w\w)(\w\w)(\w\w)(\w\w)$/$1-$2-$3-$4-$5-$6/;
            }
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
