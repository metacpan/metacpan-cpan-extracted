package RPi::WiringPi;

use strict;
use warnings;

use parent 'RPi::WiringPi::Core';

use GPSD::Parse;
use RPi::ADC::ADS;
use RPi::ADC::MCP3008;
use RPi::BMP180;
use RPi::Const qw(:all);
use RPi::DAC::MCP4922;
use RPi::DigiPot::MCP4XXXX;
use RPi::HCSR04;
use RPi::I2C;
use RPi::LCD;
use RPi::Pin;
use RPi::Serial;
use RPi::SPI;
use RPi::StepperMotor;

our $VERSION = '2.3625';

my $fatal_exit = 1;

BEGIN {
    sub _error {
        my $err = shift;
        RPi::WiringPi::Core::cleanup();
        print "\ncleaned up, exiting...\n";
        print "\noriginal error: $err\n";
        exit if $fatal_exit;
    }

    $SIG{__DIE__} = \&_error;
    $SIG{INT} = \&_error;
};

# core

sub new {
    my ($self, %args) = @_;
    $self = bless {%args}, $self;

    if (! $ENV{NO_BOARD}){
        if (my $scheme = $ENV{RPI_PIN_MODE}){
            # this checks if another application has already run
            # a setup routine

            $self->pin_scheme($scheme);
        }
        else {
            # we default to gpio mode

            if (! defined $self->{setup}) {
                $self->SUPER::setup_gpio();
                $self->pin_scheme(RPI_MODE_GPIO);
            }
            else {
                if ($self->_setup =~ /^w/) {
                    $self->SUPER::setup();
                    $self->pin_scheme(RPI_MODE_WPI);
                }
                elsif ($self->_setup =~ /^g/) {
                    $self->SUPER::setup_gpio();
                    $self->pin_scheme(RPI_MODE_GPIO);
                }
                elsif ($self->_setup =~ /^p/) {
                    $self->SUPER::setup_phys();
                    $self->pin_scheme(RPI_MODE_PHYS);
                }
                elsif ($self->_setup =~ /^W/){
                    $self->pin_scheme(RPI_MODE_WPI);
                }
                else {
                    $self->pin_scheme(RPI_MODE_UNINIT);
                }
            }
        }
        # set the env var so we can catch multiple
        # setup calls properly

        $ENV{RPI_SCHEME} = $self->pin_scheme;
    }
    $self->_fatal_exit;
    return $self;
}
sub adc {
    my ($self, %args) = @_;

    my $adc;

    if (defined $args{model} && $args{model} eq 'MCP3008'){
        my $pin = $self->pin($args{channel});
        $adc = RPi::ADC::MCP3008->new($pin->num);
    }
    else {
        # ADSxxxx ADCs don't require any pins
        $adc = RPi::ADC::ADS->new(%args);
    }
    return $adc;
}
sub bmp {
    return RPi::BMP180->new($_[1]);
}
sub dac {
    my ($self, %args) = @_;
    $self->pin($args{cs});
    $self->pin($args{shdn}) if defined $args{shdn};
    $args{model} = 'MCP4922' if ! defined $args{model};
    my $dac = RPi::DAC::MCP4922->new(%args);
    return $dac;
}
sub dpot {
    my ($self, $cs, $channel) = @_;
    $self->pin($cs);
    my $dpot = RPi::DigiPot::MCP4XXXX->new($cs, $channel);
    return $dpot;
}
sub gps {
    my ($self, %args) = @_;
    my $gps = GPSD::Parse->new(%args);
    return $gps;
}
sub hcsr04 {
    my ($self, $t, $e) = @_;
    $self->pin($t);
    $self->pin($e);
    return RPi::HCSR04->new($t, $e);
}
sub hygrometer {
    my ($self, $pin) = @_;
    $self->register_pin($pin);
    my $sensor = RPi::DHT11->new($pin);
    return $sensor;
}
sub i2c {
    my ($self, $addr, $i2c_device) = @_;
    return RPi::I2C->new($addr, $i2c_device);
}
sub lcd {
    my ($self, %args) = @_;

    # pre-register all pins so we can clean them up
    # accordingly upon cleanup

    for (qw(rs strb d0 d1 d2 d3 d4 d5 d6 d7)){
        if (! exists $args{$_} || $args{$_} !~ /^\d+$/){
            die "lcd() requires pin configuration within a hash\n";
        }
        next if $args{$_} == 0;
        $self->pin($args{$_});
    }

    my $lcd = RPi::LCD->new;
    $lcd->init(%args);
    return $lcd;
}
sub pin {
    my ($self, $pin_num) = @_;

    $self->registered_pins;
    my $gpio = $self->pin_to_gpio($pin_num);

    if (grep {$gpio == $_} @{ $self->registered_pins }){
        die "\npin $pin_num is already in use... can't create second object\n";
    }

    my $pin = RPi::Pin->new($pin_num);
    $self->register_pin($pin);
    return $pin;
}
sub serial {
    my ($self, $device, $baud) = @_;
    return RPi::Serial->new($device, $baud);
}
sub servo {
    my ($self, $pin_num, %config) = @_;

    if ($> != 0){
        die "\n\nat this time, servo() requires PWM functionality, and PWM " .
            "requires your script to be run as the 'root' user (sudo)\n\n";
    }

    $config{clock} = exists $config{clock} ? $config{clock} : 192;
    $config{range} = exists $config{range} ? $config{range} : 2000;

    $self->_pwm_in_use(1);

    my $servo = $self->pin($pin_num);
    $servo->mode(PWM_OUT);

    $self->pwm_mode(PWM_MODE_MS);
    $self->pwm_clock($config{clock});
    $self->pwm_range($config{range});

    return $servo;
}
sub shift_register {
    my ($self, $base, $num_pins, $data, $clk, $latch) = @_;

    my @pin_nums;

    for ($data, $clk, $latch){
        my $pin = $self->pin($_);
        push @pin_nums, $pin->num;
    }
    $self->shift_reg_setup($base, $num_pins, @pin_nums);
}
sub spi {
    my ($self, $chan, $speed) = @_;
    my $spi = RPi::SPI->new($chan, $speed);
    return $spi;
}
sub stepper_motor {
    my ($self, %args) = @_;

    if (! exists $args{pins}){
        die "steppermotor() requires an arrayref of pins sent in\n";
    }

    for (@{ $args{pins} }){
        $self->pin($_);
    }

    return RPi::StepperMotor->new(%args);
}

