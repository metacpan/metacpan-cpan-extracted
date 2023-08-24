use strict;
use warnings;
package Net::PcapWriter;
use Time::HiRes 'gettimeofday';
use Net::PcapWriter::TCP;
use Net::PcapWriter::UDP;
use Net::PcapWriter::ICMP_Echo;

our $VERSION = '0.725';

sub new {
    my ($class,$file) = @_;
    my $self = bless { fh => undef },$class;
    $self->reopen($file);
    return $self;
}

sub reopen {
    my ($self,$file) = @_;
    my $fh;
    if ( $file ) {
	if ( ref($file)) {
	    $fh = $file
	} else {
	    open($fh,'>',$file) or die "open $file: $!";
	    binmode($fh);
	}
    } else {
	$fh = \*STDOUT;
    }
    $self->{fh} = $fh;
    $self->_header;
}

# write pcap header
sub _header {
    my $self = shift;

    # struct pcap_file_header {
    #     bpf_u_int32 magic;
    #     u_short version_major;
    #     u_short version_minor;
    #     bpf_int32 thiszone; /* gmt to local correction */
    #     bpf_u_int32 sigfigs;    /* accuracy of timestamps */
    #     bpf_u_int32 snaplen;    /* max length saved portion of each pkt */
    #     bpf_u_int32 linktype;   /* data link type (LINKTYPE_*) */
    # };

    print {$self->{fh}} pack('LSSlLLL',
	0xa1b2c3d4, # magic
	2,4,        # major, minor
	0,0,        # timestamps correction and accuracy
	0xffff,     # snaplen
	1,          # DLT_EN10MB
    );
}

sub layer2prefix {
    my $ip = pop;
    return pack("NnNnn",
	0,1,0,1, # all macs 0:*
	$ip =~m{:} ? 0x86dd: 0x0800, # ETH_TYPE_IP6 | ETH_TYPE_IP
    );
}

# write pcap packet
sub packet {
    my ($self,$data,$timestamp) = @_;
    $timestamp ||= [ gettimeofday() ];

    # struct pcap_pkthdr {
    #     struct timeval ts;  /* time stamp */
    #     bpf_u_int32 caplen; /* length of portion present */
    #     bpf_u_int32 len;    /* length this packet (off wire) */
    # };

    my ($tsec,$tmsec);
    if (ref($timestamp)) {
	# array like in Time::HiRes
	($tsec,$tmsec) = @$timestamp; 
    } else {
	$tsec = int($timestamp);
	$tmsec = int(($timestamp - $tsec)*1_000_000);
    }

    print {$self->{fh}} pack('LLLLa*',
	$tsec,$tmsec,       # struct timeval ts
	length($data),      # caplen
	length($data),      # len
	$data,              # data
    );
}


# return new TCP connection object
sub tcp_conn {
    my ($self,$src,$sport,$dst,$dport) = @_;
    return Net::PcapWriter::TCP->new($self,$src,$sport,$dst,$dport);
}

# return new UDP connection object
sub udp_conn {
    my ($self,$src,$sport,$dst,$dport) = @_;
    return Net::PcapWriter::UDP->new($self,$src,$sport,$dst,$dport);
}

# return new ICMP_Echo "connection" object
sub icmp_echo_conn {
    my ($self,$src,$dst,$id) = @_;
    return Net::PcapWriter::ICMP_Echo->new($self,$src,$dst,$id);
}

1;

__END__

=head1 NAME

Net::PcapWriter - simple creation of pcap files from code

=head1 SYNOPSIS

 use Net::PcapWriter;

 # disabling checksum calculation leads to huge performance boost
 Net::PcapWriter::IP->calculate_checksums(0);

 my $writer = Net::PcapWriter->new('test.pcap');
 my $conn = $writer->tcp_conn('1.2.3.4',1234,'5.6.7.8',80);

 # this will automatically add syn..synack..ack handshake to pcap
 # each write will be a single packet
 $conn->write(0,"POST / HTTP/1.0\r\nContent-length: 3\r\n\r\n");
 $conn->ack(1); # force ack from server

 # send another packet w/o forcing ack
 $conn->write(0,"abc");

 # client will no longer write
 $conn->shutdown(0);

 # this will automatically add ack to last packet
 $conn->write(1,"HTTP/1.0 200 Ok\r\nContent-length: 10\r\n\r\n");
 $conn->write(1,"0123456789");

 # will automatically add remaining FIN+ACK
 undef $conn;

 # write some UDP packets with IPv6
 $conn = $writer->udp_conn('dead::beaf',1234,'beaf::dead',53);
 $conn->write(0,"....");
 $conn->write(1,"....");

 # write a ping exchange (works also with IPv6)
 $conn = $writer->icmp_echo_conn('1.2.3.4','5.6.7.8',10);
 $conn->ping(1,"foo");
 $conn->ping(2,"bar");
 $conn->pong(1,"foo");


