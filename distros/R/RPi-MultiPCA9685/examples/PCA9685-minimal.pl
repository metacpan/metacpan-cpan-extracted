#!/usr/bin/perl -w

use RPi::MultiPCA9685 qw(init_PWM setChannelPWM);

#--------------------------------------------------------------
# prepare the array reference containing the PWM values. 
# 1st value = PWM start
# 2nd value = pwm stop -  in a range of 4096 steps
# 3rd Value = the same like 1st, but for the next servo or LED.
# 4th value = like 2nd, but for the next servo or LED.
# and so on ...

  my $mref=[0,100,0,200,0,300,0,400,0,500,0,600,0,700,0,800,0,900,0,1000,
            0,1100,0,1200,0,1300,0,1400,0,1500,0,1600,0,1700,0,1800,0,1900,
            0,2000,0,2100,0,2200,0,2300,0,2400,0,2500,0,2600,0,2700,0,2800,
            0,2900,0,3000,0,3100,0,3200,0,3300,0,3400,0,3500,0,3600,0,3700,
            0,3800,0,3900,0,4000];
#--------------------------------------------------------------

  my $num_servos=40;            # make sure the number of value pairs in the array does not exceed this value
  my $i2c_freq=50;              # The frequency of the PWM signal in Hz
  my $i2cport="/dev/i2c-0";     # The I2C port device 
  my $i2c_address=0x40;         # The I2C address of the first PCA9685 Chip. If you exceed the number of addressable Channels per chip,
                                # the next chip will be used (i2c_address + 1)
  my $currentservo=0;           # The first servo or LED where you want to change the PWM. Can be any number from 0 to $num_servos.
                                # If you don't want to start with 0, make sure the number of array element does not exceed the last servo or LED

#--------------------------------------------------------------

# init the PCA9685 devices      # needs to be run only once at startup
  init_PWM($i2cport,$i2c_address,$i2c_freq,$num_servos);

# send the PWM values to the various PCA96585 Chips
  setChannelPWM($currentservo,$mref);       # the nuber of array elements define the number of Servos to be set. 