# private

sub _fatal_exit {
    my $self = shift;
    $self->{fatal_exit} = shift if @_;
    $fatal_exit = $self->{fatal_exit} if defined $self->{fatal_exit};
    return $self->{fatal_exit};
}
sub _pwm_in_use {
    my $self = shift;
    $ENV{PWM_IN_USE} = 1 if @_;
    return $self->{pwm_in_use};
}
sub _setup {
    return $_[0]->{setup};
}

sub _vim{};
1;
__END__

=head1 NAME

RPi::WiringPi - Perl interface to Raspberry Pi's board, GPIO, LCDs and other
various items

=head1 SYNOPSIS

    use RPi::WiringPi;
    use RPi::Const qw(:all);

    my $pi = RPi::WiringPi->new;

    #
    # pin
    #

    my $pin = $pi->pin(5);
    $pin->mode(OUTPUT);
    $pin->write(ON);

    my $num = $pin->num;
    my $mode = $pin->mode;
    my $state = $pin->read;

    #
    # analog to digital converter (ADS1115)
    #

    my $adc = $pi->adc;
   
    # read channel A0 on the ADC

    my $v = $adc->volts(0);
    my $p = $adc->percent(0);

    # analog to digital converter (MCP3008)

    my $adc = $pi->adc(model => 'MCP3008', channel => 0);

    print $adc->raw(0);
    print $adc->percent(0);

    #
    # I2C
    #

    my $device_addr = 0x7c;

    my $i2c_device = $pi->i2c($device_addr);

    my $register = 0x0A;

    $i2c_device->write_block([55, 29, 255], $register);

    my $byte = $i2c_device->read;

    my @bytes = $i2c_device->read_block;

    #
    # SPI
    #

    my $channel = 0; # SPI channel /dev/spidev0.0

    my $spi = $pi->spi($channel);

    my $buf = [0x01, 0x02];
    my $len = scalar @$buf;

    my @read_bytes = $spi->rw($buf, $len);

    #
    # Serial
    #

    my $dev  = "/dev/ttyS0";
    my $baud = 115200;

    my $ser = $pi->serial($dev, $baud);

    $ser->putc(5);

    my $char = $ser->getc;

    $ser->puts("hello, world!");

    my $num_bytes = 12;
    my $str  = $ser->gets($num_bytes);

    $ser->flush;

    my $bytes_available = $ser->avail;

    #
    # digital to analog converter (DAC)
    #

    my $dac_cs_pin = $pi->pin(29);
    my $spi_chan = 0;

    my $dac = $pi->dac(
        model   => 'MCP4922',
        channel => $spi_chan,
        cs      => $dac_cs_pin
    );

    my ($dacA, $dacB) = (0, 0);

    $dac->set($dacA, 4095); # 100% output
    $dac->set($dacB, 0);    # 0% output

    #
    # digital potentiometer
    #

    my $cs = 18;     # GPIO pin connected to dpot CS pin
    my $channel = 0; # SPI channel /dev/spidev0.0

    my $dpot = $pi->dpot($cs, $channel);

    # set to 50% output

    $dpot->set(127);

    # shutdown (sleep) the potentiometer

    $dpot->shutdown;

    #
    # shift register
    #
    
    my ($base, $num_pins, $data, $clk, $latch)
      = (100, 8, 5, 6, 13);

    $pi->shift_register(
        $base, $num_pins, $data, $clk, $latch
    );

    # now we can access the new 8 pins of the
    # register commencing at new pin 100-107

    for (100..107){
        my $pin = $pi->pin($_);
        $pin->write(HIGH);
    }

    #
    # BMP180 barometric pressure sensor
    #
    
    my $base = 300; 

    my $bmp = $pi->bmp($base);

    my $farenheit = $bmp->temp;
    my $celcius   = $bmp->temp('c');
    my $pressure  = $bmp->pressure; # kPa

    #
    # DHT11 temperature/humidity sensor
    #

    my $sensor_pin = 21;

    my $env = $pi->hygrometer($sensor_pin);

    my $humidity  = $env->humidity;
    my $temp      = $env->temp; # celcius
    my $farenheit = $env->temp('f');

    # GPS (requires gpsd to be installed and running)

    my $gps = $pi->gps;

    print $gps->lat;
    print $gps->lon;
    print $gps->speed;
    print $gps->direction;

    #
    # LCD
    #

    my $lcd = $pi->lcd(...);

    # first column, first row
    
    $lcd->position(0, 0); 
    $lcd->print("hi there!");

    # first column, second row
    
    $lcd->position(0, 1);
    $lcd->print("pin $num... mode: $mode, state: $state");

    $lcd->clear;
    $lcd->display(OFF);

    $pi->cleanup;

    #
    # ultrasonic distance sensor
    #

    my $trig_pin = 23;
    my $echo_pin = 24;

    my $ruler = $pi->hcsr04($trig_pin, $echo_pin);

    my $inches = $sensor->inch;
    my $cm     = $sensor->cm;
    my $raw    = $sensor->raw;

    #
    # servo
    #

    my $pin_num = 18;

    my $servo = $pi->servo($pin_num);

    $servo->pwm(150); # centre position
    $servo->pwm(50);  # left position
    $servo->pwm(250); # right position

    #
    # stepper motor
    #

    my $sm = $pi->stepper_motor(
        pins => [12, 16, 20, 21]
    );

    $sm->cw(180);   # turn clockwise 180 degrees
    $sm->ccw(240);  # turn counter-clockwise 240 degrees

