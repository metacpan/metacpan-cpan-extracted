#!/usr/bin/perl
use strict;
use Time::HiRes qw(usleep);
use PINE64::GPIO; 

package PINE64::MCP300x;

our $VERSION = '0.91';

=pod
bit-banged SPI driver implementing
routines for MCP300x 4 or 8-channel
10-bit analog to digital converter
=cut

#SPI / bitbang varables
my ($clk, $din, $dout, $chpsel);

#channels: first bit is set to single, not differential
#5 bits because the first is the start bit
my @ch0 = (1,1,0,0,0);
my @ch1 = (1,1,0,0,1);
my @ch2 = (1,1,0,1,0);
my @ch3 = (1,1,0,1,1);
my @ch4 = (1,1,1,0,0);
my @ch5 = (1,1,1,0,1);
my @ch6 = (1,1,1,1,0);
my @ch7 = (1,1,1,1,1);

#instantiate PINE64 gpio device
my $p64 = PINE64::GPIO->new();

sub new{
	my $class = shift;
	my $self = bless {}, $class;

	#
	$clk = $_[0];		#clock
	$din = $_[1];		#instructions to adc
	$dout = $_[2];		#10-bit output from adc
	$chpsel = $_[3];	#latch / load to init comm to adc

	#init gpio lines
	$p64->gpio_enable($clk, 'out');
	$p64->gpio_enable($din, 'out');
	$p64->gpio_enable($dout, 'in');
	$p64->gpio_enable($chpsel, 'out');
	
	#init chpsel high, comm begins when
	#chipsel goes from high to low
	$p64->gpio_write($chpsel, 1);

	return $self;

}#end new

sub read300x{
	#init empty array that will
	#contain 10-bit reading from ADC
	my @reading = ();
	#get reading from the MCP3004 ADC
	#starts comm when cs goes from high to low
	
	#ADC channel number
	#channel is an array reference
	my $channel = $_[1];

	#delay between clock pulses
	#needs to operate at 10KHz so
	#sample is accurate, so min usleep(100)
	my $delay = $_[2];

	#reference voltate, used only for calculations
	#can be omitted
	my $vref = $_[3];

	#main clock variable
	my $i=0;
	
	#high flag for data gpio line
	my $hf = 0;

	#number of clock pulses, 
	my $ncp = 34; #for 18 clock pulses

	#high or low state of clock pulse
	my $state = 0;
	my $seed = 3; #seed used to determine high or low, start 3 so first pulse is high
	
	#toggles CS line to init communication with the adc
	#start low, go high, then low.  comm begins when CS
	#brought from high to low
	$p64->gpio_write($chpsel, 0);
	Time::HiRes::usleep($delay);
	
	#main loop
	while($i<$ncp){
		$state = $seed%2;#toggles between 1 and 0
		$seed++;

		#clock pulse high
		if(($i%2) eq 0){
			#print "i: $i\tcp high\tstate: $state\n";

			if($channel->[$i/2] eq 1 && $i <=8){
				$p64->gpio_write($din, 1);
				$hf = 1;#set high flag
				#print "ch[".($i/2)."]: ".$channel->[$i/2]."\n";
			}#end if
			if($channel->[$i/2] eq 0 && $i <=8){
				$p64->gpio_write($din,0);
			}#end if zero on data line
		}#end if high

		#if($i>8){#data line
			#everything after D0 bit is don't care, 
			#set to state
			#gpio_write($din, $state);
		#}#end else

		#clock pulse
		$p64->gpio_write($clk, $state);

		#read data out
		#data clocked out on falling
		#edge of clk
		if(($i%2) == 1 && $i >12){
			#read state of gpio pin connected
			#to data out of ADC
			push @reading, $p64->gpio_read($dout);
			#print "i[$i]: ".$reading[($i-14)/2]."\n"
		}#end read data out

		#lower data if high flag set
		if($hf eq 1){
			#gpio_write($din,0);
			$hf = 0;#reset high flag
		}#end if
		
		#pause between clk pls
		Time::HiRes::usleep($delay);

		#increment counter
		$i++;
	}#end while
		
	#make din low
	$p64->gpio_write($din, 0);

	#make chip select high
	$p64->gpio_write($chpsel, 1);

	#perform calcuations, return a voltage
	#based of 10-bit reading, and vref val
	my $bindig = 512;
	my $rdgval = 0;
	my $voltage = 0; 
	for(my $x; $x<10;$x++){
		if($reading[$x] == 1){
			$rdgval = $rdgval + $bindig;
		}#end if
		$bindig = $bindig / 2;
	}#end for

	#voltage calculation
	$voltage = ($rdgval*$vref)/1024;

	return (\@reading, $rdgval, $voltage);
}#end read3004

