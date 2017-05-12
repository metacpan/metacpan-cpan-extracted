package Net::Canopy::BAM;

use 5.008008;
use strict;
use warnings;
use Bit::Vector;

use Data::Dumper;

require Exporter;

our $VERSION = '0.04';

=head1 NAME

Net::Canopy::BAM - Identifies, assembles, and disassembles Canopy BAM packets.

=head1 SYNOPSIS

  use Net::Canopy::BAM;

=head1 DESCRIPTION

Common Packet Assembly, Disassembly, and Identification  for the JungleAuth 
(http://code.google.com/p/jungleauth/) implementation of Canopy BAM.

Also provides a BAM test client.

=head1 METHODS

=head3 new

	my $ncb = Net::Canopy::BAM->new();
	
Instantiates Net::Canopy::BAM.

=cut

sub new {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	
	my $self = {
		@_	
	};
	
	return bless $self, $class;
}


=head3 buildQstr

	my $QoSstr = $ncb->buildQstr(
		upspeed => 512,         # Upload speed in Kbps
		downspeed => 1024,      # Download speed in Kbps
		upbucket => 320000,   # Upload bucket size in Kb
		downbucket => 5120000 # Download bucket size in Kb
	);
	
Builds a QoS string. 

=cut

# Take hash of QoS settings and return formatted qosstr
sub buildQstr {
	my ($class, %args) = @_;
	my $tailpad = "0000000000000000000000000000000000000000";
	
	my $upspeed = Bit::Vector->new_Dec(16, $args{upspeed});
	$upspeed = $upspeed->to_Hex();
	
	my $downspeed = Bit::Vector->new_Dec(16, $args{downspeed});
	$downspeed = $downspeed->to_Hex();
	
	my $upbucket = Bit::Vector->new_Dec(32, $args{upbucket});
	$upbucket = $upbucket->to_Hex();
	
	my $downbucket = Bit::Vector->new_Dec(32, $args{downbucket});
	$downbucket = $downbucket->to_Hex();
	
	my $qstr = $upspeed . $downspeed . $upbucket . $downbucket . $tailpad;
	
	return $qstr;
}

=head3 parseQstr

	my $QoShash = $ncb->parseQstr(qstr => $qosstring);

Reads a QoS string and returns its component values as a hashref

=cut

# Return hash of QoS str values
sub parseQstr {
	my ($class, %args) = @_;
	my %qhash=();
	
	my $upspeed = hex(substr($args{qstr}, 0, 4));
		
	my $downspeed = hex(substr($args{qstr}, 4, 4));
	my $upbucket = hex(substr($args{qstr}, 8, 8));
	my $downbucket = hex(substr($args{qstr}, 16, 8));
	
	%qhash = (
		'upspeed', $upspeed, 
		'downspeed', $downspeed,
		'upbucket', $upbucket, 
		'downbucket', $downbucket
	);
	
	return \%qhash;
}

=head3 mkAcceptPacket

	my $packet = $ncb->mkAcceptPacket(
		seq => $sequenceNumber.
		mac => $smMAC,
		qos => $QoSstr
	);
	
Returns a authentication acceptance packet

=cut
# Assemble accept packet
sub mkAcceptPacket {
	my ($class, %args) = @_;
	my $magic1 = "250400000000";
	my $magic2 = "000000670000000100000006";
	my $magic3 = "0000000300000001000000000700000018";
	my $magic4 = "ab8d3702bcc7d757280a7d7848f32e5910bf994e739517c";
	my $qosPre = "60000000600000020";
	my $qosPost = "0000000000000000";
	
	my $seq = sprintf("%04x", $args{seq});
	
	my $packet = $magic1 . $seq . $magic2 . $args{mac} . $magic3 . $magic4 . $qosPre . 
		$args{qos} . $qosPost;
	$packet = pack('H*', $packet);
	
	return $packet;
}

=head3 mkRejectPacket

	my $packet = $ncb->mkRejectPacket(
		seq => $sequenceNumber,
		mac => $smMAC
	);

Returns a rejection response packet.

=cut

# Assemble reject packet
sub mkRejectPacket {
	my ($class, %args) = @_;

	my $magic1 = "230400000000";
	my $magic2 = "000000370000000100000006";
	my $magic3 = "0000000300000001010000000400000010000000000000000000000000000000000000000000000000";
	
	my $seq = sprintf("%04x", $args{seq});
	
	my $packet = $magic1 . $seq . $magic2 . $args{mac} . $magic3;
	$packet = pack('H*', $packet);
	
	return $packet;
}

=head3 mkConfirmPacket 

  my $packet = $ncb->mkConfirmPacket(confirmation_token);

=cut
# Assemble confirmation packet
sub mkConfirmPacket {
  my ($class, $token) = @_;

  my $magic1 = "46000000";
  
  my $packet = $magic1 . $token;
  $packet = pack('H*', $packet);

  return $packet;
}

=head3 parsePacket

	my $parsedPacket = $ncb->parsePacket(packet => $packet);

Identify packet and parse out data. Returns packet type and data as hashref

=head4 Packet types

=over

=item authreq

Authentication request from AP

=over

=item type - packet type

=item sm - SM MAC address

=item ap - AP MAC address

=item luid - SM LUID on AP

=item seq - Packet sequence number

=back

=item authchal-1

Authentication challange from AP

=item authchal-2

Second Authentication challange from AP

=item authgrant

Authentication grant

=item authverify

=over

=item token - verification session token

=back

Authentication verification

=item authconfirm

Authentication confirmation

=back

=cut

sub parsePacket {
	my ($class, %args) = @_;
	my %pinfo = ();
		
	my $packet = unpack('H*', $args{packet});
	my $type = substr($packet, 0, 2);
	
	if ($type eq '01') { # Auth request
		$pinfo{'type'} = 'authreq';
		
		$pinfo{'sm'} = substr($packet, 2, 12);
		$pinfo{'ap'} = substr($packet, 14, 12);
		$pinfo{'luid'} = hex(substr($packet, 30, 2));
		$pinfo{'seq'} = hex(substr($packet, 36, 4));
			
	} elsif ($type eq '23') { # Auth Challange APAS->AP or Rejection APAS->AP
		$pinfo{'type'} = 'authchal-1';
		
	} elsif ($type eq '24') { # Auth Challange AP->APAS
		$pinfo{'type'} = 'authchal-2';
		
	} elsif ($type eq '25') { # Auth grant
		$pinfo{'type'} = 'authgrant';
		
	} elsif ($type eq '45') { # Auth verify
		$pinfo{'type'} = 'authverify';
		
		$pinfo{'magic1'} = substr($packet, 0, 8);
    $pinfo{'token'} = substr($packet, 8, 16);
    $pinfo{'magic2'} = substr($packet, 16, 8);
		$pinfo{'sm'} = substr($packet, 24, 12);
		$pinfo{'magic3'} = substr($packet, 36, 214);
		
	} elsif ($type eq '46') { # Auth confirm
		$pinfo{'type'} = 'authconfirm';
		
	} else {
		print "Unknown packet: $packet\n";	
	}
	
	return \%pinfo;
}

1;
__END__

=head1 SEE ALSO

Canopy BAM User Guide, Issue 4/BAM 1.1

See http://code.google.com/p/jungleauth/ for wiki, bug reports, svn, etc.

=head1 AUTHOR

Jonathan Auer, E<lt>jda@tapodi.netE<gt>

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2010 by Jonathan Auer

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

=cut