=head1 DESCRIPTION

This is the root module for the C<RPi::WiringPi> system. It interfaces to a
Raspberry Pi board, its accessories and its GPIO pins via the
L<wiringPi|http://wiringpi.com> library through the Perl wrapper
L<WiringPi::API|https://metacpan.org/pod/WiringPi::API>
module, and various other custom device specific  modules.

L<wiringPi|http://wiringpi.com> must be installed prior to installing/using
this module (v2.36+).

We always and only use the C<GPIO> pin numbering scheme. These are the pin
numbers that are printed on the Pi board itself.

This module is essentially a 'manager' for the sub-modules (ie. components).
You can use the component modules directly, but retrieving components through
this module instead has many benefits. We maintain a registry of pins and other
data. We also trap C<$SIG{__DIE__}> and C<$SIG{INT}>, so that in the event of a
crash, we can reset the Pi back to default settings, so components are not left
in an inconsistent state. Component modules do none of these things.

There are a basic set of constants that can be imported. See
L<RPi::Const>.

It's handy to have access to a pin mapping conversion chart. There's an
excellent pin scheme map for reference at
L<pinout.xyz|https://pinout.xyz/pinout/wiringpi>. You can also run the C<pinmap>
command that was installed by this module, or C<wiringPi>'s C<gpio readall>
command.

