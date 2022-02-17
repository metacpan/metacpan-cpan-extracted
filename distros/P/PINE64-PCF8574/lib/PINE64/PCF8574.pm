#!/usr/bin/perl
use strict;
use Device::I2C;
use IO::Handle;
use Fcntl;

package PINE64::PCF8574;

our $VERSION = "0.101";

#global vars
my ($i2cbus, $addr, $gpext, $debug);
my $gpregval = 0; 	#init gpio register value to 0

my @pin_nums = (1,2,4,8,16,32,64,128); 

sub new{
	my $class = shift;
	my $self = bless {}, $class;

        #first arg is device address
        $addr = $_[0];
 
	#second optional turn on debug
	$debug = $_[1]; 

        #third arg i2c bus; optional
        $i2cbus = $_[2];
         
        if($i2cbus eq ''){
                $i2cbus = '/dev/i2c-1';
        }#end if
         
        $gpext = Device::I2C->new($i2cbus, "r+"); 
 
        #init i2c device
        $gpext->checkDevice($addr);
        $gpext->selectDevice($addr);
 
        #init gp register val to all off
        $gpregval = 255; 

	print "successfully created pcf8574 object....\n";
 
	#set gpext to 0x00
	$gpext->writeByte(0xff); 

        return $self;
}#end new:

sub write_pin{
	my $ind = $_[1];
	my $iox = $pin_nums[$ind];

	#1 or 0
	my $val = $_[2];

	#see current pin states
	my $regval = $gpext->readByte();
	#my $regval = `i2cget -y 1 0x20`;
	#print "regval: $regval\n";
	my $binout = sprintf("%08b", $regval); 
	my @pinvals = split(//, $binout); 
	@pinvals = reverse(@pinvals);

	if($debug == 1){
		print "@pinvals \n";
	}#end if

	my $already_high = $pinvals[$ind]; 

        if($val == 1 && $already_high == 0){
                $gpregval+=$iox; 
        }#end if
        if($val == 0 && $already_high == 1){
                $gpregval-=$iox;
        }#end if

	$gpext->writeByte($gpregval); 

}#end write_pin

sub read_pin{
        my $ind = $_[1];
        my $iox = $pin_nums[$ind];
        my $pinval = 0; 
 
        #read GPIO register
        my $regval = $gpext->readByte(); 
 
        #ensure 8 binary places are displayed
        my $binout = sprintf("%08b", $regval);
 
        #parse eight binary digits into an array
        my @pinvals = split(//, $binout);
         
        #reverse array to match pin #'s
        @pinvals = reverse(@pinvals);
	
	if($debug == 1){
		print "@pinvals \n";
	}#end if
 
        #value of pin is index of $pinvals
        $pinval = $pinvals[$ind]; 
 
        return $pinval;
}#end read_pin

1;

__END__
