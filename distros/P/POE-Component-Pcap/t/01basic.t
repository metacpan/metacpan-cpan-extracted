#!/usr/bin/perl
##
## 01basic.t -- Basic testing.  Watches for a single ARP packet
##

use strict;
use Test;

BEGIN { plan tests => 2, }

use POE;

use Net::Pcap ();
use NetPacket::Ethernet qw( :types );
use NetPacket::ARP qw( :opcodes );

use POE::Component::Pcap;

if( $> ) {
  print <<EOT;
##
## WARNING:
## Not running as root; probably won't be able to open the
## capture device.
##
EOT
}

my( $device, $err );
$device = Net::Pcap::lookupdev( \$err )
  or die "Can't lookup default device: $err\n";

ok( 1 );

POE::Session->create(
		     inline_states => {
				       _start => \&start,
				       _stop => sub {
					 $_[KERNEL]->post( pcap => 'shutdown' )
				       },
				       got_packet => \&got_packet,
#				       _signal => \&_signal,
				      },
		    );

$poe_kernel->run;

exit 0;

sub start {
  POE::Component::Pcap->spawn(
			      Alias => 'pcap',
			      Device => $device,
			      Filter => 'arp',
			      Dispatch => 'got_packet',
			      Session => $_[SESSION],
			     );

  $_[KERNEL]->post( pcap => 'run' );

  print STDERR "\n## Waiting for one ARP packet on $device. . .\n";
}

sub _signal {
  print STDERR "\n## Got signal ", $_[ARG0], "\n";

  $_[KERNEL]->post( pcap => 'shutdown' );

  return 1
}

sub got_packet {
  my $packets = $_[ARG0];

  process_packet( @{ $_ } ) foreach( @{$packets} );

  print STDERR "\n## Saw an ARP packet.\n";
  ok( 1 );

  $_[KERNEL]->post( pcap => 'shutdown' );
}

sub process_packet {
  my( $hdr, $pkt ) = @_;

  ## Map arp opcode #'s to strings
  my %arp_opcodes = (
		     ARP_OPCODE_REQUEST, 'ARP Request',
		     ARP_OPCODE_REPLY, 'ARP Reply',
		     RARP_OPCODE_REQUEST, 'RARP Request',
		     RARP_OPCODE_REPLY, 'RARP Reply',
		    );

  my $eth = NetPacket::Ethernet->decode($pkt);
  my $arp =
    NetPacket::ARP->decode( $eth->{data} );

  print STDERR
        join(":", (localtime($hdr->{tv_sec}))[2,1,0]),
        ".", $hdr->{tv_usec}, ": ",
	$arp_opcodes{ $arp->{opcode} }, " ",
        $hdr->{caplen}, " bytes (of ", $hdr->{len}, ")\n";

  print STDERR
        "\tsha: ", _phys( $arp->{sha} ), "\tspa: ", _ipaddr( $arp->{spa} ),
        "\n\ttha: ", _phys( $arp->{tha} ), "\ttpa: ", _ipaddr( $arp->{tpa} ),
	"\n";
}



## Pretty printing subs
sub _ipaddr { join( ".", unpack( "C4", pack( "N", oct( "0x". shift ) ) ) ) }
sub _phys { join( ":", grep {length} split( /(..)/, shift ) ) }

__END__
