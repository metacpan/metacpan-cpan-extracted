use strict;
use warnings;

package Net::PcapWriter::TCP;
use fields qw(flow writer l2prefix pktmpl last_timestamp connected);

use Net::PcapWriter::IP;
use Socket qw(AF_INET IPPROTO_TCP);

sub new {
    my ($class,$writer,$src,$sport,$dst,$dport) = @_;
    my $self = fields::new($class);
    $self->{flow} = [
	# src, dst, sport, dport, state, sn
	# state = 0bFfSs: acked [F]in|send [f]in|acked [S]yn|send [s]yn
	# sn gets initialized on sending SYN
	[ $src,$dst,$sport,$dport,0,     undef ],
	[ $dst,$src,$dport,$sport,0,     undef ],
    ];
    $self->{writer} = $writer;
    $self->{last_timestamp} = undef;
    $self->{l2prefix} = $self->{writer}->layer2prefix($src);
    $self->{pktmpl} = [
	ip_packet( undef, $src, $dst, IPPROTO_TCP, 16),
	ip_packet( undef, $dst, $src, IPPROTO_TCP, 16),
    ];
    return $self;
}

sub write_with_flags {
    my ($self,$dir,$data,$flags,$timestamp) = @_;
    $flags ||= {};
    my $flow = $self->{flow}[$dir];

    if ($flags->{syn} and ($flow->[4] & 0b0001) == 0) {
	$flow->[4] |= 0b0001;
	$flow->[5] ||= rand(2**32);
    }
    my $sn = $flow->[5];

    if ($flags->{rst}) {
	# consider closed
	$flow->[4] |= 0b1100;
	$self->{flow}[$dir?0:1][4] |= 0b1100;
    }
    if ($flags->{fin}) {
	if (($flow->[4] & 0b0100) == 0) {
	    $flow->[4] |= 0b0100;
	    $flow->[5]++
	}
    }
    if ($flags->{ack}) {
	my $oflow = $self->{flow}[$dir?0:1];
	$flow->[4] |= 0b0010 if $oflow->[4] & 0b0001; # ACK the SYN
	$flow->[4] |= 0b1000 if $oflow->[4] & 0b0100; # ACK the FIN
    }

    return if ! defined $data; # only update state

    my $ack = $self->{flow}[$dir?0:1][5];
    $flags->{ack} = 1 if defined $ack;

    my $f = 0;
    $f |= 0b000100 if $flags->{rst};
    $f |= 0b001000 if $flags->{psh};
    $f |= 0b010000 if $flags->{ack};
    $f |= 0b100000 if $flags->{urg};
    $f |= 0b000001 if $flags->{fin};
    if ( $flags->{syn} ) {
	$f |= 0b000010;
	$sn = ($sn-1) % 2**32;
    }

    if (defined $flags->{_seq}) {
	$sn = ($sn + $flags->{_seq}) % 2**32; # seq=-1 for keep-alive
    }

    my $tcp = pack("nnNNCCnnna*",
	$flow->[2],$flow->[3],       # sport,dport
	$sn,                         # sn
	$ack||0,                     # ack
	0x50,                        # size of TCP header >> 4
	$f,                          # flags
	$flags->{window} || 2**15,   # window
	0,                           # checksum computed later
	$flags->{urg}||0,            # urg pointer
	$data                        # payload
    );

    $flow->[5] = (
	$flow->[5]
	+ length($data)
    ) % 2**32;
    $self->{last_timestamp} = $timestamp;
    $self->{writer}->packet(
	$self->{l2prefix} . $self->{pktmpl}[$dir]($tcp),
	$timestamp
    );
}

sub write {
    my ($self,$dir,$data,$timestamp) = @_;
    _connect($self,$timestamp) if ! $self->{connected};
    write_with_flags($self,$dir,$data,undef,$timestamp);
}

sub keepalive_probe {
    my ($self,$dir,$timestamp) = @_;
    die "not connected" if ! $self->{connected};
    write_with_flags($self,$dir,'',{ _seq => -1 },$timestamp);
}

sub _connect {
    my ($self,$timestamp) = @_;
    my $flow = $self->{flow};
    goto done if ($flow->[1][4] & 0b11) == 0b11
	&& ($flow->[0][4] & 0b11) == 0b11;

    # client: SYN
    write_with_flags($self,0,'',{ syn => 1 },$timestamp) 
	if ($flow->[0][4] & 0b01) == 0;

    # server: SYN+ACK
    write_with_flags($self,1,'',{ 
	($flow->[1][4] & 0b01) == 0 ? ( syn => 1 ):(),
	($flow->[1][4] & 0b10) == 0 ? ( ack => 1 ):(),
    },$timestamp) if ($flow->[1][4] & 0b11) != 0b11;

    # client: ACK
    write_with_flags($self,0,'',{ ack => 1 },$timestamp) 
	if ($flow->[0][4] & 0b10) == 0;

    done:
    $self->{connected} = 1;
}

sub connect {
    my ($self,$timestamp) = @_;
    _connect($self,$timestamp) if ! $self->{connected};
}

sub shutdown {
    my ($self,$dir,$timestamp) = @_;
    if (($self->{flow}[$dir][4] & 0b0100) == 0) {
	_connect($self,$timestamp) if ! $self->{connected};
	write_with_flags($self,$dir,'',{ fin => 1 },$timestamp);
	write_with_flags($self,$dir ? 0:1,'',{ ack => 1 },$timestamp);
    }
}

sub close {
    my ($self,$dir,$type,$timestamp) = @_;
    my $flow = $self->{flow};

    if (!defined $type or $type eq '') {
	# simulate close only - don't write any packets
	$flow->[0][4] |= 0b1100;
	$flow->[1][4] |= 0b1100;

    } elsif ($type eq 'fin') {
	# $dir: FIN
	write_with_flags($self,$dir,'',{ fin => 1 },$timestamp)
	    if ($flow->[$dir][4] & 0b0100) == 0;

	# $odir: FIN+ACK
	my $odir = $dir?0:1;
	write_with_flags($self,$odir,'',{
	    ($flow->[$odir][4] & 0b0100) == 0 ? ( fin => 1 ):(),
	    ($flow->[$odir][4] & 0b1000) == 0 ? ( ack => 1 ):(),
	},$timestamp) if ($flow->[$odir][4] & 0b1100) != 0b1100;

	# $dir: ACK
	write_with_flags($self,$dir,'',{ ack => 1 },$timestamp)
	    if ($flow->[$dir][4] & 0b1000) == 0;

    } elsif ($type eq 'rst') {
	# single RST and then connection is closed
	write_with_flags($self,$dir,'',{ rst => 1 },$timestamp);

    } else {
	die "only fin|rst|undef are allowed with close"
    }
}

sub ack {
    my ($self,$dir,$timestamp) = @_;
    write_with_flags($self,$dir,'',{ ack => 1 },$timestamp);
}

sub DESTROY {
    my $self = shift;
    $self->{writer} or return; # happens in global destruction
    &close($self,0,'fin',$self->{last_timestamp});
}


1;


