#!/usr/bin/perl 
use strict;

package PINE64::MCP9808;

our $VERSION = '0.905';

#global vars
my ($i2cbus, $addr) = ('','');

sub new{
	my $class = shift;
	my $self = bless {}, $class;

	$i2cbus = $_[0];
	$addr = $_[1];

	if($i2cbus eq ''){
		$i2cbus = 0;
	}#end if

	if($addr eq ''){
		$addr = '0x18';
	}#end if

	return $self;
}#end new

sub read_temperature{

	#reads ambient temperature reguster 0x05

	my $hrdg = `i2cget -y $i2cbus $addr 0x05 w`;
	my ($ubyte, $lbyte) = (0,0);

	#split into uppper and lower bytes
	$hrdg =~ /(..)(..)(..)/;
	$ubyte = $3;
	$lbyte = $2;

	#convert hex to decimal
	$ubyte = hex $ubyte;
	$lbyte = hex $lbyte;

	#convert reading to decimal temp
	#strip 15-13b
	if($ubyte > 127){$ubyte-=128;}
	if($ubyte > 63){$ubyte-=64;}
	if($ubyte > 31){$ubyte-=32;}

	my $celsius = ($ubyte * 16) + ($lbyte * 0.0625);
	my $fahrenheit = ($celsius * 1.8) + 32;

	return($celsius, $fahrenheit);
}#end read_temperature

1;
__END__

=head1 SYNOPSIS

	use PINE64::MCP9808;

	my $temp_sensor = PINE64::MCP9808->new(0, '0x18');
	my @reading = $temp_sensor->read_temperature(); 
	my $celsius = $reading[0];
	my $fahrenheit = $reading [1]; 

=head1 DESCRIPTION

This module allows you to take temperature readings with the
highly accurate MCP9808 I2C temperature sensor using a 
PINE64A+ board. 

=head1 METHODS

=head2 new(0, 0x18)

You can optionally pass the I2C device id and the address of the
MCP9808 on the I2C bus.  The PINE64A+ I2C bus is /dev/i2c-0, and
the default I2C address for an MCP9808 is 0x18.  new() called with
no arguments will default to /dev/i2c-0 and 0x18.  

=head2 read_temperature()

Reads the ambient temperature register of the MCP9808 and returns
an array containing the reading in celsius and fahrenheit.  The
ambient temperature register is 0x05.  Bits 13-15 have to be masked
out.  Bit 12 is the sign bit.  The two's complement temperature 
reading is bits 0-11.  $reading[0] is temperature in celsius, 
$reading[1] is the reading in temperature.  
