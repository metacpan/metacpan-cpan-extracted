############################################################################
# UDP
# handles single udp packets, but can also maintain virtual flows
# between the same src,dst ip:port
############################################################################
use strict;
use warnings;
package Net::Inspect::L4::UDP;
use base 'Net::Inspect::Flow';
use fields qw(conn);
use Net::Inspect::Debug qw( debug trace );

# field conn
# hash indexed by {saddr,sport,daddr,dport} with connection object as value

sub new {
    my ($class,$flow) = @_;
    my $self = $class->SUPER::new($flow);
    $self->{conn} = {};
    return $self;
}

sub pktin {
    my Net::Inspect::L4::UDP $self = shift;
    my ($pkt,$meta) = @_;
    return if $meta->{proto} != 17; # handles only udp

    # extract UDP header
    my ($sport,$dport,$len,$chksum) = unpack('nnnn',$pkt);

    # payload
    my $buf = substr($pkt,8);

    my $saddr = $meta->{saddr};
    my $daddr = $meta->{daddr};

    # find or create connection
    my ($conn,$dir);
    if ( $conn = $self->{conn}{$saddr,$sport,$daddr,$dport} ) {
	$dir = 0;
	debug("found conn $conn $saddr.$sport -> $daddr.$dport");
    } elsif ( $conn = $self->{conn}{$daddr,$dport,$saddr,$sport} ) {
	$dir = 1;
	# saddr should point to client all time..
	($saddr,$sport,$daddr,$dport) = ($daddr,$dport,$saddr,$sport);
	debug("found conn $conn $saddr.$sport <- $daddr.$dport");
    } else {
	$dir = 0
    }

    # if we have an existing connection we are done after forwarding data
    # thru it
    if ( $conn ) {
	$conn->pktin($dir,$buf,$meta->{time});
	return 1;
    }

    # otherwise just forward packet
    $conn = $self->{upper_flow}->pktin($buf,{
	%$meta,
	sport => $sport,
	dport => $dport,
    });

    # if pktin returns an connection object set the connection for
    # further packets
    $self->{conn}{$saddr,$sport,$daddr,$dport} = $conn if $conn;

    return 1;
}

sub expire {
    my ($self,$time) = @_;
    while (my ($k,$conn) = each %{$self->{conn}} ) {
	$conn->expire($time) or next;
	delete $self->{conn}{$k}
    }
}


1;

__END__

=head1 NAME

Net::Inspect::L4::UDP - get IP data,i extract UDP packets and optionally
maintain UDP connections.


=head1 SYNOPSIS

 my $udp = Net::Inspect::L4::UDP->new;
 my $raw = Net::Inspect::L3::IP->new($udp);
 $tcp->pktin($data,\%meta);

=head1 DESCRIPTION

Gets IP packets via C<pktin> method and handles connections.

Provides the hooks required by C<Net::Inspect::L3::IP>.
Will forward data to upper layer. If upper layer returned an connection
object it will feed it with further packets for this connection.

Hooks provided:

=over 4

=item pktin($pkt,$meta)

=back

Hooks called on the attached flow object:

=over 4

=item pktin($data,\%meta)

called when no connection object exist for the src+dst tuple.
Meta data are saddr, sport, daddr, dport and time.

If it returns an object this will be used as the connection object for further
packets. Otherwise it should return false.

=back

Methods called on the connection object:

=over 4

=item pktin($dir,$data,$time)

Will be called on each new packet for connection.
Return code will be ignored.

=item expire($time)

returns true if the connection expired and should be deleted.
$time is the current time

=back

Other methods

=over 4

=item expire($time)

calls C<expire> on all known connection objects

=back

=head1 LIMITS

You need to regularly call C<< $udp->expire($current_time) >> otherwise no connections
will be expired.