=head1 METHODS

See L<RPi::WiringPi::Core> for utility/helper/hardware-specific methods that are
imported into an C<RPi::WiringPi> object.

=head2 new([%args])

Returns a new C<RPi::WiringPi> object. We exclusively use the C<GPIO>
(Broadcom (BCM) GPIO) pin numbering scheme. These pin numbers are printed on the
Pi's board itself.

Parameters:

    fatal_exit => $bool

Optional: We trap all C<die()> calls and clean up for safety reasons. If a
call to C<die()> is trapped, by default, we clean up, and then C<exit()>. Set
C<fatal_exit> to false (C<0>) to perform the cleanup, and then continue running
your script. This is for unit testing purposes only.

=head2 adc()

There are two different ADCs that you can select from. The default is the
ADS1x15 series:

=head3 ADS1115

Returns a L<RPi::ADC::ADS> object, which allows you to read the four analog
input channels on an Adafruit ADS1xxx analog to digital converter.

Parameters:

The default (no parameters) is almost always enough, but please do review
the documentation in the link above for further information, and have a
look at the
L<ADC tutorial section|RPi::WiringPi::FAQ/ANALOG TO DIGITAL CONVERTERS (ADC)> in
this distribution.

=head3 MCP3008

You can also use an L<RPi::ADC::MCP3008> ADC.

Parameters:

    model => 'MCP3008'

Mandatory, String. The exact quoted string above.

    channel => $channel

Mandatory, Integer. C<0> or C<1> for the Pi's onboard hardware CS/SS CE0 and CE1
pins, or any GPIO number above C<1> in order to use an arbitrary GPIO pin for
the CS pin, and we'll do the bit-banging of the SPI bus automatically.

=head2 bmp()

Returns a L<RPi::BMP180> object, which allows you to return the
current temperature in farenheit or celcius, along with the ability to retrieve
the barometric pressure in kPa.

=head2 dac(model => 'MCP4922')

Returns a L<RPi::DAC::MCP4922> object (supports all 49x2 series DACs). These
chips provide analog output signals from the Pi's digital output. Please
see the documentation of that module for further information on both the
configuration and use of the DAC object.

Parameters:

    model => 'MCP4922'

Optional, String. The model of the DAC you're using. Defaults to C<MCP4922>.

    channel => 0|1

Mandatory, Bool. The SPI channel to use.

    cs => Integer

Mandatory, Integer. A valid GPIO pin that the DAC's Chip Select is connected to.

There are a handful of other parameters that aren't required. For those, please
refer to the L<RPi::DAC::MCP4922> documentation.

=head2 dpot($cs, $channel)

Returns a L<RPi::DigiPot::MCP4XXXX> object, which allows you to manage a
digital potentiometer (only the MCP4XXXX versions are currently supported).

See the linked documentation for full documentation on usage, or the
L<RPi::WiringPi::FAQ> for usage examples.

=head2 gps

Returns a L<GPSD::Parse> object, allowing you to track your location.

The GPS distribution requires C<gpsd> to be installed and running. All
parameters for the GPS can be sent in here and we'll pass them along. Please see
the link above for the full documentation on that module.

=head2 hcsr04($trig, $echo)

Returns a L<RPi::HCSR04> ultrasonic distance measurement sensor object, allowing
you to retrieve the distance from the sensor in inches, centimetres or raw data.

Parameters:

    $trig

The trigger pin number, in GPIO numbering scheme.

    $echo

The echo pin number, in GPIO numbering scheme.

=head2 hygrometer($pin)

Returns a L<RPi::DHT11> temperature/humidity sensor object, allows you to fetch
the temperature (celcius or farenheit) as well as the current humidity level.

=head2 i2c($addr, [$device])

Creates a new L<RPi::I2C> device object which allows you to communicate with
the devices on an I2C bus.

See the linked documentation for full documentation on usage, or the
L<RPi::WiringPi::FAQ> for usage examples.

Aruino note: If using I2C with an Arduino, the Pi may speak faster than the
Arduino can. If this is the case, try lowering the I2C bus speed on the Pi:

    dtparam=i2c_arm_baudrate=10000

=head2 lcd(...)

Returns a L<RPi::LCD> object, which allows you to fully manipulate
LCD displays connected to your Raspberry Pi.

