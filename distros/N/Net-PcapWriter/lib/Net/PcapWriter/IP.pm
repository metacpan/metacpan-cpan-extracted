use strict;
use warnings;
package Net::PcapWriter::IP;
use Socket qw(AF_INET AF_INET6);

use base 'Exporter';
# re-export the usable inet_pton
our @EXPORT = qw(ip_chksum ip4_packet ip6_packet ip_packet inet_pton);


my $do_chksum = 1;
sub calculate_checksums { $do_chksum = $_[1] }

BEGIN { 
    # inet_pton is in Socket since 5.12
    # but even if it is in Socket it can throw a non-implemented error
    eval {
	Socket->import('inet_pton');
	inet_pton(AF_INET,'127.0.0.1');
	inet_pton(AF_INET6,'::1');
	1
    } or eval {
	require Socket6;
	Socket6->import('inet_pton');
	inet_pton(AF_INET,'127.0.0.1');
	inet_pton(AF_INET6,'::1');
	1
    } or die "you need either a modern perl or Socket6"
}


# construct IPv4 packet or packet generating sub
sub ip4_packet {
    my ($data,$src,$dst,$protocol,$chksum_offset,$no_pseudo_header) = @_;
    my $hdr = pack('CCnnnCCna4a4',
	0x45,             # version 4, len=5 (no options)
	0,                # type of service
	defined($data) ? length($data)+20 : 20, # total length
	0,0,              # id=0, not fragmented
	128,              # TTL
	$protocol,
	0,                # checksum - computed later
	scalar(inet_pton(AF_INET,$src) || die "no IPv4 $src"),
	scalar(inet_pton(AF_INET,$dst) || die "no IPv4 $dst"),
    );

    if (defined $data) {
	return $hdr.$data if ! $do_chksum;
	if (defined $chksum_offset) {
	    my $ckdata = $no_pseudo_header ? $data :
		substr($hdr,-8).pack('xCna*',
		    $protocol,length($data),  # proto + len
		    $data
		);
	    substr($data,$chksum_offset, 2) = pack('n',ip_chksum($ckdata));
	}
	substr($hdr,10,2) = pack('n',ip_chksum($hdr));
	return $hdr.$data;
    }

    # data not defined, return sub which creates packet once data are known
    if (!$do_chksum) {
	return sub {
	    substr(my $lhdr = $hdr,2,2) = pack('n',length($_[0])+20);
	    return $lhdr.$_[0];
	};
    }

    if (! defined $chksum_offset) {
	return sub {
	    substr(my $lhdr = $hdr,2,2) = pack('n',length($_[0])+20);
	    substr($lhdr,10,2) = pack('n',ip_chksum($lhdr));
	    return $lhdr.$_[0];
	};
    }
    return sub {
	my $data = shift;
	my $ckdata = $no_pseudo_header ? $data : 
	    substr($hdr,-8).pack('xCna*',
		$protocol,length($data),  # proto + len
		$data
	    );
	substr($data,$chksum_offset, 2) = pack('n',ip_chksum($ckdata));
	substr(my $lhdr = $hdr,2,2) = pack('n',length($data)+20);
	substr($lhdr,10,2) = pack('n',ip_chksum($lhdr));
	return $lhdr.$data;
    };
}

# construct IPv6 packet
sub ip6_packet {
    my ($data,$src,$dst,$protocol,$chksum_offset) = @_;
    my $hdr = pack('NnCCA16A16',
	6 << 28 | 0 << 20 | 0,       # version, traffic class, flow label
	defined($data) ? length($data) : 0,  # length of payload
	$protocol,                   # next header = protocol
	128,                         # hop limit
	scalar(inet_pton(AF_INET6,$src) || die "no IPv6 $src"),
	scalar(inet_pton(AF_INET6,$dst) || die "no IPv6 $dst"),
    );

    if (defined $data) {
	# return packet
	if ($do_chksum && defined $chksum_offset) {
	    my $ckdata = substr($hdr,-32).pack('NxxxCa*',
		length($data), $protocol, # len + proto
		$data
	    );
	    substr($data,$chksum_offset, 2) = pack('n',ip_chksum($ckdata));
	}
	return $hdr.$data;
    }

    # data not defined, return sub which creates packet once data are known
    if (! defined $chksum_offset) {
	return sub {
	    substr($hdr,4,2) = pack('n',length($_[0]));
	    return $hdr.$_[0]
	}
    }
    return sub {
	my $data = shift;
	substr($hdr,4,2) = pack('n',length($data));
	if ($do_chksum) {
	    my $ckdata = substr($hdr,-32).pack('NxxxCa*',
		length($data), $protocol, # len + proto
		$data
	    );
	    substr($data,$chksum_offset, 2) = pack('n',ip_chksum($ckdata));
	}
	return $hdr.$data;
    };
}

sub ip_packet {
    goto &ip6_packet if $_[1] =~m{:};
    goto &ip4_packet;
}

sub ip_chksum16 {
    my $data = pop;
    $data .= "\x00" if length($data) % 2; # padding
    my $sum = 0;
    $sum += $_ for (unpack('n*', $data));
    $sum = ($sum >> 16) + ($sum & 0xffff);
    $sum = ~(($sum >> 16) + $sum) & 0xffff;
    return $sum;
}

sub ip_chksum32 {
    my $data = pop;
    $data .= "\x00" x (4 - length($data) % 4); # padding
    my $sum = 0;
    $sum += $_ for unpack('N*', $data);
    $sum = ($sum >> 16) + ($sum & 0xffff);
    $sum = ($sum >> 16) + ($sum & 0xffff);
    $sum = ($sum >> 16) + ($sum & 0xffff);
    return ~$sum;
}

require Config;
*ip_chksum = $Config::Config{ivsize} == 8 ? \&ip_chksum32 : \&ip_chksum16;

1;
