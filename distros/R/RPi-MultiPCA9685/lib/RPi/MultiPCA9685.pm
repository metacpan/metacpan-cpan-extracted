package RPi::MultiPCA9685;
use 5.006;
our $VERSION = '0.08';
our @ISA = qw();
use strict;
use warnings;
use POSIX qw/ceil floor/;
use RPi::I2C;
use vars qw/@dev $num_PWMPCBs/;
use Exporter 'import';
our @EXPORT_OK = qw(init_PWM setChannelPWM disablePWM);

#----------------------------------------------------------
# init all PWM PCBs - the number of boards is determined by the number of Servos (Servos /16)
#----------------------------------------------------------
sub init_PWM {
  my $i2cport=shift;
  my $i2c_address=shift;
  my $i2c_freq=shift;
  my $num_servos=shift;
  my $presc=int(25000000/(4096*$i2c_freq));# calc the prescaler value for register FEh(254)
  $num_PWMPCBs=ceil($num_servos/16);
  my $j;
  @dev=();
  for ($j=0;$j<=$num_PWMPCBs;$j++){	   # init all PWM PCBs - every 16 ports switch to the next i2c address
    $dev[$j] = RPi::I2C->new($i2c_address+$j,$i2cport);
    $dev[$j]->write_byte(16,0);            # allow to program the prescale register (only possible when PWM is inactive)
    $dev[$j]->write_byte($presc,254);      # set the calculated prescaler value to achieve the desired frequency
    $dev[$j]->write_block([32,14],0);      # init the pca9685 chip to output the PWM 
  }  
  return 1;
}
#----------------------------------------------------------
# Disable PWM - powers off all devices
#----------------------------------------------------------
sub disablePWM {
  return unless defined $num_PWMPCBs;      # Only disable if init has been done before
  my $j;
  for ($j=0;$j<=$num_PWMPCBs;$j++){        # disable all PWM PCBs - every 16 ports switch to the next i2c address
    $dev[$j]->write_block([0,0,0,0],250);  # disable PWM for all channels via chip Register FAh(250)
  }
  return 1;
}	
#----------------------------------------------------------
# send the pwm values to the PCA9685 chip
# use the auto address increment of the chip
# Switches to the next chip if channel 15,31,47,63.... is exceeded
#----------------------------------------------------------
sub setChannelPWM {
  my $servo=shift;                         # The first servo we send moves
  my $mref=shift;                          # contains a reference for an array that contains moves for perhaps several servos
  my @split=();                               
  my $h;                                   # MSB of the servo move
  my $l;                                   # LSB of the servo move
  my $i=0;                                 # start with the first array element
  my $rc=0;                                # set the register count to 0
  my $startreg=6+($servo*4%64);            # the first servo register we write to modulo 70 to reset with every new board
  my $numref=$#$mref;                      # the number of positions to write
  my $splitref=\@split;                    # RPI::I2C needs all moves in an array reference	    
  my $brd=int($servo*2/32);                # calc the board number - the pwm board to write to
  my $obrd=$brd;                           # previous board is identical with current     	  
  while ($i <= $numref){                   # $i points onto array element of input array (2 elements per servo)
    $brd=int(($i+$servo*2)/32);            # calc the board number     	  
    if ($rc > 15) {
      $dev[$obrd]->write_block($splitref,$startreg); # pass all moves of the first block to the PCA9685 chip 
      @split=();                           # empty, because we switch to a new board
      $rc=0;                               # continue with register reset to 0
      $startreg+=32;                       # make sure the next 8 registers will be higher
      if ($obrd < $brd) {                  # in addition a board border is reached ?
        $obrd=$brd;                        # note the change
        $startreg=6;                       # after the chip change start with register 6 of the chip (PWM 0)
      } 
    }
    if ($obrd < $brd) {
      $dev[$obrd]->write_block($splitref,$startreg); # pass all moves of the first block to the PCA9685 chip
      @split=();                           # empty, because we switch to a new board
      $obrd=$brd;                          # note the change
      $startreg=6;                         # after the chip change start with register 6 of the chip (PWM 0)
      $rc=0;                               # continue with register reset to 0
    }  
    $h=int($mref->[$i]) >> 8;              # calc MSB
    $l=int($mref->[$i]) & 255;             # and LSB
    push(@split,($l,$h));                  # Put all into an array
    $rc++;                                 # count the registers in buffer (must not exceed 7 since i2c lib can only write 32 byte at once)
    $i++;                                  # point to the next element
  }    
  $dev[$brd]->write_block($splitref,$startreg); # pass remaining moves to the PCA9685 chip
  return 1;
}	
1;
__END__

=head1 NAME

RPi::MultiPCA9685 - control the PWM channels of several PCA9685 ICs in one go.

=head1 SYNOPSIS

    use RPi::MultiPCA9685 qw(init_PWM setChannelPWM);

    # prepare the array reference containing the PWM values.

    my $mref=[0,100,0,200,0,300,0,400,0,500,0,600,0,700,0,800,0,900,0,1000,
              0,1100,0,1200,0,1300,0,1400,0,1500,0,1600,0,1700,0,1800,0,1900,
              0,2000,0,2100,0,2200,0,2300,0,2400,0,2500,0,2600,0,2700,0,2800,
              0,2900,0,3000,0,3100,0,3200,0,3300,0,3400,0,3500,0,3600,0,3700,
              0,3800,0,3900,0,4000];

    # The number of servos or LEDS to control PWM 

    my $num_servos=40;           

    # The frequency of the PWM signal in Hz

    $i2c_freq=50;              

    # The I2C port device

    my $i2cport="/dev/i2c-0";     

    # The I2C address of the first PCA9685 Chip. If you exceed the number of
    # addressable Channels per chip, the next chip will be used 
    # (i2c_address + 1)

    my $i2c_address=0x40;         

    # The first servo or LED where you want to change the PWM. Can be any
    # number from 0 to $num_servos. If you don't want to start with 0, make
    # sure the number of array elements does not exceed the last servo or LED

    my $currentservo=0;           

    # init the PCA9685 devices - needs to be run only once at startup

    init_PWM($i2cport,$i2c_address,$i2c_freq,$num_servos);

    # send the PWM values to the various PCA96585 Chips

    setChannelPWM($currentservo,$mref);