Please see the linked documentation for information regarding the parameters
required.

=head2 pin($pin_num)

Returns a L<RPi::Pin> object, mapped to a specified GPIO pin, which
you can then perform operations on. See that documentation for full usage
details.

Parameters:

    $pin_num

Mandatory, Integer: The pin number to attach to.

=head2 serial($device, $baud)

Creates a new L<RPi::Serial> object which allows basic read/write access to a
serial bus.

See the linked documentation for full documentation on usage, or the
L<RPi::WiringPi::FAQ> for usage examples.

NOTE: Bluetooth on the Pi overlays the serial pins (14, 15) on the Pi. To use
serial, you must disable bluetooth in the C</boot/config.txt> file:

    dtoverlay=pi3-disable-bt-overlay

=head2 servo($pin_num)

This method configures PWM clock and divisor to operate a typical 50Hz servo,
and returns a special L<RPi::Pin> object. These servos have a C<left> pulse of
C<50>, a C<centre> pulse of C<150> and a C<right> pulse of C<250>. On exit of
the program (or a crash), we automatically clean everything up properly.

Parameters:

    $pin_num

Mandatory, Integer: The pin number (technically, this *must* be C<18> on the
Raspberry Pi 3, as that's the only hardware PWM pin.

    %pwm_config

Optional, Hash. This parameter should only be used if you know what you're
doing and are having very specific issues.

Keys are C<clock> with a value that coincides with the PWM clock speed. It
defaults to C<192>. The other key is C<range>, the value being an integer that
sets the range of the PWM. Defaults to C<2000>.

Example:

    my $servo = $pi->servo(18);

    $servo->pwm(50);  # all the way left
    $servo->pwm(250); # all the way right

=head2 shift_register($base, $num_pins, $data, $clk, $latch)

Allows you to access the output pins of up to four 74HC595 shift registers in
series, for a total of eight new output pins per register. Numerous chains of
four registers are permitted, each chain uses three GPIO pins.

Parameters:

    $base

Mandatory: Integer, represents the number at which you want to start
referencing the new output pins attached to the register(s). For example, if
you use C<100> here, output pin C<0> of the register will be C<100>, output
C<1> will be C<101> etc.

    $num_pins

Mandatory: Integer, the number of output pins on the registers you want to use.
Each register has eight outputs, so if you have a single register in use, the
maximum number of additional pins would be eight.

    $data

Mandatory: Integer, the GPIO pin number attached to the C<DS> pin (14) on the
shift register.

    $clk

Mandatory: Integer, the GPIO pin number attached to the C<SHCP> pin (11) on the
shift register.

    $latch

Mandatory: Integer, the GPIO pin number attached to the C<STCP> pin (12) on the
shift register.

=head2 spi($channel, $speed)

Creates a new L<RPi::SPI> object which allows you to communicate on the Serial
Peripheral Interface (SPI) bus with attached devices.

See the linked documentation for full documentation on usage, or the
L<RPi::WiringPi::FAQ> for usage examples.

=head2 stepper_motor($pins)

Creates a new L<RPi::StepperMotor> object which allows you to drive a
28BYJ-48 stepper motor with a ULN2003 driver chip.

See the linked documentation for full usage instructions and the optional
parameters.

Parameters:

    pins => $aref

Mandatory, Array Reference: The ULN2003 has four data pins, IN1, IN2, IN3 and
IN4. Send in the GPIO pin numbers in the array reference which correlate to the
driver pins in the listed order.

    speed => 'half'|'full'

Optional, String: By default we run in "half speed" mode. Essentially, in this
mode we run through all eight steps. Send in 'full' to double the speed of the
motor. We do this by skipping every other step.

    delay => Float|Int

Optional, Float or Int: By default, between each step, we delay by C<0.01>
seconds. Send in a float or integer for the number of seconds to delay each step
by. The smaller this number, the faster the motor will turn.

=head1 RUNNING TESTS

Please see L<RUNNING TESTS|RPi::WiringPi::FAQ/RUNNING TESTS> in the
L<FAQ|RPi::WiringPi::FAQ>.

=head1 TROUBLESHOOTING

Please read through the L<SETUP|RPi::WiringPi::FAQ/SETUP> section in the
L<FAQ|RPi::WiringPi::FAQ>.

=head1 AUTHOR

Steve Bertrand, E<lt>steveb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017,2018 by Steve Bertrand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.
