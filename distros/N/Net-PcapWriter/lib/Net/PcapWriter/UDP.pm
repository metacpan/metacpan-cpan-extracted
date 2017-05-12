
use strict;
use warnings;
package Net::PcapWriter::UDP;
use fields qw(flow l2prefix pktmpl writer);
use Net::PcapWriter::IP;
use Socket qw(AF_INET IPPROTO_UDP);

sub new {
    my ($class,$writer,$src,$sport,$dst,$dport) = @_;
    my $self = fields::new($class);
    $self->{flow} = [
	# src, dst, sport, dport
	[ $src,$dst,$sport,$dport ],
	[ $dst,$src,$dport,$sport ],
    ];
    $self->{writer} = $writer;
    $self->{l2prefix} = $self->{writer}->layer2prefix($src);
    $self->{pktmpl} = [
	ip_packet( undef, $src, $dst, IPPROTO_UDP, 6),
	ip_packet( undef, $dst, $src, IPPROTO_UDP, 6),
    ];
    return $self;
}

sub write {
    my ($self,$dir,$data,$timestamp) = @_;
    my $flow = $self->{flow}[$dir];

    my $udp = pack("nnnna*",
	$flow->[2],$flow->[3],       # sport,dport
	length($data)+8,
	0,                           # checksum
	$data                        # payload
    );

    $self->{writer}->packet(
	$self->{l2prefix} . $self->{pktmpl}[$dir]($udp),
	$timestamp
    );
}

1;


