#!/usr/bin/perl -w

# original by
#
# C# Network Programming 
# by Richard Blum
#
# Publisher: Sybex 
# ISBN: 0782141765

BEGIN {
	unshift @INC, 'blib/lib', 'blib/arch';
}

use Socket::Class qw/$SOL_SOCKET $SO_RCVTIMEO $SOL_IP $IP_TTL/;
use Time::HiRes ();

if( ! $ARGV[0] ) {
	print "Usage: perl $0 <hostname>\n";
	exit;
}

$host = Socket::Class->new(
	'domain' => 'inet',
	'type' => 'raw',
	'proto' => 'icmp',
) or die "Can't create socket: $!";

$addr = $host->get_hostaddr( $ARGV[0] );
if( ! $addr ) {
	printf "%s: %s\n\n", $ARGV[0], $host->error;
	exit;
}
if( $addr eq $ARGV[0] ) {
	$ARGV[0] = $host->get_hostname( $addr ) || $addr;
}
printf "trace route to %s [%s]\n\n", $ARGV[0], $addr;
$iep = $host->pack_addr( $addr )
	or die $host->error;

$packet = ICMP->new();
$packet->{'type'} = 0x08;
$packet->{'code'} = 0x00;
$packet->{'message'} = "\x00\x01\x00\x01" . "test packet";
$packet->{'checksum'} = $packet->getChecksum();

$host->set_option( $SOL_SOCKET, $SO_RCVTIMEO, 3000 )
	or die $host->error;

$badcount = 0;
for( $i = 1; $i <= 50; $i ++ ) {
	$host->set_option( $SOL_IP, $IP_TTL, $i )
		or die $host->error;
	$timestart = Time::HiRes::time();
	$host->sendto( $packet->getBytes(), $iep )
		or die $host->error;
	$ep = $host->recvfrom( $data, 1024 )
		or undef $ep;
	$timestop = Time::HiRes::time();
	if( ! defined $ep ) {
		$badcount ++;
		printf "%2d\t\t*** no response from remote host ***\n", $i;
		if( $badcount == 5 ) {
			print "\nunable to contact remote host\n";
			last;
		}
		next;
	}
	$response = ICMP->new( $data );
	$addr = $host->unpack_addr( $ep );
	$name = $host->get_hostname( $ep ) || $addr;
	if( $response->{'type'} == 11 ) {
		printf "%2d\t %-15s\t%7.3f ms\t%s\n",
			$i, $addr,
			($timestop - $timestart) * 1000, $name;
	}
	elsif( $response->{'type'} == 0 ) {
		printf "%2d\t %-15s\t%7.3f ms\t%s\n",
			$i, $addr,
			($timestop - $timestart) * 1000, $name;
		printf "\nreached %s [%s] in %d hops\n", $ARGV[0], $addr, $i;
		last;
	}
	$badcount = 0;
}

1;

package ICMP;

sub new {
	my $class = shift;
	my $this = {
		'type' => 0,
		'code' => 0,
		'checksum' => 0,
		'message' => '',
	};
	if( @_ ) {
		my( $data ) = @_;
		$this->{'type'} = ord( substr( $data, 20, 1 ) );
		$this->{'code'} = ord( substr( $data, 21, 1 ) );
		$this->{'checksum'} = ord( substr( $data, 22, 1 ) )
			| (ord( substr( $data, 23, 1 ) ) << 8);
		$this->{'message'} = substr( $data, 24 );
	}
	bless $this, $class;
}

sub getBytes {
	my $this = shift;
	return
		chr( $this->{'type'} ) .
		chr( $this->{'code'} ) .
		chr( $this->{'checksum'} & 0xff ) .
		chr( ($this->{'checksum'} >> 8) & 0xff ) .
		$this->{'message'}
	;
}

sub getChecksum {
	my $this = shift;
	my( $data, $packet_size, $checksum, $index );
	$data = $this->getBytes();
	$packet_size = length( $data );
	$checksum = 0;
	for( $index = 0; $index < $packet_size; ) {
		$checksum += ord( substr( $data, $index ++, 1 ) )
			| (ord( substr( $data, $index ++, 1 ) ) << 8);
	}
	$checksum = ($checksum >> 16) + ($checksum & 0xffff);
	$checksum += ($checksum >> 16);
	return (~$checksum) & 0xffff;
}

1;

__END__
