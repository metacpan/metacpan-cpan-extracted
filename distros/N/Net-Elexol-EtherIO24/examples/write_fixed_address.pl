#!/usr/bin/perl
# Retrieves/writes the "fixed" IP address from/to an Elexol Ether I/O 24
# device.
#
# Of course, it relies on said device currently having a reachable address,
# eg, from DHCP.
#
# Not my best code - it was hacked up in a hurry, but it seems to work.
#
# (c) 2008 Chris Luke
#
# Use freely. Retain copyright.
#

use strict;

use Getopt::Long;
use IO::Socket;

# Validate an IP address. Bitch & return 0 if it isn't. 1 otherwise.
sub valid_ip_address($) {
	my $addr = shift;
	my $valid = 1;
	my @bits = split(/\./, $addr);

	if(scalar(@bits) != 4) {
		$valid = 0;
	} else {
		foreach my $bit (@bits) {
			if($bit !~ /^\d+$/) {
				$valid = 0;
				last;
			}
			if($bit < 0 || $bit > 255) {
				$valid = 0;
				last;
			}
		}
	}

	if(!$valid) {
		print STDERR "ERROR: Address \"$addr\" is not a valid IPv4 address.\n";
		return 0;
	}
	return 1;
}

my $current_addr = 0;
my $new_addr = 0;
my $udp_port = 2424;
my $write = 0;
my $enable = 0;
my $disable = 0;
my $reboot = 0;
my $debug = 0;
my $help = 0;