=head1 DESCRIPTION

With L<Net::PcapWriter> it is possible to create pcap files within a program
without capturing any data. This is useful for setting up test data without
setting up the needed infrastructure for data creation and capturing.

The following methods are supported:

=over 4

=item $class->new([$filename|$handle])

Creates new object.
If file name is given it will be opened for writing, if file handle is given it
will be used. Otherwise the pcap data will be written to STDOUT.
Will write pcap header for DLT_RAW to pcap file.

=item $class->reopen([$filename|$handle])

This will close the current pcap file and open a new one. No connections will
be implicitely closed, i.e. they will continue inside the new pcap file. The
main purpose is to be able to rotate the file after some time or size.

=item $writer->packet($pkt,[$timestamp])

Will write raw Layer 2 packet $pkt with $timestamp in pcap file.
$timestamp can be C<time_t> (seconds), float (like C<time_t>, but with higher
resolution) or C<<[$sec,$msec]>> like in C<<struct timeval>>.
If $timestamp is not given will use C<Time::HiRes::gettimeofday>.

To get the Layer 2 prefix in case of IP data use C<$writer->layer2prefix($ip)>.

=item $writer->tcp_conn($src,$sport,$dst,$dport)

Will return C<Net::PcapWriter::TCP> object, which then provides the following
methods:

=over 8

=item $tcpconn->write($dir,$data,[$timestamp])

Will write the given data for the direction C<$dir> (0 are data from client to
server, 1 the other way). Will write TCP handshake if not done yet.

=item $tcpconn->ack($dir,[$timestamp])

Will write an empty message with an ACK from direction C<$dir>.

=item $tcpconn->keepalive_probe($dir,[$timestamp])

Will write a TCP keep-alive probe from direction C<$dir>, i.e. a packet with
no payload and a sequence number one less than expected. To reply to this
probe the peer should just ack it.

=item $tcpconn->shutdown($dir,[$timestamp])

Will add FIN+ACK for shutdown from direction C<$dir> unless already done.

=item $tcpconn->write_with_flags($dir,$data,\%flags,[$timestamp])

Write a TCP packet with specific flags, like 
C<<{ syn => 1, ack => 1 }>>. This is also internally used to
automatically add the initial handshake (i.e SYN from client, SYN+ACK from
server and SYN+ACK from client) and the close of the connection (FIN), whereby
the close can be easier handled with C<shutdown>.

Possible flags are syn, ack, fin, rst, psh and rst.

If C<$data> is undef only the internal state regarding the flags will be set.

=item $tcpconn->close($dir,$flag,[$timestamp]);

Close the connection. C<$dir> is the side which initiates the close and C<$flag>
is how the connection is closed, i.e. C<'fin'>, C<'rst'> or C<''>. In the last
case no data will be written but only the internal state will be set to mark the
connection as closed. This way no more closing data will be written on DESTROY
of the object.

Note that the DESTROY of the object will automatically write a normal close
(with FIN) if the connection is not yet considered closed and thus an explicit
close is only needed if one needs more explicit control how the closing should
look like.

=item $tcpconn->connect($dir,[$timestamp])

This will explicitely open the connection (3-way handshake) unless it is already
open. This will be implicitely done if the connection is not fully open in case
of C<write> or C<shutdown> so usually it is not necessary to call this function
explicitely.

=item undef $tcpconn

Will call shutdown for both C<$dir> before destroying connection object.

=back

=item $writer->udp_conn($src,$sport,$dst,$dport)

Will return C<Net::PcapWriter::UDP> object, which then provides the following
methods:

=item $tcpconn->write($dir,$data,[$timestamp])

Will write the given data for the direction C<$dir> (0 are data from client to
server, 1 the other way).

=item $writer->icmp_echo_conn($src,$dst,[$id])

Will return C<Net::PcapWriter::ICMP_Echo> object which provides a connection
with echo request and reply using the identifier $id (default 0). This object
can handle echo request/reply for ICMP and ICMPv6.
It has the following methods:

=item $echo->ping($seq,$data,[$timestamp])

Will write an ICMP echo request from connection source to destination with
sequence $seq and data $data.

=item $echo->pong($seq,$data,[$timestamp])

Will write an ICMP echo reply from connection destination to source with
sequence $seq and data $data.

=back

Additionally a huge performance boost can be reached by disabling checksum
calculation:

   Net::PcapWriter::IP->calculate_checksums(0);

=head1 AUTHOR

Steffen Ullrich <sullr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Steffen Ullrich.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