1;
__END__

=head1 NAME

PINE64::MCP300x - Perl interface to the MCP300x family of 10-bit 
analog to digital converters. 

=head1 SYNOPSIS

	use PINE64::MCP300x;

	my $adc = PINE64::MCP300x->new(10,12,11,13); 
	#5 bits because the first is the start bit
	my @ch0 = (1,1,0,0,0);

	for(my $s=0;$s<200;$s++){
		my ($reading, $binval, $voltage ) = $adc->read300x(\@ch0, 50, 5.01);
		$voltage = sprintf("%.3f", $voltage);
		print "binval: $binval\tvoltage: $voltage vdc\n";
		usleep(500000);
	}#end for

=head1 DESCRIPTION

This module allows you to control an MCP3004 or MCP3008 10-bit
analog to digital controller via bit-banged SPI using Perl on the
PINE64A+ single board computer. Works in single channel or 
differential mode. 

=head1 METHODS

=head2 new($clock,$data_in,$data_out,$chip_select) 

Takes clock pin number, SPI data in pin number, SPI data out pin
number, SPI chip select pin number, and returns a PINE64::MAX300x
object.  Pin numbers are valid PINE64::GPIO objects on the Pi-2
bus.

=head2 read300x($channel_number,$clk_pls_delay,$voltage_reference); 

This is the main function of the package.  It takes an array 
reference to select the channel number and mode (single/differential)
that you want to sample

The following are valid single channel array values:
 @ch0 = (1,1,0,0,0);
 @ch1 = (1,1,0,0,1);
 @ch2 = (1,1,0,1,0);
 @ch3 = (1,1,0,1,1);
 @ch4 = (1,1,1,0,0);
 @ch5 = (1,1,1,0,1);
 @ch6 = (1,1,1,1,0);
 @ch7 = (1,1,1,1,1);

The following are valid differential channel array values
 @ch0_diff = (1,0,0,0,0);
 @ch1_diff = (1,0,0,0,1);
 @ch2_diff = (1,0,0,1,0);
 @ch3_diff = (1,0,0,1,1);

So, when calling read300x, you would pass a reference of the 
channel you want to sample

$adc->read300x(\@ch0, 50, $vref);

The second argument is the delay between clock pulses in 
milliseconds.  This is a crude way to control the sample
speed.  I almost always use 50msec, and have had good
results.  

The third argument is a reference voltage and is optional. 
This method will calculate the returned voltage value based
on the output code of the converter in proportion of the
reference voltage.  So if the reference voltage is 50V, and
the output code is 512,  the method will return 25V.  

The reference voltage can be useful if you are using a voltage
divider circuit to step-down a voltage higher that the 
maximum input reference voltage of the MCP300x.  

read300x() returns an array that contains an array reference 
of the 10-bit binary result i.e. 1011010001, the output code 
in decimal i.e. 1024, 567, 311, etc., and the calculated
voltage based on the supplied reference voltage.   
		
Below is an example call to the read300x() method:
my ($reading, $binval, $voltage ) = $adc->read300x(\@ch0, 50, 5.01);