if(!GetOptions(
	'current=s'	=> \$current_addr,
	'new=s'		=> \$new_addr,
	'udpport=i'	=> \$udp_port,
	'write!'	=> \$write,
	'enable!'	=> \$enable,
	'disable!'	=> \$disable,
	'reboot!'	=> \$reboot,
	'debug'		=> \$debug,
	'help'		=> \$help,
) ||
		$help ||
		!$current_addr || !valid_ip_address($current_addr) ||
		($new_addr && !valid_ip_address($new_addr)) ||
		($enable && $disable)) {
	my $h_write = ($write?"do":"don't");
	my $h_enable = ($enable?"do":"don't");
	my $h_disable = ($disable?"do":"don't");
	my $h_reboot = ($reboot?"do":"don't");
	print STDERR <<EOT;

Usage: $0 [options]

--current=<ip-address>*    The *current* IP address of an Elexol Ether IO 24.
--new=<ip-address>         The desired *new* and *fixed* address of the device.

--udpport=<number>         UDP port to talk to. [$udp_port]

--[no]write                Do [don't] actually write any changes. [$h_write]

--[no]enable               Do [don't] enable the fixed IP addreess [$h_enable]
--[no]disable              Do [don't] disable the dixed IP address [$h_disable]

--[no]reboot               Do [don't] reboot the device after programming.
                           (Changes don't take effect till a reboot or a
                           powercycle) [$h_reboot]

--debug                    Some debugging output.
--help                     This message.

* Indicates a mandatory parameter.

"enable" and "disable" are mutually exclusive.

EOT
	exit 1;
}

my $socket = IO::Socket::INET->new(
	PeerAddr => 	$current_addr,
	PeerPort => 	$udp_port,
	Proto => 	'udp',
	ReuseAddr => 	1,
);
if(!$socket) {
	print STDERR "ERROR: Unable to create a socket to talk to '$current_addr:$udp_port': $!\n";
	exit 1;
}

my $pkt;

sub dump_packet($) {
	my $packet = shift;

	my $offset = 0;
	my $incr = 16;

	while($offset < length($packet)) {
		my $l = substr($packet, $offset, $incr);
		my $hexstr = join(' ', map { sprintf "%02.2x", $_ } unpack("C*", $l));
		my $ascstr = $l;
		$ascstr =~ s/\W/./g;

		my $hexlen = ($incr*3)-1;
		printf("%4.4s  %-${hexlen}.${hexlen}s  %s\n", $offset, $hexstr, $ascstr);

		$offset += $incr;
	}
}

sub get_packet($) {
	my $socket = shift;

	my $pkt;
	print "Waiting for packet...\n" if($debug);
	if(!$socket->recv($pkt, 16)) {
		print STDERR "ERROR: Unable to read from socket: $!\n";
		exit 1;
	}
	if($debug) {
		print "Received ".length($pkt)." byte packet:\n";
		dump_packet($pkt);
	}
	return $pkt;
}

# Desconstruct IP address
my @quad = split('\.', $new_addr, 4);
my @pquad = (0,0,0,0);

if($write && $new_addr) {
	print "Enable config writes...\n" if($debug);
	$pkt = "'1".pack('C*', 0x00, 0xaa, 0x55);
	$socket->send($pkt);
	
	print "Write fixed address hi-word (".sprintf("%02.2x, %02.2x", $quad[1], $quad[0]).")...\n";

	$pkt = "'W".pack('C*', 0x06, $quad[1], $quad[0]);
	$socket->send($pkt);
	
	sleep 1;

	print "Write fixed address lo-word (".sprintf("%02.2x, %02.2x", $quad[3], $quad[2]).")...\n";

	$pkt = "'W".pack('C*', 0x07, $quad[3], $quad[2]);
	$socket->send($pkt);

	print "Disable config writes...\n" if($debug);
	$pkt = "'0".pack('C*', 0x00, 0xaa, 0x55);
	$socket->send($pkt)
}

sleep 1;

# Verify hi-word:

$pkt = "'R".pack('C*', 0x06, 0x00, 0x00);
$socket->send($pkt);

if(!(my $pkt = get_packet($socket))) {
	print STDERR "ERROR: Didn't receive packet!\n";
	exit 1;
} else {
	my ($c, $addr, $b1, $b0) = unpack('C4', $pkt);
	printf("c: %c  addr: %x  b0: %02.2x b1: %02.2x\n", $c, $addr, $b0, $b1) if($debug);
	if($addr != 0x06) {
		print STDERR "ERROR: Reply is not for expected EEPROM address!\n";
		exit 1;
	}
	$pquad[0] = $b0;
	$pquad[1] = $b1;
}

# Verify lo-word:

$pkt = "'R".pack('C*', 0x07, 0x00, 0x00);
$socket->send($pkt);

if(!(my $pkt = get_packet($socket))) {
	print STDERR "ERROR: Didn't receive packet!\n";
	exit 1;
} else {
	my ($c, $addr, $b1, $b0) = unpack('C4', $pkt);
	printf("c: %c  addr: %x  b0: %02.2x b1: %02.2x\n", $c, $addr, $b0, $b1) if($debug);
	if($addr != 0x07) {
		print STDERR "ERROR: Reply is not for expected EEPROM address!\n";
		exit 1;
	}
	$pquad[2] = $b0;
	$pquad[3] = $b1;
}

my $paddr = join('.', @pquad);
print "Addr in EEPROM is \"$paddr\"\n";

if($new_addr && $paddr ne $new_addr) {
	print STDERR "ERROR: Address in EEPROM doesn't match requested address!\n";
	exit 1;
}

if($write && ($enable || $disable)){
	print "Enable config writes...\n" if($debug);
	$pkt = "'1".pack('C*', 0x00, 0xaa, 0x55);
	$socket->send($pkt);

	print "Enable fixed IP address...\n" if($enable);
	print "Disable fixed IP address...\n" if($disable);

	$pkt = "'R".pack('C*', 0x05, 0x00, 0x00);
	$socket->send($pkt);

	if(!(my $pkt = get_packet($socket))) {
		print STDERR "ERROR: Didn't receive packet!\n";
		exit 1;
	} else {
		my ($c, $addr, $b1, $b0) = unpack('C4', $pkt);
		printf("c: %c  addr: %x  b0: %02.2x b1: %02.2x\n", $c, $addr, $b0, $b1) if($debug);
		if($addr != 0x05) {
			print STDERR "ERROR: Reply is not for expected EEPROM address!\n";
			exit 1;
		}
		$b0 &= 0xfe if($enable);
		$b0 |= 0x01 if($disable);

		$pkt = "'W".pack('C*', 0x05, $b1, $b0);
		$socket->send($pkt);

		sleep 1;
	}

	print "Disable config writes...\n" if($debug);
	$pkt = "'0".pack('C*', 0x00, 0xaa, 0x55);
	$socket->send($pkt)
}

# Reboot?
if($reboot) {
	print "Reboot module...\n";
	$pkt = "'@";
	$socket->send($pkt);
}