=head1 DESCRIPTION

Interface to set the PWM values for one or several PCA9685 ICs in one go.
PWM stands for "Pulse Width Modulation" - a technic for stepless control of 
electric devices to adjust LED brightness or Servo positions and much more. 
You may set the PWM channels of several consecutively addressed PCA9685 ICs  
by providing one single array reference that contains the pwm values for all 
of these chips. This Module may replace Device::PWMGenerator::PCA9685 as 
this Module is time consuming to install and starts slowly. MultiPCA9685.pm 
requires only RPi::I2C as a prequisite and not a huge module chain like 
Device::PWMGenerator::PCA9685. MultiPC9685.pm is especially useful in time 
critical applications, because it uses the continuous write feature of the chip
that saves a lot of addressing time. 

=head1 READ THIS FIRST

There are particular things to know how PCA9685 ICs are handled in one go.

=head2 General

A single PCA9685 chip has 16 PWM channels. Each channel can be individually set
by providing a start- and stopvalue. Both values have a resolution of 12 bit,
this means a value of 0 to 4096. By providing a start- and stopvalue, the phase
of the PWM signal can be defined compared to other channels. So for each PWM 
channel two values of a range in between 0 and 4096 are reqired. 

The array of PWM values passed to setChannelPWM when called can be very long.
This depends on the number of PCA9685 chips attached to the I2C bus. So the  
channels addressed in the array may reach beyond a single PCA9685 chip. In this
case the module detects the border of the previous chip and continues 
automatically with addressing the next chip. This imples, that the next chip 
has a chip address of +1 compared to the current chip. This is the reason, why
only one I2C address needs to be provided during the initialization of the 
chips using init_PWM. The Array containing the PWM values is one dimensional,
so the first element in the array ( mref->[0] ) is the start value of the first 
channel addressed, where the second value is the stop value of the first 
channel. The third value is the start value of the second channel and so on...
So we can say, even array elements always contain channel start values and odd
array elements always contain channel stop values.
Along with the module a small sample script will be copied to your
/usr/local/bin directory called PCA9685-minimal.pl When started it sets 40 
channels for three PCA9685 Chips as an example.

=head1 METHODS

=head2 init_PWM($i2cport,$i2c_address,$i2c_freq,$num_servos);

Intializes all PCA9685 chips on the bus - depending on the $num_servos 
parameter.

Parameters:

    $i2cport

Mandatory, String: The name of the I2C device file. Defaults to C</dev/i2c-1>.

    $i2c_address

Mandatory, Integer (in hex): The address of the first PCA9685 on the I2C bus
(C<i2cdetect -y 1>). eg: C<0x40>.

    $i2c_freq

Mandatory,Integer : The frequency of the PWM in Hz

    $num_servos

Mandatory, Integer : The number of PWM channels you want to address. This 
defines the number of elements in the array you provide later with 
setChannelPWM Calc with: num_servos x 2 = number of required array elements to 
address all channels

=head2 setChannelPWM($currentservo,$mref)

Sets the PWM for the channels using the PWM values in the array. 

Parameters:

    $currentservo

Mandatory, Integer : 

Usually this value is 0 if you want to address all channels starting from the 
first one.
This number defines the first channel you want to address to write PWM values
to. All channels - even on subsequent chips have their own unique consecutive
channel number. The channel number starts with 0, this is the first channel 
on the first PCA9685 Chip. The channel number may be quite high and is only 
limited by the number of PCA9685 chips on the i2C bus. Maximum channel = 
number of chips x 16. Example: If you have 5 PCA9685 chips attached on the Bus,
your maximum Number of channels = 5 x 16 = 80. Imagine you want to start 
setting PWM at the 2nd channel of the 3rd chip on the bus, then the consecutive
channel number for this channel is 33 (2 x 16 -1 +2). the -1 in the calculation
is, because the first channel has number 0. 

If you set $currentservo to different from 0, you must make sure to pass a 
shorter array to setChannelPWM than the full range, so you do not write beyond
the existing number of channels 

If you do not respect this, improper data may be sent to the I2C bus with
unpredictable consequences.

    $mref

Mandatory,Array reference to an array of integer values:

This is a array reference to an array, that contains the PWM values - see also
section general. The Array may be smaller than $num_servos x 2, but must be at
least 2 array elements in size (one servo or LED). If the array is smaller than
$num_servos x2, simply the channel PWM setting stops at the last array element.
This means, using the combination $currentservo and $mref, you can set only a 
fraction of all consecutive channels. 

=head2 disablePWM

Disables the PWM output for all channels.

Parameters: none

Disables the PWM output for all channels. This function may help
to prevent of damages to servos if they run against a mechanical block. Servos
usually stop moving if they get no PWM at all.

=head1 AUTHOR

Rolf Jethon, C<< <rolf at bechele.de> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2023 by Rolf Jethon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.
=cut
