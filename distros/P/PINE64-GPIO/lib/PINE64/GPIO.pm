#!/usr/bin/perl -w
use strict;

package PINE64::GPIO;

our $VERSION = '0.91';

#global vars

#array of system gpio pin numbers
my @line_nums = (227,226,362,71,233,76,64,65,66,229,230,69,73,80,32,33,72,77,78,79,67,231,68,70,74,75);

#gpio index num. maps to line_nums system gpio number
my $iox;

sub new{
	my $class = shift;
	my $self = bless {}, $class;
	return $self;
}#end new

sub gpio_enable{
	my $ind = $_[1];
	$iox = $line_nums[$ind];

	my $gpiosz = @line_nums;	

	my $direction = $_[2];

	#err chk
	if($ind < 0 || $ind > $gpiosz){
		print "INVALID GPIO RANGE\n";
		exit;
	}#end if invalid index
	if($direction ne 'in' && $direction ne 'out'){
		print "INVALID DIRECTION\n";
		exit;
	}#end if invalid direction
	
	#write gpio pin val to export file
	open(EF, ">", "/sys/class/gpio/export") or die $!;
	print EF $iox;
	close(EF);

	#set direction of gpio pin
	open(GF, ">", "/sys/class/gpio/gpio$iox/direction") or die $!;
	print GF $direction;
	close(GF);

}#end gpio_enable

sub gpio_disable{
	#takes gpio pin num as arg
	my $ind = $_[1];

	#map pin num to system gpio number
	$iox = $line_nums[$ind];

	#unexport gpio pin
	open(UE, ">", "/sys/class/gpio/unexport");
	print UE $iox; 
	close UE;

}#end gpio_disable

sub gpio_read{
	#gpio number as arg, returns direction in/out
	my $ind = $_[1];
	$iox = $line_nums[$ind];
	
	my $value = ''; 

	#reads state of gpio pin
	open(GS, "/sys/class/gpio/gpio$iox/value") or die $!;
	while(<GS>){ $value = $_; };
	#print "$iox val: $value";
	close(GS);

	if($value == 0 || $value == 1){
		return $value;
	}#end unless
	else{ 
		print "ERROR: Undefined value on GPIO $iox\n";
		exit;
	}#end else
}#end gpio_read

sub gpio_write{
	my $ind = $_[1];
	$iox = $line_nums[$ind];

	my $value = $_[2];

	#write value to gpio pin
	open(GV, ">", "/sys/class/gpio/gpio$iox/value") or die $!;
	print GV $value;
	close(GV);
}#end gpio_write

1;
__END__

=head1 NAME

PINE64::GPIO - Perl interface to PineA64 and PineA64+ GPIO pins

=head1 SYNOPSIS

	use PINE64::GPIO;

	#instantiate PINE64::GPIO object
	my $p64 = PINE64::GPIO->new();
	
	#export pin 25 (physical pin 40) for output
	$p64->gpio_enable(25, 'out');

	#continuously blink LED
	for(;;){
		$p64->gpio_write(25, 1);
		sleep(1);
		$p64->gpio_write(25, 0);
		sleep(1);
	}#end for

=head1 DESCRIPTION

This module manipulates the GPIO file system interface of the PineA64
and PineA64+ single board computers so you can control the GPIO pins
on the PineA64's PI-2 bus.  

The PineA64's 40-pin PI-2 bus has the same pinout as the Raspberry Pi's
40-pin GPIO, however this module has it's own GPIO pin numbering
convention for the 26 GPIO pins as follows:

Module#		Physical#	A64 sys#
------------------------------------------
0		3		227
1		5		226
2		7		362
3		11		71
4		13		233
5		15		76
6		19		64
7		21		65
8		23		66
9		29		229
10		31		230
11		33		69
12		35		73
13		37		80
14		8		32
15		10		33
16		12		72
17		16		77
18		18		78
19		22		79
20		24		67
21		26		231
22		32		68
23		36		70
24		38		74
25		40		75

=head1 METHODS

=head2 new()

Returns a new C<PINE64::GPIO> object.  

=head2 gpio_enable($pin, 'out')

Takes the GPIO pin number and direction as arguments and exports it for use 
as either an input or output. 

Valid pin number arguments are 0-15, and the direction is either 'in' or 'out'.  

$p64->gpio_enable(25, 'out');

=head2	gpio_read($pin)

Takes pin number as an argument and returns the logic value on the pin. 

=head2 gpio_write($pin, $value)

Takes pin number and value as an argument and writes the value to the GPIO pin. 
Valid values are 0 or 1.

=head2 gpio_disable($pin)

Takes pin number as an argument and unexports the pin in the file system
interface.  

=head1 AUTHOR

Dustin La Ferney
=cut
