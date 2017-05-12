#!/usr/bin/perl -w

use strict;

use threads;
use threads::shared;

use Getopt::Long;
use Net::Elexol::EtherIO24;

Getopt::Long::Configure("require_order", "pass_through");

my $debug = 0;

my $addrw = "1.2.3.1";  # i/o module with relays attached
my $addrr = "1.2.3.2";  # i/o module with rain sensor
my $rain_sensor_line = 0;      # line on module for rain sensor

GetOptions(
	"debug=i" => \$debug,
);


system("ping -c 1 $addrr >/dev/null 2>&1"); # wake it up

my $rain_sensor = 0; # is it raining?
my $rain_sensor_inverted = 1;

Net::Elexol::EtherIO24->debug($debug);
my $eior = Net::Elexol::EtherIO24->new(
	target_addr => $addrr,
	debug_prefix => 'EIO READ THREAD',
	threaded => 1,
	direct_writes => 0,
	direct_reads => 0,
);

if(!$eior) {
	print STDERR "ERROR: Can't create new EtherIO24 object for $addrr: ".Net::Elexol::EtherIO24->error."\n";
	# Rather than exit here, we revert to assuming it's raining
	# and shut everything down (which only works, of course, if
	# we can get to the other i/o module).

	$rain_sensor = 1;
} else {
	# Check rain sensor

	$rain_sensor = $eior->get_line_live($rain_sensor_line);
	$rain_sensor += $eior->get_line_live($rain_sensor_line); # debounce
	$rain_sensor += $eior->get_line_live($rain_sensor_line); # debounce
	$rain_sensor = 1 if($rain_sensor);
}

$rain_sensor = !$rain_sensor if($rain_sensor_inverted);

if($rain_sensor) {
	# It's raining, turn all off.
	@ARGV = ();
}

print $$." It's ".($rain_sensor?"":"not ")."raining.\n";

$eior->close;

if(scalar(@ARGV) == 1 && $ARGV[0] eq 'raincheck') {
	# exit now, only checking if it's raining, and it's not, so all goes as normal.
	# Otherwise, if it was raining, ARGV is replaced with (), meaning all outputs get turned off
	exit;
}


system("ping -c 1 $addrw >/dev/null 2>&1"); # wake it up

my $eiow = Net::Elexol::EtherIO24->new(
	target_addr => $addrw,
	debug_prefix => 'EIO WRITE THREAD',
	threaded => 1,
	direct_writes => 0,
	direct_reads => 0,
);

if(!$eiow) {
	print STDERR "ERROR: Can't create new EtherIO24 object for $addrw: ".Net::Elexol::EtherIO24->error."\n";
	exit 1;
}

my @lines = ();
for my $line (0..23) {
	print "line $line dir: ".$eiow->get_line_dir($line)."  ".  "line $line val: ".$eiow->get_line($line)."\n" if($debug);
	$eiow->set_line_dir($line, 0); # it's an output. make it so.
	$lines[$line] = 0;
}

while (my $line = shift) {
	if(defined($line)) {
		$lines[$line] = 1;
	}
}

for my $line(0..23) {
	$eiow->set_line($line, $lines[$line]);
	print "line $line val: ".$eiow->get_line($line)."\n" if($debug);
}

$eiow->close;

exit;
