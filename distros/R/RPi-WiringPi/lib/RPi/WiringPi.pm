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
use RPi::OLED::SSD1306::128_64;
use RPi::Pin;
use RPi::RTC::DS3231;
use RPi::Serial;
use RPi::SPI;
use RPi::StepperMotor;

our $VERSION = '2.3633';

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
                if ($self->_setup =~ /^w/i) {
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

    if (defined $args{model} && $args{model} eq 'MCP3008'){
        my $pin = $self->pin($args{channel});
        return RPi::ADC::MCP3008->new($pin->num);
    }
    else {
        # ADSxxxx ADCs don't require any pins
        return RPi::ADC::ADS->new(%args);
    }
}
sub bmp {
    return RPi::BMP180->new($_[1]);
}
sub dac {
    my ($self, %args) = @_;
    $self->pin($args{cs});
    $self->pin($args{shdn}) if defined $args{shdn};
    $args{model} = 'MCP4922' if ! defined $args{model};
    return RPi::DAC::MCP4922->new(%args);
}
sub dpot {
    my ($self, $cs, $channel) = @_;
    $self->pin($cs);
    return RPi::DigiPot::MCP4XXXX->new($cs, $channel);
}
sub expander {
    my ($self, $addr, $expander) = @_;

    if (! defined $expander || $expander eq 'MCP23017'){
        $addr = 0x20 if ! defined $addr;
        return RPi::GPIOExpander::MCP23017->new($addr);
    }
}
sub gps {
    my ($self, %args) = @_;
    return GPSD::Parse->new(%args);
}
sub hcsr04 {
    my ($self, $t, $e) = @_;
    $self->pin($_) for ($t, $e);
    return RPi::HCSR04->new($t, $e);
}
sub hygrometer {
    my ($self, $pin) = @_;
    $self->register_pin($pin);
    return RPi::DHT11->new($pin);
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
sub oled {
    my ($self, $model, $i2c_addr, $display_splash_page) = @_;

    $model //= '128x64';
    $i2c_addr //= 0x3C;

    my %models = (
        '128x64'  => 1,
        '128x32'  => 1,
        '96x16'   => 1,
    );

    if (! exists $models{$model}){
        die "oled() requires one of the following models sent in: " .
              "128x64, 128x32 or 96x16\n";
    }

    if ($model eq '128x64'){
        return RPi::OLED::SSD1306::128_64->new($i2c_addr, $display_splash_page);
    }
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
sub rtc {
    my ($self, $rtc_addr) = @_;
    return RPi::RTC::DS3231->new($rtc_addr);
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

Please see the L<FAQ|RPi::WiringPi::FAQ> for full usage details.

    use RPi::WiringPi;
    use RPi::Const qw(:all);

    my $pi = RPi::WiringPi->new;

    # For the below handful of system methods, see RPi::SysInfo

    my $mem_percent = $pi->mem_percent;
    my $cpu_percent = $pi->cpu_percent;
    my $cpu_temp    = $pi->core_temp;
    my $gpio_info   = $pi->gpio_info;
    my $raspi_conf  = $pi->raspi_config;
    my $net_info    = $pi->network_info;
    my $file_system = $pi->file_system;
    my $hw_details  = $pi->pi_details;

    # pin

    my $pin = $pi->pin(5);
    $pin->mode(OUTPUT);
    $pin->write(ON);

    my $num = $pin->num;
    my $mode = $pin->mode;
    my $state = $pin->read;

    # cleanup all pins and reset them to default before exiting your program

    $pi->cleanup;

=head1 DESCRIPTION

This is the root module for the C<RPi::WiringPi> system. It interfaces to a
Raspberry Pi board, its accessories and its GPIO pins via the
L<wiringPi|http://wiringpi.com> library through the Perl wrapper
L<WiringPi::API|https://metacpan.org/pod/WiringPi::API>
module, and various other custom device specific  modules.

L<wiringPi|http://wiringpi.com> must be installed prior to installing/using
this module (v2.36+).

We always and only use the C<GPIO> pin numbering scheme.

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

=head1 BASE METHODS

=head2 new([%args])

Returns a new C<RPi::WiringPi> object. We exclusively use the C<GPIO>
(Broadcom (BCM) GPIO) pin numbering scheme.

Parameters:

    fatal_exit => $bool

Optional: We trap all C<die()> calls and clean up for safety reasons. If a
call to C<die()> is trapped, by default, we clean up, and then C<exit()>. Set
C<fatal_exit> to false (C<0>) to perform the cleanup, and then continue running
your script.

We recommend only disabling this feature if you're doing unit test work, want to
allow other exit traps to catch, allow the Pi to continue on working after a
fatal error etc. If disabled, you will be responsible for doing your own cleanup
of the Pi hardware configuration on exit.

=head2 adc

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

=head2 bmp

Returns a L<RPi::BMP180> object, which allows you to return the
current temperature in farenheit or celcius, along with the ability to retrieve
the barometric pressure in kPa.

=head2 dac

Returns a L<RPi::DAC::MCP4922> object (supports all 49x2 series DACs). These
chips provide analog output signals from the Pi's digital output. Please
see the documentation of that module for further information on both the
configuration and use of the DAC object.

Parameters:

    model => 'MCP4922'

Optional, String. The model of the DAC you're using. Defaults to C<MCP4922>.

    channel => 0|1

Mandatory, Bool. The SPI channel to use.

    cs => $pin

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

Mandatory, Integer: The trigger pin number, in GPIO numbering scheme.

    $echo

Mandatory, Integer: The echo pin number, in GPIO numbering scheme.

=head2 hygrometer($pin)

Returns a L<RPi::DHT11> temperature/humidity sensor object, allows you to fetch
the temperature (celcius or farenheit) as well as the current humidity level.

Parameters:

    $pin

Mandatory, Integer: The GPIO pin the sensor is connected to.

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

=head2 oled([$model], [$i2c_addr])

Returns a specific C<RPi::OLED::SSD1306> OLED display object, allowing you to
display text, characters and shapes to the screen.

Currently, only the C<128x64> size model is offered, see the
L<RPi::OLED::SSD1306::128_64> documentation for full usage details.

Parameters:

    $model

Optional, String: The screen size of the OLED you've got. Valid options are
C<128x64>, C<128x32> and C<96x16>. Currently, only the C<128x64> option is
valid, and it's the default if not sent in.

    $i2c_addr

Optional, Integer: The I2C address of your display. Defaults to C<0x3C> if not
sent in.

=head2 pin($pin_num)

Returns a L<RPi::Pin> object, mapped to a specified GPIO pin, which
you can then perform operations on. See that documentation for full usage
details.

Parameters:

    $pin_num

Mandatory, Integer: The pin number to attach to.

=head2 rtc

Creates a new L<RPi::RTC::DS3231> object which provides access to the C<DS3231>
or C<DS1307> real-time clock modules.

See the linked documentation for full documentation on usage, or the
L<RPi::WiringPi::FAQ> for some usage examples.

Parameters:

    $i2c_addr

Optional, Integer: The I2C address of the RTC module. Defaults to C<0x68> for
the C<DS3231> unit.

=head2 expander

Creates a new L<RPi::GPIOExpander::MCP23017> GPIO expander chip object. This
adds an additional 16 pins across two banks (8 pins per bank).

See the linked documentation for full documentation on usage, or the
L<RPi::WiringPi::FAQ> for some usage examples.

Parameters:

    $i2c_addr

Optional, Integer: The I2C address of the device. Defaults to C<0x20>.

    $expander

Optional, String: The GPIO expander device type. Defaults to C<MCP23017>, and
currently, this is the only option available.

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

=head2 CORE PI SYSTEM METHODS

Core methods are inherited in and documented in L<RPi::WiringPi::Core>. See
that documentation for full details of each one. I've included a basic
description of them here.

=head3 gpio_layout

Returns the GPIO layout, which in essence is the Pi board revision number.

=head3 io_led

Turn the disk IO (green) LED on or off.

=head3 pwr_led

Turn the power (red) LED on or off.

=head3 identify

Toggles the power led off and disk IO led on which allows external physical
identification of the Pi you're running on.

=head3 label

Sets an internal label/name to your L<RPi::WiringPi> Pi object.

=head3 pin_scheme

Returns the current pin mapping scheme in use within the object.

=head3 pin_map

Returns a hash reference mapping of the physical pin numbers to a pin scheme's
pin numbers.

=head3 pin_to_gpio

Converts a pin number from any non-GPIO (BCM) scheme to GPIO (BCM) scheme.

=head3 wpi_to_gpio

Converts a wiringPi pin number to GPIO pin number.

=head3 phys_to_gpio

Converts a physical pin number to the GPIO pin number.

=head3 pwm_range

Set/get the PWM range.

=head3 pwm_mode

Set/get the PWM mode.

=head3 pwm_clock

Set/get the PWM clock.

=head3 export_pin

Exports a pin if running under the C<setup_sys()> initialization scheme.

=head3 unexport_pin

Un-exports a pin if running under the C<setup_sys()> initialization scheme.

=head3 registered_pins

Returns an array reference of all pin numbers currently registered in the
system. Used primarily for cleanup functionality.

=head3 register_pin

Registers a pin with the system for error checking, and proper resetting in the
cleanup routines.

=head3 unregister_pin

Removes an already registered pin.

=head3 cleanup

Cleans up the entire system, resetting all pins and devices back to the state
we found them in when we initialized the system.

=head2 ADDITIONAL PI SYSTEM METHODS

We also include in the Pi object several hardware-type methods brought in from
L<RPi::SysInfo>. They are loaded through L<RPi::WiringPi::Core> via
inheritance. See the L<RPi::SysInfo> documentation for full method details.

    my $mem_percent = $pi->mem_percent;
    my $cpu_percent = $pi->cpu_percent;
    my $cpu_temp    = $pi->core_temp;
    my $gpio_info   = $pi->gpio_info;
    my $raspi_conf  = $pi->raspi_config;
    my $net_info    = $pi->network_info;
    my $file_system = $pi->file_system;
    my $hw_details  = $pi->pi_details;

=head3 cpu_percent

Returns the current CPU usage.

=head3 mem_percent

Returns the current memory usage.

=head3 core_temp

Returns the current temperature of the CPU core.

=head3 gpio_info

Returns the current status and configuration of one, many or all of the GPIO
pins.

=head3 raspi_config

Returns a list of all configured parameters in the C</boot/config.txt> file.

=head3 network_info

Returns the network configuration of the Pi.

=head3 file_system

Returns current disk and mount information.

=head3 pi_details

Returns various information on both the hardware and OS aspects of the Pi.

=head1 RUNNING TESTS

Please see L<RUNNING TESTS|RPi::WiringPi::FAQ/RUNNING TESTS> in the
L<FAQ|RPi::WiringPi::FAQ>.

=head1 TROUBLESHOOTING

Please read through the L<SETUP|RPi::WiringPi::FAQ/SETUP> section in the
L<FAQ|RPi::WiringPi::FAQ>.

=head1 AUTHOR

Steve Bertrand, E<lt>steveb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2019 by Steve Bertrand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.
